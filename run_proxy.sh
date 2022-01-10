#!/bin/sh -e
# Script to run socks proxy

root_dir=$(dirname "$0")

"${root_dir}/scripts/proxy.py" "$@"
