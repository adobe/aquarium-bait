#/bin/sh
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to simplify the style check process

root_dir="$PWD"
script_dir="$(cd $(dirname "$0"); echo "$PWD")"

# Overriding pip.conf location to use the override one
export PIP_CONFIG_FILE="${root_dir}/pip.conf"

# Setup virtual env
[ -f "${script_dir}/.venv/bin/activate" ] || python3 -m venv "${script_dir}/.venv"
. "${script_dir}/.venv/bin/activate"
pip -q install --upgrade pip wheel
pip -q install -r "${script_dir}/requirements.txt"

errors=0

echo
echo '---------------------- Custom Checks ----------------------'
echo
for f in `git ls-files`; do
    # Check text files
    if file "$f" | grep -q 'text$'; then
        # Ends with newline as POSIX requires
        if [ -n "$(tail -c 1 "$f")" ]; then
            echo "Not ends with newline: $f"
            errors=$((${errors}+1))
        fi
        # Ansible step `register` variable starts with "reg_"
        if [ "$(grep 'register:' "$f" | grep -v 'register: reg_')" ]; then
            echo "Register variable not starts with 'reg_' prefix: $f"
            errors=$((${errors}+1))
        fi
    fi
done

echo
echo '---------------------- YAML Lint ----------------------'
echo
yamllint --strict playbooks specs
errors=$((${errors}+$?))

echo
echo '---------------------- Ansible Lint ----------------------'
echo
ansible-lint playbooks/*.yml
errors=$((${errors}+$?))

exit ${errors}
