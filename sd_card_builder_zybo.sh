#!/bin/bash
# smart_sd_card_builder.sh — numbered selection, full wipe, 200 MiB BOOT, rest ROOTFS

set -euo pipefail

# 1) Find BOOT.BIN & image.ub
BOOT_BIN=$(find . -path "*/images/linux/BOOT.BIN" | head -n1)
IMAGE_UB=$(find . -path "*/images/linux/image.ub"   | head -n1)

if [[ -z $BOOT_BIN || -z $IMAGE_UB ]]; then
  echo "ERROR: BOOT.BIN or image.ub not found under ./images/linux/"
  exit 1
fi

echo "Found:"
echo "  BOOT = $BOOT_BIN"
echo "  KIMG = $IMAGE_UB"
echo

# 2) List removable drives
mapfile -t DEVS < <(lsblk -dpno NAME,RM,SIZE,MODEL | awk '$2==1{print $1}')
if (( ${#DEVS[@]} == 0 )); then
  echo "No removable block devices found."
  exit 1
fi

echo "Select SD card to flash:"
for i in "${!DEVS[@]}"; do
  echo "  [$i] ${DEVS[$i]}"
done
echo
read -rp "Enter number: " IDX
if ! [[ $IDX =~ ^[0-9]+$ ]] || (( IDX<0 || IDX>=${#DEVS[@]} )); then
  echo "Invalid selection."; exit 1
fi
DEV=${DEVS[$IDX]}
echo "→ You chose $DEV"; echo

# 3) Confirm
read -rp "This will ERASE ALL DATA on $DEV. Type YES to confirm: " CONF
[[ $CONF == "YES" ]] || { echo "Aborted."; exit 1; }

# 4) Unmount & wipe
echo "Unmounting partitions..."
umount "${DEV}"* 2>/dev/null || true
echo "Wiping partitions..."
wipefs -a "$DEV"
sgdisk --zap-all "$DEV" >/dev/null 2>&1

# 5) Partition: 200 MiB FAT32 + rest ext4
echo "Creating partition table..."
parted -s "$DEV" mklabel msdos
echo "Creating BOOT partition (200 MiB)..."
parted -s "$DEV" mkpart primary fat32 1MiB 201MiB
echo "Creating ROOTFS partition..."
parted -s "$DEV" mkpart primary ext4 201MiB 100%

sleep 2
if [[ $DEV == *mmcblk* ]]; then
  BOOT_P="${DEV}p1"; ROOT_P="${DEV}p2"
else
  BOOT_P="${DEV}1";  ROOT_P="${DEV}2"
fi

# 6) Format & label
echo "Formatting BOOT ($BOOT_P) as FAT32..."
mkfs.vfat -F32 -n BOOT "$BOOT_P"
echo "Formatting ROOTFS ($ROOT_P) as ext4..."
mkfs.ext4 -F -L ROOTFS "$ROOT_P"

# 7) Mount points
M1=$(mktemp -d)
M2=$(mktemp -d)
mount "$BOOT_P" "$M1"
mount "$ROOT_P" "$M2"

# 8) Verify BOOT space
avail=$(df --output=avail -k "$M1" | tail -1)
needed=$(( $(stat -c%s "$BOOT_BIN") + $(stat -c%s "$IMAGE_UB") + 4*1024*1024 ))
if (( avail*1024 < needed )); then
  echo "ERROR: Not enough space on BOOT partition ($((avail/1024)) MiB available)." 
  umount "$M1" "$M2"; rm -rf "$M1" "$M2"
  exit 1
fi

# 9) Copy files
echo "Copying BOOT files..."
cp "$BOOT_BIN" "$M1/"
cp "$IMAGE_UB" "$M1/"
[[ -f boot.scr ]] && cp boot.scr "$M1/"
[[ -f system.dtb ]] && cp system.dtb "$M1/"

# 10) Optional: extract rootfs
if [[ -f rootfs.tar.gz ]]; then
  echo "Extracting rootfs.tar.gz to ROOTFS..."
  tar -xzf rootfs.tar.gz -C "$M2"
fi

# 11) Cleanup
sync
umount "$M1" "$M2"
rm -rf "$M1" "$M2"

echo
echo "✅ SD card $DEV is ready for Zybo Z7-20!"
