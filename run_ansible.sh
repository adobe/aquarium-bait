#!/bin/sh -e
# Script to quickly run ansible

root_dir=$(dirname "$0")

# Setup virtual env
[ -f "${root_dir}/.venv/bin/activate" ] || python3 -m venv "${root_dir}/.venv"
. "${root_dir}/.venv/bin/activate"
pip -q install --upgrade pip wheel
pip -q install -r "${root_dir}/requirements.txt"

# Run the playbook
if [ "x$DEBUG" != "x" ]; then
    "${root_dir}/.venv/bin/ansible-playbook" -vvv "$@"
else
    "${root_dir}/.venv/bin/ansible-playbook" "$@" 2>/dev/null
fi
