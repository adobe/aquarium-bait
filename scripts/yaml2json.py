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
# processing in the middle to simplify our life as developers. You can provide update_json
# as the first argument to merge in.yml data and update_json together.
#
# Usage:
#   $ cat in.yml | ./yaml2json.py [update_json] > out.json

import sys, yaml, json

# Simple merger for dict/list data
def merge(data, update):
    items = update.items() if isinstance(update, dict) else enumerate(update)
    for k, v in items:
        if isinstance(v, dict) or isinstance(v, list):
            data_val = data.get(k, None) if isinstance(data, dict) else (data[k] if len(data) > k else None)
            if data_val == None:
                if isinstance(data, list) and len(data) <= k:
                    data.append(v)
                else:
                    data[k] = v
            else:
                if isinstance(data_val, dict) or isinstance(data_val, list):
                    data[k] = merge(data_val, v)
                else:
                    data[k] = v
        else:
            data[k] = v
    return data


data = yaml.safe_load(sys.stdin.read())

if len(sys.argv) > 1 and sys.argv[1] != '':
    update = json.loads(sys.argv[1])
    data = merge(data, update)

print(json.dumps(data))
