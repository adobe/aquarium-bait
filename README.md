# [Aquarium Bait](https://github.com/adobe/aquarium-bait)

This project is an essential part of the [Aquarium](https://github.com/adobe/aquarium-fish/wiki/Aquarium)
system - it's purpose is creating the enterprise oriented, consistent and reliable environment
images for further using as an env source for the [Aquarium Fish](https://github.com/adobe/aquarium-fish/)
node.

You can use Aquarium Bait as a general image building system without the rest of the [Aquarium](https://github.com/adobe/aquarium-fish/wiki/Aquarium)
stack components and run the images manually (it's described how below for each driver).

It's not only useful for the CI where we need to ensure the environment is exactly the one we
needed, but also for general purpose to run the applications of your organization in the safe and
completely controlled conditions according to the specifications.

In a nutshell, it's a shell wrapper around Packer and Ansible, which organizes the image building
in a certain manner in order to achieve specific enterprise-required goals, especially
supportability. By replacing the nasty configuration management with complicated logic with layered
versioned image building and management - the configuration scripts have become just a list of
steps and doesn't require anymore to have a degree to figure out what's going on. From layer to
layer Bait allows you to record and reuse state, branching the images from Base OS to infinity
variations and quickly figure out which ones requires rebuilding saving your time (and network
bandwidth) to distribute the images.

## Goals

* Easy track of the changes in the images
* Complete automation of the images builds
* Organize way to build and store the images for various environments
* Build from scratch if possible to completely control the environment
* Strict isolation to not allow the OS/Apps on the image to interact with network
* Use various image size optimizations including linking and reusing
* Proper versioning of the images
* Ability to build locally with no access to remote services (if have required cached artifacts)
* Replace complicated `change management` with layered versioned image building & management

## Requirements

* Host:
   * MacOS
   * Linux
* Python 3 + venv
* [Packer v1.7.9](https://www.packer.io/downloads)
* Make sure you have at least 200GB of disk space to build an image.
* For MacOS images:
   * The installer timeouts are tuned for MacBook Pro '19 2.3 GHz 8-Core Intel Core i9 (connected
   to power adapter).
   * Can only be running on MacOS host (Apple license restrictions)
   * VMWare Fusion 12.2.0

## Image structure

The image forms a tree and reuses the parent disks to optimize the storage and the build process,
so the leaves of the trees will require the parents to be in place.

* **macos1015** - the base OS with low-level configs
   * macos1015-**xcode122** - the Xcode tools of a specific version
      * macos1015-xcode122-**ci** - jenkins user and autorunning jnlp agent

In this example the VMX packer spec is using `source_path` (`specs/vmx/macos1015/xcode122/ci.yml`)
to build the `ci` image on top of the previously created `xcode122` image which was created as a
child of the `macos1015` image. That's why `build_image.sh` wrapper is executing the directory tree
stages sequentially - to make sure we already built the previous stage image to use it in the upper
levels of the images.

## Static checks

Even simple image-management Ansible specifications needs to be linted. You can run the verification
by `./check_style.sh` script and it will execute a number of tools to validate the playbooks.

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
   $ hdiutil detach /Volumes/Install\ macOS*
   ```
   * If here is an error - check the usage by and detach/kill the apps from the inside:
      ```
      sudo lsof | grep '/Volumes/Install macOS'
      ```
6. Convert the dmg to cdr and iso:
   ```
   $ hdiutil convert /tmp/macos-installer.dmg -format UDTO -o /tmp/macos-installer.cdr
   $ mv /tmp/macos-installer.cdr /tmp/macos-installer.iso
   $ rm -f /tmp/macos-installer.dmg
   ```

### 2. Put the dependencies in place

#### ISO images

Packer will use iso images from `init/iso` directory. The iso should be named just like the packer
yml file, but with the iso extension.

* Build or Download `MacOS-Catalina-10.15.7-210125.190800.iso`
* Place it as `init/iso/MacOS-Catalina-10.15.7.iso`

#### Ansible files

Roles can download files from artifact storage, but in case it's not an option (you're remote and
can't use VPN for some reason) - you can place the files locally: Ansible playbooks use a number of
binary packages you can find on artifact-storage, check the [playbooks/files/README.md](playbooks/files/README.md)
for additional information.

Another file will help you to override the URL's to your own org storage - `override.yml`, it's
placed in the repo root directory and readed by the `run_ansible.sh` script. It can contain the
variables from the roles. For example:
```yaml
---
vmtools_lin_vmware_download_url: https://my-own-artifact-storage/archive-ubuntu-remote/pool/universe/o/open-vm-tools/open-vm-tools_11.3.0-2ubuntu0~ubuntu20.04.2_amd64.deb

xcode_version_133_download_url: https://my-own-artifact-storage/aquarium/files/mac/Xcode_13.3.xip
xcode_version_133_download_checksum: sha256:dc5fd115b0e122427e2a82b3fbd715c3aee49ef76a64c4d1c59a787ce17a611b
xcode_version_133_cmd_download_url: https://my-own-artifact-storage/aquarium/files/mac/Command_Line_Tools_for_Xcode_13.3.dmg
xcode_version_133_cmd_download_checksum: sha256:7eff583b5ce266cde5c1c8858e779fcb76510ec1af3d9d5408c9f864111005c3
...
```

You can grep all the variables that have `_url: http` and put them in the file and override
one-by-one. Some specs are overriding the main download variable by the template (as in example for
xcode) and you can specify the version for each one to build the different images properly.

**WARNING**: Make sure you using http as your artifact transport, otherwise it could interfere with
the local proxy and won't allow you to download the artifacts from the role.

### 3. Run build

**NOTICE:** The Aquarium Bait supports local image building with corporate VPN connected through a
special local proxy which ignores the routing rules and always uses the local interfaces. For
additional info please look into [./build_image.sh](build_image.sh), [proxy_local.py](scripts/proxy_local.py)
and [./specs/vmx/.yml](specs/vmx/) specifications.

**NOTICE:** By default Aquarium Bait designed to build the images in sandbox with access from VM
only to the host. But in case it's strictly necessary you can run the http proxy during ansible
execution on the host system by setting the env variable in packer spec for ansible provisioner:
```
environment:
  - PROXY_REMOTE_LISTEN={{ build \`PackerHTTPIP\`}}
```
The ansible variables to access this proxy passed as `proxy_remote_host` and `proxy_remote_port`.

**NOTICE:** During the VM build the script records the VM screen through VNC and places it into
`./records/<image_name>.mp4` - so you can always check what's happened if your build accedentally
crashed during packer execution. For additional info look into [./build_image.sh](build_image.sh)
and [./scripts/vncrecord.py](scripts/vncrecord.py).

Now when all the required things are ready - you can run the image builder:
```
$ ./build_image.sh <specs/path/to/spec.yml> [...]
```

This script will automatically create the not-existing images in out directory. You can specify the
packer yml files as arguments to build the specific images. Also, you can put `DEBUG=1` env var to
tell the builder to ask in case of any issue happening during the build, but debug mode created
images are not supposed to be uploaded to the artifact storage - just for debugging.

### 4. Run pack of the images

Now you can run script to pack all the generated images into tight tar.xz archives:
```
$ ./pack_image.sh [out/type/image_dir] [...]
```

As with the build you can pack specific images by defining the out directories to pack.

Storing the images in directory allows us to preserve the additional metadata, checksums and build
logs for further investigations.

### 5. Upload the packed images

The last step is to upload the image to artifact storage to use it across the organization:
```
$ ./upload_image.sh <out/type/image.tar.xz> [...]
```

It will output the upload progress and info about the uploaded image when it will be completed.

We're using TAR for it's ability to pack multiple files, preserve the important metadata and
XZ for it's best compacting abilities to reduce the required bandwidth.

## Supported drivers

Aquarium Bait supports a number of drivers and can be relatively easily extended with the ones you
need. When you are navigating to `specs` directory you see the driver directory (like "vmx",
"docker"), it's just for convenience and output images separation (this dir will be used in `out`
to place the images). This way the images for drivers can be built with no conflicts.

### Docker

* TODO: Network isolation - right now there is no way to properly use hostonly network - only NAT.
This is a minor issue because containers don't run any OS services on their own and will not
interact with the internet if it's not described in the specs/playbooks.

It's a good driver to run Linux envs without the VM overhead on Linux hosts - gives enough
flexibility and starts relatively quickly. The images are stored using `docker save` command and
after that in the postprocess the parent layers are removed from the child image (otherwise it
contains them all).

The Aquarium Bait is not using the docker registry to control the images and uses regular files to
store them. That could be seen as bad choice until you need to support a number of different image
receiving transports. With files it's relatively easy to control the access, store the additional
metadata and have cache in the huge organization. But it's still possible to use registry to get
the base images.

#### Using manually

##### 1. Download and unpack

You need to download and unpack all the images in the same directory - as the result you will see
a number of directories which contains the layers from base OS to the target image.

##### 2. Load the images

The docker images can't be used directly from disk and need to be loaded to the docker in order
from base os to the target image:
```
$ docker load -i out/docker/ubuntu2004-VERSION/ubuntu2004.tar
$ docker load -i out/docker/ubuntu2004-python3-VERSION/ubuntu2004-python3.tar
$ docker load -i out/docker/ubuntu2004-python3-ci-VERSION/ubuntu2004-python3-ci.tar
```

And now you will be able to see that the `docker ps` contains those versioned images. All of them
will have `aquarium/` prefix so you quickly can distinguish the loaded images from your own.

##### 3. Run the container

Docker will take care about the images and will not modify them, but will allow you to run the
container like that:
```
$ docker run --rm -it aquarium/ubuntu2004:VERSION
```

Of course you can mount volumes, limit the amount of resources for each container and so on - just
check the docker capabilities.

### VMWare VMX

Aquarium Bait can work with VMware Fusion (on MacOS) and with VMware Workstation (on Linux). Player
is not tested, but in theory could work too with some additional tuning. 30 day trial period is
offered when you run the vmware gui application.

#### Using manually

##### 1. Download and unpack

You need to download and unpack all the images in the same directory - as the result you will see
a number of directories which contains the layers from base OS to the target image.

##### 2. Clone worker VM

Please ensure the image is never running as VM, it will make much simpler to update the images and
leave the images unmodified for quick recreating of the worker VM. All the images contains the
`original` snapshot (which is used for proper cloning) so don't forget to use it.
```
$ vmrun clone images/macos1106-xcode131-ci-220112.204142_cb486d76/macos1106-xcode131-ci.vmx worker/worker.vmx linked -snapshot original
```

##### 3. Change worker `.vmx` file:

When you just manually cloned the new VM to run it on the target system - you need to use the most
of the resources you have - so don't forget this part otherwise you will struggle of the performance
penalty.

During actual run on the target system you can change CPU & MEM values to the required values, but
please leave some for the HOST system.

* CPU (if you have more than one CPU socket - use `CPUS_PER_SOCKET = TOTAL_CPUS / <NUM_SOCKETS>`
to preserve the NUMA config). Tests showed that it's better to leave 2 vCPU for the host system.
   ```
   # CPU
   numvcpus = "<TOTAL_CPU_THREADS>"
   cpuid.coresPerSocket = "<CPUS_PER_SOCKET>"
   ```
* RAM. Leave ~1/3 of the total RAM to the host system for VM disk caching.
   ```
   # Mem
   memsize = "<RAM_IN_MB>"
   ```

##### 4. Run the worker VM

I always recommend to run the VM's headless and access them via CLI/SSH as much as possible. Only
the exceptional reasons where no CLI/SSH can help it's allowed to use GUI to debug the VM. So we
running the VM as nogui - and you always have a way to run the VMWare UI interface for GUI access.

```
$ vmrun start worker/worker.vmx nogui
```

## Advices on testing

### SSH: connecting through proxy

In order to connect to the local VM with VPN connection it's necessary to use the local proxy
started up by the `build_image.sh` script.

1. Run image build in debug mode and wait until the error happened:
   ```
   $ DEBUG=1 ./build_image.sh specs/<PACKER_SPEC_PATH>.yml
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
$ ./scipts/run_ansible.sh -vvv -e ansible_password=packer -i inv.ini playbooks/base_image.yml
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
executes `./scripts/run_ansible.sh` script during preparation of any image.

```
$ . ./.venv/bin/activate
(.venv) $ ansible all -i localhost, -m debug -a "msg={{ tst_var | regex_replace('\r', '') }}" --extra-vars '{"tst_var":"test\r\n\r\n"}'
```
