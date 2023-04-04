#!/bin/sh
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script allows to check which roles, playbooks and specs were affected by the changes
# Usage:
#   $ ./list_affected.sh
#     # Will show only the branch affects compared to origin/main
#   $ ./list_affected.sh 12abcdef
#     # Will show the changes down to 12abcdef (not included)
#   $ ./list_affected.sh 12abcdef~1
#     # Will show the changes till 12abcdef (included)

diff_commit=$1
[ "$diff_commit" -a "$diff_commit" != 'X' ] || diff_commit="$(git rev-list HEAD ^origin/main | tail -1)~1"
[ "$diff_commit" != '~1' ] || diff_commit="HEAD"

# Get list of roles
roles=$(git diff --name-only $diff_commit | grep '^playbooks/roles' | cut -d/ -f 2-3 | sort -u)

# Get list of directly affected playbooks
playbooks=$(git diff --name-only $diff_commit | grep '^playbooks/[^/]\+.yml$')

# Look for the playbooks affected by changed roles (no nested roles)
role_names=$(echo "$roles" | cut -d/ -f 2)
playbooks="$playbooks\n$(for role in $role_names; do
    grep -l ": $role" playbooks/*.yml
done)"
playbooks=$(echo "$playbooks" | sort -u)

# Get list of directly affected specs, skipping deleted ones with filter
specs=$(git diff --diff-filter=AMRC --name-only $diff_commit | grep '^specs/.\+.yml$')

# Look for the specs affected by the changed playbooks
specs="$specs\n$(for playbook in $playbooks; do
    grep -lr "$playbook" specs
done)"
specs=$(echo "$specs" | sort -u)

# Print the results
if [ "$1" != 'X' ]; then
    if [ "$roles" ]; then
        echo "$roles"
        echo
    fi
    if [ "$playbooks" ]; then
        echo "$playbooks"
        echo
    fi
    if [ "$specs" ]; then
        echo "$specs"
    fi
fi
