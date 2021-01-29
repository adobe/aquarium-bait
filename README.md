# CI Image packer

System to ensue the CI build environment will be consistent from build to build. The images can be
used with versioning to easily reproduce the same results of the past build.

## Requirements

* Python 3 + venv
* [Packer v1.6.6](https://www.packer.io/downloads)
* For MacOS image:
  * Can only be running on MacOS (license restrictions)
  * VMWare fusion 12.1.0

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

### 2. Install MacOS to VM

1. Install VMWare fusion
2. Setup Host-VM network:
   * Run it and go to `Preferences...` - `Network` and setup new Custom network `vmnet2`
   * We will use it to disable the Internet access during the installation and have just Host-VM network
3. Create VM with the iso file installation and set net adapter to the created `vmnet2` network
4. During installation just try to setup as minimum as possible, user: `admin`, password: `admin`
5. Right after install is completed - enable the remote access and shutdown the VM

### 3. Run packer over the created VM

**WARNING:** make sure you don't have VPN enabled, otherwise it will lead to redirect your traffic through
VPN and will never find your VM host. VM only have connection to host, not to the local net / internet.

Now when all the required things are ready - you can run the image builder:
```
$ ./build_macos.sh "${HOME}/Build/macos-vmware/Catalina.iso"
```

This script will automatically create the useful slim base image in out directory
