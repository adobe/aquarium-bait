#!/bin/sh -e
# Build packer images
# Usage:
#   ./build_image.sh <packer/path/to.yml> [...]
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

# Make sure no VM is running currently to provide the clean environment for the build
if which vmrun > /dev/null 2>&1; then
    if [ "x$(vmrun list | head -1 | rev | cut -d" " -f 1)" != "x0" ]; then
        echo "ERROR: Found running VMware VM's, please shutdown them before running the build:\n$(vmrun list)"
        exit 1
    fi
fi

# Clean of the running background apps on exit
function clean_bg {
    find "${root_dir}/packer" -name '*.json' -delete
    pkill -SIGINT -f './scripts/vncrecord.py' || true
    pkill -SIGINT -f 'tail -f' || true
}

trap "clean_bg ; pkill -f './scripts/proxy.py' || true" EXIT

##
# Running the local proxy process to workaround the VPN tunnel routing
##
# Get the available port to listen on localhost
proxy_port=$(python3 -c 'import socket; sock = socket.socket(); sock.bind(("127.0.0.1", 0)); print(sock.getsockname()[1]); sock.close()')
./run_proxy.sh $proxy_port &
# Exporting proxy for the Ansible WinRM transport
export http_proxy="socks5://127.0.0.1:$proxy_port"

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
            if [ $(echo "$yml" | tr / '\n' | wc -l) -eq $(($stage+1)) ]; then
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

    # TODO: build stage in parallel (check max cpu/max mem)
    for yml in $to_process; do
        IFS="$_IFS"
        image=$(echo "${yml}" | cut -d. -f1 | cut -d/ -f2- | tr / -)
        echo "INFO: Building image for '${image}'..."

        if [ "$(find ./out -maxdepth 1 -type d -name "${image}-[0-9]*")" ]; then
            echo "INFO:  skip: the output path 'out/${image}-[0-9]*' already exists"
            continue
        fi

        # Check the spec have headless mode enabled in release mode
        if [ "x${DEBUG}" = 'x' ]; then
            if [ "x$(grep -s 'headless:' "${yml}" | tr -d ' ')" != 'xheadless:true' ]; then
                echo "ERROR: The spec doesn't contain the headless mode enabled: ${yml}"
                continue
            fi
        fi

        # Collecting packer params to build the image
        packer_params="-var aquarium_bait_proxy_port=${proxy_port}"
        packer_params="$packer_params -var username=packer -var password=packer"
        packer_params="$packer_params -var vm_name=${image}"
        packer_params="$packer_params -var out_full_path=${root_dir}/out"
        if [ $stage -gt 1 ]; then
            parent_name=$(echo "${yml}" | cut -d. -f1 | cut -d/ -f2- | rev | cut -d/ -f2- | rev | tr / -)
            # Filter the dirs in addition with grep due to the childrens could be found too
            parent_image=$(find "${root_dir}/out" -type d -name "${parent_name}-*" | grep -E "${parent_name}-[^-]*$")
            if [ $(echo "$parent_image" | wc -l) -gt 1 ]; then
                echo "ERROR:  there is more than one parent image '${parent_name}'."
                echo "        Please move the unnecessary one aside of out directory:\n$parent_image"
                continue
            elif [ $(echo "$parent_image" | wc -l) -eq 0 ]; then
                echo "ERROR:  there is no required parent images with prefix '${parent_name}'."
                echo "        Please download the prebuilt one (preferrable) or build it yourself."
                continue
            fi
            echo "INFO:  using parent image: ${parent_image}"
            packer_params="$packer_params -var vmx_full_path=${parent_image}/${parent_name}.vmx"
        fi

        # Cleaning the non-tracked files from the init directory
        git clean -fX ./init/ || true

        clean_bg

        echo "INFO:  generating packer json for '${yml}'..."
        ruby -ryaml -rjson -e "puts YAML.load_file('${yml}').to_json" > "${yml}.json"

        # Running the vncrecord script to capture VNC screen during the build
        rm -rf "./records/${image}.mp4"
        mkdir -p ./records
        rm -f /tmp/packer.log
        ./run_vncrecord.sh /tmp/packer.log "./records/${image}.mp4" &

        echo 'INFO:  running packer build'
        if [ "x${DEBUG}" = 'x' ]; then
            PACKER_LOG=1 PACKER_LOG_PATH=/tmp/packer.log packer build $packer_params "${yml}.json"
            # /tmp/packer.log is copied in the post processing script to the image dir
            ./run_image_postprocess.sh "${root_dir}/out/${image}"
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
