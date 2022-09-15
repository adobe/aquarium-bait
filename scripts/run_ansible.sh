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

root_dir=$(dirname "$(dirname "$0")")

# Setup virtual env
[ -f "${root_dir}/.venv/bin/activate" ] || python3 -m venv "${root_dir}/.venv"
. "${root_dir}/.venv/bin/activate"
pip -q install --upgrade pip wheel
pip -q install -r "${root_dir}/requirements.txt"

# Loads the override configuration for ansible
override_yml="${root_dir}/override.yml"
if [ -f "${override_yml}" ]; then
    override_yml="-e @${override_yml}"
else
    unset override_yml
fi

# Run the proxy_remote on the provided address and random free port
if [ "x$PROXY_REMOTE_LISTEN" != "x" ]; then
    proxy_remote_port=$(python3 -c "import socket, sys; sock = socket.socket(); sock.bind((sys.argv[1], 0)); print(sock.getsockname()[1]); sock.close()" "${PROXY_REMOTE_LISTEN}")
    proxy_remote_args="-e proxy_remote_host=${PROXY_REMOTE_LISTEN} -e proxy_remote_port=${proxy_remote_port}"
    echo "Running Proxy Remote on ${PROXY_REMOTE_LISTEN}:${proxy_remote_port}..."
    python3 "${root_dir}/scripts/proxy_remote.py" "${PROXY_REMOTE_LISTEN}" "${proxy_remote_port}" &
    trap "pkill -f '${root_dir}/scripts/proxy_remote.py' || true" EXIT
fi

# Run the playbook
if [ "x$DEBUG" != "x" ]; then
    "${root_dir}/.venv/bin/ansible-playbook" -vvv $proxy_remote_args $override_yml "$@"
else
    "${root_dir}/.venv/bin/ansible-playbook" $proxy_remote_args $override_yml "$@" 2>/dev/null
fi
