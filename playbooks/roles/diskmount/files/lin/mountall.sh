#!/bin/sh
# Mounts all the available volumes on external disks
# It could take some time to fill the disks list, so repeating it

# 210 sec to mount the external disks
for i in $(seq 1 20); do
    labels=$(find /dev/disk/by-label -mindepth 1)
    echo "Located disk labels: $labels"
    for label in $labels; do
        disk="$(readlink -f "$label")"
        # Make sure we're not mounting already mounted disk
        if mount | grep -qF "$disk "; then
            echo "Skipping already mounted disk: $label ($disk)"
            continue
        fi

        point="/mnt/$(basename "$label")"
        echo "Mounting: $label ($disk) to $point..."
        mkdir "$point"

        # Mount could fail if the disk is not healthy
        mount "$label" "$point"
        # Change the mountpoint mod to "access for all"
        chmod 0777 "$point"

        mount | grep "^$disk"
    done

    sleep $i
done

exit 0
