#!/bin/sh -e
# Pack the images in out directory
# Usage:
#   ./pack_image.sh <out/image_dir> [...]

for path in "$@"; do
    # Skipping non-dir target
    [ -d "${path}" ] || continue

    image=$(basename "${path}")
    # Strip version to get name of the image
    name=$(echo "$image" | rev | cut -d- -f2- | rev)

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
    need_files=''
    find_noneed_pattern=''
    for filename in 'MainDisk-*.vmdk' 'packer.log' "$name.vmx" "$name.vmsd" "$name.nvram" "$name-Snapshot*.vmsn" "$name.vmxf" "$image.sha256" "$image.req"; do
        if [ "x$(sh -c "find '${path}' -name '$filename'")" = 'x' ]; then
            need_files="$need_files $filename"
        fi
        find_noneed_pattern="$find_noneed_pattern ! -name '$filename'"
    done
    if [ "x$need_files" != 'x' ]; then
        echo "ERROR: Image '${path}' doesn't contain the required files for packing:\n$need_files"
        exit 1
    fi
    noneed_files=$(sh -c "find '${path}' $find_noneed_pattern")
    if [ "x$noneed_files" != "x${path}" ]; then
        echo "ERROR: Image '${path}' contains weird files need to be cleaned before packing: $noneed_files"
        exit 1
    fi

    package="$path.tar.xz"

    echo
    echo "INFO: Processing '${package}'..."

    if [ -f "${package}" ]; then
        echo "INFO:   skip since '${path}' is already packed"
        continue
    fi

    vmsd_file="${path}/${name}.vmsd"
    if [ -f "${vmsd_file}" ]; then
        # Cleaning the snapshot clones which is created by the child linked VMs
        mv "${vmsd_file}" "${vmsd_file}.bak"
        grep -F -v -e 'snapshot0.clone' -e 'snapshot0.numClones' "${vmsd_file}.bak" > "${vmsd_file}"
        rm -f "${vmsd_file}.bak"
    fi

    # Print out the image size
    echo "  Unpacked image size: $(du -d 1 -h "${path}" | tail -1 | cut -f 1)"

    # Pack the image hard, using quarter of the available vcores to not overload the system
    XZ_OPT="-e9 --threads=$(($(getconf _NPROCESSORS_ONLN)/4))" tar -C out -cvJf "${package}" "${image}"

    # Print out the image size
    echo "  Packed image size: $(du -h "${package}" | cut -f 1)"
done

echo "INFO: Pack operation done"
