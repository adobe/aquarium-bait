# Xcode role

This role installs Xcode and commandline utils

## Tasks

* Install xcode of any version
* Install simulator defined runtimes

## Additional info

In order to install simulators you need to download them from Apple and store in your artifact
storage.

### Manual method:

1. Go to https://developer.apple.com/download/all/?q=Simulator%20Runtime (need login)
2. Download the required sim runtime DMG files (should fit your `xcodebuild -showsdks` versions)
3. Make sure the filenames are fit the desired pattern: `<platform>_<version>_Simulator_Runtime.dmg`
3. Place them in the `playbooks/files/mac` folder or upload to artifact storage server as usual

### Automatic method:

Unfortunately I found no way for automatic download, but xcodebuild somehow downloads without login
so that should be possible...

Index: https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex
