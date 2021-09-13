#!/bin/sh -e
# Build macos vmware images (only on macos)
# Usage:
#   ./build_macos.sh [path_of_the_yaml_to_build [...]]
#
# Debug mode:
#   DEBUG=true ./build_macos.sh ...

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

root_dir=$(realpath "$(dirname "$0")")
cd "${root_dir}"

# Convert yml files to json
for yml in $(find packer -name '*.yml'); do
    echo "INFO: Generate packer json for '${yml}'..."
    ruby -ryaml -rjson -e "puts YAML.load_file('${yml}').to_json" > "${yml}.json"
done

# Disable packer auto-update calls
export CHECKPOINT_DISABLE=1
# Set root dir to use in packer configs
export PACKER_ROOT="${root_dir}"

# The process walks on the different levels of packer dir tree and process the configs
stage=1
while true; do
    to_process=$(find packer -mindepth ${stage} -maxdepth ${stage} -type f -name '*.json')
    [ "${to_process}" ] || break

    echo "INFO: ---------------"
    echo "INFO: Stage: ${stage}"
    echo "INFO: ---------------"

    # TODO: build stage in parallel (check max cpu/max mem)
    for json in ${to_process}; do
        # Skip if path not in the filter
        if [ "$1" ]; then
            skip_image=true
            for filter in "$@"; do
                [ "${json}" != "${filter}.json" ] || skip_image=""
            done
            [ -z "${skip_image}" ] || continue
        fi

        name=$(basename "${json}" | cut -d'.' -f1)

        echo "INFO: Building image for '${name}'..."

        if [ -e "out/${name}" ]; then
            echo "INFO:  skip: the output path '${out}/${name}' is existing"
            continue
        fi

        [ "${DEBUG}" ] || packer build "${json}"
        [ -z "${DEBUG}" ] || PACKER_LOG=1 packer build -on-error=ask "${json}"
    done
    stage=$(($stage+1))
done

echo "INFO: Build completed"
