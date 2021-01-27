# MacOSX Image builder

## How to create from scratch

### 1. Create ISO

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
VPN and will never find your VM host.

Now when all the required things are ready - you can run the image builder:
```
$ ./build_macos.sh "${HOME}/Virtual Machines.localized/macOS_10.15_basic.vmwarevm/macOS_10.15_basic.vmx"
```

This script will automatically create the useful slim base image in out directory
