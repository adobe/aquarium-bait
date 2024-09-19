# Disk mount role

This role mounts the disks, format if needed and can warmup the disks

## Tasks

* Automount - mounts disks to default OS mountpoints
* Autoformat - creates filesystems on raw disks
* Warmup - multithread read of used data of the mounted disks
