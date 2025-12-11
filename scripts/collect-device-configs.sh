#!/bin/bash
set -euo pipefail

# Script to collect device configurations from various repositories
# Usage: ./collect-device-configs.sh --repos "repo1 repo2 repo3..."

DEVICE_CONFIGS_DIR="device-configs"
REPOS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repos)
      REPOS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --repos \"repo1 repo2 repo3...\""
      exit 1
      ;;
  esac
done

if [ -z "$REPOS" ]; then
  echo "Error: --repos argument is required"
  echo "Usage: $0 --repos \"repo1 repo2 repo3...\""
  exit 1
fi

# Create device-configs directory structure
mkdir -p "$DEVICE_CONFIGS_DIR"/{vendor,device,kernel,nethunter,build-env}

echo "=== Collecting Device Configurations ==="
echo "Target directory: $DEVICE_CONFIGS_DIR"
echo ""

# Clone and collect files from each repository
for repo in $REPOS; do
  echo "Processing repository: $repo"
  
  # Extract repo name from URL
  repo_name=$(basename "$repo" .git)
  
  # Determine target subdirectory based on repo name/path
  if [[ "$repo" == *"vendor"* ]]; then
    target_dir="$DEVICE_CONFIGS_DIR/vendor/$repo_name"
  elif [[ "$repo" == *"device"* ]]; then
    target_dir="$DEVICE_CONFIGS_DIR/device/$repo_name"
  elif [[ "$repo" == *"kernel"* ]] || [[ "$repo" == *"genevn"* ]]; then
    target_dir="$DEVICE_CONFIGS_DIR/kernel/$repo_name"
  elif [[ "$repo" == *"nethunter"* ]] || [[ "$repo" == *"nh-"* ]] || [[ "$repo" == *"kali"* ]]; then
    target_dir="$DEVICE_CONFIGS_DIR/nethunter/$repo_name"
  elif [[ "$repo" == *"Build-Env"* ]]; then
    target_dir="$DEVICE_CONFIGS_DIR/build-env/$repo_name"
  else
    target_dir="$DEVICE_CONFIGS_DIR/other/$repo_name"
    mkdir -p "$DEVICE_CONFIGS_DIR/other"
  fi
  
  echo "  -> Cloning to: $target_dir"
  
  # Clone with depth 1 for faster download
  if git clone --depth 1 "$repo" "$target_dir" 2>&1; then
    echo "  -> Successfully cloned $repo_name"
    
    # Remove .git directory to save space
    rm -rf "$target_dir/.git"
    
    # Count files collected
    file_count=$(find "$target_dir" -type f 2>/dev/null | wc -l || echo 0)
    echo "  -> Collected $file_count files"
  else
    echo "  -> Warning: Failed to clone $repo"
  fi
  
  echo ""
done

# Create summary file
summary_file="$DEVICE_CONFIGS_DIR/collection-summary.txt"
echo "=== Device Configuration Collection Summary ===" > "$summary_file"
echo "Collection date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$summary_file"
echo "" >> "$summary_file"
echo "Repositories processed:" >> "$summary_file"
for repo in $REPOS; do
  echo "  - $repo" >> "$summary_file"
done
echo "" >> "$summary_file"
echo "Directory structure:" >> "$summary_file"
tree -L 2 "$DEVICE_CONFIGS_DIR" >> "$summary_file" 2>/dev/null || \
  find "$DEVICE_CONFIGS_DIR" -maxdepth 2 -type d >> "$summary_file"
echo "" >> "$summary_file"
echo "Total files collected: $(find "$DEVICE_CONFIGS_DIR" -type f | wc -l)" >> "$summary_file"
echo "Total size: $(du -sh "$DEVICE_CONFIGS_DIR" | cut -f1)" >> "$summary_file"

echo "=== Collection Complete ==="
echo "Summary saved to: $summary_file"
cat "$summary_file"
