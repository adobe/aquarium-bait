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
        # Unfortunately the file image on top of external disk does not work correctly with xcode lsregister
        # (it still needs ext disk access), so complex logic was removed and replaced by user TCC.db mods

        diskutil eraseDisk APFS "ws$counter" "${disk}"

        counter=$(($counter+1))
    done

    if [ "x$to_format" != "x" ]; then
        echo "Disabling Spotlight for all the mounted volumes"
        # Unfortunately with enabled SIP it's hard to disable spotlight for specific volume
        mdutil -a -i off
    fi

    sleep $i
done
