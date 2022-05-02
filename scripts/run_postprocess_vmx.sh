#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to run the vmx images post-process actions.
#
# No needed to be run manually - executed by the build_image.sh script after the packer build

IMAGE_FULL_PATH="$1"

OUT_PATH=$(dirname "${IMAGE_FULL_PATH}")
IMAGE_NAME=$(basename "${IMAGE_FULL_PATH}")

cd "${OUT_PATH}"

# Detecting the main disk
disk_file="${IMAGE_NAME}/MainDisk-1.vmdk"
disk_file_cloned=$(find "${IMAGE_NAME}" -name 'MainDisk-1-cl*.vmdk' ! -name 'MainDisk-1-cl*-*.vmdk')
[ "x${disk_file_cloned}" = "x" ] || disk_file="${disk_file_cloned}"

# Getting the timestamp of the VM for proper versioning
vm_timestamp=$(for f in "${IMAGE_NAME}"/*; do date -ur "$f" +%y%m%d.%H%M%S; done | sort | tail -1)
image_name_completed="${IMAGE_NAME}-${vm_timestamp}_$(grep '^CID=' "${disk_file}" | cut -d= -f2)"


if grep -q '^sata0:1.*iso"\?$' "${IMAGE_NAME}/${IMAGE_NAME}.vmx"; then
    echo 'INFO: Removing iso from the virtual machine config for the image'
    sed -i.orig -e '/^sata0:1/d' "${IMAGE_NAME}/${IMAGE_NAME}.vmx"
fi

echo 'INFO: Use relative path in vmx, vmsd and vmdk to simplify the image usage on different systems'
sed -i.orig -e "s|${OUT_PATH}|..|g" "${IMAGE_NAME}/${IMAGE_NAME}.vmx" "${IMAGE_NAME}/${IMAGE_NAME}.vmsd" "${disk_file}"

echo 'INFO: Create the "original" snapshot to use in the child images'
vmrun snapshot "${IMAGE_NAME}/${IMAGE_NAME}.vmx" original

echo 'INFO: Add CID and timestamp to the image directory name to identify the image properly'
mv "${IMAGE_NAME}" "${image_name_completed}"
disk_file_cloned=$(find "${image_name_completed}" -name 'MainDisk-1-cl*.vmdk' ! -name 'MainDisk-1-cl*-*.vmdk')

echo 'INFO: Copy packer log of the build process to the image'
cp /tmp/packer.log "${image_name_completed}/packer.log"

echo 'INFO: Put the manifest with the unpacked size of the image (in kb, whole dir first)'
echo "---\n# Aquarium Bait image manifest file\nsize_kb:" > "${image_name_completed}/${image_name_completed}.yml"
du -a -k "${image_name_completed}" | awk '{ print "  \"" $2 "\": " $1}' | sort >> "${image_name_completed}/${image_name_completed}.yml"
if [ "x${disk_file_cloned}" != "x" ]; then
    echo 'INFO: Collect dependencies of the image and store in the manifest file'
    echo "parents:" >> "${image_name_completed}/${image_name_completed}.yml"
    disk_to_process="${disk_file_cloned}"
    while [ "${disk_to_process}" ]; do
        parent_disk=$(grep '^parentFileNameHint=' "${disk_to_process}" | cut -d= -f2 | tr -d '"')
        [ "x${parent_disk}" != "x" ] || break
        parent_image=$(echo "${parent_disk}" | rev | cut -d/ -f2 | rev)
        echo "  - ${parent_image}" >> "${image_name_completed}/${image_name_completed}.yml"
        disk_to_process="$(echo "${parent_disk}" | sed 's|^../||')"
    done
fi


echo 'INFO: Clean up the *.orig files in the completed image'
rm -f "${image_name_completed}/"*.orig

echo 'INFO: Run checksum of all the files in the archive'
shasum -a 256 -b "${image_name_completed}"/* > "${image_name_completed}.sha256"
mv "${image_name_completed}.sha256" "${image_name_completed}/"

# Applying restrictive permissions to the image
chmod 640 "${image_name_completed}"/*
chmod 750 "${image_name_completed}"

echo "INFO: Image post-process completed: ${image_name_completed}"
