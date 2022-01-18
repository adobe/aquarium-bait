#!/bin/sh -e
# Build macos vmware images (only on macos)
# Usage:
#   ./build_macos.sh <path_to_yml> [...]
#
# Debug mode:
#   DEBUG=true ./build_macos.sh ...

cd "$(dirname "$0")"
root_dir="$PWD"

# Disable packer auto-update calls
export CHECKPOINT_DISABLE=1
# No need to color the output to store proper log files
export PACKER_NO_COLOR=1
# Set root dir to use in packer configs
export PACKER_ROOT="${root_dir}"

# Clean of the running background apps on exit
function clean_bg {
    find "${root_dir}/packer" -name '*.json' -delete
    pkill -f './scripts/screenshot.py' || true
    pkill -f 'tail -f' || true
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

        if [ -e "out/${image}" ]; then
            echo "INFO:  skip: the output path 'out/${image}' is existing"
            continue
        fi

        # Collecting packer params to build the image
        packer_params="-var aquarium_bait_proxy_port=${proxy_port}"
        packer_params="$packer_params -var username=packer -var password=packer"
        packer_params="$packer_params -var vm_name=${image}"
        packer_params="$packer_params -var out_full_path=${root_dir}/out"
        if [ $stage -gt 1 ]; then
            parent_name=$(echo "${yml}" | cut -d. -f1 | cut -d/ -f2- | rev | cut -d/ -f2- | rev | tr / -)
            parent_image=$(find "${root_dir}/out" -type d -name "${parent_name}*")
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

        # Running the screenshot application to capture VNC screens during the build
        rm -rf "./screenshots/${image}"
        mkdir -p "./screenshots/${image}"
        rm -f /tmp/packer.log
        ./run_screenshot.sh /tmp/packer.log "screenshots/${image}/${image}" &

        echo 'INFO:  running packer build'
        if [ "x${DEBUG}" = 'x' ]; then
            PACKER_LOG=1 PACKER_LOG_PATH=/tmp/packer.log packer build $packer_params "${yml}.json"
            # /tmp/packer.log is copied in the post processing script to the image dir
        else
            echo "WARNING:  running DEBUG image build - do not upload it"
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
