# VM Tools role

This role installs VM tools to control VM properly

## Links

* Windows tools download without registration: https://packages.vmware.com/tools/releases/11.3.5/windows/x64/
* MacOS guest tools - better to get from the vmware fusion package:
  * Download and install vmware fusion package
  * Mount `/Applications/VMware Fusion.app/Contents/Library/isoimages/darwin.iso`
  * Unpack tool package to get version: `pkgutil --expand '/Volumes/VMware Tools 1/Install VMware Tools.app/Contents/Resources/VMware Tools.pkg' /tmp/pkg`
  * Check /tmp/pkg/Distribution file and find the version there
  * Place the file similarly to the found versions: `playbooks/files/mac/VMware-tools-11.3.5-18557794.pkg`
* VMWare Guest Tools - but requires vmware registration: https://vmware.com/go/tools

## Tasks

* Install VMWare tools
