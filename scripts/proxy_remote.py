#!/usr/bin/env python3
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# The HTTP proxy python script to allow the VM's to leave the sandbox
# in case it's really needed. Triggered by `run_asnible.sh` if needed
# so no need to run manually.
#
# Usage:
#   $ ./proxy_remote.py [[host] port]

import sys
import http.server
import http.client
import socket
import ssl
import threading
import select
from urllib.parse import urlparse

class ProxyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        self.handle_http_request()

    def do_POST(self):
        self.handle_http_request()

    def do_CONNECT(self):
        self.handle_tcp_connect()

    def handle_http_request(self):
        url = urlparse(self.path)
        print(f"PROXYR: {self.command} request for {url.geturl()}")

        if url.scheme == "https":
            client = http.client.HTTPSConnection(url.netloc, context=ssl._create_unverified_context())
        else:
            client = http.client.HTTPConnection(url.netloc)

        client.request(
            self.command,
            url.path,
            body=self.rfile.read(int(self.headers['Content-Length'])) if 'Content-Length' in self.headers else None,
            headers=self.headers
        )

        response = client.getresponse()
        self.send_response(response.status)

        for key, value in response.getheaders():
            self.send_header(key, value)
        self.end_headers()

        self.wfile.write(response.read())
        client.close()

    def handle_tcp_connect(self):
        print(f"PROXYR: {self.command} request for {self.path}")
        self.send_response(200)
        self.end_headers()
        try:
            hostname, port = self.path.split(':')
            port = int(port)
        except ValueError:
            self.wfile.write(b'Invalid host or port')
            return

        try:
            downstream = socket.create_connection((hostname, port))
            print(f"PROXYR: Connected to {hostname}:{port}")
        except Exception as e:
            print(f"PROXYR: Failed to connect to {hostname}:{port}: {e}")
            self.wfile.write(b'Failed to connect')
            return

        print(f"PROXYR: Tunnel established to {hostname}:{port}")
        upstream = self.connection
        self.rfile = downstream.makefile('rb')
        self.wfile = downstream.makefile('wb')
        self._run_request_loop(upstream, downstream)

    def _run_request_loop(self, upstream, downstream):
        try:
            while True:
                r, w, x = select.select([upstream, downstream], [], [])
                if upstream in r:
                    data = upstream.recv(1024)
                    if not data:
                        break
                    downstream.sendall(data)
                if downstream in r:
                    data = downstream.recv(4024)
                    if not data:
                        break
                    upstream.sendall(data)
        except socket.error as e:
            print(f"PROXYR: Socket error: {e}")
        finally:
            print("PROXYR: Tunnel closed")
            upstream.close()
            downstream.close()


if __name__ == "__main__":
    host = '0.0.0.0'
    port = 0 # Automatically select available port
    if len(sys.argv) > 2:
        host = sys.argv[1]
        port = int(sys.argv[2])
    elif len(sys.argv) > 1:
        port = int(sys.argv[1])

    with http.server.HTTPServer((host, port), ProxyHTTPRequestHandler) as server:
        print("PROXYR: Started Aquarium Bait HTTP Remote proxy on %s:%d" % server.socket.getsockname())
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("PROXYR: Stopping the proxy process...")

