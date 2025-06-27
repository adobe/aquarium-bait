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
#   ./build_image.sh <specs/path/to.yml>
#
# Debug mode:
#   DEBUG=true ./build_image.sh <specs/path/to.yml>

root_dir="$PWD"
cd $(dirname "$0")
script_dir="$PWD"
cd "${root_dir}"

# Used to separate different builds on the same machine
export BAIT_SESSION=$(dd bs=1024 if=/dev/urandom count=1 2>/dev/null | LC_ALL=C tr -dc a-zA-Z0-9 | head -c 8)

# Disable packer auto-update calls
export CHECKPOINT_DISABLE=1
# No need to color the output to store proper log files
export PACKER_NO_COLOR=1
# Set root dir to use in packer configs
export PACKER_ROOT="${script_dir}"
# Increase the max attempts to 1h30m for AWS wait of AMI. Could take a while (up to 1h) for big
# images and raise "Error waiting for AMI: Failed with ResourceNotReady error" on image completion
export AWS_MAX_ATTEMPTS=360

yml="$1"
# We need to get the path starts with `specs/` to process it properly
# due to an ability to run from outside overlay repository
yml_bait="$yml"
if [ "$(echo "$yml_bait" | cut -d/ -f 1)" != 'specs' ]; then
    yml_bait=$(echo "$yml_bait" | cut -d/ -f 2-) ;
fi
if [ "$(echo "$yml_bait" | cut -d/ -f 1)" != 'specs' ]; then
    echo "ERROR: Incorrect spec path is provided: $yml"
    exit 1
fi

##
# Collecting info and verifying basic checks
##
stage=$(( $(echo "$yml_bait" | tr / '\n' | wc -l)-2 ))

image_type=$(echo "$yml_bait" | cut -d/ -f2)
image_outdir="${script_dir}/out/${image_type}"
mkdir -p "${image_outdir}"
image=$(echo "${yml_bait}" | cut -d. -f1 | cut -d/ -f3- | tr / -)
echo "INFO: Building image for ${image_type} '${image}' ${BAIT_SESSION}..."

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
    exit 1
fi

##
# Running the local proxy process to workaround the VPN tunnel routing
##
# Get the available port to listen on localhost
proxy_port=$(python3 -c 'import socket; sock = socket.socket(); sock.bind(("127.0.0.1", 0)); print(sock.getsockname()[1]); sock.close()')
"${script_dir}/scripts/run_proxy_local.sh" $proxy_port &
# Exporting proxy for the Ansible WinRM transport
# TODO: it's not perfect if you want to use http transport to get
# your artifacts but it's a simpliest solution I found for now
export http_proxy="socks5://127.0.0.1:$proxy_port"

# Generating port for remote proxy to use in bait_proxy_url
remote_proxy_port=$(python3 -c 'import socket; sock = socket.socket(); sock.bind(("0.0.0.0", 0)); print(sock.getsockname()[1]); sock.close()')

# Run the proxy_remote script to listen on the provided address and random free port on the host
echo "Running Proxy Remote on http://0.0.0.0:${remote_proxy_port} ..."
remote_proxy_cmd="scripts/proxy_remote.py 0.0.0.0 ${remote_proxy_port}"
python3 "${script_dir}"/$remote_proxy_cmd &


# Clean of the running background apps on exit
clean_bg() {
    rm -f "${yml}.json"
    pkill -SIGINT -f "scripts/vncrecord.py logs/bait-${image}-packer-${BAIT_SESSION}.log" || true
    if [ ! -f "./records/${image}.mp4" ]; then
        pkill -f "scripts/vncrecord.py logs/bait-${image}-packer-${BAIT_SESSION}.log" || true
    fi
    pkill -SIGTERM -f "tail -f logs/bait-${image}-packer-${BAIT_SESSION}.log" || true
    # TODO: Remove the broken docker images
}

trap "clean_bg ; pkill -f 'scripts/proxy_local.py $proxy_port' || true; pkill -f '$remote_proxy_cmd' || true" EXIT

# Running the docker isolate container
if [ "$image_type" = 'docker' ]; then
    # Docker on macos is particularly hard to isolate, so running proxy container which allows
    # just the host.docker.internal access and using it as network for the container we building
    # Use bait_proxy_build_opts to set the build args like the BASE_IMAGE or APT_URL
    # --add-host is required here for linux docker hosts where we have it not set by default
    echo "INFO: Running isolation proxy container: bait_proxy"
    [ "$(docker images -q bait_proxy)" ] || docker build --tag bait_proxy $bait_proxy_build_opts "${script_dir}/init/docker/bait_proxy"
    [ "$(docker ps -q -f name=bait_proxy)" ] || docker run --rm -id --cap-add=NET_ADMIN --add-host=host.docker.internal:host-gateway --name bait_proxy bait_proxy
fi

##
# Collecting packer params to build the image
##
packer_params="-var aquarium_bait_proxy_port=${proxy_port}"
packer_params="$packer_params -var bait_path=${script_dir}"
packer_params="$packer_params -var image_name=${image}"
packer_params="$packer_params -var username=packer -var password=packer"
packer_params="$packer_params -var out_full_path=${image_outdir}"
packer_params="$packer_params -var remote_proxy_port=${remote_proxy_port}"
if [ $stage -gt 1 ]; then
    parent_name=$(echo "${yml_bait}" | cut -d. -f1 | cut -d/ -f3- | rev | cut -d/ -f2- | rev | tr / -)
    if [ $image_type != "aws" ] && [ $image_type != "aquarium" ]; then
        # Filter the dirs in addition with grep due to the childrens could be found too
        parent_image=$(find "${image_outdir}" -type d -name "${parent_name}-*" | grep -E "${parent_name}-[^-]*$" || printf '')
        parent_version=$(basename "${parent_image}" | rev | cut -d- -f1 | rev)
        if [ $(echo "$parent_image" | wc -l) -gt 1 ]; then
            echo "ERROR:  there is more than one parent image '${parent_name}'."
            echo "        Please move the unnecessary one aside of out directory:\n$parent_image"
            exit 1
        elif [ "x$parent_image" = 'x' ]; then
            echo "ERROR:  there is no required parent image with name '${parent_name}'."
            echo "        Please download the prebuilt one (preferrable) or build it yourself."
            exit 1
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
        # MacOS doesn't have tac command
        if ! command -v tac > /dev/null; then alias tac="tail -r"; fi
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
cat "${yml}" | "${script_dir}/scripts/run_yaml2json.sh" "$BAIT_SPEC_APPLY" "$BAIT_SPEC_CHANGE" "$BAIT_SPEC_DELETE" > "${yml}.json"

if [ "$image_type" = 'vmx' ]; then
    # Cleaning the non-tracked files from the init directory
    git -C "${root_dir}" clean -fX init/vmx/ || true

    # Running the vncrecord script to capture VNC screen during the build
    rm -rf "./records/${image}.mp4"
    mkdir -p ./records
    "${script_dir}/scripts/run_vncrecord.sh" logs/bait-${image}-packer-${BAIT_SESSION}.log "./records/${image}.mp4" &
fi

echo "INFO:  running packer build ${BAIT_SESSION}"
mkdir -p ./logs
if [ "x${DEBUG}" = 'x' ]; then
    PACKER_LOG=1 PACKER_LOG_PATH=logs/bait-${image}-packer-${BAIT_SESSION}.log packer build $packer_params "${yml}.json"
    "${script_dir}/scripts/run_postprocess_${image_type}.sh" "${BAIT_SESSION}" "${image_outdir}/${image}"
else
    echo "WARNING:  running DEBUG image build - you will not be able to upload it"
    touch logs/bait-${image}-packer-${BAIT_SESSION}.log
    tail -f logs/bait-${image}-packer-${BAIT_SESSION}.log &
    PACKER_LOG=1 packer build -on-error=ask $packer_params "${yml}.json" > logs/bait-${image}-packer-${BAIT_SESSION}.log 2>&1
fi

clean_bg

echo "INFO: Build ${BAIT_SESSION} completed"
