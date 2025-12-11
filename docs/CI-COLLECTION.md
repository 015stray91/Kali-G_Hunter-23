# Device Configuration Collection CI

This directory contains scripts and workflows for collecting device configurations, vendor files, kernel sources, and NetHunter resources for the Motorola G Stylus 5G 2020 (XT-2315, codename: genevn/yume).

## Overview

The CI workflow implements an end-to-end flow that:

1. **Attempts NetHunter Installer Provisioning**: First tries to clone and run NetHunter installer scripts from GitLab
2. **Falls Back to PizzaG Build-Env**: If NetHunter provisioning fails, falls back to PizzaG's Build-Env-Setup-Scripts
3. **Collects Device Configurations**: Gathers all device, kernel, vendor, and NetHunter-related files
4. **Prepares Build Environment**: Initializes the build environment for subsequent kernel build steps
5. **Uploads Artifact**: Packages everything into a `device-configs` artifact for inspection

## Files

### Scripts

- **`scripts/collect-device-configs.sh`**: Main collection script that clones repositories and extracts configuration files

### Workflows

- **`.github/workflows/collect-device-configs.yml`**: CI workflow that orchestrates the entire collection and provisioning process
- **`.github/workflows/build-kernel.yml`**: Existing kernel build workflow (unchanged)

## Usage

### Running the Collection Script Locally

```bash
./scripts/collect-device-configs.sh \
  --repos "https://github.com/PizzaG/android_vendor_motorola_yume.git https://github.com/PizzaG/android_device_motorola_yume.git" \
  --kernel-tarball "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz" \
  --output device-configs \
  --verbose
```

### Triggering the CI Workflow

The workflow runs automatically on:
- Push to `ci/collect-device-configs` branch
- Manual trigger via GitHub Actions UI (`workflow_dispatch`)

## Sources

The workflow fetches and collects from:

### GitHub Repositories
- PizzaG Build-Env: `https://github.com/PizzaG/Build-Env-Setup-Scripts.git`
- Vendor files: `https://github.com/PizzaG/android_vendor_motorola_yume.git`
- Device files: `https://github.com/PizzaG/android_device_motorola_yume.git`
- Kernel source: `https://github.com/sosRR/platform_kernel_motorola_genevn.git`

### GitLab Repositories (NetHunter)
- `https://gitlab.com/kalilinux/nethunter/nh-resources.git`
- `https://gitlab.com/kalilinux/nethunter/nh-scripts.git`
- `https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-installer.git`
- `https://gitlab.com/akabulous/So_You_Want_To_Build_A_Nethunter_Kernel.git`
- `https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-pro.git`

### Kernel Tarball
- Linux 5.10.233: `https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz`

## Output Structure

The `device-configs` artifact contains:

```
device-configs/
├── MANIFEST.txt                           # Collection manifest with metadata
├── ENVIRONMENT.txt                        # Build environment summary
├── BUILD_ENV.sh                           # Environment variables for builds
├── android_vendor_motorola_yume/          # Vendor configuration files
├── android_device_motorola_yume/          # Device configuration files
├── platform_kernel_motorola_genevn/       # Kernel configuration files
├── nh-resources/                          # NetHunter resources
├── nh-scripts/                            # NetHunter scripts
├── kali-nethunter-installer/              # NetHunter installer
├── kernel-configs/                        # Extracted kernel configs from tarball
├── vendor-files/                          # Complete vendor repository
├── device-files/                          # Complete device repository
├── kernel-source/                         # Kernel defconfigs and Makefiles
└── nethunter-files/                       # NetHunter installation files
```

## Build Environment Initialization

After the workflow completes, the build environment is ready for kernel builds. The `BUILD_ENV.sh` script sets:

- `ARCH=arm64`
- `CROSS_COMPILE=aarch64-linux-gnu-`
- `LLVM=1`
- Device-specific variables (DEVICE=yume, VENDOR=motorola, PLATFORM=genevn)

To use in subsequent steps:
```bash
source device-configs/BUILD_ENV.sh
```

## Flow Diagram

```
Start
  ↓
Install Base Dependencies
  ↓
Try NetHunter Installer Provisioning
  ↓
Success? ─→ Continue
  ↓ No
Fallback to PizzaG Build-Env-Setup
  ↓
Clone Device/Vendor/Kernel Repos
  ↓
Download Kernel Tarball
  ↓
Run Collection Script
  ↓
Copy Additional Device Files
  ↓
Create Environment Summary
  ↓
Initialize Build Environment
  ↓
Upload device-configs Artifact
  ↓
Complete
```

## Integration with Kernel Build

The collected configurations can be used in subsequent kernel build jobs:

1. Download the `device-configs` artifact
2. Source the build environment: `source device-configs/BUILD_ENV.sh`
3. Use device configurations for kernel compilation
4. Apply NetHunter patches if needed

## Notes

- The workflow uses `continue-on-error: true` for NetHunter provisioning to ensure the fallback mechanism works
- All cloning operations use `--depth 1` for faster execution
- The workflow timeout is set to 120 minutes to accommodate large repository clones
- Artifacts are retained for 30 days
