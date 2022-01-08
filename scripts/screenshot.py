#!/usr/bin/env python3

# This script looks at the packer logs and makes screenshots during vnc
# commands execution, it stores screenshots as png images so you will be
# able to get what's happened during the build even if you using headless
# mode or stepped aside for a coffee brake.
#
# The screenshots are taken when the script sees "Waiting" in the packer
# logs - and if it's more than 9 seconds it takes a screenshot

import os, sys, time
import logging
import threading
from datetime import datetime, timedelta
from vncdotool import api

logging.basicConfig(level=logging.ERROR)

class Screenshot:
    def __init__(self, screenshots_path, host = None, port = None, pwd = None):
        self._scr_path = screenshots_path

        self._host = host
        self._port = port
        self._password = pwd
        self._catched_wait_number = 0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    def process(self, log_path):
        print('SCREENSHOT: Waiting for the log file "{}"'.format(log_path))
        while not os.path.isfile(log_path):
            time.sleep(0.1)

        print('SCREENSHOT: Reading the log file "{}"'.format(log_path))
        with open(log_path, 'r') as f:
            # Locating the VNC credentials
            for line in self.tail(f):
                if self._password and self._host and self._port:
                    print('SCREENSHOT: VNC credentials was found: {}:{} "{}"'.format(self._host, self._port, self._password))
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

            begin_time = datetime.now()

            # Looking for the "Waiting" patterns
            for line in self.tail(f):
                if line is None:
                    return

                if 'vmware-vmx: Waiting' in line and ' for boot...' in line:
                    duration = self.parseDuration(line.split('vmware-vmx: Waiting ')[-1].split(' ')[0])
                    self.screenshotWait(datetime.now() - begin_time + duration)
                elif 'plugin: [INFO] Waiting' in line:
                    duration = self.parseDuration(line.rsplit(' ')[-1].strip())
                    if duration > timedelta(seconds=9):
                        self.screenshotWait(duration)

    def parseDuration(self, data):
        try:
            try:
                try:
                    t = datetime.strptime(data, '%Hh%Mm%Ss')
                except ValueError:
                    t = datetime.strptime(data, '%Mm%Ss')
            except ValueError:
                t = datetime.strptime(data, '%Ss')
        except ValueError as e:
            print("SCREENSHOT: Warn: weird data to parse duration: {}: {}".format(data, e))
            return timedelta(seconds=0)
        return timedelta(hours=t.hour, minutes=t.minute, seconds=t.second)

    def screenshotWait(self, dur):
        '''
        Runs the waiting process and taking screenshots in the meanwhile.
        At least 2 screenshots will be taken - in the beginning and in the end (-2s) of wait.
        Each minute of waiting adds 1 screenshot in the middle to 5 total maximum.
        '''
        begin_time = datetime.now()
        wait_max_screenshots = 5
        screenshot_counter = 0
        if dur < timedelta(minutes=wait_max_screenshots):
            wait_max_screenshots = max(int(dur.total_seconds() / 60), 1)

        screenshot_interval = (dur - timedelta(seconds=2)) / wait_max_screenshots

        while True:
            self._thread = threading.Thread(target=self.screenshot, args=('%s-%04d-%d' % (self._scr_path, self._catched_wait_number, screenshot_counter),), daemon=True)
            self._thread.start()
            screenshot_counter += 1
            dur_left = begin_time - datetime.now() + dur
            if dur_left <= timedelta(seconds=2):
                break
            elif dur_left < screenshot_interval:
                screenshot_interval = dur_left - timedelta(seconds=2)

            print("SCREENSHOT: Sleeping for {} ({} left)".format(screenshot_interval, dur_left))
            time.sleep(screenshot_interval.total_seconds())

        self._catched_wait_number += 1

    def screenshot(self, name):
        # TODO: I think it's not great to create vncdo client for every screenshot, maybe
        # we can preserve it and the connection (and reconnect only if the connection was
        # broken) - not sure, need to check this possibility.
        client = api.connect('{}::{}'.format(self._host, int(self._port)), password=self._password)
        client.captureScreen('{}.png'.format(name))
        print("SCREENSHOT: Created screenshot '{}.png'".format(name))

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
    with Screenshot(sys.argv[2]) as s:
        s.process(sys.argv[1])
    print('SCREENSHOT: Log reading was completed')
