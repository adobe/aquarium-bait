#!/bin/sh
# Detects the raw disks (not mounted and without partitions) and formats them

echo "Started formatall at $(date "+%y.%m.%d %H:%M:%S")"

# Check the ws labels to start counter properly, otherwise we will see conflicts
ws_labels_num=$(find /dev/disk/by-label -mindepth 1 -name 'ws*' | wc -l)
[ "$ws_labels_num" -eq 0 ] || counter=$ws_labels_num

# List disks without loop devices
disks=$(lsblk --list --noheadings --nodeps --output PATH | sort | grep -v '^/dev/loop')

# Filter only no partition disks
for disk in $disks; do
    disk_info=$(lsblk --list --noheadings --output PATH,MOUNTPOINT "$disk")

    # If there is some partitions it will output them as additional lines
    if [ "$(echo "$disk_info" | wc -l)" -gt 1 ]; then continue; fi
    # Check if the disk is not mounted already
    if [ "$(echo "$disk_info" | cut -d' ' -f 2)" != '' ]; then continue; fi

    to_format="$disk $to_format"
done

# Process format of the disks, first one will have workspace label
for disk in $to_format; do
    echo "Formatting disk '$disk'..."

    # Creating the partition table with one partition
    (
        echo o # Create a new empty DOS partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 1 # Partition number
        echo   # First sector (Accept default: 1)
        echo   # Last sector (Accept default: varies)
        echo w # Write changes
    ) | fdisk "$disk"

    # Creating the filesystem
    mkfs -t ext4 -L "ws$counter" "${disk}p1" || mkfs -t ext4 -L "ws$counter" "${disk}1"

    # Call partprobe to notify the system that the partition table was changed
    partprobe

    counter=$(($counter+1))
done

echo "Ended formatall at $(date "+%y.%m.%d %H:%M:%S")"
