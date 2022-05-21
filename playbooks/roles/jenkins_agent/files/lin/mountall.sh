#!/bin/sh
# Mounts all the available volumes on external disks
# It could take some time to fill the disks list, so repeating it

# 210 sec to mount the external disks
for i in $(seq 1 20); do
    labels=$(find /dev/disk/by-label -mindepth 1)
    echo "Located disk labels: $labels"
    for label in $labels; do
        disk="$(readlink -f "$label")"
        point="/mnt/$(basename "$label")"
        echo "Mounting: $label ($disk) to $point..."
        mkdir "$point"
        # Mount could fail if the disk is not healthy
        if ! mount -o uid=jenkins,gid=jenkins "$label" "$point"; then
            # Mount again if the fs doesn't support uid/gid options
            mount "$label" "$point"
            # Execute chown to change the owner/group of the volume or as
            # the last resort change the mountpoint mod to "access to all"
            chown jenkins:jenkins "$point" || chmod 0777 "$point"
        fi
        mount | grep "^$disk"
    done
    sleep $i
done

exit 0
