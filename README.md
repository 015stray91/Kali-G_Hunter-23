# Kali-G_Hunter-23

This is the colonoscopy for the Moto G Stylus 5G 2020 XT-2315 Code name (Genevn / G_Hunter)

## Device Information

- **Device**: Motorola Moto G Stylus 5G (2020)
- **Model**: XT-2315
- **Codename**: genevn / G_Hunter
- **SoC**: Qualcomm SM6450 (Snapdragon 6 Gen 1)

## Features

### Device Configuration Collection

This repository includes automation to collect device, kernel, and vendor configuration files from multiple upstream sources:

- **Script**: `scripts/collect-device-configs.sh`
- **CI Workflow**: `.github/workflows/collect-device-configs.yml`
- **Metadata**: `device-metadata.md`

The collection script:
- Clones device, vendor, and kernel repositories
- Downloads kernel source tarball
- Extracts configuration files (*.mk, *.bp, *.conf, defconfig, etc.)
- Provisions build environment using PizzaG's Build-Env-Setup-Scripts

### CI/CD

#### Collect Device Configs Workflow

Runs inside a Kali Linux container to collect and upload device configurations as artifacts.

**Trigger**: Manual dispatch, push to main/ci branches, or pull requests

**Artifacts**:
- `device-configs`: Collected configuration files from all sources
- `device-metadata`: Device and build environment metadata

#### Build Kernel Workflow

Builds the Motorola kernel for the device.

**Trigger**: Manual dispatch

**Artifacts**:
- `build-log`: Build log output
- `kernel-out`: Kernel build output directory
- `device-kernel`: Device kernel image (if provided)

## Usage

### Collecting Device Configurations

Run locally:
```bash
./scripts/collect-device-configs.sh
```

Run with custom repositories:
```bash
./scripts/collect-device-configs.sh --repos "https://github.com/example/repo1.git" "https://github.com/example/repo2.git"
```

Run with custom kernel:
```bash
./scripts/collect-device-configs.sh --kernel-url "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.0.tar.xz"
```

See `scripts/README.md` for detailed documentation.

### Running CI Workflows

Workflows can be triggered manually from the Actions tab or automatically on push/PR.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── build-kernel.yml          # Kernel build workflow
│       └── collect-device-configs.yml # Config collection workflow
├── device-kernel/                    # Device kernel storage
├── scripts/
│   ├── README.md                     # Script documentation
│   └── collect-device-configs.sh     # Config collection script
├── device-metadata.md                # Device and build metadata
└── README.md                         # This file
```

## Contributing

Contributions are welcome! Please ensure:
- Scripts are tested before committing
- Documentation is updated for new features
- CI workflows pass successfully

## License

See repository license file for details.
