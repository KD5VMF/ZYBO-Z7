#!/bin/bash
# smart_sd_card_autobuilder.sh — Full SD setup for Zybo Z7-20
# Creates BOOT (200MiB FAT32) + ROOTFS (ext4, full Linux root), wipes old partitions

set -euo pipefail

# Step 1: Locate necessary files
BOOT_BIN=$(find . -name BOOT.BIN | head -n1)
IMAGE_UB=$(find . -name image.ub | head -n1)
ROOTFS_TAR=$(find . -name rootfs.tar.gz | head -n1 || true)

if [[ ! -f "$BOOT_BIN" || ! -f "$IMAGE_UB" ]]; then
  echo "ERROR: BOOT.BIN and/or image.ub not found."
  exit 1
fi

echo "Found:"
echo "  BOOT.BIN: $BOOT_BIN"
echo "  image.ub: $IMAGE_UB"
[[ -f "$ROOTFS_TAR" ]] && echo "  rootfs.tar.gz: $ROOTFS_TAR"
echo

# Step 2: Detect removable devices
mapfile -t DEVS < <(lsblk -dpno NAME,RM,SIZE,MODEL | awk '$2==1{print $1}')
if (( ${#DEVS[@]} == 0 )); then
  echo "No removable devices found."
  exit 1
fi

echo "Select SD card device:"
for i in "${!DEVS[@]}"; do
  echo "  [$i] ${DEVS[$i]}"
done
read -rp "Enter number: " IDX
[[ $IDX =~ ^[0-9]+$ && $IDX -ge 0 && $IDX -lt ${#DEVS[@]} ]] || { echo "Invalid selection."; exit 1; }
DEV=${DEVS[$IDX]}
echo "Using device: $DEV"

read -rp "⚠️ This will erase ALL data on $DEV. Type YES to confirm: " CONF
[[ "$CONF" == "YES" ]] || { echo "Aborted."; exit 1; }

# Step 3: Unmount & Wipe
umount "${DEV}"* 2>/dev/null || true
wipefs -a "$DEV"
sgdisk --zap-all "$DEV" || true

# Step 4: Create new partitions
parted -s "$DEV" mklabel msdos
parted -s "$DEV" mkpart primary fat32 1MiB 201MiB
parted -s "$DEV" mkpart primary ext4 201MiB 100%

sleep 2
if [[ "$DEV" == *mmcblk* ]]; then
  BOOT_P="${DEV}p1"
  ROOT_P="${DEV}p2"
else
  BOOT_P="${DEV}1"
  ROOT_P="${DEV}2"
fi

# Step 5: Format
mkfs.vfat -F32 -n BOOT "$BOOT_P"
mkfs.ext4 -F -L ROOTFS "$ROOT_P"

# Step 6: Mount
BOOT_MNT=$(mktemp -d)
ROOT_MNT=$(mktemp -d)
mount "$BOOT_P" "$BOOT_MNT"
mount "$ROOT_P" "$ROOT_MNT"

# Step 7: Copy files
cp "$BOOT_BIN" "$BOOT_MNT/"
cp "$IMAGE_UB" "$BOOT_MNT/"
[[ -f boot.scr ]] && cp boot.scr "$BOOT_MNT/"
[[ -f system.dtb ]] && cp system.dtb "$BOOT_MNT/"
sync

if [[ -f "$ROOTFS_TAR" ]]; then
  echo "Extracting rootfs to ROOTFS partition..."
  tar -xzf "$ROOTFS_TAR" -C "$ROOT_MNT"
  sync
fi

# Step 8: Finalize
umount "$BOOT_MNT" "$ROOT_MNT"
rm -rf "$BOOT_MNT" "$ROOT_MNT"
sync

echo "✅ SD card ready. ROOTFS is now bootable partition."
