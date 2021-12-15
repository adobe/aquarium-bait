# Download role

This role unifies a way to get files to VM during packer execution. The binaries firstly are
checked in `aquarium-bait/playbooks/files` directory by local path, and if it's not here - it's
downloaded to the local machine and then copied to VM, because VM have no direct connection to the
outside network.

## Tasks

* Download binary to VM

## Usage

```yaml
- name: Download file to the environment
  include_role:
    name: download
  vars:
    download_url: <URL>
    download_checksum: <hash_algo:checksum>

- name: Unpack the downloaded archive
  unarchive:
    src: '{{ download_path }}'
    dest: /usr/local
    remote_src: true
```
