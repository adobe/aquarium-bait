#!/bin/sh
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script allows to check which roles, playbooks and specs were affected by the branch changes

branch_commits=$(git rev-list HEAD ^main)

# Get list of roles
roles=$(git show --name-only $branch_commits | grep '^playbooks/roles' | cut -d/ -f 2-3 | sort -u)

# Get list of directly affected playbooks
playbooks=$(git show --name-only $branch_commits | grep '^playbooks/[^/]\+.yml')

# Look for the playbooks affected by changed roles (no nested roles)
role_names=$(echo "$roles" | cut -d/ -f 2)
playbooks="$playbooks\n$(for role in $role_names; do
    grep -l ": $role" playbooks/*.yml
done)"
playbooks=$(echo "$playbooks" | sort -u)

# Get list of directly affected specs
specs=$(git show --name-only $branch_commits | grep '^specs/.\+.yml')

# Look for the specs affected by the changed playbooks
specs="$specs\n$(for playbook in $playbooks; do
    grep -lr "$playbook" specs
done)"
specs=$(echo "$specs" | sort -u)

echo "$roles"
echo
echo "$playbooks"
echo
echo "$specs"
