# Aquarium Bait

Image builder system to ensue the CI build environment will be consistent from build to build. The
images can be used with versioning to easily reproduce the same results of the past build.

## Requirements

* Host: the installer delays are tuned for MacBook Pro '19 2.3 GHz 8-Core Intel Core i9 (connected
  to power outlet). Make sure you have at least 200GB of disk space to build an image.
* Python 3 + venv
* [Packer v1.7.1](https://www.packer.io/downloads)
* For MacOS image:
  * Can only be running on MacOS (license restrictions)
  * VMWare fusion 12.1.0

## Image structure

The image forms a tree and basically reuses the parent disks to optimize the storage and the build
process, so the leaves of the trees will require the parents to be in place.

* **macos-1015** - the base os with low-level configs ([base_image.yml](playbooks/base_image.yml))
   * macos-1015-**ci** - jenkins user and autorunning jnlp agent
      * macos-1015-ci-**xcode-122** - the Xcode tools of a specific version

The VMX packer specs are using `source_path` (in `packer/macos-1015/ci.yml` for example) to build
the `CI` image on top of the previously created `macos-1015` image. That's why `build_macos.sh`
wrapper is executing the directory tree levels sequentially - to make sure we already built the
previous level image to use it in the next levels of images.

## Using of the images

Basic VM and VM build system right now uses 2CPU and 4GB for VM build process.

During actual run on the target system you can change CPU & MEM values to the required values, but
please leave some for the HOST system:

### VMWare

Change `.vmx` file:

* CPU (if you have more than one CPU socket - use `CPUS_PER_SOCKET = TOTAL_CPUS / <NUM_SOCKETS>`
  to preserve the NUMA config):
   ```
   # CPU
   numvcpus = "<TOTAL_CPUS>"
   cpuid.coresPerSocket = "<CPUS_PER_SOCKET>"
   ```
* RAM:
   ```
   # Mem
   memsize = "<RAM_IN_MB>"
   ```

## Static checks

Ansible is a complex system, so linting is necessary. You can run the verification by `./check.sh`
script and it will execute docker to validate the playbooks.

## How to create from scratch

### 1. Create ISO of MacOS installer

1. Download MacOS installer from app store:
  * [Catalina 10.15](https://itunes.apple.com/us/app/macos-catalina/id1466841314?ls=1&mt=12)
  * [BigSur 11.0](https://itunes.apple.com/us/app/macos-big-sur/id1526878132?ls=1&mt=12)
2. Create dmg:
   ```
   $ hdiutil create -o /tmp/macos-installer -size 8500m -volname macosx-installer -layout SPUD -fs HFS+J
   ```
3. Mount the dmg:
   ```
   $ hdiutil attach /tmp/macos-installer.dmg -noverify -mountpoint /Volumes/macos-installer
   ```
4. Unpack the installer:
   ```
   $ sudo /Applications/Install\ macOS\ Catalina.app/Contents/Resources/createinstallmedia --volume /Volumes/macos-installer --nointeraction
   ```
5. Umount the dmg:
   ```
   $ hdiutil detach /Volumes/macos-installer
   ```
6. Convert the dmg to cdr and iso:
   ```
   $ hdiutil convert /tmp/macos-installer.dmg -format UDTO -o /tmp/macos-installer.cdr
   $ mv /tmp/macos-installer.cdr /tmp/macos-installer.iso
   $ rm -f /tmp/macos-installer.dmg
   ```

### 2. Put the dependencies in place

#### ISO images

Packer will use iso images from iso directory. The iso should be named just like the packer yml
file, but with the iso extension.

* Build or Download MacOS-Catalina-10.15.7-210125.190800.iso
* Place it as iso/MacOS-Catalina-10.15.7.iso

#### Ansible files

Roles can download files from artifact storage, but in case it's not an option (you're remote and
can't use VPN due to client routing restrictions) - you can place the files locally.

Ansible playbooks uses a number of binary packages you can find in artifact storage, check the
[playbooks/files/README.md](playbooks/files/README.md) and the other dirs to get the clue.

### 3. Run build

**WARNING:** if you're remote - make sure you don't have VPN enabled, otherwise it will lead to
redirecting all your traffic through VPN and packer will never find your VM to execute operations.
VM only have connection to host, not to the local net or internet. In case you want to build the
images locally - you will need to fill the binaries directory as described in **Ansible files**
section.

Now when all the required things are ready - you can run the image builder:
```
$ ./build_macos.sh
```

This script will automatically create the not-existing images in out directory. You can specify the
packer yml files as arguments to build the specific images. Also you can put `DEBUG=1` env var to
tell builder to ask in case of any issue happening during the build.

Also the builder supports `screenshot-packer` during the build process, you just need to build or
place binary into `screenshot-packer` directory and run the build script.

### 4. Run pack of the images

Now you can run script to pack all the generated images into tight tar.xz archives:
```
$ ./pack_macos.sh
```

As with the build you can pack specific images by defining the out directories to pack.

## Upload the artifacts

* ISO installer:
   ```
   file=iso/MacOS-Catalina-10.15.7.iso ;
   name=$(basename "$file" | rev | cut -d. -f2-) | rev ;
   curl --progress-bar -u "<user>:<token>" -X PUT \
     -H "X-Checksum-Sha256: $(sha256sum "$file" | cut -d' ' -f1)"  -T "$file" \
     "https://artifact-storage/aquarium/installer/$name/$name-$(date -r "$file" +%y%m%d.%H%M%S).iso" | tee /dev/null
   ```

* VM Image:
   ```
   file=out/macos-1015.tar.xz ;
   name=$(basename "$file" | cut -d. -f1) ;
   curl --progress-bar -u "<user>:<token>" -X PUT \
     -H "X-Checksum-Sha256: $(sha256sum "$file" | cut -d' ' -f1)"  -T "$file" \
     "https://artifact-storage/aquarium/image/$name/$name-$(date -r "$file" +%y%m%d.%H%M%S).tar.xz" | tee /dev/null
   ```

## Advices on testing

### Ansible: run playbook

To test the playbook you will just need a VM and inventory. For example inventory for windows
looks like that and automatically generated by packer, so the inventory path can be copied from its
output "Executing Ansible:"
```
$ cat inv.ini
default ansible_host=172.16.1.80 ansible_connection=winrm ansible_winrm_transport=basic ansible_shell_type=powershell ansible_user=packer ansible_port=5985
```

```
$ cp /var/folders/dl/lb2z806x47q7dwq_lpwcmlzc0000gq/T/packer-provisioner-ansible355942774 inv.ini
$ ./run_ansible.sh -vvv -e ansible_password=packer -i inv.ini playbooks/base_image.yml
```

### Ansible: execute module

When you need to test the module behavior on the running packer VM - just copy the inventory (it is
created when packer runs ansible) file and use it to connect to the required VM.

```
$ cp /var/folders/dl/lb2z806x47q7dwq_lpwcmlzc0000gq/T/packer-provisioner-ansible355942774 inv.ini
$ . ./.venv/bin/activate
(.venv) $ no_proxy="*" ansible default -e ansible_password=packer -i inv.ini -m shell -a "echo lol"
(.venv) $ no_proxy="*" ansible default -e ansible_password=packer -i inv.ini -m win_shell -a "dir C:\\tmp\\"
(.venv) $ no_proxy="*" ansible default -e ansible_password=packer -i inv.ini -m win_copy -a "src=$(pwd)/playbooks/files/win/PSTools-v2.48.zip dest=C:\\tmp\\PSTools-v2.48.zip"
```

### Ansible: template validation

You just need to activate the python venv and run ansible in it. Venv is created when packer
executes `./run_ansible.sh` script during preparation of any image.

```
$ . ./.venv/bin/activate
(.venv) $ ansible all -i localhost, -m debug -a "msg={{ tst_var | regex_replace('\r', '') }}" --extra-vars '{"tst_var":"test\r\n\r\n"}'
```
