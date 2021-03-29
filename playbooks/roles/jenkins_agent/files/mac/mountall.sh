#!/bin/sh -e
# Mounts all the available volumes on external disks
# It takes some time for MacOS to fill the disks list, so repeating it

for i in $(seq 1 10); do
    disks=$(diskutil list | grep external | cut -d ' ' -f 1)
    echo "Located disks: $disks"
    for disk in $disks; do
        echo "Mounting: $disk..."
        diskutil list "$disk"
        diskutil mountDisk "$disk"
        mount | grep "^$disk"
    done
    sleep $i
done
