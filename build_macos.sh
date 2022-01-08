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
# No need to color the output to store proper log files
export PACKER_NO_COLOR=1
# Set root dir to use in packer configs
export PACKER_ROOT="${root_dir}"

# Clean of the running apps in bg on exit
function clean_bg {
    pkill -f './scripts/screenshot.py' || true
    pkill -f 'tail -f' || true
}
trap "clean_bg" EXIT

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

        image=$(echo "${json}" | cut -d. -f1 | cut -d/ -f2- | tr / -)

        echo "INFO: Building image for '${image}'..."

        if [ -e "out/${image}" ]; then
            echo "INFO:  skip: the output path '${out}/${image}' is existing"
            continue
        fi

        # Cleaning the non-tracked files from the init directory
        git clean -fX ./init/ || true

        clean_bg

        # Running the screenshot application to capture VNC screens during the build
        rm -rf "./screenshots/${image}"
        mkdir -p "./screenshots/${image}"
        rm -f "out/${image}.log"
        ./run_screenshot.sh "out/${image}.log" "screenshots/${image}/${image}" &

        if [ "x${DEBUG}" = 'x' ]; then
            PACKER_LOG=1 PACKER_LOG_PATH="out/${image}.log" packer build -var "aquarium_bait_stage=$(($stage-1))" "${json}"
            # Log is placed into the image only if it's not debug mode
            mv "out/${image}.log" "out/${image}/packer.log"
        else
            echo "WARNING: Running DEBUG image build"
            touch "out/${image}.log"
            tail -f "out/${image}.log" &
            PACKER_LOG=1 packer build -var "aquarium_bait_stage=$(($stage-1))" -on-error=ask "${json}" > "out/${image}.log" 2>&1
        fi

        clean_bg
    done
    stage=$(($stage+1))
done

echo "INFO: Build completed"
