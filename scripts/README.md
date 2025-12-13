# Build Scripts for Motorola G Stylus 5G (2023)

This directory contains helper scripts for setting up the build environment and building NetHunter/Kernel modules for the Motorola G Stylus 5G (2023).

## Scripts

### config.genevn

NetHunter kernel builder device configuration file in TOML format for the Motorola G Stylus 5G (2023).

#### Format

This is a TOML configuration file that defines:
- **Chipset**: SM6450 (Snapdragon 6 Gen 1)
- **Boot image parameters**: Load addresses and block device sector size
- **Device parameters**: Vendor, model, and device-specific settings

#### Configuration Structure

```toml
# Chipset for device-tree file naming
chipset = "sm6450"

# Boot image parameters
[bootimg]
base = 0x0
kernel = 0x8000
ramdisk = 0x1000000
second = 0x0
tags = 0x100
pagesize = 4096

# Device entry
[[device]]
vendor = "motorola"
model = "genevn"
```

#### Usage

This configuration file is used by NetHunter kernel builder tools to:
1. Identify the correct device-tree file
2. Construct the boot image with proper load addresses
3. Build kernel for the specific device

#### Device Information

- **Device**: Motorola G Stylus 5G (2023)
- **Model**: XT-2315
- **Codename**: genevn / G_Hunter
- **Chipset**: Qualcomm SM6450 (Snapdragon 6 Gen 1)
- **Architecture**: ARM64 (64-bit)
- **Kernel Source**: MMI-T1TGNS33.60-41-2-7 branch

#### Boot Image Parameters

The boot image parameters can be extracted from an existing boot image using `abootimg -i <image>` or similar tools. These values are specific to the Motorola G Stylus 5G (2023) device.

## Motorola G Stylus 5G (2023) Toolchain

For the Motorola G Stylus 5G (2023) device (codename: genevn/G_Hunter), you need the appropriate ARM64 cross-compiler toolchain.

### Recommended Toolchains

1. **Google's Android Prebuilt Toolchain** (Recommended)
   - URL: Available from Android AOSP repositories
   - Suitable for building Android device kernels
   - Architecture: aarch64-linux-android

2. **ARM GNU Toolchain**
   - Alternative if the Android toolchain is not available
   - Download from ARM Developer or use system packages

3. **Linaro Toolchain**
   - Another alternative for ARM64 cross-compilation

### Setting up the Toolchain for Building

After running `config.genevn`, configure your environment:

```bash
# Add toolchain to PATH
export PATH="${PWD}/toolchains/motorola/bin:${PATH}"

# Set cross-compiler prefix (adjust based on your toolchain)
export CROSS_COMPILE=aarch64-linux-android-
# or
export CROSS_COMPILE=aarch64-linux-gnu-

# Set architecture
export ARCH=arm64
```

## Building Kernel Modules

Once the toolchain is set up, you can build kernel modules:

```bash
# Configure the build
cd upstream-kernel
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export PATH="${PWD}/../toolchains/motorola/bin:${PATH}"

# Build kernel image and modules
make -j$(nproc) O=out Image.gz dtbs modules
```

## CI/CD Integration

The `config.genevn` script can be integrated into CI workflows:

```yaml
- name: Setup Motorola Toolchain
  run: |
    ./scripts/config.genevn \
      --url "${{ secrets.TOOLCHAIN_URL }}" \
      --checksum "${{ secrets.TOOLCHAIN_CHECKSUM }}"
  
- name: Build with Toolchain
  run: |
    export PATH="${PWD}/toolchains/motorola/bin:${PATH}"
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-android-
    # Build commands here
```

## NetHunter Module Building

NetHunter modules must be built against:
1. The correct cross-compiler/toolchain (setup by this script)
2. Kernel headers from the device kernel source
3. Android NDK for userland components (if needed)

### Prerequisites

```bash
# Install build dependencies
sudo apt-get install -y \
  build-essential bc flex bison libssl-dev libncurses-dev \
  libelf-dev git curl wget
```

### Building NetHunter Modules

```bash
# 1. Setup toolchain
./scripts/config.genevn --url <TOOLCHAIN_URL>

# 2. Configure environment
export PATH="${PWD}/toolchains/motorola/bin:${PATH}"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-

# 3. Build kernel modules for NetHunter
cd upstream-kernel
make -j$(nproc) O=out modules
make -j$(nproc) O=out INSTALL_MOD_PATH=../nethunter-modules modules_install
```

## Troubleshooting

### Toolchain Not Found After Setup

Make sure to add the toolchain bin directory to your PATH:

```bash
export PATH="${PWD}/toolchains/motorola/bin:${PATH}"
```

### Compiler Version Mismatch

Different kernel versions may require specific compiler versions. Ensure you're using a compatible toolchain for your kernel source.

### Permission Errors

If you get permission errors during extraction:

```bash
chmod +x scripts/config.genevn
```

### Download Failures

If downloading fails:
1. Check your internet connection
2. Verify the URL is correct and accessible
3. Try downloading manually and use `--local-archive`

## Additional Resources

- [Motorola Kernel Source](https://github.com/MotorolaMobilityLLC/kernel-msm)
- [NetHunter Documentation](https://www.kali.org/docs/nethunter/)
- [Android Kernel Building Guide](https://source.android.com/docs/setup/build/building-kernels)

## License

See the repository LICENSE file for details.
