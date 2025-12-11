# Scripts Directory

This directory contains automation scripts for the Kali-G_Hunter-23 project.

## collect-device-configs.sh

A shell script that collects device configuration files from multiple upstream repositories and downloads kernel source.

### Usage

```bash
./scripts/collect-device-configs.sh [OPTIONS]
```

### Options

- `--repos <repo1> <repo2> ...`: Space-separated list of Git repository URLs to clone
- `--kernel-url <url>`: URL to the kernel tarball to download

### Default Repositories

If `--repos` is not provided, the script will clone the following repositories by default:

1. https://github.com/PizzaG/Build-Env-Setup-Scripts.git
2. https://github.com/PizzaG/android_vendor_motorola_yume.git
3. https://github.com/PizzaG/android_device_motorola_yume.git
4. https://github.com/sosRR/platform_kernel_motorola_genevn.git

### Default Kernel

If `--kernel-url` is not provided, the script will download:
- https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz

### Behavior

The script performs the following actions:

1. Creates a temporary working directory at `$GITHUB_WORKSPACE/tmp-collect`
2. Creates a target directory at `$GITHUB_WORKSPACE/device-configs`
3. For each repository:
   - Performs a shallow clone (git clone --depth 1)
   - Extracts relevant configuration files (*.mk, *.bp, *.conf, *.rc, defconfig, etc.)
   - Copies files to the target directory preserving structure
4. Downloads the specified kernel tarball
5. Extracts kernel configuration files (defconfig, Kconfig)
6. Creates a summary file with collection details

### Output

The script generates:
- `device-configs/`: Directory containing all collected configuration files
- `device-configs/collection-summary.txt`: Summary of the collection process
- Console output showing progress and statistics

### Environment Variables

- `GITHUB_WORKSPACE`: Base workspace directory (defaults to current directory if not set)

### Example

```bash
# Use default repositories and kernel
./scripts/collect-device-configs.sh

# Use custom repositories
./scripts/collect-device-configs.sh --repos "https://github.com/example/repo1.git" "https://github.com/example/repo2.git"

# Use custom kernel URL
./scripts/collect-device-configs.sh --kernel-url "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.0.tar.xz"

# Combine custom options
./scripts/collect-device-configs.sh \
  --repos "https://github.com/example/repo1.git" \
  --kernel-url "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.0.tar.xz"
```

### Exit Codes

- `0`: Success
- `1`: Invalid arguments or usage error

### Notes

- The script uses `set -euo pipefail` for strict error handling
- Temporary files are stored in `tmp-collect/` (automatically cleaned on each run)
- Final output is in `device-configs/` (automatically cleaned on each run)
- Network connectivity is required to clone repositories and download kernel tarball
- The script is designed to be run in CI/CD environments (GitHub Actions)
