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
  echo 'INFO: Creating new python venv environment...' 1>&2
  python3 -m venv "${bait_dir}/.venv" 1>&2
  . "${bait_dir}/.venv/bin/activate"
  PIP_CONFIG_FILE="${PWD}/pip.conf" pip install --upgrade pip wheel 1>&2
else
  . "${bait_dir}/.venv/bin/activate"
fi

# Install the requirements if necessary, otherwise it will skip upgrade
PIP_CONFIG_FILE="${PWD}/pip.conf" pip install -r "${bait_dir}/requirements.txt" | (grep -v 'Requirement already satisfied:' || true) 1>&2
