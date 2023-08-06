#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to quickly run ansible
#
# No needed to be run manually - executed by the ansible provisioner section of the packer spec.

bait_dir=$(dirname "$(dirname "$0")")

# Setup virtual env for ansible
. "${bait_dir}/scripts/require_venv.sh"

# Loads the override configuration for ansible
override_yml=./override.yml
if [ -f "${override_yml}" ]; then
    override_yml="-e @${override_yml}"
else
    unset override_yml
fi

# Run the playbook
if [ "x$DEBUG" != "x" ]; then
    echo -- "${bait_dir}/.venv/bin/ansible-playbook" -vvv $override_yml "$@"
    "${bait_dir}/.venv/bin/ansible-playbook" -vvv $override_yml "$@"
else
    "${bait_dir}/.venv/bin/ansible-playbook" $override_yml "$@"
fi
