#!/bin/sh
# Mounts all the available volumes on external disks

# It takes some time for VMX MacOS to fill the disks list, so repeating it
# 55 sec to mount the external disks
for i in $(seq 1 10); do
    # List physical disks devices paths with suffix "internal" or "external"
    disks_type=$(diskutil list physical | grep '^/dev' | tr -d '(,):' | cut -d' ' -f 1-2 | tr ' ' '-' | grep 'internal\|external')

    echo "Located disks: $disks_type"

    # Internal disks doesn't need much and available for regular user, but external ones needs additional attention
    mounted=''
    for disk_type in $disks_type; do
        disk=$(echo "$disk_type" | cut -d'-' -f 1)
        type=$(echo "$disk_type" | cut -d'-' -f 2)

        # Getting the amount of volumes inside the disk to process
        vol_num=$(diskutil list -plist "$disk" | plutil -extract AllDisks raw -)
        if [ "x$vol_num" = "x" -a "$vol_num" -gt 0 ]; then continue; fi

        # Skipping 0 here because it will be the disk device itself
        for vol_index in $(seq 1 $(($vol_num-1))); do
            vol="/dev/$(diskutil list -plist "$disk" | plutil -extract AllDisks.$vol_index raw -)"
            echo "Processing volume: $vol..."
            # Check if already mounted
            mountpoint=$(diskutil info -plist "${vol}" | plutil -extract MountPoint raw -)
            if [ "x$mountpoint" = "x" ]; then
                echo "Mounting: $vol..."
                diskutil mount nobrowse "${vol}" && mounted=1
                mountpoint=$(diskutil info -plist "${vol}" | plutil -extract MountPoint raw -)
            fi
        done
    done

    if [ "x$mounted" != 'x' ]; then
        echo "Disabling Spotlight for all the mounted volumes"
        # Unfortunately with enabled SIP it's hard to disable spotlight for specific volume
        mdutil -a -i off
    fi

    sleep $i
done
