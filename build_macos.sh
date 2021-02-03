#!/bin/sh -e
# Build macos vmware images (only on macos)
# Usage: ./build_macos.sh [name_of_the_image_to_build]

# Disable packer auto-update calls
export CHECKPOINT_DISABLE=1

root_dir=$(realpath "$(dirname "$0")")

for yml in $(ls "${root_dir}/packer/"*.yml); do
    echo "Generate packer json for '${yml}'..."
    ruby -ryaml -rjson -e "puts YAML.load_file('${yml}').to_json" > "${yml}.json"
done

echo "-----------------------------------------"
echo "First stage: Create the MacOS base images"

# 2 CPU is just enough for the base image
export PACKER_CPU_NUMBER=2

# TODO: build in parallel (check max cpu/max mem)
for json in $(ls "${root_dir}/packer/"*-base-*.json); do
    name=$(basename "${json}" | cut -d'.' -f1)

    # Skip if the name not in filter
    if [ "$1" ]; then
       [ "${name}" = "$1" ] || continue
    fi

    echo "Run packer for '${name}'..."

    # Set iso path for packer
    export PACKER_ISO_PATH="${root_dir}/iso/${name}.iso"
    if [ ! -e "${PACKER_ISO_PATH}" ]; then
        echo "  skip: unable to find iso ${PACKER_ISO_PATH}"
        continue
    fi

    # Use init vmx as the VM base
    export PACKER_VMX_PATH="${root_dir}/init/${name}/${name}.vmx"
    [ -e "${PACKER_VMX_PATH}" ] || unset PACKER_VMX_PATH

    # For debug:
    #PACKER_LOG=1 packer build -on-error=ask "${json}"
    packer build "${json}"
done

echo "-----------------------------------------"
echo "Second stage: Create the MacOS tool images"

# Get total vcpu available and leave 2 for the host system
export PACKER_CPU_NUMBER=$(($(getconf _NPROCESSORS_ONLN)-2))

# TODO
