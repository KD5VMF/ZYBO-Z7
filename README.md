# Zybo Z7-20 PetaLinux 2022.1 Full Setup & SD Card Boot Guide

This guide walks you through creating a bootable SD card for the Digilent **Zybo Z7-20** board using the provided BSP file and generating all necessary files (`BOOT.BIN`, `image.ub`, etc).

---

## 📁 Directory Structure

We assume you have this layout inside your working directory:

```
~/xilinx_installers/
├── Xilinx_Unified_2022.1_0420_0327_Lin64.bin
├── petalinux-v2022.1-04191534-installer.run
├── Zybo-Z7-20-Petalinux-2022-1.bsp
└── ZYBO_Z7-20_Builds/
```

Create the build folder:

```bash
mkdir -p ~/xilinx_installers/ZYBO_Z7-20_Builds
cd ~/xilinx_installers/ZYBO_Z7-20_Builds
```

---

## 🧰 Step 1: Create PetaLinux Project from BSP

```bash
petalinux-create -t project -s ../Zybo-Z7-20-Petalinux-2022-1.bsp -n zybo_digilent
cd zybo_digilent
```

---

## ⚙️ Step 2: Build the Project

```bash
petalinux-build
```

> 💡 This step will take some time. You can monitor usage with `htop`.

---

## 📦 Step 3: Package BOOT.BIN

Once `petalinux-build` completes, generate `BOOT.BIN`:

```bash
petalinux-package --boot \
  --fsbl images/linux/zynq_fsbl.elf \
  --fpga images/linux/system.bit \
  --u-boot \
  --kernel \
  --force
```

This generates `BOOT.BIN` and confirms `image.ub` exists.

---

## 💾 Step 4: Flash SD Card Using Menu Script

Place the following `write_sd_card.sh` in your project root:

```bash
nano write_sd_card.sh
```

Paste the following:

\`\`\`bash
#!/bin/bash
set -e

echo "Available removable drives:"
lsblk -dpno NAME,SIZE,MODEL | grep -E "/dev/sd"

read -p "Enter the path of the SD card (e.g., /dev/sda): " SD_CARD

echo "You selected: $SD_CARD"
read -p "Are you sure you want to WRITE to $SD_CARD? This will ERASE ALL DATA. (y/N): " confirm
[[ $confirm != "y" ]] && echo "Aborted." && exit 1

echo "🔄 Wiping old partitions..."
sudo umount ${SD_CARD}?* || true
sudo dd if=/dev/zero of=$SD_CARD bs=1M count=10
sudo parted -s $SD_CARD mklabel msdos

echo "💽 Creating new partitions..."
sudo parted -s $SD_CARD mkpart primary fat32 4MB 100MB
sudo parted -s $SD_CARD mkpart primary ext4 100MB 100%

sleep 1
sudo mkfs.vfat ${SD_CARD}1 -n BOOT
sudo mkfs.ext4 ${SD_CARD}2 -L ROOTFS

echo "📁 Mounting partitions..."
sudo mkdir -p /mnt/sdboot
sudo mount ${SD_CARD}1 /mnt/sdboot

echo "📦 Copying boot files..."
sudo cp images/linux/BOOT.BIN images/linux/image.ub /mnt/sdboot/
sync

echo "📦 Unmounting and cleaning up..."
sudo umount /mnt/sdboot
sudo rmdir /mnt/sdboot

echo "✅ SD card successfully flashed to $SD_CARD"
\`\`\`

Then run:

```bash
chmod +x write_sd_card.sh
./write_sd_card.sh
```

---

## 🧪 Step 5: Boot the Zybo Z7-20

1. Insert the flashed SD card into the board
2. Set boot mode to SD (MIO[5:0] = `00010`)
3. Power cycle the board
4. You should see PetaLinux boot over serial (115200 baud)

---

## 🧯 Troubleshooting

- `BOOT.BIN` build errors? Delete `BOOT.BIN` and `image.ub` and rebuild using `petalinux-package`
- LED not blinking? Confirm the device tree correctly maps `axi_gpio_led` to the user LEDs.

---

## 📝 Notes

- Your working PetaLinux project folder is:  
  `~/xilinx_installers/ZYBO_Z7-20_Builds/zybo_digilent/`
- All final boot files are inside:  
  `~/xilinx_installers/ZYBO_Z7-20_Builds/zybo_digilent/images/linux/`

---

Happy building! 💻⚡
