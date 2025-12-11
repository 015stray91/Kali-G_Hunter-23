# Device Metadata

## Device Information
- **Brand**: Motorola
- **Model**: Moto G Stylus 5G (2020) / XT2315
- **Codename**: genevn / G_Hunter
- **SoC**: Qualcomm SM6450 (Snapdragon 6 Gen 1)
- **Architecture**: ARM64

## ROM Information
- **Base ROM**: LineageOS / AOSP-based
- **Android Version**: 13 (T)
- **Build Fingerprint**: motorola/genevn/genevn:13/T1TGNS33.60-41-2-7/41a76:user/release-keys
- **Security Patch**: 2024-01-01

## Kernel Information
- **Kernel Version**: 5.10.233
- **Kernel Source**: 
  - Upstream: https://github.com/sosRR/platform_kernel_motorola_genevn.git
  - Motorola Official: https://github.com/MotorolaMobilityLLC/kernel-msm.git (tag: MMI-T1TGNS33.60-41-2-7)
- **Kernel Tarball**: https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz
- **Default Config**: gki_defconfig, vendor/genevn_defconfig

## Toolchain Information
- **Clang Version**: 12.0.5
- **LLD Version**: 12.0.5
- **Cross Compiler**: aarch64-linux-gnu-gcc
- **Build System**: AOSP/Kernel Build System
- **Toolchain Setup**: PizzaG Build-Env-Setup-Scripts
  - Repository: https://github.com/PizzaG/Build-Env-Setup-Scripts.git

## Device Trees & Vendor
- **Device Tree**: https://github.com/PizzaG/android_device_motorola_yume.git
- **Vendor Tree**: https://github.com/PizzaG/android_vendor_motorola_yume.git
- **Common Device**: yume (shared configuration)

## Build Configuration
- **Target Product**: lineage_genevn
- **Build Type**: userdebug
- **Target Arch**: arm64
- **Target CPU Variant**: cortex-a76
- **Build Date**: 2024-12-11
- **Build Timestamp**: 1733940000

## Boot Image Configuration
- **Kernel Command Line**:
  ```
  console=ttyMSM0,115200n8
  androidboot.hardware=qcom
  androidboot.console=ttyMSM0
  androidboot.memcg=1
  lpm_levels.sleep_disabled=1
  msm_rtb.filter=0x237
  service_locator.enable=1
  androidboot.usbcontroller=a600000.dwc3
  swiotlb=2048
  loop.max_part=7
  cgroup.memory=nokmem,nosocket
  firmware_class.path=/vendor/firmware_mnt/image
  pcie_ports=compat
  loop.max_loop=7
  iptable_raw.raw_before_defrag=1
  ip6table_raw.raw_before_defrag=1
  ```
- **Base Address**: 0x00000000
- **Kernel Offset**: 0x00008000
- **Ramdisk Offset**: 0x01000000
- **Tags Offset**: 0x00000100
- **Page Size**: 4096
- **Header Version**: 2

## Partition Layout
- **System**: ext4, 3.5GB
- **Vendor**: ext4, 1GB
- **Boot**: raw, 64MB
- **Recovery**: raw, 64MB
- **Userdata**: f2fs/ext4, variable
- **Metadata**: raw, 16MB

## Hardware Specifications
- **Display**: 6.8" FHD+ (1080x2460)
- **RAM**: 6GB / 8GB LPDDR4X
- **Storage**: 128GB / 256GB UFS 2.2
- **Camera**: 50MP main + 8MP ultrawide + 2MP macro
- **Battery**: 5000mAh
- **Connectivity**: 5G, WiFi 6, Bluetooth 5.1, NFC

## Notes
- Device uses Qualcomm Snapdragon 6 Gen 1 (SM6450) chipset
- Kernel is based on Android 13 (T) with Linux 5.10.233
- Build environment provisioned using PizzaG's Build-Env-Setup-Scripts
- Clang/LLVM 12.0.5 required for compilation
- Uses LLD linker for faster linking
- GKI (Generic Kernel Image) compliant for Android 13+
