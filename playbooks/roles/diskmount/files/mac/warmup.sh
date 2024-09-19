#!/bin/sh
# Warm up the mounted disks

# It takes some time for VMX MacOS to fill the disks list, so repeating it
# 210 sec to warmup the mounted disks
for i in $(seq 1 20); do
    df -m | grep '^/dev/disk' | grep -F ' /Volumes/' | while read line; do
        disk=$(echo "$line" | awk '{print $1}')
        # Synthesized disks can't be read while the disk is mounted, so looking for physical storage
        while diskutil list "$disk" | grep -sq '(synthesized):'; do
            disk=$(diskutil info -plist "$disk" | plutil -extract APFSPhysicalStores.0.APFSPhysicalStore raw -)
        done

        uuid=$(diskutil info -plist "$disk" | plutil -extract DiskUUID raw -)
        # Warmup disk one time
        [ ! -f "/tmp/warmup_$uuid.txt" ] || continue

        usage=$(echo "$line" | awk '{print $3}')
        # Minimum disk warmup usage is 32MB
        [ "$usage" -gt 32 ] || continue

        mountpoint=$(echo "$line" | awk '{print $9}')
        echo "Warmup: $mountpoint ($disk, ${usage}MB used)..."

        fio --filename "$disk" --rw read --bs 1M --iodepth 32 --size "${usage}M" --ioengine posixaio --direct 1 --name warmup_$uuid &

        # Save the volume is warmed up
        date > "/tmp/warmup_$uuid.txt"
    done

    sleep $i
done
