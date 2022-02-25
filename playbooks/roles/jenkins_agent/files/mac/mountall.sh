#!/bin/sh
# Mounts all the available volumes on external disks
# It takes some time for MacOS to fill the disks list, so repeating it
#
# Works well only if System Integrity Protection (SIP) is disabled, otherwise the jenkins user
# will not be able to access the mounted workspace disk.

# 210 sec to mount the external disks
for i in $(seq 1 20); do
    disks=$(diskutil list | grep external | cut -d ' ' -f 1)
    echo "Located disks: $disks"
    for disk in $disks; do
        echo "Mounting: $disk..."
        diskutil list "$disk"
        # Mount could fail if the disk is not healthy
        diskutil mountDisk "$disk"
        # Disable Spotlight for the mounted volume
        mdutil -i off "$(diskutil info "$disk" | grep 'Mount Point:' | cut -d: -f 2 | awk '{$1=$1};1')"
        mount | grep "^$disk"
    done
    sleep $i
done
