#!/usr/bin/env python3
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# This script looks at the packer logs and record video of what's happening on
# the screen so you will be able to get what's happened during the image build
# even if you using headless mode or stepped aside for a coffee brake.
#
# The screenshots are taken when the script sees "Waiting" in the packer
# logs - and if it's more than 9 seconds it takes a screenshot

import os, sys, time
import time
from datetime import datetime as dt
import logging
import threading, queue
from vncdotool import api
import cv2
import numpy

logging.basicConfig(level=logging.ERROR)

class VNCRecord:
    def __init__(self, record_path, host = None, port = None, pwd = None):
        self._rec_path = record_path

        self._host = host
        self._port = port
        self._password = pwd
        self._resolution = (1024, 768)
        self._fps = 2

        self._fetch_thread = None
        self._encode_thread = None

        self._is_recording = False
        self._frame_queue = queue.Queue(1)
        self._current_log = ''

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    def process(self, log_path):
        print('VNCRECORD: Waiting for the log file "{}"'.format(log_path))
        while not os.path.isfile(log_path):
            time.sleep(0.1)

        print('VNCRECORD: Reading the log file "{}"'.format(log_path))
        with open(log_path, 'r') as f:
            # Locating the VNC credentials
            for line in self.tail(f):
                if self._password and self._host and self._port:
                    print('VNCRECORD: VNC credentials was found: {}:{} "{}"'.format(self._host, self._port, self._password))
                    break

                if line is None:
                    return

                # Check for password
                #     vmware-vmx: view the screen of the VM, connect via VNC with the password "nTtBphgk" to
                if 'connect via VNC with the password "' in line:
                    self._password = line.rsplit(' ', 2)[-2].strip('"')

                # Check for host and port
                #     vmware-vmx: vnc://127.0.0.1:5983
                elif 'vmware-vmx: vnc://' in line:
                    self._host, self._port = line.rsplit('vnc://', 1)[-1].split(':')

            # Looking for the "Waiting" patterns
            was_started = False
            try:
                for line in self.tail(f):
                    if line is None:
                        return

                    self._current_log = line.strip()

                    if 'vmware-vmx: Waiting' in line and ' for boot...' in line:
                        self.startRecording()
                        was_started = True
                    elif 'vmware-vmx: Gracefully halting virtual machine...' in line or \
                            'vmware-vmx: Stopping virtual machine' in line:
                        break

                    if was_started and not self._is_recording:
                        # End the log reading when recording was stopped
                        break
            except KeyboardInterrupt:
                print('VNCRECORD: Exiting by keyboard interrupt...')
            self.stopRecording()

    def startRecording(self):
        if self._is_recording:
            return
        self._is_recording = True
        self._encode_thread = threading.Thread(target=self._encodeFramesProcess)
        self._encode_thread.start()
        self._fetch_thread = threading.Thread(target=self._fetchFramesProcess, daemon=True)
        self._fetch_thread.start()
        print("VNCRECORD: Recording started")

    def stopRecording(self):
        if not self._is_recording:
            return
        self._is_recording = False
        print("VNCRECORD: Recording stopping...")

    def addFrame(self, pil_image):
        '''Puts the copy of received image into the queue for encoding'''
        frame_log = str(self._current_log)
        self._frame_queue.put( (pil_image.convert('RGB'), frame_log) )

    def _fetchFramesProcess(self):
        client = api.connect('{}::{}'.format(self._host, int(self._port)), password=self._password)
        partial = 0
        while self._is_recording:
            start = time.time()
            # It will wait for the screen changes, but will not return until it will be here
            d = client.refreshScreen(incremental=partial)
            # In case the update is not here - add the same frame to the video
            partial = 1
            self.addFrame(d.screen)
            tosleep = max(1.0/self._fps - (time.time() - start), 0)
            time.sleep(tosleep)
        print("VNCRECORD: Fetch stopped")

    def _encodeFramesProcess(self):
        '''Processes the queue and generates the record file'''
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        if sys.platform == 'darwin':
            # mp4v messing up the video if it has too low framerate on MacOS (<10FPS)
            fourcc = cv2.VideoWriter_fourcc(*'avc1')
        out = cv2.VideoWriter(self._rec_path, fourcc, self._fps, self._resolution, isColor=True)

        counter = 0
        # Timeout needs to keep the frame rate for the video
        time_out = 1/self._fps - (1/self._fps/20)

        # There could be no frame in queue if screen is the same - so we need
        # to keep the previous one to ensure the video will be continuous
        frame, log_line = None, None
        while self._is_recording or not self._frame_queue.empty():
            counter+=1
            start = time.time()
            try:
                (frame, log_line) = self._frame_queue.get(timeout=time_out)
            except queue.Empty:
                # If there is no previous frame - skipping this frame
                if not frame:
                    continue
                # Making the log rolling even if there is no frame was received
                log_line = str(self._current_log)

            cv_img = cv2.cvtColor(numpy.array(frame), cv2.COLOR_RGB2BGR)
            cv_img = self.resizeAndPad(cv_img, self._resolution)
            # Put log line on the bottom
            cv2.putText(cv_img, log_line, (20, self._resolution[1]-20), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255,255,255), 1, 2)
            # Put current time on top
            cv2.putText(cv_img, dt.fromtimestamp(start).strftime("%Y/%m/%d, %H:%M:%S"), (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255,255,255), 1, 2)
            out.write(cv_img)

            tosleep = max(1.0/self._fps - (time.time() - start), 0)
            time.sleep(tosleep)

        out.release()
        print("VNCRECORD: Encode stopped on frame", counter)

    def resizeAndPad(self, img, size):
        '''Ensures we keep the same resolution for the output video'''
        h, w = img.shape[:2]
        sw, sh = size

        # Interpolation method
        if h > sh or w > sw: # Shrinking image
            interp = cv2.INTER_AREA
        else: # Stretching image
            interp = cv2.INTER_CUBIC

        # Aspect ratio of image
        aspect = w/h

        # Compute scaling and pad sizing
        if aspect > 1: # For horizontal image
            new_w = sw
            new_h = numpy.round(new_w/aspect).astype(int)
            pad_vert = (sh-new_h)/2
            pad_top, pad_bot = numpy.floor(pad_vert).astype(int), numpy.ceil(pad_vert).astype(int)
            pad_left, pad_right = 0, 0
        elif aspect < 1: # For vertical image
            new_h = sh
            new_w = numpy.round(new_h*aspect).astype(int)
            pad_horz = (sw-new_w)/2
            pad_left, pad_right = numpy.floor(pad_horz).astype(int), numpy.ceil(pad_horz).astype(int)
            pad_top, pad_bot = 0, 0
        else: # For square image
            new_h, new_w = sh, sw
            pad_left, pad_right, pad_top, pad_bot = 0, 0, 0, 0

        # Scale and pad
        scaled_img = cv2.resize(img, (new_w, new_h), interpolation=interp)
        scaled_img = cv2.copyMakeBorder(scaled_img, pad_top, pad_bot, pad_left, pad_right, borderType=cv2.BORDER_CONSTANT, value=(0,0,0))

        return scaled_img

    def tail(self, file, sleep_sec=0.1):
        line = ''
        while True:
            if not os.path.isfile(file.name):
                # The file is not exists anymore so returning None
                return None
            tmp = file.readline()
            if tmp:
                line += tmp
                if line.endswith("\n"):
                    yield line
                    line = ''
            else:
                time.sleep(sleep_sec)

if __name__ == '__main__':
    with VNCRecord(sys.argv[2]) as s:
        s.process(sys.argv[1])
    print('VNCRECORD: Log reading was completed')
