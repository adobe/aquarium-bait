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

    echo
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

    # Check the lock files are not present
    if [ "$(find "${image}" -name '*.lck')" ]; then
        echo "ERROR: Image '${image}' contains lock files, please stop the vmware vms and the application."
        exit 1
    fi

    # Make sure the image was build in release mode
    if [ ! -f "${image}/packer.log" ]; then
        echo "ERROR: Image '${image}' was build in DEBUG mode."
        exit 1
    fi

    # Check that only allowed files are in the image
    find_pattern=''
    for pattern in 'MainDisk-*.vmdk' 'packer.log' "$name.vmx" "$name.vmsd" "*.vm*.orig" "$name.nvram" "$name-Snapshot*.vmsn" "$name.vmxf" "$name.sha256"; do
        find_pattern="$find_pattern ! -name '$pattern'"
    done
    noneed_files=$(sh -c "find '${image}' $find_pattern")
    if [ "x$noneed_files" != "x${image}" ]; then
        echo "ERROR: Image '${image}' contains weird files need to be cleaned before packing: $noneed_files"
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

    # Print out the image size
    echo "  Unpacked image size: $(du -d 1 -h "${image}" | tail -1 | cut -f 1)"

    # Run checksum of all the files in the archive
    rm -f "${name}/${name}.sha256"
    cd "${root_dir}/out"
    shasum -a 256 -b ${name}/* > "${name}.sha256"
    mv "${name}.sha256" "${name}/${name}.sha256"
    cd "${root_dir}"

    # Pack the image hard, using half of available vcores to not overload the system
    XZ_OPT="-e9 --threads=$(($(getconf _NPROCESSORS_ONLN)/4))" tar -C out -cvJf "${image}.tar.xz" "${name}"

    # Print out the image size
    echo "  Packed image size: $(du -h "${image}.tar.xz" | cut -f 1)"

    # Restore the vmsd file
    [ ! -f "${vmsd_file}.bak" ] || mv "${vmsd_file}.bak" "${vmsd_file}"
done

echo "INFO: Pack operation done"
