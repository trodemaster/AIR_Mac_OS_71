#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob nocaseglob

# modern bash version check
! [ "${BASH_VERSINFO:-0}" -ge 4 ] && echo "This script requires bash v4 or later" && exit 1

# path to self and parent dir
SCRIPT=$(realpath $0)
SCRIPTPATH=$(dirname $SCRIPT)

# check for qemu-system-m68k
if [ ! -f "/opt/local/bin/qemu-system-m68k" ]; then
  echo "qemu-system-m68k not found"
  exit 1
fi

# check for Quadra_800.rom
if [ ! -f "$SCRIPTPATH/Quadra_800.rom" ]; then
  echo "Quadra_800.rom not found"
  exit 1
fi

# create pram-q800.img if it doesn't exist
if [ ! -f "$SCRIPTPATH/pram_q800_712.img" ]; then
  echo "Creating pram_q800_712.img"
  /opt/local/bin/qemu-img create -f raw pram_q800_712.img 256b
fi

# check for quadra800_712.qcow2
if [ ! -f "$SCRIPTPATH/quadra800_712.qcow2" ]; then
  echo "quadra800_712.qcow2 not found"
  /opt/local/bin/qemu-img create -f qcow2 quadra800_712.qcow2 2G
fi

# install boot
sudo /opt/local/bin/qemu-system-m68k \
  -M q800 \
  -m 64 \
  -bios "$SCRIPTPATH/Quadra_800.rom" \
  -device nubus-virtio-mmio,romfile="$SCRIPTPATH/roms/declrom.older" \
  -device virtio-tablet-device \
  -drive file=pram_q800_712.img,format=raw,if=mtd \
  -device scsi-hd,scsi-id=0,drive=hd0 \
  -drive "file=$SCRIPTPATH/quadra800_712.qcow2,media=disk,format=qcow2,if=none,id=hd0" \
  -nic vmnet-bridged,model=dp83932,mac=08:00:07:12:34:56,ifname=en0 \
  -audio none \
  -g 1152x870x8

exit 0