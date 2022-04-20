#!/bin/sh -e
# Script to run vncrecord python script in venv
# It's used to capture VNC screen during the packer build process
#
# No needed to be run manually - executed by the build_image.sh script to read the packer build log

root_dir=$(dirname "$0")

# Setup virtual env
[ -f "${root_dir}/.venv/bin/activate" ] || python3 -m venv "${root_dir}/.venv"
. "${root_dir}/.venv/bin/activate"
pip -q install --upgrade pip wheel
pip -q install -r "${root_dir}/requirements.txt"

# Run the screenshot application
"${root_dir}/scripts/vncrecord.py" "$@"