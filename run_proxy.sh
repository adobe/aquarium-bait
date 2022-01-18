#!/bin/sh -e
# Script to run socks proxy
#
# No needed to be run manually - executed by the build_macos.sh script

root_dir=$(dirname "$0")

"${root_dir}/scripts/proxy.py" "$@"
