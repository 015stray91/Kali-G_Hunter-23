# Device Config Collection

This directory contains scripts for collecting device, kernel, and vendor configuration files from upstream repositories.

## Scripts

### collect-device-configs.sh

This script automates the collection of device-specific configuration files needed for building the Moto G Stylus kernel.

**Purpose:**
- Clone device/kernel/vendor repositories
- Download and extract the kernel tarball
- Collect device tree sources, defconfigs, vendor blobs, and other config files
- Generate a manifest with repository information and commit SHAs

**Usage:**
```bash
./scripts/collect-device-configs.sh
```

**Output:**
The script creates a `device-configs/` directory containing:
- `manifest.txt` - Repository information and commit SHAs
- `COLLECTION_SUMMARY.txt` - Summary of collected files
- `device-tree/` - Device tree source files (.dts, .dtsi)
- `defconfigs/` - Kernel defconfig files
- `vendor/` - Vendor blobs and makefiles
- `device/` - Device configuration files (SELinux policies, init scripts, etc.)
- `kernel-defconfigs/` - Kernel defconfigs from the kernel source
- `kernel-kconfig/` - Kernel Kconfig files
- `docs/` - Documentation and README files

**Environment Variables:**
- `GITHUB_WORKSPACE` - Workspace directory (defaults to current directory)

## CI Workflow

The `.github/workflows/collect-device-configs.yml` workflow automates the device config collection process:

**Triggers:**
- Manual workflow dispatch
- Push to `main` or `ci/**` branches (when script or workflow changes)

**Outputs:**
- `device-configs` artifact - All collected configuration files
- `kernel-tarball` artifact - Downloaded kernel tarball

**Retention:**
Artifacts are retained for 30 days.

## Repositories

The script collects files from the following repositories:

1. **Build-Env-Setup-Scripts**
   - URL: https://github.com/PizzaG/Build-Env-Setup-Scripts.git
   - Purpose: Build environment setup scripts

2. **android_vendor_motorola_yume**
   - URL: https://github.com/PizzaG/android_vendor_motorola_yume.git
   - Purpose: Vendor blobs and makefiles for Motorola Yume (Moto G Stylus)

3. **android_device_motorola_yume**
   - URL: https://github.com/PizzaG/android_device_motorola_yume.git
   - Purpose: Device configuration for Motorola Yume

4. **platform_kernel_motorola_genevn**
   - URL: https://github.com/sosRR/platform_kernel_motorola_genevn.git
   - Purpose: Kernel sources for Motorola Genevn

5. **Linux Kernel Tarball**
   - URL: https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz
   - Purpose: Base kernel source (version 5.10.233)

## Device Information

- **Device:** Moto G Stylus 5G 2020 (XT-2315)
- **Code Names:** genevn / G_Hunter / yume
- **Architecture:** ARM64
