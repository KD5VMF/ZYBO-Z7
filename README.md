# Zybo Z7-20 Petalinux Build and SD Card Setup

This guide will walk you through building a working Petalinux image and preparing an SD card for the Digilent Zybo Z7-20 board.

---

## 📁 Directory Setup

Create a main folder for your project:

```bash
mkdir -p ~/xilinx_installers/ZYBO_Z7-20_Builds
cd ~/xilinx_installers/ZYBO_Z7-20_Builds
```

---

## 📦 Create the PetaLinux Project

Make sure you've sourced the environment setup script:

```bash
source ~/Xilinx/PetaLinux/2022.1/settings.sh
```

Then run:

```bash
petalinux-create -t project -s ~/xilinx_installers/Zybo-Z7-20-Petalinux-2022-1.bsp -n zybo_digilent
cd zybo_digilent
```

---

## 🛠️ Build the Project

To build everything:

```bash
petalinux-build
```

---

## 🧱 Package BOOT.BIN and image.ub

After a successful build:

```bash
petalinux-package --boot \
  --fsbl images/linux/zynq_fsbl.elf \
  --fpga images/linux/system.bit \
  --u-boot \
  --kernel \
  --force
```

This will generate the `BOOT.BIN` file in `images/linux`.

---

## 💾 Prepare the SD Card

Use the interactive SD card flashing script provided.

### Example:

```bash
cd ~/xilinx_installers/ZYBO_Z7-20_Builds
chmod +x write_sd_card.sh
./write_sd_card.sh
```

It will:

- List removable drives
- Ask you to pick one
- Wipe old partitions
- Create:
  - a 100MB `boot` (FAT32)
  - the rest as `rootfs` (ext4)
- Copy `BOOT.BIN` and `image.ub` from `zybo_digilent/images/linux/`

---

## ✅ Boot Zybo Z7-20

Insert the SD card, set the boot mode to SD on the Zybo Z7-20 board, and power it on. It should boot Linux from the SD card.

---
