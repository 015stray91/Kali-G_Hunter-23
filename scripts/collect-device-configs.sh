#!/bin/bash
#
# collect-device-configs.sh
# 
# Script to provision toolchains and collect device/kernel/NetHunter configuration files
# into an artifact directory for CI purposes.
#
# Usage: ./collect-device-configs.sh --repos "repo1,repo2,repo3"
#

set -e

# Default values
REPOS=""
OUTPUT_DIR="device-configs-artifact"
NETHUNTER_INSTALLER_REPOS=(
    "https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-devices.git"
)
PIZZAG_TOOLCHAIN_REPO="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"

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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --repos REPOS    Comma-separated list of additional repositories to check"
            echo "  --output DIR     Output directory for collected configs (default: device-configs-artifact)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Create output directory structure
mkdir -p "${OUTPUT_DIR}/device"
mkdir -p "${OUTPUT_DIR}/kernel"
mkdir -p "${OUTPUT_DIR}/nethunter"
mkdir -p "${OUTPUT_DIR}/toolchain"

echo "=== Device Configuration Collection Script ==="
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Function to try cloning a repository
try_clone_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    local depth="${3:-1}"
    local timeout="${4:-30}"
    
    echo "Attempting to clone: ${repo_url}"
    if timeout "${timeout}" git clone --depth "${depth}" "${repo_url}" "${dest_dir}" 2>&1 | grep -v "Username\|Password"; then
        if [ -d "${dest_dir}/.git" ]; then
            echo "✓ Successfully cloned ${repo_url}"
            return 0
        fi
    fi
    echo "✗ Failed to clone ${repo_url}"
    return 1
}

# Function to collect device configuration from NetHunter devices repo
collect_nethunter_configs() {
    echo ""
    echo "=== Attempting to collect NetHunter device configurations ==="
    
    for repo in "${NETHUNTER_INSTALLER_REPOS[@]}"; do
        local temp_dir=$(mktemp -d)
        if try_clone_repo "${repo}" "${temp_dir}"; then
            # Look for device configurations
            if [ -d "${temp_dir}/devices" ]; then
                echo "Found devices directory, copying configurations..."
                cp -r "${temp_dir}/devices"/* "${OUTPUT_DIR}/nethunter/" 2>/dev/null || true
            fi
            
            # Look for kernel configurations
            if [ -d "${temp_dir}/kernel-configs" ]; then
                echo "Found kernel-configs directory, copying..."
                cp -r "${temp_dir}/kernel-configs"/* "${OUTPUT_DIR}/kernel/" 2>/dev/null || true
            fi
            
            # Copy any .config or defconfig files
            find "${temp_dir}" -name "*.config" -o -name "*defconfig" | while read -r config_file; do
                cp "${config_file}" "${OUTPUT_DIR}/kernel/" 2>/dev/null || true
            done
            
            rm -rf "${temp_dir}"
            echo "✓ NetHunter configurations collected"
            return 0
        fi
        rm -rf "${temp_dir}"
    done
    
    echo "✗ Could not collect NetHunter configurations"
    return 1
}

# Function to provision PizzaG toolchain as fallback
provision_pizzag_toolchain() {
    echo ""
    echo "=== Provisioning fallback toolchain ==="
    
    # Create toolchain info even if we can't clone
    cat > "${OUTPUT_DIR}/toolchain/toolchain-info.txt" <<EOF
Toolchain Fallback Configuration
Repository attempted: ${PIZZAG_TOOLCHAIN_REPO}
Collected at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Status: Attempting to provision...
EOF
    
    local temp_dir=$(mktemp -d)
    if try_clone_repo "${PIZZAG_TOOLCHAIN_REPO}" "${temp_dir}"; then
        echo "Toolchain cloned successfully"
        
        # Copy toolchain info
        if [ -f "${temp_dir}/README.md" ]; then
            cp "${temp_dir}/README.md" "${OUTPUT_DIR}/toolchain/toolchain-README.md"
        fi
        
        # Update toolchain info file
        cat > "${OUTPUT_DIR}/toolchain/toolchain-info.txt" <<EOF
Toolchain Configuration
Repository: ${PIZZAG_TOOLCHAIN_REPO}
Clone path: ${temp_dir}
Status: Successfully provisioned
Collected at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF
        
        rm -rf "${temp_dir}"
        echo "✓ Toolchain information collected"
        return 0
    else
        rm -rf "${temp_dir}"
        
        # Update status to indicate failure but continue
        cat > "${OUTPUT_DIR}/toolchain/toolchain-info.txt" <<EOF
Toolchain Configuration
Repository attempted: ${PIZZAG_TOOLCHAIN_REPO}
Status: Failed to clone (network/auth issue)
Note: This is optional for config collection
Collected at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Alternative: Use system toolchain or manual provisioning
EOF
        echo "✗ Failed to provision toolchain (continuing anyway)"
        return 1
    fi
}

# Function to collect device-specific files from current repository
collect_local_device_files() {
    echo ""
    echo "=== Collecting local device/kernel files ==="
    
    # Collect device kernel if present
    if [ -d "device-kernel" ]; then
        echo "Found device-kernel directory"
        
        # Copy kernel binary
        if [ -f "device-kernel/kernel" ]; then
            cp "device-kernel/kernel" "${OUTPUT_DIR}/device/kernel-image"
            echo "✓ Copied kernel image"
        fi
        
        # Look for any config files
        find device-kernel -name "*.config" -o -name "*defconfig" | while read -r config_file; do
            cp "${config_file}" "${OUTPUT_DIR}/device/" 2>/dev/null || true
            echo "✓ Copied $(basename ${config_file})"
        done
    fi
    
    # Collect any device tree files
    if [ -d "device-tree" ]; then
        cp -r device-tree/* "${OUTPUT_DIR}/device/" 2>/dev/null || true
        echo "✓ Copied device tree files"
    fi
    
    # Collect README and documentation
    if [ -f "README.md" ]; then
        cp "README.md" "${OUTPUT_DIR}/device/README.md"
        echo "✓ Copied README.md"
    fi
}

# Function to process additional repositories
process_additional_repos() {
    if [ -n "${REPOS}" ]; then
        echo ""
        echo "=== Processing additional repositories ==="
        
        IFS=',' read -ra REPO_ARRAY <<< "$REPOS"
        for repo in "${REPO_ARRAY[@]}"; do
            repo=$(echo "$repo" | xargs) # Trim whitespace
            if [ -n "$repo" ]; then
                local temp_dir=$(mktemp -d)
                if try_clone_repo "${repo}" "${temp_dir}"; then
                    # Copy any relevant files
                    find "${temp_dir}" -name "*.config" -o -name "*defconfig" | while read -r config_file; do
                        cp "${config_file}" "${OUTPUT_DIR}/device/" 2>/dev/null || true
                    done
                fi
                rm -rf "${temp_dir}"
            fi
        done
    fi
}

# Main execution flow
echo "Starting configuration collection..."

# Try to collect NetHunter configurations first
if ! collect_nethunter_configs; then
    echo "NetHunter collection failed, proceeding with fallback..."
fi

# Provision PizzaG toolchain (fallback)
if ! provision_pizzag_toolchain; then
    echo "Warning: PizzaG toolchain provisioning failed"
fi

# Collect local device files
collect_local_device_files

# Process additional repositories if provided
process_additional_repos

# Create summary file
cat > "${OUTPUT_DIR}/collection-summary.txt" <<EOF
Device Configuration Collection Summary
========================================
Collection Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Repository: $(git remote get-url origin 2>/dev/null || echo "unknown")
Branch: $(git branch --show-current 2>/dev/null || echo "unknown")
Commit: $(git rev-parse HEAD 2>/dev/null || echo "unknown")

Files Collected:
$(find "${OUTPUT_DIR}" -type f | sort)

Total Files: $(find "${OUTPUT_DIR}" -type f | wc -l)
Total Size: $(du -sh "${OUTPUT_DIR}" | cut -f1)
EOF

echo ""
echo "=== Collection Complete ==="
echo "Output directory: ${OUTPUT_DIR}"
echo "Summary:"
find "${OUTPUT_DIR}" -type f | wc -l | xargs echo "  Total files:"
du -sh "${OUTPUT_DIR}" | cut -f1 | xargs echo "  Total size:"
echo ""
echo "✓ Configuration collection completed successfully"
