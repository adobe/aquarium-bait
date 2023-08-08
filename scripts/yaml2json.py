#!/usr/bin/env python3
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to convert easy-to-read yaml format to packer-acceptable json one with a bit of
# processing in the middle to simplify our life as developers. You can provide 3 additional
# arguments to the script to alter the data:
#  * apply_json - will forcefully apply the described json to the in.yml effectively overriding it
#  * change_json - will only change if the value exists in the in.yml data, otherwise will skip it
#  * delete_json - will delete the described values from the in.yml data tree
#
# Usage:
#   $ cat in.yml | ./yaml2json.py [add_json [change_json [delete_json]]] > out.json

import sys, yaml, json

# Simple merger for dict/list data
# * data - input data to change
# * update - data to apply/change/delete
# * operation - "a", "c" or "d"
def merge(data, update, operation):
    items = update.items() if isinstance(update, dict) else enumerate(update)
    for k, v in items:
        if isinstance(v, dict) or isinstance(v, list):
            data_val = data.get(k, None) if isinstance(data, dict) else (data[k] if len(data) > k else None)
            if data_val == None:
                # Data value is not here
                if operation == 'a':  # Apply anyway
                    if isinstance(data, list) and len(data) <= k:
                        data.append(v)
                    else:
                        data[k] = v
                # Change & delete are not needed here - the value doesn't exist
            else:
                # Data value is here
                if isinstance(data_val, dict) or isinstance(data_val, list):
                    data[k] = merge(data_val, v, operation)
                else:
                    if operation == 'd':  # Need to delete
                        if k in data:
                            del data[k]
                    else:
                        data[k] = v
        else:
            # The item of update is not the type for iteration
            if operation == 'd':  # Deleting only if it's the last key in update
                if k in data:
                    del data[k]
            elif operation == 'a':  # Applying the data or change if key exists
                data[k] = v
            elif operation == 'c':
                data_val = data.get(k, None) if isinstance(data, dict) else (data[k] if len(data) > k else None)
                if data_val != None:
                    data[k] = v
    return data


data = yaml.safe_load(sys.stdin.read())

# Apply / Change / Delete data from the input yaml
if len(sys.argv) > 1 and sys.argv[1] != '':
    apply = json.loads(sys.argv[1])
    data = merge(data, apply, 'a')
if len(sys.argv) > 2 and sys.argv[2] != '':
    change = json.loads(sys.argv[2])
    data = merge(data, change, 'c')
if len(sys.argv) > 3 and sys.argv[3] != '':
    delete = json.loads(sys.argv[3])
    data = merge(data, delete, 'd')

print(json.dumps(data))
