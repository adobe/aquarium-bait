#!/bin/sh
# Build macos vmware images (only on macos)

export PACKER_VMX_PATH="${1}"
if [ -z "$PACKER_VMX_PATH" ]; then
    echo "Usage: ./build.sh <init vmx image path>"
    exit 1
fi

echo "Create the MacOS base image"
ruby -ryaml -rjson -e "puts YAML.load_file('packer/macos-vmware-base.yml').to_json" > _packer.json

# Get total vcpu available and leave 2 for the host system
export PACKER_CPU_NUMBER=$(($(getconf _NPROCESSORS_ONLN)-2))

# For debug: PACKER_LOG=1 packer build -on-error=ask _packer.json
packer build _packer.json

echo "Create the MacOS xcode image"
