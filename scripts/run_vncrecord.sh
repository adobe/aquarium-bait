#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to run vncrecord python script in venv
# It's used to capture VNC screen during the packer build process
#
# No needed to be run manually - executed by the build_image.sh script to read the packer build log

root_dir=$(dirname "$(dirname "$0")")

# Setup virtual env
[ -f "${root_dir}/.venv/bin/activate" ] || python3 -m venv "${root_dir}/.venv"
. "${root_dir}/.venv/bin/activate"
pip -q install --upgrade pip wheel
pip -q install -r "${root_dir}/requirements.txt"

# Run the screenshot application
"${root_dir}/scripts/vncrecord.py" "$@"
