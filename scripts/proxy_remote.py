#!/usr/bin/env python3
# Copyright 2021-2025 Adobe. All rights reserved.
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

import socket
import threading
import sys
import logging
import time
import urllib.parse
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='PROXYR: %(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('proxy.log')
    ]
)
logger = logging.getLogger(__name__)

class HTTPProxy:
    def __init__(self, host='0.0.0.0', port=0):
        self.host = host
        self.port = port
        self.server_socket = None

    def start(self):
        """Start the proxy server"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        try:
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(100)
            logger.info("Started Aquarium Bait HTTP Remote proxy on %s:%d" % self.server_socket.getsockname())

            while True:
                client_socket, client_address = self.server_socket.accept()
                logger.info(f"New connection from {client_address[0]}:{client_address[1]}")

                # Handle each client in a separate thread
                client_thread = threading.Thread(
                    target=self.handle_client,
                    args=(client_socket, client_address)
                )
                client_thread.daemon = True
                client_thread.start()

        except KeyboardInterrupt:
            logger.info("Shutting down proxy server...")
        except Exception as e:
            logger.error(f"Error starting server: {e}")
        finally:
            if self.server_socket:
                self.server_socket.close()

    def handle_client(self, client_socket, client_address):
        """Handle a client connection"""
        try:
            # Receive the request
            request_data = client_socket.recv(4096)
            if not request_data:
                return

            request_str = request_data.decode('utf-8', errors='ignore')
            request_lines = request_str.split('\r\n')

            if not request_lines:
                return

            # Parse the first line to get method, URL, and HTTP version
            first_line = request_lines[0]
            parts = first_line.split(' ')

            if len(parts) < 3:
                return

            method = parts[0]
            url = parts[1]
            http_version = parts[2]

            logger.info(f"Request from {client_address[0]}:{client_address[1]} - {method} {url}")

            if method == 'CONNECT':
                self.handle_connect(client_socket, client_address, url)
            else:
                self.handle_http_request(client_socket, client_address, request_data, method, url)

        except Exception as e:
            logger.error(f"Error handling client {client_address}: {e}")
        finally:
            client_socket.close()

    def handle_connect(self, client_socket, client_address, url):
        """Handle CONNECT method for HTTPS tunneling"""
        try:
            # Parse host and port from CONNECT request
            if ':' in url:
                target_host, target_port = url.split(':', 1)
                target_port = int(target_port)
            else:
                target_host = url
                target_port = 443  # Default HTTPS port

            logger.info(f"CONNECT tunnel from {client_address[0]}:{client_address[1]} to {target_host}:{target_port}")

            # Create connection to target server
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.settimeout(10)

            try:
                target_socket.connect((target_host, target_port))
                logger.info(f"Successfully connected to {target_host}:{target_port}")

                # Send 200 Connection established response
                response = "HTTP/1.1 200 Connection established\r\n\r\n"
                client_socket.send(response.encode())

                # Start tunneling data between client and target
                self.tunnel_data(client_socket, target_socket, client_address, target_host, target_port)

            except socket.timeout:
                logger.error(f"Timeout connecting to {target_host}:{target_port}")
                error_response = "HTTP/1.1 504 Gateway Timeout\r\n\r\n"
                client_socket.send(error_response.encode())
            except socket.gaierror as e:
                logger.error(f"DNS resolution failed for {target_host}: {e}")
                error_response = "HTTP/1.1 502 Bad Gateway\r\n\r\n"
                client_socket.send(error_response.encode())
            except Exception as e:
                logger.error(f"Error connecting to {target_host}:{target_port}: {e}")
                error_response = "HTTP/1.1 502 Bad Gateway\r\n\r\n"
                client_socket.send(error_response.encode())
            finally:
                target_socket.close()

        except Exception as e:
            logger.error(f"Error in CONNECT handler: {e}")

    def handle_http_request(self, client_socket, client_address, request_data, method, url):
        """Handle regular HTTP requests"""
        try:
            # Parse URL
            parsed_url = urllib.parse.urlparse(url)

            # For absolute URLs, extract host and port
            if parsed_url.netloc:
                host_port = parsed_url.netloc
                if ':' in host_port:
                    target_host, target_port = host_port.split(':', 1)
                    target_port = int(target_port)
                else:
                    target_host = host_port
                    target_port = 80  # Default HTTP port

                # Reconstruct the path for the request
                path = parsed_url.path
                if parsed_url.query:
                    path += '?' + parsed_url.query
                if not path:
                    path = '/'

            else:
                # Relative URL - this shouldn't happen in proxy requests
                logger.error(f"Received relative URL in proxy request: {url}")
                error_response = "HTTP/1.1 400 Bad Request\r\n\r\n"
                client_socket.send(error_response.encode())
                return

            logger.info(f"HTTP request from {client_address[0]}:{client_address[1]} to {target_host}:{target_port} - {method} {path}")

            # Create connection to target server
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.settimeout(10)

            try:
                target_socket.connect((target_host, target_port))

                # Modify the request to use the path instead of full URL
                request_str = request_data.decode('utf-8', errors='ignore')
                request_lines = request_str.split('\r\n')

                # Replace the first line with the modified path
                first_line_parts = request_lines[0].split(' ')
                if len(first_line_parts) >= 3:
                    first_line_parts[1] = path
                    request_lines[0] = ' '.join(first_line_parts)

                # Reconstruct the request
                modified_request = '\r\n'.join(request_lines)

                # Send the modified request to target server
                target_socket.send(modified_request.encode())

                # Forward the response back to client
                while True:
                    response_data = target_socket.recv(4096)
                    if not response_data:
                        break
                    client_socket.send(response_data)

                logger.info(f"HTTP request completed for {client_address[0]}:{client_address[1]}")

            except socket.timeout:
                logger.error(f"Timeout connecting to {target_host}:{target_port}")
                error_response = "HTTP/1.1 504 Gateway Timeout\r\n\r\n"
                client_socket.send(error_response.encode())
            except socket.gaierror as e:
                logger.error(f"DNS resolution failed for {target_host}: {e}")
                error_response = "HTTP/1.1 502 Bad Gateway\r\n\r\n"
                client_socket.send(error_response.encode())
            except Exception as e:
                logger.error(f"Error forwarding HTTP request to {target_host}:{target_port}: {e}")
                error_response = "HTTP/1.1 502 Bad Gateway\r\n\r\n"
                client_socket.send(error_response.encode())
            finally:
                target_socket.close()

        except Exception as e:
            logger.error(f"Error in HTTP request handler: {e}")

    def tunnel_data(self, client_socket, target_socket, client_address, target_host, target_port):
        """Tunnel data between client and target sockets"""
        def forward_data(source, destination, direction):
            try:
                bytes_transferred = 0
                while True:
                    data = source.recv(4096)
                    if not data:
                        break
                    destination.send(data)
                    bytes_transferred += len(data)
                logger.info(f"Tunnel {direction} closed - {bytes_transferred} bytes transferred")
            except Exception as e:
                logger.warning(f"Issue in tunnel {direction}: {e}")

        # Start forwarding data in both directions
        client_to_target = threading.Thread(
            target=forward_data,
            args=(client_socket, target_socket, f"{client_address[0]}:{client_address[1]} -> {target_host}:{target_port}")
        )
        target_to_client = threading.Thread(
            target=forward_data,
            args=(target_socket, client_socket, f"{target_host}:{target_port} -> {client_address[0]}:{client_address[1]}")
        )

        client_to_target.daemon = True
        target_to_client.daemon = True

        client_to_target.start()
        target_to_client.start()

        # Wait for both threads to complete
        client_to_target.join()
        target_to_client.join()

        logger.info(f"Tunnel closed between {client_address[0]}:{client_address[1]} and {target_host}:{target_port}")

def main():
    """Main function to start the proxy server"""
    host = '0.0.0.0'
    port = 0 # Automatically select available port

    # Parse command line arguments
    if len(sys.argv) == 2:
        # Only port provided
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("Error: Port must be a number")
            sys.exit(1)
    elif len(sys.argv) == 3:
        # Host and port provided
        host = sys.argv[1]
        try:
            port = int(sys.argv[2])
        except ValueError:
            print("Error: Port must be a number")
            sys.exit(1)
    elif len(sys.argv) > 3:
        print("Usage: ./proxy_remote.py [[host] port]")
        sys.exit(1)

    # Validate port range
    if port < 0 or port > 65535:
        print("Error: Port must be between 0 and 65535")
        sys.exit(1)

    # Create and start the proxy server
    proxy = HTTPProxy(host, port)
    proxy.start()

if __name__ == "__main__":
    main()
