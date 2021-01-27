# Cleanup role

This role runs at the end of the playbook and ensures the machine is all cleaned up and ready to be snapshotted.

## Tasks

* Delete shell history files
* Empty trash
* Fill free disk space with zeroes (to allow to squeeze the disk properly)

## TODO

* Remove not needed services:
  * MacOS: https://github.com/Brantone/macos-vmware-packer/blob/master/scripts/mcandre/strip-services.macos.sh
