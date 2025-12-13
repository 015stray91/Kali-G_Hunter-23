# Kali-G_Hunter-23

This is the repository for the Moto G Stylus 5G 2023 XT-2315 (codename: Genevn/G_Hunter) - NetHunter kernel and module development.

## Overview

This repository contains build scripts, kernel sources, and toolchain setup for building NetHunter modules and custom kernels for the Motorola G Stylus 5G (2023).

## Quick Start

### 1. Source Device Configuration

First, source the device configuration file:

```bash
# Source device config
source ./scripts/config.genevn

# Verify configuration
echo "Building for: $DEVICE_FULL_NAME"
echo "Architecture: $ARCH (64-bit)"
```

### 2. Clone Kernel Source

```bash
# Clone Motorola kernel source
git clone --depth 1 --branch MMI-T1TGNS33.60-41-2-7 \
  https://github.com/MotorolaMobilityLLC/kernel-msm.git kernel
```

### 3. Build Kernel/Modules

```bash
# Setup toolchain (add to PATH)
export PATH="${PWD}/toolchains/motorola/bin:${PATH}"

# Build kernel
cd kernel
make O=$OUT_DIR $DEFCONFIG
make -j$(nproc) O=$OUT_DIR Image.gz dtbs modules
```

## Repository Structure

```
.
├── device-kernel/           # Device-specific kernel binaries
├── scripts/                 # Build and setup scripts
│   ├── config.genevn        # Device configuration for NetHunter builds
│   └── README.md            # Detailed script documentation
├── toolchains/              # Extracted toolchains (gitignored)
└── .github/workflows/       # CI/CD workflows
```

## Device Information

- **Device**: Motorola G Stylus 5G (2023)
- **Model**: XT-2315
- **Codename**: Genevn / G_Hunter
- **Architecture**: ARM64 (aarch64)
- **Kernel Source**: [Motorola kernel-msm](https://github.com/MotorolaMobilityLLC/kernel-msm) (tag: MMI-T1TGNS33.60-41-2-7)

## Building for NetHunter

NetHunter modules require:
1. Device-specific cross-compiler toolchain
2. Kernel headers from the device kernel source
3. Android NDK (for userland components, if needed)

Follow the setup steps above to configure the toolchain, then build the required kernel modules.

## CI/CD

The repository includes GitHub Actions workflows for automated kernel building. See [.github/workflows/build-kernel.yml](.github/workflows/build-kernel.yml).

## Contributing

Contributions are welcome! Please ensure your changes:
- Are tested on the target device
- Follow the existing code structure
- Include appropriate documentation

## Resources

- [NetHunter Documentation](https://www.kali.org/docs/nethunter/)
- [Motorola Kernel Source](https://github.com/MotorolaMobilityLLC/kernel-msm)
- [Android Kernel Building Guide](https://source.android.com/docs/setup/build/building-kernels)

## License

See LICENSE file for details.
