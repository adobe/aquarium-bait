#!/bin/sh -e
# Pack the images in out directory
# Usage:
#   ./pack_macos.sh [path_of_the_image_dir_to_pack [...]]

root_dir=$(realpath "$(dirname "$0")")
cd "${root_dir}"

for image in out/*; do
    # Skip if path not in the filter
    if [ "$1" ]; then
        skip_image=true
        for filter in "$@"; do
            [ "${image}" != "${filter}" ] || skip_image=""
        done
        [ -z "${skip_image}" ] || continue
    fi

    name=$(basename "${image}")

    echo "INFO: Packing image '${name}'..."

    # Skip if image is a file or already have been packed
    if [ -f "${image}" -o -f "${image}.tar.xz" ]; then
        echo "INFO:   skip: '${image}'"
        continue
    fi

    # Check that the machine was not running manually after packing
    if [ -f "${image}/vmware.log" -o -f "${image}/startMenu.plist" ]; then
        echo "ERROR: Image '${image}' is not clean, please remove it and build it again"
        exit 1
    fi

    vmsd_file="${image}/${name}.vmsd"
    if [ -f "${vmsd_file}" ]; then
        # Save backup to restore later and replace absolute path with token to change on the target
        [ -f "${vmsd_file}.bak" ] || cp "${vmsd_file}" "${vmsd_file}.bak"
        grep -F -v 'snapshot0.clone0' "${vmsd_file}.bak" | grep -F -v 'snapshot0.numClones' > "${vmsd_file}"
        sed -i.orig -e "s|${root_dir}/out|<REPLACE_PARENT_VM_FULL_PATH>|" "${vmsd_file}"
    fi

    # Cleaning the .orig files
    rm -f "${image}"/*.orig

    # Pack the image hard, using half of available vcores to not overload the system
    XZ_OPT="-e9 --threads=$(($(getconf _NPROCESSORS_ONLN)/2))" tar -C out -cJf "${image}.tar.xz" "${name}"

    # Restore the vmsd file
    [ ! -f "${vmsd_file}.bak" ] || mv "${vmsd_file}.bak" "${vmsd_file}"
done

echo "INFO: Pack operation done"
