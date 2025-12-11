#!/usr/bin/env bash
set -euo pipefail

#
# collect-device-configs.sh
#
# Collects device and kernel configurations from multiple repositories,
# provisions Android kernel toolchain via PizzaG's Build-Env-Setup-Scripts,
# includes NetHunter resources, and downloads the specified kernel tarball.
#
# Usage:
#   ./scripts/collect-device-configs.sh --repos "repo1,repo2,..." --kernel-url "https://..." --output-dir "path/to/output"
#

# Default values
OUTPUT_DIR="device-configs-collected"
KERNEL_URL=""
REPOS=""
WORK_DIR="$(pwd)/work"

# Device metadata for Motorola Moto G Stylus 5G (2020)
DEVICE_BRAND="Motorola"
DEVICE_MODEL="Moto G Stylus 5G (2020)"
DEVICE_CODENAME="genevn"
DEVICE_SOC="SM6450"
KERNEL_VERSION="5.10.233"
CLANG_VERSION="12.0.5"
LLD_VERSION="12.0.5"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repos)
            REPOS="$2"
            shift 2
            ;;
        --kernel-url)
            KERNEL_URL="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --repos <repo1,repo2,...> --kernel-url <url> [--output-dir <dir>]"
            echo ""
            echo "Options:"
            echo "  --repos         Comma-separated list of repository URLs to clone"
            echo "  --kernel-url    URL to kernel tarball (e.g., https://cdn.kernel.org/...)"
            echo "  --output-dir    Output directory for collected configs (default: device-configs-collected)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=== Device Configuration Collection ==="
echo "Device: $DEVICE_BRAND $DEVICE_MODEL ($DEVICE_CODENAME)"
echo "SoC: $DEVICE_SOC"
echo "Kernel Version: $KERNEL_VERSION"
echo "Toolchain: Clang $CLANG_VERSION / LLD $LLD_VERSION"
echo ""

# Create work and output directories
mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"

# Create metadata file
METADATA_FILE="$OUTPUT_DIR/device-metadata.txt"
cat > "$METADATA_FILE" << EOF
Device Information
==================
Brand: $DEVICE_BRAND
Model: $DEVICE_MODEL
Codename: $DEVICE_CODENAME
SoC: $DEVICE_SOC
Kernel Version: $KERNEL_VERSION
Toolchain: Clang $CLANG_VERSION / LLD $LLD_VERSION
Collection Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Build Timestamp: $(date +%s)

Repositories Cloned
===================
EOF

# Clone repositories
if [ -n "$REPOS" ]; then
    echo "=== Cloning Repositories ==="
    IFS=',' read -ra REPO_ARRAY <<< "$REPOS"
    for repo_url in "${REPO_ARRAY[@]}"; do
        repo_url=$(echo "$repo_url" | xargs)  # trim whitespace
        if [ -z "$repo_url" ]; then
            continue
        fi
        
        # Extract repo name from URL
        repo_name=$(basename "$repo_url" .git)
        echo "Cloning $repo_name from $repo_url..."
        
        cd "$WORK_DIR"
        if [ -d "$repo_name" ]; then
            echo "  Already exists, skipping..."
        else
            git clone --depth 1 "$repo_url" "$repo_name" || {
                echo "  Warning: Failed to clone $repo_url"
                continue
            }
        fi
        
        echo "$repo_url -> $repo_name" >> "$METADATA_FILE"
    done
    echo ""
fi

# Provision toolchain using PizzaG's Build-Env-Setup-Scripts
echo "=== Provisioning Toolchain ==="
if [ -d "$WORK_DIR/Build-Env-Setup-Scripts" ]; then
    echo "Found Build-Env-Setup-Scripts repository"
    cd "$WORK_DIR/Build-Env-Setup-Scripts"
    
    # Check for setup scripts
    if [ -f "setup.sh" ]; then
        echo "Running setup.sh..."
        bash setup.sh || echo "Warning: setup.sh exited with non-zero status"
    fi
    
    if [ -f "install-toolchain.sh" ]; then
        echo "Running install-toolchain.sh..."
        bash install-toolchain.sh || echo "Warning: install-toolchain.sh exited with non-zero status"
    fi
    
    # Document toolchain setup
    echo "" >> "$METADATA_FILE"
    echo "Toolchain Setup" >> "$METADATA_FILE"
    echo "===============" >> "$METADATA_FILE"
    echo "Provisioned via: PizzaG/Build-Env-Setup-Scripts" >> "$METADATA_FILE"
    echo "Scripts executed: setup.sh, install-toolchain.sh" >> "$METADATA_FILE"
else
    echo "Warning: Build-Env-Setup-Scripts not found in work directory"
fi
echo ""

# Download kernel tarball
if [ -n "$KERNEL_URL" ]; then
    echo "=== Downloading Kernel Tarball ==="
    KERNEL_TARBALL=$(basename "$KERNEL_URL")
    echo "URL: $KERNEL_URL"
    echo "File: $KERNEL_TARBALL"
    
    cd "$WORK_DIR"
    if [ -f "$KERNEL_TARBALL" ]; then
        echo "Tarball already exists, skipping download..."
    else
        curl -L -o "$KERNEL_TARBALL" "$KERNEL_URL" || {
            echo "Warning: Failed to download kernel tarball"
        }
    fi
    
    if [ -f "$KERNEL_TARBALL" ]; then
        echo "Extracting kernel tarball..."
        tar -xf "$KERNEL_TARBALL" || echo "Warning: Failed to extract tarball"
        
        # Document kernel source
        echo "" >> "$METADATA_FILE"
        echo "Kernel Source" >> "$METADATA_FILE"
        echo "=============" >> "$METADATA_FILE"
        echo "URL: $KERNEL_URL" >> "$METADATA_FILE"
        echo "File: $KERNEL_TARBALL" >> "$METADATA_FILE"
    fi
    echo ""
fi

# Collect device configurations
echo "=== Collecting Device Configurations ==="
cd "$WORK_DIR"

# Collect from android_device_motorola_yume
if [ -d "android_device_motorola_yume" ]; then
    echo "Collecting from android_device_motorola_yume..."
    mkdir -p "$OUTPUT_DIR/device"
    find android_device_motorola_yume -name "*.mk" -o -name "*.prop" -o -name "*.rc" -o -name "BoardConfig*.mk" -o -name "device.mk" | while read -r file; do
        cp --parents "$file" "$OUTPUT_DIR/device/" 2>/dev/null || true
    done
fi

# Collect from android_vendor_motorola_yume
if [ -d "android_vendor_motorola_yume" ]; then
    echo "Collecting from android_vendor_motorola_yume..."
    mkdir -p "$OUTPUT_DIR/vendor"
    find android_vendor_motorola_yume -name "*.mk" -o -name "*.prop" | while read -r file; do
        cp --parents "$file" "$OUTPUT_DIR/vendor/" 2>/dev/null || true
    done
fi

# Collect kernel configurations
if [ -d "platform_kernel_motorola_genevn" ]; then
    echo "Collecting from platform_kernel_motorola_genevn..."
    mkdir -p "$OUTPUT_DIR/kernel"
    
    # Copy defconfig files
    find platform_kernel_motorola_genevn -name "*defconfig*" -o -name ".config" | while read -r file; do
        cp --parents "$file" "$OUTPUT_DIR/kernel/" 2>/dev/null || true
    done
    
    # Copy kernel makefiles
    find platform_kernel_motorola_genevn -maxdepth 2 -name "Makefile" -o -name "Kconfig" | while read -r file; do
        cp --parents "$file" "$OUTPUT_DIR/kernel/" 2>/dev/null || true
    done
fi

# Collect NetHunter resources
echo "Collecting NetHunter resources..."
mkdir -p "$OUTPUT_DIR/nethunter"

if [ -d "nh-resources" ]; then
    echo "  Copying nh-resources..."
    cp -r nh-resources "$OUTPUT_DIR/nethunter/" || true
fi

if [ -d "nh-scripts" ]; then
    echo "  Copying nh-scripts..."
    cp -r nh-scripts "$OUTPUT_DIR/nethunter/" || true
fi

if [ -d "kali-nethunter-installer" ]; then
    echo "  Copying kali-nethunter-installer..."
    cp -r kali-nethunter-installer "$OUTPUT_DIR/nethunter/" || true
fi

if [ -d "So_You_Want_To_Build_A_Nethunter_Kernel" ]; then
    echo "  Copying So_You_Want_To_Build_A_Nethunter_Kernel..."
    cp -r So_You_Want_To_Build_A_Nethunter_Kernel "$OUTPUT_DIR/nethunter/" || true
fi

if [ -d "kali-nethunter-pro" ]; then
    echo "  Copying kali-nethunter-pro..."
    cp -r kali-nethunter-pro "$OUTPUT_DIR/nethunter/" || true
fi

# Document NetHunter resources
echo "" >> "$METADATA_FILE"
echo "NetHunter Resources" >> "$METADATA_FILE"
echo "===================" >> "$METADATA_FILE"
echo "nh-resources: $([ -d 'nh-resources' ] && echo 'included' || echo 'not found')" >> "$METADATA_FILE"
echo "nh-scripts: $([ -d 'nh-scripts' ] && echo 'included' || echo 'not found')" >> "$METADATA_FILE"
echo "kali-nethunter-installer: $([ -d 'kali-nethunter-installer' ] && echo 'included' || echo 'not found')" >> "$METADATA_FILE"
echo "So_You_Want_To_Build_A_Nethunter_Kernel: $([ -d 'So_You_Want_To_Build_A_Nethunter_Kernel' ] && echo 'included' || echo 'not found')" >> "$METADATA_FILE"
echo "kali-nethunter-pro: $([ -d 'kali-nethunter-pro' ] && echo 'included' || echo 'not found')" >> "$METADATA_FILE"

echo ""
echo "=== Collection Summary ==="
echo "Output directory: $OUTPUT_DIR"
echo "Metadata file: $METADATA_FILE"
echo ""
echo "Collected configurations:"
ls -lh "$OUTPUT_DIR"
echo ""
echo "Collection complete!"
