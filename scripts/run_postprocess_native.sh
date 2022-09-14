#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# The Native images needs packing

IMAGE_FULL_PATH="$1"

OUT_PATH=$(dirname "${IMAGE_FULL_PATH}")
IMAGE_NAME=$(basename "${IMAGE_FULL_PATH}")

echo 'INFO: Pack the prepared environment as tar archive'
cd "${IMAGE_FULL_PATH}"
tar -cf "${IMAGE_FULL_PATH}.tar" *

cd "${OUT_PATH}"

# Getting the timestamp of the environment for proper versioning
image_timestamp=$(for f in "${IMAGE_NAME}"/*; do date -ur "$f" +%y%m%d.%H%M%S; done | sort | tail -1)
image_name_completed="${IMAGE_NAME}-${image_timestamp}_$(shasum -a 256 -b "${IMAGE_FULL_PATH}.tar" | cut -c -8)"

echo 'INFO: Creating the imag directory and removing the env directory'
mkdir "${image_name_completed}"
rm -rf "${IMAGE_FULL_PATH}"

echo 'INFO: Place the environment into the image directory'
mv "${IMAGE_FULL_PATH}.tar" "${image_name_completed}/"

echo 'INFO: Copy packer log of the build process to the image dir'
cp /tmp/packer.log "${image_name_completed}/packer.log"

echo 'INFO: Put the manifest with the unpacked size of the image (in kb, whole dir first)'
echo "---\n# Aquarium Bait image manifest file\nsize_kb:" > "${image_name_completed}/${image_name_completed}.yml"
du -a -k "${image_name_completed}" | awk '{ print "  \"" $2 "\": " $1}' | sort >> "${image_name_completed}/${image_name_completed}.yml"

echo 'INFO: Run checksum of all the files in the archive'
shasum -a 256 -b "${image_name_completed}"/* > "${image_name_completed}.sha256"
mv "${image_name_completed}.sha256" "${image_name_completed}/"

echo "INFO: Image post-process completed: ${image_name_completed}"
