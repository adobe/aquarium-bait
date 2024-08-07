#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Script to run the docker images post-process actions.
#
# No needed to be run manually - executed by the build_image.sh script after the packer build

BAIT_SESSION="$1"
IMAGE_FULL_PATH="$2"

OUT_PATH=$(dirname "${IMAGE_FULL_PATH}")
IMAGE_NAME=$(basename "${IMAGE_FULL_PATH}")

root_dir="$PWD"
cd "${OUT_PATH}"

# Getting the image build timestamp and part of the checksum
image_date=$(docker image inspect --format '{{ index (split .Created ".") 0 }}' "aquarium/${IMAGE_NAME}:original" | tr 'T' '.' | tr -d ':-')
image_version="${image_date}_$(docker image inspect --format '{{ slice .Id 7 15 }}' "aquarium/${IMAGE_NAME}:original")"
image_name_completed="${IMAGE_NAME}-${image_version}"
image_stage=$(echo "${IMAGE_NAME}" | tr '-' ' ' | wc -w)

echo 'INFO: Tag the image with version and untag the original one'
docker image tag "aquarium/${IMAGE_NAME}:original" "aquarium/${IMAGE_NAME}:${image_version}"
docker rmi "aquarium/${IMAGE_NAME}:original"

echo 'INFO: Save the docker image archive to the directory'
mkdir "${image_name_completed}"
docker image save -o "${image_name_completed}/${IMAGE_NAME}.tar" "aquarium/${IMAGE_NAME}:${image_version}"

echo 'INFO: Copy packer log of the build process to the image'
cp "${root_dir}/logs/bait-${IMAGE_NAME}-packer-${BAIT_SESSION}.log" "${image_name_completed}/packer.log"

echo 'INFO: Put the manifest with the unpacked size of the image (in kb, whole dir first)'
image_manifest="${image_name_completed}/${image_name_completed}.yml"
echo "---\n# Aquarium Bait image manifest file\nsize_kb:" > "${image_manifest}"
du -a -k "${image_name_completed}" | awk '{ print "  \"" $2 "\": " $1}' | sort >> "${image_manifest}"
if [ $image_stage -gt 1 ]; then
    echo 'INFO: Collect dependencies and store them in the image yml manifest'
    echo "parents:" >> "${image_manifest}"
    parent_image=$(docker image inspect -f '{{ .Config.Image }}' "aquarium/${IMAGE_NAME}:${image_version}" | cut -d/ -f2 | tr ':' '-')
    echo "  - ${parent_image}" >> "${image_manifest}"

    # Adding the rest of the dependencies from parent yml file
    parent_manifest="${parent_image}/${parent_image}.yml"
    if [ ! -f "${parent_manifest}" ]; then
        echo "ERROR: Unable to find parent image manifest: ${parent_manifest}"
        exit 1
    fi
    grep -A100 -m 1 '^parents:' "${parent_manifest}" | tail -n +2 | awk '{if(/^ /)print;else exit}' >> "${image_manifest}"

    echo 'INFO: Going through the found parents and cutting out the duplicated layers'
    rm -rf "${IMAGE_NAME}_tmp"
    mkdir "${IMAGE_NAME}_tmp"
    tar -xC "${IMAGE_NAME}_tmp" -f "${image_name_completed}/${IMAGE_NAME}.tar"
    image_deps=$(grep -A100 -m 1 '^parents:' "${image_manifest}" | tail -n +2 | cut -d- -f2-)
    for parent_name in ${image_deps}; do
        parent_tar="${parent_name}/$(echo "${parent_name}" | rev | cut -d- -f2- | rev).tar"
        parent_layers_removed=''
        # If the image is OCI - we need to use different way of processing
        if tar -tf "${parent_tar}" oci-layout > /dev/null 2>&1; then
            # Using OCI layout where the images are stored in blobs/sha256 dir
            for parent_layer in $(tar -tf "${parent_tar}" | grep '^blobs/sha256/.'); do
                if [ -f "${IMAGE_NAME}_tmp/${parent_layer}" ]; then
                    parent_layer_sha256=$(basename "$parent_layer")
                    echo "INFO:   removing OCI parent layer ${parent_name}:${parent_layer_sha256}"
                    parent_layers_removed="${parent_layers_removed} ${parent_layer}"
                    rm -f "${IMAGE_NAME}_tmp/${parent_layer}"
                fi
            done
        else
            # Using old method where the layers are folders in tar root
            for parent_layer in $(tar -tf "${parent_tar}" | grep '/$' | tr -d /); do
                if [ -d "${IMAGE_NAME}_tmp/${parent_layer}" ]; then
                    echo "INFO:   removing parent layer ${parent_name}:${parent_layer}"
                    parent_layers_removed="${parent_layers_removed} ${parent_layer}"
                    rm -rf "${IMAGE_NAME}_tmp/${parent_layer}"
                fi
            done
        fi
        if [ "x${parent_layers_removed}" = 'x' ]; then
            echo "ERROR:   none parent layers was found to remove for ${parent_name}"
            exit 1
        fi
    done
    echo 'INFO:   pack the image back to tar archive'
    rm -f "${image_name_completed}/${IMAGE_NAME}.tar"
    image_files=$(find "${IMAGE_NAME}_tmp" -maxdepth 1 | tail -n +2 | rev | cut -d/ -f 1 | rev)
    tar -cC "${IMAGE_NAME}_tmp" -f "${image_name_completed}/${IMAGE_NAME}.tar" ${image_files}
    rm -rf "${IMAGE_NAME}_tmp"
fi


echo 'INFO: Run checksum of all the files in the archive'
# MacOS doesn't have sha256sum command
if ! command -v sha256sum > /dev/null; then alias sha256sum="shasum -a 256 -b"; fi
sha256sum "${image_name_completed}"/* > "${image_name_completed}.sha256"
mv "${image_name_completed}.sha256" "${image_name_completed}/"

# Applying restrictive permissions to the image
chmod 640 "${image_name_completed}"/*
chmod 750 "${image_name_completed}"

echo "INFO: Image post-process completed: ${image_name_completed}"
