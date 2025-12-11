#!/bin/bash
#
# collect-device-configs.sh
# Collects device, kernel, vendor, and NetHunter-related files into device-configs/ directory
#
# Usage:
#   ./collect-device-configs.sh --repos "repo1 repo2 ..." --output <dir> [--kernel-tarball <url>] [--verbose]
#

set -e

# Default values
OUTPUT_DIR="device-configs"
VERBOSE=false
REPOS=""
KERNEL_TARBALL=""
WORK_DIR="$(pwd)/nethunter-work"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repos)
            REPOS="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --kernel-tarball)
            KERNEL_TARBALL="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 --repos \"repo1 repo2 ...\" --output <dir> [--kernel-tarball <url>] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --repos          Space-separated list of repository URLs to clone"
            echo "  --output         Output directory for collected configs (default: device-configs)"
            echo "  --kernel-tarball URL to kernel tarball to download"
            echo "  --verbose        Enable verbose output"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log() {
    if [ "$VERBOSE" = true ]; then
        echo "[collect-device-configs] $*"
    fi
}

error() {
    echo "[ERROR] $*" >&2
}

# Create output directory
mkdir -p "$OUTPUT_DIR"
log "Output directory: $OUTPUT_DIR"

# Create work directory
mkdir -p "$WORK_DIR"
log "Work directory: $WORK_DIR"

# Clone repositories
if [ -n "$REPOS" ]; then
    log "Cloning repositories..."
    for repo in $REPOS; do
        repo_name=$(basename "$repo" .git)
        log "Cloning $repo_name..."
        
        if git clone --depth 1 "$repo" "$WORK_DIR/$repo_name" 2>/dev/null; then
            log "Successfully cloned $repo_name"
            
            # Copy relevant files to output directory
            if [ -d "$WORK_DIR/$repo_name" ]; then
                # Create subdirectory for this repo
                mkdir -p "$OUTPUT_DIR/$repo_name"
                
                # Copy configuration files, device trees, makefiles, etc.
                find "$WORK_DIR/$repo_name" -type f \( \
                    -name "*.mk" -o \
                    -name "*.rc" -o \
                    -name "*.prop" -o \
                    -name "*.dts" -o \
                    -name "*.dtsi" -o \
                    -name "*.defconfig" -o \
                    -name "*.config" -o \
                    -name "*.sh" -o \
                    -name "*.py" -o \
                    -name "Makefile" -o \
                    -name "Kconfig" -o \
                    -name "README*" -o \
                    -name "BoardConfig*" -o \
                    -name "device.mk" -o \
                    -name "vendor.mk" -o \
                    -name "AndroidProducts.mk" \
                \) -exec cp --parents {} "$OUTPUT_DIR/$repo_name/" \; 2>/dev/null || true
                
                log "Collected config files from $repo_name"
            fi
        else
            error "Failed to clone $repo"
        fi
    done
fi

# Download kernel tarball if specified
if [ -n "$KERNEL_TARBALL" ]; then
    log "Downloading kernel tarball from $KERNEL_TARBALL..."
    tarball_name=$(basename "$KERNEL_TARBALL")
    
    if curl -L -o "$WORK_DIR/$tarball_name" "$KERNEL_TARBALL" 2>/dev/null; then
        log "Successfully downloaded $tarball_name"
        
        # Extract and collect kernel configs
        tar_dir="$WORK_DIR/kernel-extract"
        mkdir -p "$tar_dir"
        
        log "Extracting kernel tarball..."
        tar -xf "$WORK_DIR/$tarball_name" -C "$tar_dir" --strip-components=1 2>/dev/null || true
        
        # Copy kernel configuration files
        mkdir -p "$OUTPUT_DIR/kernel-configs"
        find "$tar_dir" -type f \( \
            -name "*.defconfig" -o \
            -name "*.config" -o \
            -name "Kconfig*" -o \
            -name "Makefile" \
        \) -path "*/arch/arm64/*" -exec cp --parents {} "$OUTPUT_DIR/kernel-configs/" \; 2>/dev/null || true
        
        log "Collected kernel config files"
    else
        error "Failed to download kernel tarball"
    fi
fi

# Create manifest file
log "Creating manifest..."
cat > "$OUTPUT_DIR/MANIFEST.txt" << EOF
Device Configuration Collection
Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Collection Script: collect-device-configs.sh

Repositories Cloned:
EOF

if [ -n "$REPOS" ]; then
    for repo in $REPOS; do
        echo "  - $repo" >> "$OUTPUT_DIR/MANIFEST.txt"
    done
fi

if [ -n "$KERNEL_TARBALL" ]; then
    echo "" >> "$OUTPUT_DIR/MANIFEST.txt"
    echo "Kernel Tarball:" >> "$OUTPUT_DIR/MANIFEST.txt"
    echo "  - $KERNEL_TARBALL" >> "$OUTPUT_DIR/MANIFEST.txt"
fi

echo "" >> "$OUTPUT_DIR/MANIFEST.txt"
echo "Directory Structure:" >> "$OUTPUT_DIR/MANIFEST.txt"
tree -L 3 "$OUTPUT_DIR" >> "$OUTPUT_DIR/MANIFEST.txt" 2>/dev/null || find "$OUTPUT_DIR" -type f | sort >> "$OUTPUT_DIR/MANIFEST.txt"

log "Collection complete. Output in: $OUTPUT_DIR"
echo "Device configs collected in: $OUTPUT_DIR"
exit 0
