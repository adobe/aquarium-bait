#!/bin/sh -e
# Script to quickly run ansible

root_dir=$(dirname "$0")

# Setup virtual env
[ -f "${root_dir}/.venv/bin/activate" ] || python3 -m venv "${root_dir}/.venv"
. "${root_dir}/.venv/bin/activate"
pip install --upgrade pip wheel
pip install -r "${root_dir}/requirements.txt"

# Run the playbook
"${root_dir}/.venv/bin/ansible-playbook" "$@"
