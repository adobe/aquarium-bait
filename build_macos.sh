#!/bin/sh -e
# Build macos vmware images (only on macos)

export PACKER_ISO_PATH="${1}"
if [ -z "$PACKER_ISO_PATH" ]; then
    echo "Usage: ./build.sh <macos iso image path>"
    exit 1
fi

root_dir=$(realpath "$(dirname "$0")")

for yml in $(ls "${root_dir}/packer/"*.yml); do
    echo "Generate packer json for '${yml}'..."
    ruby -ryaml -rjson -e "puts YAML.load_file('${yml}').to_json" > "${yml}.json"
done

echo "----------------------------"
echo "First stage: Create the MacOS base images"

# 2 CPU is just enough for the base image
export PACKER_CPU_NUMBER=2

# TODO: build in parallel (check max cpu/max mem)
for json in $(ls "${root_dir}/packer/"*-base-*.json); do
    name=$(basename "${json}" | cut -d'.' -f1)
    echo "Run packer for '${name}'..."
    export PACKER_VMX_PATH="${root_dir}/init/${name}/${name}.vmx"
    echo DEBUG:${PACKER_VMX_PATH}
    [ -e "${PACKER_VMX_PATH}" ] || unset PACKER_VMX_PATH
    echo DEBUG:${PACKER_VMX_PATH}

    # For debug:
    PACKER_LOG=1 packer build -on-error=ask "${json}"
    #packer build "${json}"
done

echo "----------------------------"
echo "Second stage: Create the MacOS tool images"

# Get total vcpu available and leave 2 for the host system
export PACKER_CPU_NUMBER=$(($(getconf _NPROCESSORS_ONLN)-2))
