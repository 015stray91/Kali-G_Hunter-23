# Device Configuration Collection Workflow

This document describes the CI workflow for collecting device, kernel, vendor, and NetHunter-related configuration files.

## Overview

The `collect-device-configs.yml` workflow implements an end-to-end CI flow that:

1. **Attempts NetHunter provisioning first**: Tries to clone and provision NetHunter installer scripts from GitLab
2. **Falls back to PizzaG toolchain**: If NetHunter provisioning fails, provisions the Android/LLVM toolchain using PizzaG's Build-Env-Setup-Scripts
3. **Collects device configurations**: Clones and organizes device, kernel, vendor, and NetHunter-related files
4. **Prepares build environment**: Initializes environment variables and toolchain for subsequent kernel build steps
5. **Uploads artifact**: Creates a `device-configs` artifact containing all collected files

## Workflow Trigger

The workflow is triggered manually via `workflow_dispatch` from the GitHub Actions UI.

## Repositories Used

### PizzaG Repositories
- **Build-Env**: https://github.com/PizzaG/Build-Env-Setup-Scripts.git
- **Vendor**: https://github.com/PizzaG/android_vendor_motorola_yume.git
- **Device**: https://github.com/PizzaG/android_device_motorola_yume.git

### Kernel Repository
- **sosRR Kernel**: https://github.com/sosRR/platform_kernel_motorola_genevn.git

### NetHunter Repositories (GitLab)
- https://gitlab.com/kalilinux/nethunter/nh-resources.git
- https://gitlab.com/kalilinux/nethunter/nh-scripts.git
- https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-installer.git
- https://gitlab.com/akabulous/So_You_Want_To_Build_A_Nethunter_Kernel.git
- https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-pro.git

### Kernel Sources
- **Mainline Kernel**: https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz

## Workflow Steps

### 1. NetHunter Provisioning
The workflow first attempts to clone and set up NetHunter installer scripts. If successful, it sets `nethunter_status=success`. If any required components fail to clone, the step fails and triggers the fallback.

### 2. PizzaG Build-Env Fallback
If NetHunter provisioning fails, the workflow falls back to cloning PizzaG's Build-Env-Setup-Scripts. This ensures the toolchain is available even if NetHunter setup is incomplete.

### 3. Device Configuration Collection
The `scripts/collect-device-configs.sh` script is invoked to:
- Clone all specified repositories
- Organize files into structured directories:
  - `vendor/`: Vendor-specific files
  - `device/`: Device-specific files
  - `kernel/`: Kernel sources and configurations
  - `nethunter/`: NetHunter-related scripts
  - `build-env/`: Build environment setup scripts
  - `kernel-sources/`: Kernel tarball and references
- Generate collection summary

### 4. Build Environment Preparation
The workflow sets up environment variables for kernel builds:
- `ARCH=arm64`
- `CROSS_COMPILE=aarch64-linux-gnu-`
- `LLVM=1`

These variables are exported to `$GITHUB_ENV` for use in subsequent job steps.

### 5. Artifact Upload
The complete `device-configs/` directory is uploaded as a GitHub Actions artifact with:
- **Name**: `device-configs`
- **Retention**: 30 days
- **Contents**: All collected configuration files, summaries, and manifests

## Artifact Structure

\`\`\`
device-configs/
├── vendor/
│   └── android_vendor_motorola_yume/
├── device/
│   └── android_device_motorola_yume/
├── kernel/
│   └── platform_kernel_motorola_genevn/
├── nethunter/
│   ├── nh-resources/
│   ├── nh-scripts/
│   ├── kali-nethunter-installer/
│   ├── So_You_Want_To_Build_A_Nethunter_Kernel/
│   └── kali-nethunter-pro/
├── build-env/
│   └── Build-Env-Setup-Scripts/
├── kernel-sources/
│   ├── linux-5.10.233.tar.xz
│   └── README.txt
├── collection-summary.txt
├── build-env-setup.txt
└── MANIFEST.txt
\`\`\`

## Using the Artifact

To use the collected configurations in a subsequent kernel build job:

1. Download the `device-configs` artifact in your build job
2. Extract the artifact to your workspace
3. Reference device-specific files from the structured directories
4. Use the environment variables already set in `$GITHUB_ENV`

Example:
\`\`\`yaml
- name: Download device configs
  uses: actions/download-artifact@v4
  with:
    name: device-configs
    path: device-configs/

- name: Build kernel
  run: |
    # Environment variables are already set
    cd device-configs/kernel/platform_kernel_motorola_genevn
    make -j$(nproc) Image.gz dtbs modules
\`\`\`

## Script Usage

The `collect-device-configs.sh` script can also be run manually:

\`\`\`bash
./scripts/collect-device-configs.sh --repos "repo1 repo2 repo3..."
\`\`\`

Example:
\`\`\`bash
./scripts/collect-device-configs.sh --repos "https://github.com/user/repo1.git https://github.com/user/repo2.git"
\`\`\`

## Build Environment Details

The workflow installs the following build dependencies:
- build-essential, bc, flex, bison
- libssl-dev, libncurses-dev, zlib1g-dev
- git, curl, wget, jq
- python3, python3-pip
- gcc-aarch64-linux-gnu, binutils-aarch64-linux-gnu
- lld, llvm
- tree, rsync

## Timeout

The workflow has a timeout of 120 minutes to accommodate large repository clones and downloads.

## Notes

- All repositories are cloned with `--depth 1` for faster downloads
- `.git` directories are removed after cloning to save artifact space
- The workflow continues on error for NetHunter provisioning, ensuring fallback works
- Collection summary and manifest files are automatically generated for reference
