#!/bin/bash

# Zybo Z7-20 SD Card Builder Script
# Safely format and copy BOOT.BIN and image.ub to SD card

set -e

BOOT_BIN="images/linux/BOOT.BIN"
IMAGE_UB="images/linux/image.ub"

echo "=== Zybo Z7-20 SD Card Builder ==="

# Check required files
if [[ ! -f "$BOOT_BIN" || ! -f "$IMAGE_UB" ]]; then
    echo "ERROR: $BOOT_BIN or $IMAGE_UB not found!"
    exit 1
fi

# Show block devices
echo
echo "Available storage devices:"
lsblk -dpno NAME,SIZE,MODEL | grep -v "loop"

# Ask user for target device
echo
read -rp "Enter the device path to your SD card (e.g., /dev/sdX): " DEV

if [[ ! -b "$DEV" ]]; then
    echo "ERROR: $DEV is not a valid block device."
    exit 1
fi

echo
read -rp "Are you sure you want to erase and reformat $DEV? This will destroy all data on it. (yes/NO): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo
echo "Unmounting any mounted partitions..."
for part in $(ls ${DEV}?* 2>/dev/null); do
    umount "$part" 2>/dev/null || true
done

echo "Wiping partition table..."
wipefs -a "$DEV"
sgdisk --zap-all "$DEV"

echo "Creating new partition..."
echo -e "o\nn\np\n1\n\n\nw" | fdisk "$DEV"

sleep 1
mkfs.vfat -F 32 "${DEV}1" -n BOOT

echo "Mounting and copying files..."
MOUNTDIR=$(mktemp -d)
mount "${DEV}1" "$MOUNTDIR"

cp "$BOOT_BIN" "$MOUNTDIR"
cp "$IMAGE_UB" "$MOUNTDIR"

sync
umount "$MOUNTDIR"
rm -rf "$MOUNTDIR"

echo
echo "✅ SD card prepared successfully with:"
echo "  - $BOOT_BIN"
echo "  - $IMAGE_UB"
