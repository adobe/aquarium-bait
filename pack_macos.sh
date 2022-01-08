#!/bin/sh -e
# Pack the images in out directory
# Usage:
#   ./pack_macos.sh [path_of_the_image_dir_to_pack [...]]

root_dir=$(realpath "$(dirname "$0")")
cd "${root_dir}"

for path in out/*; do
    # Skipping non-dir target
    [ -d "${path}" ] || continue

    # Skip if path not in the filter
    if [ "$1" ]; then
        skip_image=true
        for filter in "$@"; do
            [ "${path}" != "${filter}" ] || skip_image=""
        done
        [ -z "${skip_image}" ] || continue
    fi

    # date -r "$file" +%y%m%d.%H%M%S
    name=$(basename "${path}")

    # Check the lock files are not present
    if [ "$(find "${path}" -name '*.lck')" ]; then
        echo "ERROR: Image '${path}' contains lock files, please stop the vmware vms and the application."
        exit 1
    fi

    # Make sure the image was build in release mode
    if [ ! -f "${path}/packer.log" ]; then
        echo "ERROR: Image '${path}' was build in DEBUG mode, only the release images can be packed."
        exit 1
    fi

    # Check that only allowed files are in the image
    find_pattern=''
    for pattern in 'MainDisk-*.vmdk' 'packer.log' "$name.vmx" "$name.vmsd" "*.vm*.orig" "$name.nvram" "$name-Snapshot*.vmsn" "$name.vmxf" "$name.sha256"; do
        find_pattern="$find_pattern ! -name '$pattern'"
    done
    noneed_files=$(sh -c "find '${path}' $find_pattern")
    if [ "x$noneed_files" != "x${path}" ]; then
        echo "ERROR: Image '${path}' contains weird files need to be cleaned before packing: $noneed_files"
        exit 1
    fi

    # Making the package path based on the last changed file in the image
    package="$path-$(for f in "$path"/*; do date -r "$f" +%y%m%d.%H%M%S; done | sort | tail -1).tar.xz"

    echo
    echo "INFO: Processing '${package}'..."

    if [ -f "${package}" ]; then
        echo "INFO:   skip since '${path}' is already packed"
        continue
    fi

    vmsd_file="${path}/${name}.vmsd"
    if [ -f "${vmsd_file}" ]; then
        # Save backup to restore later and replace absolute path with token to change on the target
        [ -f "${vmsd_file}.bak" ] || cp "${vmsd_file}" "${vmsd_file}.bak"
        grep -F -v 'snapshot0.clone0' "${vmsd_file}.bak" | grep -F -v 'snapshot0.numClones' > "${vmsd_file}"
        sed -i.orig -e "s|${root_dir}/out|<REPLACE_PARENT_VM_FULL_PATH>|" "${vmsd_file}"
    fi

    # Cleaning the .orig files
    rm -f "${path}"/*.orig

    # Print out the image size
    echo "  Unpacked image size: $(du -d 1 -h "${path}" | tail -1 | cut -f 1)"

    # Run checksum of all the files in the archive
    rm -f "${name}/${name}.sha256"
    cd "${root_dir}/out"
    shasum -a 256 -b ${name}/* > "${name}.sha256"
    mv "${name}.sha256" "${name}/${name}.sha256"
    cd "${root_dir}"

    # Pack the image hard, using quarter of the available vcores to not overload the system
    XZ_OPT="-e9 --threads=$(($(getconf _NPROCESSORS_ONLN)/4))" tar -C out -cvJf "${package}" "${name}"

    # Print out the image size
    echo "  Packed image size: $(du -h "${package}" | cut -f 1)"

    # Restore the vmsd file
    [ ! -f "${vmsd_file}.bak" ] || mv "${vmsd_file}.bak" "${vmsd_file}"
done

echo "INFO: Pack operation done"
