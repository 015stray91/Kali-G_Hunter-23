# Device Configuration Collection

This directory contains device configuration files collected from external repositories and kernel sources for the **Moto G Stylus 5G** (code names: genevn/G_Hunter/yume).

## Contents

The automated collection script (`scripts/collect-device-configs.sh`) gathers the following types of files:

### Configuration Files
- **defconfig files**: Kernel default configuration files
  - `*defconfig`
  - `arch/*/configs/*defconfig`

- **Config fragments**: Additional kernel configuration fragments
  - `.config`
  - `*.config`
  - `*config.fragment`

### Device Tree Files
- **DTS/DTSI files**: Device tree source files describing hardware
  - `*.dts`
  - `*.dtsi`
  - `arch/*/boot/dts/*`

### Android Build Files
- **Board configuration**: Device-specific build configuration
  - `BoardConfig*.mk`
  - `AndroidProducts.mk`
  - `AndroidBoard.mk`
  - `Android.mk`

### Proprietary Files
- **Proprietary files lists**: Lists of proprietary blobs needed for the device
  - `proprietary-files.txt`
  - `device-proprietary-files.txt`

### Vendor Manifests
- **HAL manifests**: Hardware abstraction layer interface definitions
  - `manifest.xml`
  - `vendor_manifest.xml`

### Build System Files
- **Kconfig files**: Kernel configuration menu descriptions
  - `Kconfig`
  - `Kconfig.*`

## Output Structure

```
device-configs/
├── README.md (this file)
├── manifest.txt (detailed listing of sources and collected files)
├── index.json (machine-readable summary)
└── <source-name>/ (one directory per source)
    └── <original-path>/ (preserves original directory structure)
        └── <collected-files>
```

## Manifest Files

### manifest.txt
A human-readable text file containing:
- Source URLs (git repos and kernel tarballs)
- Commit SHAs for git repos or checksums for tarballs
- List of all collected files with their original paths
- Collection statistics

### index.json
A machine-readable JSON file containing:
- Generation timestamp
- Device information
- Sources list
- Collected files organized by category
- Statistics (total files, presence of critical files)

## Adding New Sources

To add additional repositories or kernel tarballs to the collection:

1. Edit `.github/workflows/build-kernel.yml`
2. Locate the step that runs `scripts/collect-device-configs.sh`
3. Add new repository URLs to the `--repos` parameter (space-separated)
4. Update the `--kernel-url` parameter if using a different kernel version

### Example

```yaml
- name: Collect device configs
  run: |
    ./scripts/collect-device-configs.sh \
      --repos "https://github.com/user/repo1.git https://github.com/user/repo2.git" \
      --kernel-url "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz"
```

## Current Sources

The workflow is configured to collect from:
- https://github.com/PizzaG/Build-Env-Setup-Scripts.git
- https://github.com/PizzaG/android_vendor_motorola_yume.git
- https://github.com/PizzaG/android_device_motorola_yume.git
- https://github.com/sosRR/platform_kernel_motorola_genevn.git
- Kernel tarball: https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz

## Notes

- The collection script performs shallow clones (`--depth 1`) to minimize download time
- Files are copied with their original directory structure preserved
- The script validates that at least one defconfig and DTS file are found
- If validation fails, the script exits with a non-zero code but still produces the artifact
- The script does not execute any code from cloned repositories for security

## CI/CD Integration

This collection is automated in the GitHub Actions workflow (`build-kernel.yml`). The collected files are uploaded as a build artifact named `device-configs` which can be downloaded from the workflow run page.

## Private Repositories

If any of the configured source repositories are private, the workflow will fail unless:
1. A GitHub Personal Access Token (PAT) with appropriate permissions is configured
2. The repository is made public, or
3. Deploy keys are set up for the workflow

Contact the repository maintainer to arrange access if needed.
