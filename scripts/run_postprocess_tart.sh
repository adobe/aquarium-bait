#!/bin/sh -e
# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# The Tart images are not supporting proper linked clone functionality, so we're going to
# use tar incremental archives to keep the child images small and require parent for unpack

BAIT_SESSION="$1"
IMAGE_FULL_PATH="$2"

OUT_PATH=$(dirname "${IMAGE_FULL_PATH}")
IMAGE_NAME=$(basename "${IMAGE_FULL_PATH}")

root_dir="$PWD"
cd "${OUT_PATH}"

# Getting the timestamp of the VM for proper versioning
vm_timestamp=$(for f in "$HOME/.tart/vms/${IMAGE_NAME}"/*; do date -ur "$f" +%y%m%d.%H%M%S; done | sort | tail -1)
image_name_completed="${IMAGE_NAME}-${vm_timestamp}"

echo 'INFO: Changing name of the VM to append the timestamp'
tart rename "${IMAGE_NAME}" "${image_name_completed}"

echo 'INFO: Creating new image directory'
mkdir -p "${image_name_completed}"

echo 'INFO: Copy packer log of the build process to the image'
cp "${root_dir}/logs/bait-${IMAGE_NAME}-packer-${BAIT_SESSION}.log" "${image_name_completed}/packer.log"

echo 'INFO: Put the manifest with the unpacked size of the image (in kb, whole dir first)'
echo "---\n# Aquarium Bait image manifest file\nsize_kb:" > "${image_name_completed}/${image_name_completed}.yml"
du -a -k "${image_name_completed}" | awk '{ print "  \"" $2 "\": " $1}' | sort >> "${image_name_completed}/${image_name_completed}.yml"
# TODO:
#if [ "x${disk_file_cloned}" != "x" ]; then
#    echo 'INFO: Collect dependencies of the image and store in the manifest file'
#    echo "parents:" >> "${image_name_completed}/${image_name_completed}.yml"
#    disk_to_process="${disk_file_cloned}"
#    while [ "${disk_to_process}" ]; do
#        parent_disk=$(grep '^parentFileNameHint=' "${disk_to_process}" | cut -d= -f2 | tr -d '"')
#        [ "x${parent_disk}" != "x" ] || break
#        parent_image=$(echo "${parent_disk}" | rev | cut -d/ -f2 | rev)
#        echo "  - ${parent_image}" >> "${image_name_completed}/${image_name_completed}.yml"
#        disk_to_process="$(echo "${parent_disk}" | sed 's|^../||')"
#    done
#fi

echo 'INFO: Clean up the *.orig files in the completed image'
rm -f "${image_name_completed}/"*.orig

echo 'INFO: Run checksum of all the files in the archive'
# MacOS doesn't have sha256sum command
if ! command -v sha256sum > /dev/null; then alias sha256sum="shasum -a 256 -b"; fi
sha256sum "${image_name_completed}"/* > "${image_name_completed}.sha256"
mv "${image_name_completed}.sha256" "${image_name_completed}/"

# Applying restrictive permissions to the image
chmod 640 "${image_name_completed}"/*
chmod 750 "${image_name_completed}"

echo "INFO: Image post-process completed: ${image_name_completed}"
