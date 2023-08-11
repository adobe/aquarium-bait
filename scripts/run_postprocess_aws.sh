#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# The AWS images are already good as is and doesn't need a post-processing, but needs to
# report the image name anyway

BAIT_SESSION="$1"
IMAGE_FULL_PATH="$2"

IMAGE_NAME=$(basename "${IMAGE_FULL_PATH}")

root_dir="$PWD"

# Getting AMI name from the packer log
image_name_completed=$(grep "==> amazon-ebs: Prevalidating AMI Name:" "${root_dir}/logs/bait-${IMAGE_NAME}-packer-${BAIT_SESSION}.log" | rev | cut -d" " -f -1 | rev)

echo "INFO: Image post-process completed: ${image_name_completed}"
