#!/bin/sh
# Detects the raw disks (without partitions), formats and mounts them

# It takes some time for VMX MacOS to fill the disks list, so repeating it
# 55 sec to process the physical disks
for i in $(seq 1 10); do
    # List physical disks devices paths with suffix "internal" or "external"
    disks_type=$(diskutil list physical | grep '^/dev' | tr -d '(,):' | cut -d' ' -f 1-2 | tr ' ' '-' | grep 'internal\|external')

    # Filter only no partition disks
    to_format=''
    for disk_type in $disks_type; do
        disk=$(echo "$disk_type" | cut -d'-' -f 1)
        partitioned=$(diskutil info -plist "$disk" | plutil -extract Content raw -)

        # Empty if not partitioned, otherwise - type of partition scheme
        if [ "x$partitioned" = "x" ]; then
            to_format="$disk_type $to_format"
        fi
    done

    # Internal disks doesn't need much and available for regular user
    for disk_type in $to_format; do
        disk=$(echo "$disk_type" | cut -d'-' -f 1)
        type=$(echo "$disk_type" | cut -d'-' -f 2)

        echo "Formatting & mounting disk '$disk'..."
        # External disks mounts are prohibited by SIP to be used by a regular UI user - "operation not permitted"
        # So using a workaround in creating dmg image and mounting it instead
        if [ "x$type" = "xexternal" ]; then
            # Using MBR here to not create EFI partition
            diskutil eraseDisk HFS+ "disk_ws$counter" MBR "${disk}"

            size=$(df -h "/Volumes/disk_ws$counter" | tail -1 | awk '{print $2}')
            echo "Creating ws_image ($size) file on '$disk'..."
            hdiutil create -o /Volumes/disk_ws$counter/ws_image -size "$size" -volname "ws$counter" -type SPARSEBUNDLE -fs HFS+ -attach
        else
            # Using MBR here to not create EFI partition
            diskutil eraseDisk HFS+ "ws$counter" MBR "${disk}"

            # We need to set owner to allow non-UI jenkins user to write to the disk
            diskutil enableOwnership "/Volumes/ws$counter"
            chown jenkins:jenkins "/Volumes/ws$counter"
        fi

        counter=$(($counter+1))
    done

    if [ "x$to_format" != "x" ]; then
        echo "Disabling Spotlight for all the mounted volumes"
        # Unfortunately with enabled SIP it's hard to disable spotlight for specific volume
        mdutil -a -i off
    fi

    sleep $i
done
