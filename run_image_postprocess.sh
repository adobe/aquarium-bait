#!/bin/sh -e
# Script to run the common images post-process actions.
#
# No needed to be run manually - executed by the build_image.sh script after the packer build

IMAGE_FULL_PATH="$1"

OUT_PATH=$(dirname "${IMAGE_FULL_PATH}")
VM_NAME=$(basename "${IMAGE_FULL_PATH}")

cd "${OUT_PATH}"
chmod -R g+r "${VM_NAME}"

# Detecting the main disk
disk_file="${VM_NAME}/MainDisk-1.vmdk"
disk_file_cloned=$(find "${VM_NAME}" -name 'MainDisk-1-cl*.vmdk' ! -name 'MainDisk-1-cl*-*.vmdk')
[ "x${disk_file_cloned}" = "x" ] || disk_file="${disk_file_cloned}"

# Getting the timestamp of the VM for proper versioning
vm_timestamp=$(for f in "${VM_NAME}"/*; do date -ur "$f" +%y%m%d.%H%M%S; done | sort | tail -1)
vm_name_completed="${VM_NAME}-${vm_timestamp}_$(grep '^CID=' "${disk_file}" | cut -d= -f2)"



if grep -q '^sata0:1.*iso"\?$' "${VM_NAME}/${VM_NAME}.vmx"; then
    echo 'INFO: Removing iso from the virtual machine config for the image'
    sed -i.orig -e '/^sata0:1/d' "${VM_NAME}/${VM_NAME}.vmx"
fi

echo 'INFO: Use relative path in vmx, vmsd and vmdk to simplify the image usage on different systems'
sed -i.orig -e "s|${OUT_PATH}|..|g" "${VM_NAME}/${VM_NAME}.vmx" "${VM_NAME}/${VM_NAME}.vmsd" "${disk_file}"

echo 'INFO: Create the "original" snapshot to use in the child images'
vmrun snapshot "${VM_NAME}/${VM_NAME}.vmx" original

echo 'INFO: Add CID and timestamp to the image directory name to identify the image properly'
mv "${VM_NAME}" "${vm_name_completed}"
disk_file_cloned=$(find "${vm_name_completed}" -name 'MainDisk-1-cl*.vmdk' ! -name 'MainDisk-1-cl*-*.vmdk')

echo 'INFO: Put the manifest with the unpacked size of the image (in kb, whole dir first)'
echo "---\n# Aquarium Bait manifest file\nsize_kb:" > "${vm_name_completed}/${vm_name_completed}.yml"
du -a -k "${vm_name_completed}" | awk '{ print "  \"" $2 "\": " $1}' | sort >> "${vm_name_completed}/${vm_name_completed}.yml"
if [ "x${disk_file_cloned}" != "x" ]; then
    echo 'INFO: Collect dependencies of the image and store in the manifest file'
    echo "parents:" >> "${vm_name_completed}/${vm_name_completed}.yml"
    disk_to_process="${disk_file_cloned}"
    while [ "${disk_to_process}" ]; do
        parent_disk=$(grep '^parentFileNameHint=' "${disk_to_process}" | cut -d= -f2 | tr -d '"')
        [ "x${parent_disk}" != "x" ] || break
        parent_image=$(echo "${parent_disk}" | rev | cut -d/ -f2 | rev)
        echo "  - ${parent_image}" >> "${vm_name_completed}/${vm_name_completed}.yml"
        disk_to_process="$(echo "${parent_disk}" | sed 's|^../||')"
    done
fi

echo 'INFO: Copy packer log of the build process to the image'
cp /tmp/packer.log "${vm_name_completed}/packer.log"



echo 'INFO: Clean up the *.orig files in the completed image'
rm -f "${vm_name_completed}/"*.orig

echo 'INFO: Run checksum of all the files in the archive'
shasum -a 256 -b "${vm_name_completed}"/* > "${vm_name_completed}.sha256"
mv "${vm_name_completed}.sha256" "${vm_name_completed}/"

echo "INFO: Image post-process completed: ${vm_name_completed}"
