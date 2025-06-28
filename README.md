# PetaLinux for Digilent Zybo Z7-20 (2022.1)

This project builds a custom Linux image for the [Digilent Zybo Z7-20](https://digilent.com/reference/programmable-logic/zybo-z7/start) Zynq-7000 development board using **Xilinx PetaLinux 2022.1**.

It includes:
- A complete PetaLinux project pre-configured for the Zybo Z7-20
- Smart SD card flashing script
- Easy boot image generation
- Verified instructions

---

## 🔧 System Requirements

- **Ubuntu 18.04 or 20.04 LTS** (64-bit)
- **PetaLinux 2022.1**
- **Vivado 2022.1** (WebPACK is sufficient)
- At least **50 GB of free disk space**
- Internet access for package and BSP downloads

---

## 📦 Required Downloads

### 1. 🔽 Vivado & PetaLinux 2022.1

Get them from the official Xilinx site (free Xilinx account required):

- **Vivado WebPACK 2022.1:**  
  https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html

- **PetaLinux 2022.1 Installer (petalinux-v2022.1-final-installer.run):**  
  https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2022.1-final-installer.run

---

### 2. 🔽 Digilent Zybo Z7-20 PetaLinux BSP (Board Support Package)

Download from Digilent's GitHub:

- **Zybo Z7-20 PetaLinux 2022.1 BSP**  
  https://github.com/Digilent/Petalinux-Zybo-Z7-20/releases/download/v2022.1/zybo-z7-20.bsp

Save the file as `Zybo-Z7-20-Petalinux-2022-1.bsp` in your working folder.

---

## 📦 Required Dependencies

Install all needed libraries with:

```bash
sudo apt update
sudo apt install -y gawk device-tree-compiler   libncurses5-dev libncursesw5-dev libssl-dev   flex bison zlib1g:i386 libssl-dev   libselinux1 gnupg diffstat chrpath   xterm socat autoconf libtool   libglib2.0-dev libarchive-dev   python3 python3-pip unzip file
```

---

## 🚀 Quick Start

### 1. Set Up Environment

Source the `settings.sh` script from your PetaLinux 2022.1 install:

```bash
source /opt/pkg/petalinux/2022.1/settings.sh
```

(adjust path as needed)

---

### 2. Create PetaLinux Project from BSP

```bash
petalinux-create -t project -s ./Zybo-Z7-20-Petalinux-2022-1.bsp -n zybo_digilent
cd zybo_digilent
```

---

### 3. Build Project

```bash
petalinux-build
```

After it finishes, all boot files will be in `images/linux/`.

---

### 4. Generate BOOT.BIN (includes FSBL, Bitstream, U-Boot, Kernel, boot.scr)

```bash
petalinux-package --boot   --fsbl images/linux/zynq_fsbl.elf   --fpga images/linux/system.bit   --u-boot   --kernel   --force
```

---

## 💾 Flash SD Card

This repo includes a full script to safely flash the BOOT and ROOTFS partitions to a removable SD card.

### ⚠️ WARNING: THIS WILL ERASE ALL DATA ON THE TARGET DRIVE

To run it:

```bash
cd zybo_digilent
chmod +x sd_card_builder_zybo.sh
sudo ./sd_card_builder_zybo.sh
```

### It will:
- Detect `BOOT.BIN` and `image.ub`
- List available removable devices
- Ask user to select a target
- Fully wipe old partitions
- Create:
  - Partition 1: FAT32 (BOOT) → BOOT.BIN + image.ub
  - Partition 2: EXT4 (ROOTFS) → ready for writable Linux storage

---

## 🧪 First Boot

1. Insert SD into Zybo Z7-20
2. Set **boot jumpers** to `SD Boot` (JP5: OFF, ON, OFF)
3. Connect USB serial console (`/dev/ttyUSB0`, 115200 baud)
4. Power on board

You should see the U-Boot log and Linux booting.

---

## 🖧 Notes

- If you see `ERROR: 'serverip' not set` or PXE errors, it's likely U-Boot is trying network boot → fix your `boot.scr` or rebuild `BOOT.BIN` with `--kernel`
- To troubleshoot deeper, use a serial console to capture logs
- If `BOOT.BIN` is too large, it may be due to overlapping addresses — adjust `.bif` if needed

---

## 📁 Project Structure

```
zybo_digilent/
├── project-spec/
├── images/linux/
│   ├── BOOT.BIN
│   ├── image.ub
│   ├── system.dtb
│   └── ...
├── build/
├── sd_card_builder_zybo.sh
└── README.md
```

---

## 🧠 Credits

- Digilent Inc. for the Zybo Z7-20 board and BSP  
- Xilinx for the PetaLinux and Vivado tools  
- Community contributors for SD flashing improvements

---

## 📎 License

MIT License (see LICENSE file)
