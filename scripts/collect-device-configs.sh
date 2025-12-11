#!/bin/bash
set -euo pipefail

# Default repositories to clone
DEFAULT_REPOS=(
  "https://github.com/PizzaG/Build-Env-Setup-Scripts.git"
  "https://github.com/PizzaG/android_vendor_motorola_yume.git"
  "https://github.com/PizzaG/android_device_motorola_yume.git"
  "https://github.com/sosRR/platform_kernel_motorola_genevn.git"
)

# Default kernel tarball URL
DEFAULT_KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz"

# Parse command line arguments
REPOS=()
KERNEL_URL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --repos)
      shift
      # Read space-separated repos
      while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; do
        REPOS+=("$1")
        shift
      done
      ;;
    --kernel-url)
      KERNEL_URL="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--repos <repo1> <repo2> ...] [--kernel-url <url>]"
      exit 1
      ;;
  esac
done

# Use defaults if not provided
if [ ${#REPOS[@]} -eq 0 ]; then
  REPOS=("${DEFAULT_REPOS[@]}")
fi

if [ -z "$KERNEL_URL" ]; then
  KERNEL_URL="$DEFAULT_KERNEL_URL"
fi

# Set up directories
WORKSPACE="${GITHUB_WORKSPACE:-.}"
TMP_COLLECT="$WORKSPACE/tmp-collect"
TARGET_DIR="$WORKSPACE/device-configs"

echo "===== Device Configuration Collection Script ====="
echo "Working directory: $WORKSPACE"
echo "Temporary directory: $TMP_COLLECT"
echo "Target directory: $TARGET_DIR"
echo ""

# Clean and create directories
rm -rf "$TMP_COLLECT" "$TARGET_DIR"
mkdir -p "$TMP_COLLECT" "$TARGET_DIR"

echo "Repositories to clone:"
for repo in "${REPOS[@]}"; do
  echo "  - $repo"
done
echo ""
echo "Kernel tarball URL: $KERNEL_URL"
echo ""

# Clone repositories
for repo in "${REPOS[@]}"; do
  repo_name=$(basename "$repo" .git)
  echo "===== Cloning $repo_name ====="
  
  # Validate repository URL (basic check for https://github.com)
  if [[ ! "$repo" =~ ^https://github\.com/ ]]; then
    echo "✗ Skipping $repo_name: Only GitHub HTTPS URLs are supported for security"
    continue
  fi
  
  if git clone --depth 1 "$repo" "$TMP_COLLECT/$repo_name"; then
    echo "✓ Successfully cloned $repo_name"
    
    # Copy relevant configuration files to target directory
    mkdir -p "$TARGET_DIR/$repo_name"
    
    # Copy device-specific configs (*.mk, *.conf, *.rc, defconfig, etc.)
    if [ -d "$TMP_COLLECT/$repo_name" ]; then
      # Find and copy configuration files, preserving structure relative to repo root
      cd "$TMP_COLLECT/$repo_name"
      
      # Create a function to copy files preserving directory structure
      copy_configs() {
        local target_base="$1"
        find . -type f \( \
          -name "*.mk" -o \
          -name "*.bp" -o \
          -name "*.conf" -o \
          -name "*.rc" -o \
          -name "*defconfig*" -o \
          -name "*.te" -o \
          -name "*.xml" -o \
          -name "*.prop" -o \
          -name "*.sh" -o \
          -name "Makefile" -o \
          -name "Android.mk" -o \
          -name "Android.bp" \
        \) | while read -r file; do
          dest_dir="$target_base/$(dirname "$file")"
          mkdir -p "$dest_dir"
          cp "$file" "$dest_dir/" || true
        done
      }
      
      copy_configs "$TARGET_DIR/$repo_name"
      cd "$WORKSPACE"
      
      echo "✓ Copied configuration files from $repo_name"
    fi
  else
    echo "✗ Failed to clone $repo_name"
  fi
  echo ""
done

# Download and extract kernel tarball
echo "===== Downloading Kernel Tarball ====="
kernel_tarball="$TMP_COLLECT/$(basename "$KERNEL_URL")"

# Validate kernel URL (basic check for https://cdn.kernel.org)
if [[ ! "$KERNEL_URL" =~ ^https://cdn\.kernel\.org/ ]]; then
  echo "⚠ Warning: Kernel URL is not from cdn.kernel.org, skipping for security"
else
  if curl -L --max-redirs 3 -o "$kernel_tarball" "$KERNEL_URL"; then
    echo "✓ Downloaded kernel tarball"
    
    # Extract kernel tarball
    kernel_extract_dir="$TMP_COLLECT/kernel-source"
    mkdir -p "$kernel_extract_dir"
    
    echo "Extracting kernel tarball..."
    if tar -xf "$kernel_tarball" -C "$kernel_extract_dir" --strip-components=1; then
      echo "✓ Extracted kernel tarball"
      
      # Copy kernel config files
      mkdir -p "$TARGET_DIR/kernel-configs"
      
      # Copy defconfig files and other relevant kernel configs
      if [ -d "$kernel_extract_dir/arch/arm64/configs" ]; then
        cp -r "$kernel_extract_dir/arch/arm64/configs" "$TARGET_DIR/kernel-configs/" || true
      fi
      
      if [ -d "$kernel_extract_dir/arch/arm/configs" ]; then
        cp -r "$kernel_extract_dir/arch/arm/configs" "$TARGET_DIR/kernel-configs/" || true
      fi
      
      # Copy Kconfig files for reference, preserving paths to avoid overwrites
      mkdir -p "$TARGET_DIR/kernel-configs/Kconfig-files"
      find "$kernel_extract_dir" -maxdepth 2 -name "Kconfig*" | while read -r kconfig; do
        # Preserve filename uniqueness by including parent dir
        parent_dir=$(basename "$(dirname "$kconfig")")
        filename=$(basename "$kconfig")
        cp "$kconfig" "$TARGET_DIR/kernel-configs/Kconfig-files/${parent_dir}_${filename}" 2>/dev/null || true
      done
      
      echo "✓ Copied kernel configuration files"
    else
      echo "✗ Failed to extract kernel tarball"
    fi
  else
    echo "✗ Failed to download kernel tarball"
  fi
fi
echo ""

# Create a summary file
echo "===== Creating Summary ====="
cat > "$TARGET_DIR/collection-summary.txt" <<EOF
Device Configuration Collection Summary
========================================
Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Repositories Cloned:
EOF

for repo in "${REPOS[@]}"; do
  repo_name=$(basename "$repo" .git)
  echo "  - $repo_name: $repo" >> "$TARGET_DIR/collection-summary.txt"
done

cat >> "$TARGET_DIR/collection-summary.txt" <<EOF

Kernel Tarball:
  - URL: $KERNEL_URL
  - File: $(basename "$KERNEL_URL")

Target Directory: $TARGET_DIR
EOF

echo "✓ Summary created at $TARGET_DIR/collection-summary.txt"
echo ""

# List collected files
echo "===== Collected Files ====="
find "$TARGET_DIR" -type f | sort | head -50
total_files=$(find "$TARGET_DIR" -type f | wc -l)
echo ""
echo "Total files collected: $total_files"

# Show directory sizes
echo ""
echo "===== Directory Sizes ====="
du -sh "$TARGET_DIR"/* 2>/dev/null || true

echo ""
echo "===== Collection Complete ====="
echo "Device configurations saved to: $TARGET_DIR"
