#!/usr/bin/env python3

# Simple python socks proxy to skip routing to the local resources.
#
# Usage:
#   $ ./proxy.py [port]
#
# The magic behind it - is using socket.SO_DONTROUTE which skipping
# the route table and allow to connect to the local resources even if
# corporate VPN connetion is active (which reroutes all the traffic).

import sys
import select
import socket
import struct
from socketserver import ThreadingMixIn, TCPServer, StreamRequestHandler

SOCKS_VERSION = 5

class ThreadingTCPServer(ThreadingMixIn, TCPServer):
    _running = True
    pass

class SocksProxy(StreamRequestHandler):
    def handle(self):
        print('PROXY: Accepting connection from:', self.client_address)

        # greeting header
        # read and unpack 2 bytes from a client
        header = self.connection.recv(2)
        version, nmethods = struct.unpack("!BB", header)

        # socks 5
        assert version == SOCKS_VERSION
        assert nmethods > 0

        # get available methods
        methods = self.get_available_methods(nmethods)

        # send welcome message
        self.connection.sendall(struct.pack("!BB", SOCKS_VERSION, 0))

        # request
        version, cmd, _, address_type = struct.unpack("!BBBB", self.connection.recv(4))
        assert version == SOCKS_VERSION

        if address_type == 1:  # IPv4
            address = socket.inet_ntoa(self.connection.recv(4))
        elif address_type == 3:  # Domain name
            domain_length = self.connection.recv(1)[0]
            address = self.connection.recv(domain_length)
            address = socket.gethostbyname(address)
        port = struct.unpack('!H', self.connection.recv(2))[0]

        # reply
        try:
            print('PROXY: Connecting to:', address, port)
            if cmd == 1:  # CONNECT
                remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                remote.setsockopt(socket.SOL_SOCKET, socket.SO_DONTROUTE, 1)
                remote.connect((address, port))
                bind_address = remote.getsockname()
                print('PROXY: Connected to:', address, port)
            else:
                self.server.close_request(self.request)

            addr = struct.unpack("!I", socket.inet_aton(bind_address[0]))[0]
            port = bind_address[1]
            reply = struct.pack("!BBBBIH", SOCKS_VERSION, 0, 0, 1, addr, port)

        except Exception as err:
            print("PROXY: Error:", err)
            # return connection refused error
            reply = self.generate_failed_reply(address_type, 5)

        self.connection.sendall(reply)

        # establish data exchange
        if reply[1] == 0 and cmd == 1:
            self.exchange_loop(self.connection, remote)

        self.server.close_request(self.request)

    def get_available_methods(self, n):
        methods = []
        for i in range(n):
            methods.append(ord(self.connection.recv(1)))
        return methods

    def generate_failed_reply(self, address_type, error_number):
        return struct.pack("!BBBBIH", SOCKS_VERSION, error_number, 0, address_type, 0, 0)

    def exchange_loop(self, client, remote):
        while self.server._running:
            # wait until client or remote is available for read
            r, w, e = select.select([client, remote], [], [])

            if client in r:
                try:
                    data = client.recv(4096)
                    if remote.send(data) <= 0:
                        break
                except ConnectionResetError:
                    print("PROXY: Connection was reset by client")
                    break

            if remote in r:
                try:
                    data = remote.recv(4096)
                    if client.send(data) <= 0:
                        break
                except ConnectionResetError:
                    print("PROXY: Connection was reset by remote")
                    break

if __name__ == '__main__':
    port = 0 # Automatically select available port
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    with ThreadingTCPServer(('127.0.0.1', port), SocksProxy) as server:
        print("PROXY: Started Aquarium Bait noroute proxy on %s %s" % server.server_address)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("PROXY: Stopping the proxy process...")
            server._running = False
