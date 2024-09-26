#!/bin/sh
# Warm up the mounted disks

echo "Started warmup at $(date "+%y.%m.%d %H:%M:%S")"

# It takes some time for VMX MacOS to fill the disks list, so repeating it
# 210 sec to warmup the mounted disks
for i in $(seq 1 20); do
    df -m | grep '^/dev/disk' | grep -F ' /Volumes/' | while read line; do
        disk=$(echo "$line" | awk '{print $1}')
        # Synthesized disks can't be read while the disk is mounted, so looking for physical storage
        while diskutil list "$disk" | grep -sq '(synthesized):'; do
            disk="/dev/$(diskutil info -plist "$disk" | plutil -extract APFSPhysicalStores.0.APFSPhysicalStore raw -)"
        done

        # Trying to get uuid as DiskUUID or, if unavailable, VolumeUUID
        uuid=$(diskutil info -plist "$disk" | plutil -extract DiskUUID raw -)
        [ $? -eq 0 ] || uuid=$(diskutil info -plist "$disk" | plutil -extract VolumeUUID raw -)

        # Warmup disk one time
        [ ! -f "/tmp/warmup_$uuid.txt" ] || continue

        usage=$(echo "$line" | awk '{print $3}')
        # Minimum disk warmup usage is 32MB
        [ "$usage" -gt 32 ] || continue

        mountpoint=$(diskutil info -plist "$disk" | plutil -extract MountPoint raw -)
        echo "Warmup: $mountpoint ($disk, ${usage}MB used)..."

        # External devices needs special attention
        ext_device=$(diskutil info -plist "$disk" | plutil -extract RemovableMediaOrExternalDevice raw -)
        if [ "x$ext_device" = 'xtrue' ]; then
            # We need to process the whole disk because try to use volume will throw "Resource busy"
            disk="/dev/$(diskutil info -plist "$disk" | plutil -extract ParentWholeDisk raw -)"

            # Storing root authorized key and running fio through ssh (to get free external disk access)
            # SIP rules prevent root access to external disks and makes our automation life harder...
            mkdir -p /var/root/.ssh
            root_keys_used=true
            ssh-keygen -N '' -f "/var/root/.ssh/warmup_$uuid"
            cat "/var/root/.ssh/warmup_$uuid.pub" >> /var/root/.ssh/authorized_keys
            ssh -i "/var/root/.ssh/warmup_$uuid" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@localhost \
                /usr/local/bin/fio --filename "$disk" --rw read --bs 1M --iodepth 32 --size "${usage}M" --ioengine posixaio --name "warmup_$uuid" --output "/var/log/warmup_$uuid.log" &
        else
            # Otherwise just executing the fio app - internal disks will work just fine
            /usr/local/bin/fio --filename "$disk" --rw read --bs 1M --iodepth 32 --size "${usage}M" --ioengine posixaio --name "warmup_$uuid" &
        fi

        # Save the volume is warmed up
        date > "/tmp/warmup_$uuid.txt"
    done

    sleep $i
done

# Cleanup root ssh keys when was used
[ "x$root_keys_used" = "x" ] || rm -rf /var/root/.ssh

echo "Ended warmup at $(date "+%y.%m.%d %H:%M:%S")"
