#!/usr/bin/env bash

args=(
  -m 4096 -cpu host -M accel=hvf
  -machine q35
  -smp 4,cores=2,sockets=1
  -usb -device usb-kbd -device usb-tablet
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
  -drive if=pflash,format=raw,readonly=on,file="ovmf_efi.fd"
  -drive if=pflash,format=raw,file="ovmf_vars.fd"
  -smbios type=2
  -device ich9-ahci,id=sata

  # Boot helper
  -device ide-hd,bus=sata.0,drive=OpenCoreBoot
    -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="./OpenCore.qcow2"
  # Main VM disk
  -device ide-hd,bus=sata.1,drive=MacHDD
    -drive id=MacHDD,if=none,format=qcow2,file="./MainDisk-1.qcow2"

  # Uncomment next 2 lines to use MacOS DVD as installation media
  -device ide-cd,bus=sata.2,drive=MacDVD
    -drive id=MacDVD,if=none,format=raw,file="./MacOS.iso"
  # Uncomment next 2 lines to use recovery system as installation media
  #-device ide-hd,bus=sata.2,drive=RecoveryMedia
  #  -drive id=RecoveryMedia,if=none,format=raw,file="./BaseSystem.img"

  #-netdev tap,id=net0,script=no,downscript=no -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  #-netdev user,id=net0 -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  -monitor stdio
  -vga virtio
  -display default,show-cursor=on
)

qemu-system-x86_64 "${args[@]}"
