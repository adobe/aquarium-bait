# Aquarium Bait

Image builder system to ensue the CI build environment will be consistent from build to build. The
images can be used with versioning to easily reproduce the same results of the past build.

## Requirements

* Host: the installer delays are tuned for MacBook Pro '19 2.3 GHz 8-Core Intel Core i9 (connected
  to power outlet). Make sure you have at least 200GB of disk space to build an image.
* Python 3 + venv
* [Packer v1.7.9](https://www.packer.io/downloads)
* For MacOS image:
  * Can only be running on MacOS host (license restrictions)
  * VMWare fusion 12.2.0

## Image structure

The image forms a tree and basically reuses the parent disks to optimize the storage and the build
process, so the leaves of the trees will require the parents to be in place.

* **macos1015** - the base os with low-level configs ([base_image.yml](playbooks/base_image.yml))
   * macos1015-**ci** - jenkins user and autorunning jnlp agent
      * macos1015-ci-**xcode-122** - the Xcode tools of a specific version

The VMX packer specs are using `source_path` (in `packer/macos1015/ci.yml` for example) to build
the `CI` image on top of the previously created `macos1015` image. That's why `build_image.sh`
wrapper is executing the directory tree levels sequentially - to make sure we already built the
previous level image to use it in the next levels of images.

## Using of the images

### VMWare

#### Change `.vmx` file:

When you just cloned the new VM to run it on the target system - you need to make sure that you will
use the most of the resources you have - so don't forget this part otherwise you will struggle of
the performance penalty.

During actual run on the target system you can change CPU & MEM values to the required values, but
please leave some for the HOST system.

* CPU (if you have more than one CPU socket - use `CPUS_PER_SOCKET = TOTAL_CPUS / <NUM_SOCKETS>`
  to preserve the NUMA config):
   ```
   # CPU
   numvcpus = "<TOTAL_CPU_THREADS>"
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
can't use VPN for some reason) - you can place the files locally: Ansible playbooks uses a number
of binary packages you can find on artifact-storage, check the [playbooks/files/README.md](playbooks/files/README.md)
for additional information.

### 3. Run build

**NOTICE:** the Aquarium Bait supports building images with corporate VPN connected through special
local proxy which ignores the routing rules and always uses the local interfaces. For additional
info please look into [./build_image.sh](build_image.sh), [./scripts/proxy.py](scripts/proxy.py)
and [./packer/.yml](packer/) specs.

**NOTICE:** during the build the script takes pictures of the VM screen through VNC and places them
into `./screenshots/<image_name>` directory - so you can always check what's happened if your build
accedentally crashed during packer `boot_command` execution. For additional info look into
[./build_image.sh](build_image.sh) and [./scripts/screenshot.py](scripts/screenshot.py).

Now when all the required things are ready - you can run the image builder:
```
$ ./build_image.sh <packer/spec.yml> [...]
```

This script will automatically create the not-existing images in out directory. You can specify the
packer yml files as arguments to build the specific images. Also you can put `DEBUG=1` env var to
tell builder to ask in case of any issue happening during the build.

### 4. Run pack of the images

Now you can run script to pack all the generated images into tight tar.xz archives:
```
$ ./pack_image.sh [out/image_dir] [...]
```

As with the build you can pack specific images by defining the out directories to pack.

### 5. Upload the packed images

The last step is to upload the image to artifact storage to use it across the organization:
```
$ ./upload_image.sh <out/image.tar.xz> [...]
```

It will output the upload progress and info about the uploaded image when it will be completed.

## Advices on testing

### SSH: connecting through proxy

In order to connect to the local VM with VPN connection it's necessary to use the local proxy
started up by the `build_image.sh` script.

1. Run image build in debug mode and wait until the error happened:
   ```
   $ DEBUG=1 ./build_image.sh packer/<PACKER_SPEC_PATH>.yml
   ```
2. Find in console line `PROXY: Started Aquarium Bait noroute proxy on` which will contain proxy
host and port.
3. Find in console line `PROXY: Connected to:` which will show you the VM IP address
4. Run the next SSH command to use `nc` as the SSH transport for socks5 proxy with located info:
   ```
   $ ssh -o ProxyCommand='nc -X 5 -x 127.0.0.1:<PROXY_PORT> %h %p' packer@<VM_IP>
   ```
5. Type the default password `packer` and you good to go!

### VMWare Fusion visual debugging

Sometimes it's useful to get visual representation of the running VM and there is 2 ways to do that:

1. Modify the packer spec yml file to comment the `headless` option - but don't forget to change it
back after that. This way packer will run the build process with showing the VM GUI.

2. Just open the VMWare Fusion UI and it will show the currently active VM GUI. It's dangerous,
because if you will leave the VMWare Fusion UI - it will not remove the lock files in the VM dir,
so make sure when you complete the debugging you're properly close any signs of VMWare Fusion UI.

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
