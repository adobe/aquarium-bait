#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to setup and activate venv
# No needed to be run manually - executed by the scripts when needed.

[ "$bait_dir" ] || bait_dir=$(cd "$(dirname "$(dirname "$0")")"; echo "$PWD")

# Setup virtual env
if [ ! -f "${bait_dir}/.venv/bin/activate" ]; then
  python3 -m venv "${bait_dir}/.venv"
fi

. "${bait_dir}/.venv/bin/activate"

# Install the requirements if necessary
if ! python3 -c "import sys, pkg_resources; pkg_resources.require(open(sys.argv[1],mode='r'))" "${bait_dir}/requirements.txt" 2> /dev/null; then
  PIP_CONFIG_FILE="${PWD}/pip.conf" pip -q install --upgrade pip wheel
  PIP_CONFIG_FILE="${PWD}/pip.conf" pip -q install -r "${bait_dir}/requirements.txt"
fi
