#!/bin/bash
# collect-device-configs.sh
# Collects device configuration files from external git repos and kernel tarballs
# for Moto G Stylus 5G (genevn/G_Hunter/yume)

set -e

# Parse arguments
REPOS=""
KERNEL_URL=""

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
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --repos 'repo1 repo2 ...' --kernel-url URL"
      exit 1
      ;;
  esac
done

if [ -z "$REPOS" ] && [ -z "$KERNEL_URL" ]; then
  echo "Error: At least one of --repos or --kernel-url must be provided"
  exit 1
fi

# Setup directories
WORK_DIR="$(pwd)/work-collect-configs"
OUTPUT_DIR="$(pwd)/device-configs"
MANIFEST_FILE="$OUTPUT_DIR/manifest.txt"
INDEX_FILE="$OUTPUT_DIR/index.json"

# Clean up and create directories
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

echo "=== Device Configuration Collection Script ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

# Initialize manifest and index
echo "Device Configuration Sources" > "$MANIFEST_FILE"
echo "============================" >> "$MANIFEST_FILE"
echo "Generated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$MANIFEST_FILE"
echo "" >> "$MANIFEST_FILE"

# Initialize JSON index
echo "{" > "$INDEX_FILE"
echo "  \"generated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$INDEX_FILE"
echo "  \"device\": \"Moto G Stylus 5G (genevn/G_Hunter/yume)\"," >> "$INDEX_FILE"
echo "  \"sources\": []," >> "$INDEX_FILE"
echo "  \"collected_files\": {" >> "$INDEX_FILE"

# Tracking for validation
FOUND_DEFCONFIG=0
FOUND_DTS=0
COLLECTED_FILES=0
FIRST_CATEGORY=1

# Function to add source to manifest
add_source_to_manifest() {
  local source_type=$1
  local source_url=$2
  local commit_or_checksum=$3
  
  echo "Source: $source_url" >> "$MANIFEST_FILE"
  echo "Type: $source_type" >> "$MANIFEST_FILE"
  if [ "$source_type" = "git" ]; then
    echo "Commit: $commit_or_checksum" >> "$MANIFEST_FILE"
  else
    echo "Checksum: $commit_or_checksum" >> "$MANIFEST_FILE"
  fi
  echo "" >> "$MANIFEST_FILE"
}

# Function to collect files matching patterns
collect_files() {
  local source_dir=$1
  local source_name=$2
  local category=$3
  shift 3
  local patterns=("$@")
  
  local found_in_category=0
  local category_files=""
  
  for pattern in "${patterns[@]}"; do
    # Use find with -path for pattern matching, exclude .git directories
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        # Calculate relative path from source_dir
        local rel_path="${file#$source_dir/}"
        
        # Skip .git directory files
        if [[ "$rel_path" == .git/* ]]; then
          continue
        fi
        
        # Create destination directory structure
        local dest_dir="$OUTPUT_DIR/$source_name/$(dirname "$rel_path")"
        mkdir -p "$dest_dir"
        
        # Copy file preserving path
        cp "$file" "$dest_dir/"
        
        # Add to manifest
        echo "  Collected: $rel_path" >> "$MANIFEST_FILE"
        
        # Track for JSON
        if [ $found_in_category -eq 0 ]; then
          category_files="\"$rel_path\""
        else
          category_files="$category_files, \"$rel_path\""
        fi
        
        found_in_category=$((found_in_category + 1))
        COLLECTED_FILES=$((COLLECTED_FILES + 1))
        
        # Track specific types
        if [[ "$rel_path" == *defconfig* ]]; then
          FOUND_DEFCONFIG=1
        fi
        if [[ "$rel_path" == *.dts ]] || [[ "$rel_path" == *.dtsi ]]; then
          FOUND_DTS=1
        fi
      fi
    done < <(cd "$source_dir" && find . -not -path './.git/*' -type f -path "./$pattern" 2>/dev/null | sed 's|^\./||')
  done
  
  # Add category to JSON index if files found
  if [ $found_in_category -gt 0 ]; then
    if [ $FIRST_CATEGORY -eq 0 ]; then
      echo "," >> "$INDEX_FILE"
    fi
    echo -n "    \"$category\": [$category_files]" >> "$INDEX_FILE"
    FIRST_CATEGORY=0
  fi
  
  return $found_in_category
}

# Clone git repositories
if [ -n "$REPOS" ]; then
  echo "Cloning git repositories..."
  
  for repo in $REPOS; do
    repo_name=$(basename "$repo" .git)
    clone_dir="$WORK_DIR/$repo_name"
    
    echo "  Cloning: $repo"
    if git clone --depth 1 "$repo" "$clone_dir"; then
      cd "$clone_dir"
      commit_sha=$(git rev-parse HEAD)
      origin_url=$(git config --get remote.origin.url)
      cd - > /dev/null
      
      echo "    Commit: $commit_sha"
      add_source_to_manifest "git" "$origin_url" "$commit_sha"
      
      # Collect device-relevant files
      echo "Collecting files from $repo_name..." >> "$MANIFEST_FILE"
      
      # defconfig files
      collect_files "$clone_dir" "$repo_name" "defconfig" \
        "*defconfig" "arch/*/configs/*defconfig" || true
      
      # config fragments
      collect_files "$clone_dir" "$repo_name" "config" \
        ".config" "*.config" "*config.fragment" || true
      
      # Device tree files
      collect_files "$clone_dir" "$repo_name" "dts" \
        "*.dts" "*.dtsi" "arch/*/boot/dts/*" "arch/*/boot/dts/*/*" || true
      
      # Android build files
      collect_files "$clone_dir" "$repo_name" "android_build" \
        "BoardConfig*.mk" "AndroidProducts.mk" "AndroidBoard.mk" "Android.mk" || true
      
      # Proprietary files lists
      collect_files "$clone_dir" "$repo_name" "proprietary" \
        "proprietary-files.txt" "device-proprietary-files.txt" "*proprietary*.txt" || true
      
      # Vendor manifest
      collect_files "$clone_dir" "$repo_name" "manifest" \
        "manifest.xml" "vendor_manifest.xml" "*manifest*.xml" || true
      
      # Kconfig files
      collect_files "$clone_dir" "$repo_name" "kconfig" \
        "Kconfig" "Kconfig.*" "*/Kconfig" || true
      
      echo "" >> "$MANIFEST_FILE"
    else
      echo "  Warning: Failed to clone $repo" >&2
      echo "Source: $repo (FAILED TO CLONE)" >> "$MANIFEST_FILE"
      echo "" >> "$MANIFEST_FILE"
    fi
  done
fi

# Download and extract kernel tarball
if [ -n "$KERNEL_URL" ]; then
  echo "Downloading kernel tarball..."
  
  tarball_name=$(basename "$KERNEL_URL")
  tarball_path="$WORK_DIR/$tarball_name"
  
  echo "  URL: $KERNEL_URL"
  if curl -f -L -o "$tarball_path" "$KERNEL_URL"; then
    # Calculate checksum
    checksum=$(sha256sum "$tarball_path" | awk '{print $1}')
    echo "    SHA256: $checksum"
    
    add_source_to_manifest "tarball" "$KERNEL_URL" "$checksum"
    
    # Extract tarball
    extract_dir="$WORK_DIR/linux-kernel"
    mkdir -p "$extract_dir"
    echo "  Extracting tarball..."
    
    if tar -xf "$tarball_path" -C "$extract_dir" --strip-components=1; then
      echo "Collecting files from linux-kernel..." >> "$MANIFEST_FILE"
      
      # Collect kernel config files
      collect_files "$extract_dir" "linux-kernel" "defconfig" \
        "*defconfig" "arch/*/configs/*defconfig" || true
      
      # Collect device tree files
      collect_files "$extract_dir" "linux-kernel" "dts" \
        "*.dts" "*.dtsi" "arch/*/boot/dts/*" "arch/*/boot/dts/*/*" || true
      
      # Kconfig files
      collect_files "$extract_dir" "linux-kernel" "kconfig" \
        "Kconfig" "Kconfig.*" || true
      
      echo "" >> "$MANIFEST_FILE"
    else
      echo "  Warning: Failed to extract tarball" >&2
    fi
  else
    echo "  Warning: Failed to download kernel tarball" >&2
    echo "Source: $KERNEL_URL (FAILED TO DOWNLOAD)" >> "$MANIFEST_FILE"
    echo "" >> "$MANIFEST_FILE"
  fi
fi

# Finalize JSON index
echo "" >> "$INDEX_FILE"
echo "  }," >> "$INDEX_FILE"
echo "  \"statistics\": {" >> "$INDEX_FILE"
echo "    \"total_files_collected\": $COLLECTED_FILES," >> "$INDEX_FILE"
echo "    \"found_defconfig\": $([ $FOUND_DEFCONFIG -eq 1 ] && echo "true" || echo "false")," >> "$INDEX_FILE"
echo "    \"found_dts\": $([ $FOUND_DTS -eq 1 ] && echo "true" || echo "false")" >> "$INDEX_FILE"
echo "  }" >> "$INDEX_FILE"
echo "}" >> "$INDEX_FILE"

# Summary
echo "=== Collection Summary ===" >> "$MANIFEST_FILE"
echo "Total files collected: $COLLECTED_FILES" >> "$MANIFEST_FILE"
echo "Found defconfig: $([ $FOUND_DEFCONFIG -eq 1 ] && echo "Yes" || echo "No")" >> "$MANIFEST_FILE"
echo "Found DTS files: $([ $FOUND_DTS -eq 1 ] && echo "Yes" || echo "No")" >> "$MANIFEST_FILE"

echo ""
echo "=== Collection Complete ==="
echo "Total files collected: $COLLECTED_FILES"
echo "Output directory: $OUTPUT_DIR"
echo "Manifest: $MANIFEST_FILE"
echo "Index: $INDEX_FILE"

# Validation
EXIT_CODE=0
if [ $FOUND_DEFCONFIG -eq 0 ]; then
  echo "WARNING: No defconfig files found!" >&2
  EXIT_CODE=1
fi

if [ $FOUND_DTS -eq 0 ]; then
  echo "WARNING: No DTS files found!" >&2
  EXIT_CODE=1
fi

# Clean up work directory
rm -rf "$WORK_DIR"

exit $EXIT_CODE
