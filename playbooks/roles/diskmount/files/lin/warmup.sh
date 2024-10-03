#!/bin/sh
# Warm up the mounted disks
# It could take some time to fill the disks list, so repeating it

echo "Started warmup at $(date "+%y.%m.%d %H:%M:%S")"

# 210 sec to warmup the mounted disks
for i in $(seq 1 20); do
    labels=$(find /dev/disk/by-label -mindepth 1)
    for label in $labels; do
        uuid=$(lsblk --output UUID --noheadings "$label")
        # Warmup disk one time
        [ ! -f "/tmp/warmup_$uuid.txt" ] || continue

        disk="$(readlink -f "$label")"
        # The disk need to be mounted
        mount | grep -qF "$disk " || continue

        usage=$(df --output=used -m "$label" | tail -1 | tr -d ' ')
        # Minimum disk warmup usage is 32MB
        [ "$usage" -gt 32 ] || continue

        echo "Warmup: $label $uuid ($disk, ${usage}MiB used)..."
        fio --filename "$disk" --rw read --bs 1Mi --iodepth 32 --size "${usage}Mi" --ioengine libaio --direct 1 --name warmup_$uuid --output "/var/log/warmup_$uuid.log" &

        # Save the volume is warmed up
        date > "/tmp/warmup_$uuid.txt"
    done

    sleep $i
done

# Waiting for the running background jobs before wrapping up
wait $(jobs -p)

echo "Ended warmup at $(date "+%y.%m.%d %H:%M:%S")"
