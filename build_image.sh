#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Build packer images
# Usage:
#   ./build_image.sh <specs/path/to.yml> [...]
#
# Debug mode:
#   DEBUG=true ./build_image.sh ...

cd "$(dirname "$0")"
root_dir="$PWD"

# Disable packer auto-update calls
export CHECKPOINT_DISABLE=1
# No need to color the output to store proper log files
export PACKER_NO_COLOR=1
# Set root dir to use in packer configs
export PACKER_ROOT="${root_dir}"

##
# Running the local proxy process to workaround the VPN tunnel routing
##
# Get the available port to listen on localhost
proxy_port=$(python3 -c 'import socket; sock = socket.socket(); sock.bind(("127.0.0.1", 0)); print(sock.getsockname()[1]); sock.close()')
./scripts/run_proxy_local.sh $proxy_port &
# Exporting proxy for the Ansible WinRM transport
# TODO: it's not perfect if you want to use http transport to get
# your artifacts but it's a simpliest solution I found for now
export http_proxy="socks5://127.0.0.1:$proxy_port"

# Clean of the running background apps on exit
clean_bg() {
    find "${root_dir}/specs" -name '*.json' -delete
    pkill -SIGINT -f './scripts/vncrecord.py' || true
    pkill -SIGTERM -f 'tail -f /tmp/packer.log' || true
    # TODO: Remove the docker images
}

trap "clean_bg ; pkill -f './scripts/proxy_local.py' || true" EXIT

# This is needed to properly work with the spaces in the path
spec_list=''
_IFS="$IFS"
IFS='|'
for item in "$@"; do
    spec_list="$spec_list$item|"
done

##
# The process walks on the different levels of packer dir tree and process the configs
##
stage=1
while true; do
    if [ "x$1" != "x" ]; then
        # Need to make sure we will build the provided specs by stage
        to_process=''
        for yml in $spec_list; do
            if [ $(echo "$yml" | tr / '\n' | wc -l) -eq $(($stage+2)) ]; then
                to_process="$to_process$yml|"
            else
                spec_list_tmp="$spec_list_tmp$yml|"
            fi
        done
        spec_list="$spec_list_tmp"
        spec_list_tmp=''
    fi
    if [ "${spec_list}" -a ! "${to_process}" ]; then
        echo "Skipping Stage ${stage}"
        stage=$(($stage+1))
        continue
    fi
    [ "${to_process}" ] || break

    echo "INFO: ---------------"
    echo "INFO: Stage: ${stage}"
    echo "INFO: ---------------"

    # We building single-threaded because build of the images in parallel
    # will lead to resource conflicts and the timeouts (for VNC scripts)
    # will not be met.
    for yml in $to_process; do
        IFS="$_IFS"

        image_type=$(echo "$yml" | cut -d/ -f2)
        image_outdir="${root_dir}/out/${image_type}"
        mkdir -p "${image_outdir}"
        image=$(echo "${yml}" | cut -d. -f1 | cut -d/ -f3- | tr / -)
        echo "INFO: Building image for ${image_type} '${image}'..."

        if [ "$image_type" = 'vmx' ]; then
            # Make sure no VM is running currently to provide the clean environment for the build
            if which vmrun > /dev/null 2>&1; then
                if [ "x$(vmrun list | head -1 | rev | cut -d" " -f 1)" != "x0" ]; then
                    echo "ERROR: Found running VMware VM's, please shutdown them before running the build:\n$(vmrun list)"
                    exit 1
                fi
            fi

            # Check the spec have headless mode enabled in release mode
            if [ "x${DEBUG}" = 'x' ]; then
                if [ "x$(grep -s 'headless:' "${yml}" | tr -d ' ')" != 'xheadless:true' ]; then
                    echo "ERROR: The spec doesn't contain the headless mode enabled: ${yml}"
                    exit 1
                fi
            fi

            # Check the minimum disk space (200GB) is available for proper VM disk cleanup
            if [ "$(df -m "${image_outdir}" | tail -1 | awk '{print $4}')" -lt 201000 ]; then
                echo "ERROR: Available disk space is lower than required 200GB for VM"
                exit 1
            fi
        fi

        if [ "$(find "${image_outdir}" -maxdepth 1 -type d -name "${image}-[0-9]*")" ]; then
            echo "INFO:  skip: the output path '${image_outdir}/${image}-[0-9]*' already exists"
            continue
        fi

        # Collecting packer params to build the image
        packer_params="-var aquarium_bait_proxy_port=${proxy_port}"
        packer_params="$packer_params -var username=packer -var password=packer"
        packer_params="$packer_params -var image_name=${image}"
        packer_params="$packer_params -var out_full_path=${image_outdir}"
        if [ $stage -gt 1 ]; then
            parent_name=$(echo "${yml}" | cut -d. -f1 | cut -d/ -f3- | rev | cut -d/ -f2- | rev | tr / -)
            if [ $image_type != "aws" ]; then
                # Filter the dirs in addition with grep due to the childrens could be found too
                parent_image=$(find "${image_outdir}" -type d -name "${parent_name}-*" | grep -E "${parent_name}-[^-]*$" || printf '')
                parent_version=$(basename "${parent_image}" | rev | cut -d- -f1 | rev)
                if [ $(echo "$parent_image" | wc -l) -gt 1 ]; then
                    echo "ERROR:  there is more than one parent image '${parent_name}'."
                    echo "        Please move the unnecessary one aside of out directory:\n$parent_image"
                    continue
                elif [ "x$parent_image" = 'x' ]; then
                    echo "ERROR:  there is no required parent image with name '${parent_name}'."
                    echo "        Please download the prebuilt one (preferrable) or build it yourself."
                    continue
                fi
                echo "INFO:  using parent image: ${parent_image}"
                packer_params="$packer_params -var parent_full_path=${parent_image}"
                packer_params="$packer_params -var parent_version=${parent_version}"
            fi
            packer_params="$packer_params -var parent_name=${parent_name}"

            if [ "$image_type" = 'docker' ]; then
                echo "INFO: Loading Docker parent images"
                parent_manifest="${parent_image}/${parent_name}-${parent_version}.yml"
                if [ ! -f "${parent_manifest}" ]; then
                    echo "ERROR: Unable to find parent image manifest: ${parent_manifest}"
                    exit 1
                fi
                # Getting the list of the other dependencies and load them in reverse order
                image_deps=$(grep -A100 -m 1 '^parents:' "${parent_manifest}" | tail -n +2 | awk '{if(/^ /)print;else exit}' | cut -d- -f2- | tac)
                for dep_name in ${image_deps}; do
                    dep_image="$(dirname "${parent_image}")/${dep_name}"
                    dep_tar="${dep_image}/$(echo "${dep_name}" | rev | cut -d- -f2- | rev).tar"
                    echo "INFO:   loading ${dep_tar}..."
                    docker image load -i "${dep_tar}"
                done

                # When all the deps images are loaded - load the closest parent image
                echo "INFO:   loading ${parent_image}/${parent_name}.tar..."
                docker image load -i "${parent_image}/${parent_name}.tar"
            fi
        fi

        clean_bg

        echo "INFO:  generating packer json for '${yml}'..."
        cat "${yml}" | ./scripts/run_yaml2json.sh > "${yml}.json"

        if [ "$image_type" = 'vmx' ]; then
            # Cleaning the non-tracked files from the init directory
            git clean -fX ./init/vmx/ || true

            # Running the vncrecord script to capture VNC screen during the build
            rm -rf "./records/${image}.mp4"
            mkdir -p ./records
            rm -f /tmp/packer.log
            ./scripts/run_vncrecord.sh /tmp/packer.log "./records/${image}.mp4" &
        fi

        echo 'INFO:  running packer build'
        if [ "x${DEBUG}" = 'x' ]; then
            PACKER_LOG=1 PACKER_LOG_PATH=/tmp/packer.log packer build $packer_params "${yml}.json"
            # /tmp/packer.log is copied in the post processing script to the image dir
            "./scripts/run_postprocess_${image_type}.sh" "${image_outdir}/${image}"
        else
            echo "WARNING:  running DEBUG image build - you will not be able to upload it"
            touch /tmp/packer.log
            tail -f /tmp/packer.log &
            PACKER_LOG=1 packer build -on-error=ask $packer_params "${yml}.json" > /tmp/packer.log 2>&1
        fi

        clean_bg

        IFS="|"
    done
    stage=$(($stage+1))
done
IFS="$_IFS"

echo "INFO: Build completed"
