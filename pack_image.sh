#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Pack the images in out directory
# Usage:
#   ./pack_image.sh <out/type/image_dir>

curr_dir="$PWD"

path="$1"
# Skipping non-dir target
if [ ! -d "${path}" ]; then
    echo "ERROR: Unable to find image directory ${path}"
    exit 1
fi

cd "$(dirname "${path}")"

image=$(basename "${path}")
type="$(basename "$(dirname "${path}")")"
# Strip version to get name of the image
name=$(echo "$image" | rev | cut -d- -f2- | rev)

if [ "x${type}" = 'xvmx' ]; then
    # Check the lock files are not present
    if [ "$(find "${image}" -name '*.lck')" ]; then
        echo "ERROR: Image '${path}' contains lock files, please stop the vmware vms and the application."
        exit 1
    fi
fi

# Make sure the image was build in release mode
if [ ! -f "${image}/packer.log" ]; then
    echo "ERROR: Image '${path}' was build in DEBUG mode, only the release images can be packed."
    exit 1
fi

# Check that only allowed files are in the image and make the list of them to pack properly
need_files=''
find_noneed_pattern=''
to_pack_list=''
# The files will be packed in this order - manifest files first to stream-process them first
[ "x${type}" != 'xdocker' ] || add_files="$name.tar"
[ "x${type}" != 'xvmx' ] || add_files="$name.vmx $name.vmsd $name.nvram $name-Snapshot*.vmsn $name.vmxf MainDisk-*.vmdk"
for filename in "$image.yml" "$image.sha256" 'packer.log' ${add_files}; do
    found_files=$(sh -c "find '${image}' -name '$filename'" | sort)
    to_pack_list="$to_pack_list $(echo "$found_files" | tr '\n' ' ')"
    if [ "x${found_files}" = 'x' ]; then
        need_files="$need_files $filename"
    fi
    find_noneed_pattern="$find_noneed_pattern ! -name '$filename'"
done
if [ "x$need_files" != 'x' ]; then
    echo "ERROR: Image '${path}' doesn't contain the required files for packing:\n$need_files"
    exit 1
fi
noneed_files=$(sh -c "find '${image}' $find_noneed_pattern")
if [ "x$noneed_files" != "x${image}" ]; then
    echo "ERROR: Image '${path}' contains weird files need to be cleaned before packing: $noneed_files"
    exit 1
fi

package="$image.tar.xz"

echo
echo "INFO: Processing '${package}'..."

if [ -f "${package}" ]; then
    echo "INFO:   skip since '${path}' is already packed"
    continue
fi

if [ "x${type}" = 'xvmx' ]; then
    vmsd_file="${image}/${name}.vmsd"
    if [ -f "${vmsd_file}" ]; then
        # Cleaning the snapshot clones which is created by the child linked VMs
        mv "${vmsd_file}" "${vmsd_file}.bak"
        grep -F -v -e 'snapshot0.clone' -e 'snapshot0.numClones' "${vmsd_file}.bak" > "${vmsd_file}"
        rm -f "${vmsd_file}.bak"
    fi
fi

# Print out the image size
echo "  Unpacked image size: $(du -d 1 -h "${image}" | tail -1 | cut -f 1)"

# Pack the image hard, using quarter of the available vcores to not overload the system
XZ_OPT="-e9 --threads=$(($(getconf _NPROCESSORS_ONLN)/4))" tar -cvJf "${package}" $to_pack_list

# Print out the image size
echo "  Packed image size: $(du -h "${package}" | cut -f 1)"

echo "INFO: Pack operation done"
