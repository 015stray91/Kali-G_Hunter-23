# Build Scripts for Motorola G Stylus 5G (2023)

This directory contains helper scripts for setting up the build environment and building NetHunter/Kernel modules for the Motorola G Stylus 5G (2023).

## Scripts

### setup-toolchain.sh

Downloads, verifies, and extracts the Motorola device toolchain required for building kernel modules.

#### Usage

```bash
# Download from URL
./scripts/setup-toolchain.sh --url https://example.com/toolchain.tar.gz

# Use local archive
./scripts/setup-toolchain.sh --local-archive /path/to/toolchain.tar.gz

# With checksum verification
./scripts/setup-toolchain.sh --url https://example.com/toolchain.tar.gz \
  --checksum abc123def456...

# Force re-extraction
./scripts/setup-toolchain.sh --local-archive toolchain.tar.gz --force
```

#### Options

- `--url URL` - URL to download the toolchain archive from
- `--local-archive PATH` - Path to a local toolchain archive file
- `--checksum HASH` - Optional SHA256 checksum to verify the archive integrity
- `--force` - Force re-extraction even if toolchain already exists
- `--help` - Show help message

#### Environment Variables

- `TOOLCHAIN_URL` - Default URL if `--url` is not provided
- `TOOLCHAIN_CHECKSUM` - Default checksum if `--checksum` is not provided

#### Examples

**Using environment variables:**

```bash
export TOOLCHAIN_URL="https://example.com/motorola-toolchain.tar.gz"
export TOOLCHAIN_CHECKSUM="abc123def456..."
./scripts/setup-toolchain.sh
```

**Download and extract in one command:**

```bash
./scripts/setup-toolchain.sh \
  --url https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/android-12.0.0_r1.tar.gz
```

**Using a local archive:**

```bash
# If you've already downloaded the toolchain manually
./scripts/setup-toolchain.sh --local-archive ~/Downloads/toolchain.tar.gz
```

#### Output

The toolchain will be extracted to:
```
toolchains/motorola/
```

Downloaded archives are cached in:
```
.toolchain-downloads/
```

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

After running `setup-toolchain.sh`, configure your environment:

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

The `setup-toolchain.sh` script can be integrated into CI workflows:

```yaml
- name: Setup Motorola Toolchain
  run: |
    ./scripts/setup-toolchain.sh \
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
./scripts/setup-toolchain.sh --url <TOOLCHAIN_URL>

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
chmod +x scripts/setup-toolchain.sh
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
