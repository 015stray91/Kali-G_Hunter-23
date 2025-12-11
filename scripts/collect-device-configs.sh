#!/bin/bash
#
# collect-device-configs.sh
#
# Purpose: Clone device/kernel/vendor repos, download kernel tarball,
#          and collect device/kernel/vendor config files into device-configs/
#
# Usage: ./scripts/collect-device-configs.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Repository URLs to clone
REPOS=(
    "https://github.com/PizzaG/Build-Env-Setup-Scripts.git"
    "https://github.com/PizzaG/android_vendor_motorola_yume.git"
    "https://github.com/PizzaG/android_device_motorola_yume.git"
    "https://github.com/sosRR/platform_kernel_motorola_genevn.git"
)

# Kernel tarball URL
KERNEL_TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.233.tar.xz"

# Workspace directory (default to current directory or GITHUB_WORKSPACE)
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
TMP_DIR="${WORKSPACE}/tmp-clone"
OUTPUT_DIR="${WORKSPACE}/device-configs"
MANIFEST_FILE="${OUTPUT_DIR}/manifest.txt"
KERNEL_TARBALL="${WORKSPACE}/kernel.tar.xz"
KERNEL_EXTRACT_DIR="${WORKSPACE}/linux-kernel"

log_info "Starting device config collection..."
log_info "Workspace: ${WORKSPACE}"

# Clean up any previous runs
if [ -d "${TMP_DIR}" ]; then
    log_warn "Cleaning up previous temporary directory..."
    rm -rf "${TMP_DIR}"
fi

if [ -d "${OUTPUT_DIR}" ]; then
    log_warn "Cleaning up previous output directory..."
    rm -rf "${OUTPUT_DIR}"
fi

# Create directories
mkdir -p "${TMP_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Initialize manifest file
log_info "Initializing manifest file: ${MANIFEST_FILE}"
echo "# Device Config Collection Manifest" > "${MANIFEST_FILE}"
echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "${MANIFEST_FILE}"
echo "" >> "${MANIFEST_FILE}"

# Clone repositories
log_info "Cloning repositories..."
for repo_url in "${REPOS[@]}"; do
    repo_name=$(basename "${repo_url}" .git)
    clone_path="${TMP_DIR}/${repo_name}"
    
    log_info "Cloning ${repo_url}..."
    if git clone --depth 1 "${repo_url}" "${clone_path}"; then
        # Get commit SHA
        commit_sha=$(cd "${clone_path}" && git rev-parse HEAD)
        
        # Record in manifest
        echo "Repository: ${repo_url}" >> "${MANIFEST_FILE}"
        echo "  Commit: ${commit_sha}" >> "${MANIFEST_FILE}"
        echo "  Clone path: ${repo_name}" >> "${MANIFEST_FILE}"
        echo "" >> "${MANIFEST_FILE}"
        
        log_info "  Cloned ${repo_name} at commit ${commit_sha:0:8}"
    else
        log_error "Failed to clone ${repo_url}"
        exit 1
    fi
done

# Download kernel tarball
log_info "Downloading kernel tarball from ${KERNEL_TARBALL_URL}..."
if curl -L -o "${KERNEL_TARBALL}" "${KERNEL_TARBALL_URL}"; then
    log_info "  Downloaded to ${KERNEL_TARBALL}"
    
    # Record in manifest
    echo "Kernel Tarball: ${KERNEL_TARBALL_URL}" >> "${MANIFEST_FILE}"
    echo "  Downloaded: ${KERNEL_TARBALL}" >> "${MANIFEST_FILE}"
    echo "" >> "${MANIFEST_FILE}"
else
    log_error "Failed to download kernel tarball"
    exit 1
fi

# Extract kernel tarball
log_info "Extracting kernel tarball..."
mkdir -p "${KERNEL_EXTRACT_DIR}"
if tar -xf "${KERNEL_TARBALL}" -C "${KERNEL_EXTRACT_DIR}" --strip-components=1; then
    log_info "  Extracted to ${KERNEL_EXTRACT_DIR}"
    
    # Update manifest
    echo "Kernel extracted to: linux-kernel/" >> "${MANIFEST_FILE}"
    echo "" >> "${MANIFEST_FILE}"
else
    log_error "Failed to extract kernel tarball"
    exit 1
fi

# Function to copy files matching pattern
copy_matching_files() {
    local source_dir="$1"
    local pattern="$2"
    local dest_subdir="$3"
    local description="$4"
    
    log_info "Searching for ${description} (${pattern})..."
    
    # Create destination directory
    mkdir -p "${OUTPUT_DIR}/${dest_subdir}"
    
    # Find and copy files
    local count=0
    while IFS= read -r -d '' file; do
        # Get relative path from source
        rel_path="${file#${source_dir}/}"
        dest_path="${OUTPUT_DIR}/${dest_subdir}/${rel_path}"
        
        # Create destination directory for file
        mkdir -p "$(dirname "${dest_path}")"
        
        # Copy file
        cp "${file}" "${dest_path}"
        count=$((count + 1))
    done < <(find "${source_dir}" -type f -name "${pattern}" -print0 2>/dev/null)
    
    log_info "  Copied ${count} ${description} files"
    return 0
}

# Function to copy entire directories matching pattern
copy_matching_dirs() {
    local source_dir="$1"
    local pattern="$2"
    local dest_subdir="$3"
    local description="$4"
    
    log_info "Searching for ${description} directories (${pattern})..."
    
    # Create destination directory
    mkdir -p "${OUTPUT_DIR}/${dest_subdir}"
    
    # Find and copy directories
    local count=0
    while IFS= read -r -d '' dir; do
        # Get relative path from source
        rel_path="${dir#${source_dir}/}"
        dest_path="${OUTPUT_DIR}/${dest_subdir}/$(basename "${rel_path}")"
        
        # Copy directory
        cp -r "${dir}" "${dest_path}"
        count=$((count + 1))
    done < <(find "${source_dir}" -type d -name "${pattern}" -print0 2>/dev/null)
    
    log_info "  Copied ${count} ${description} directories"
    return 0
}

# Collect device tree sources (.dts, .dtsi files)
log_info "Collecting device tree sources..."
copy_matching_files "${TMP_DIR}" "*.dts" "device-tree" "device tree source (.dts)"
copy_matching_files "${TMP_DIR}" "*.dtsi" "device-tree" "device tree include (.dtsi)"

# Collect defconfig files
log_info "Collecting defconfig files..."
copy_matching_files "${TMP_DIR}" "*defconfig*" "defconfigs" "kernel defconfig"

# Collect vendor blobs and makefiles
log_info "Collecting vendor files..."
copy_matching_files "${TMP_DIR}" "*.mk" "vendor" "vendor makefile (.mk)"
copy_matching_files "${TMP_DIR}" "Android.mk" "vendor" "Android makefile"
copy_matching_files "${TMP_DIR}" "Android.bp" "vendor" "Android blueprint"
copy_matching_dirs "${TMP_DIR}" "proprietary" "vendor" "proprietary blobs"

# Collect device configuration files
log_info "Collecting device configuration files..."
copy_matching_files "${TMP_DIR}" "*.te" "device" "SELinux policy (.te)"
copy_matching_files "${TMP_DIR}" "*.rc" "device" "init script (.rc)"
copy_matching_files "${TMP_DIR}" "*.xml" "device" "device XML config"
copy_matching_files "${TMP_DIR}" "*.conf" "device" "device config"

# Collect kernel configuration from extracted kernel
log_info "Collecting kernel configs from extracted kernel..."
copy_matching_files "${KERNEL_EXTRACT_DIR}" "*defconfig*" "kernel-defconfigs" "kernel defconfig"
copy_matching_files "${KERNEL_EXTRACT_DIR}" "Kconfig*" "kernel-kconfig" "kernel Kconfig"

# Copy any README or documentation files
log_info "Collecting documentation..."
copy_matching_files "${TMP_DIR}" "README*" "docs" "README files"
copy_matching_files "${TMP_DIR}" "*.md" "docs" "Markdown documentation"

# Create a summary
SUMMARY_FILE="${OUTPUT_DIR}/COLLECTION_SUMMARY.txt"
log_info "Creating collection summary..."

cat > "${SUMMARY_FILE}" << EOF
Device Config Collection Summary
=================================
Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Workspace: ${WORKSPACE}
Output Directory: ${OUTPUT_DIR}

Repositories Cloned:
EOF

for repo_url in "${REPOS[@]}"; do
    echo "  - ${repo_url}" >> "${SUMMARY_FILE}"
done

cat >> "${SUMMARY_FILE}" << EOF

Kernel Tarball:
  - ${KERNEL_TARBALL_URL}
  - Extracted to: ${KERNEL_EXTRACT_DIR}

Collected Files:
EOF

# Count files in each category
for subdir in device-tree defconfigs vendor device kernel-defconfigs kernel-kconfig docs; do
    if [ -d "${OUTPUT_DIR}/${subdir}" ]; then
        file_count=$(find "${OUTPUT_DIR}/${subdir}" -type f 2>/dev/null | wc -l)
        echo "  ${subdir}: ${file_count} files" >> "${SUMMARY_FILE}"
    fi
done

echo "" >> "${SUMMARY_FILE}"
echo "See manifest.txt for detailed repository information." >> "${SUMMARY_FILE}"

log_info "Collection summary saved to ${SUMMARY_FILE}"

# Clean up temporary directory
log_info "Cleaning up temporary directory..."
rm -rf "${TMP_DIR}"

log_info "Device config collection complete!"
log_info "Output directory: ${OUTPUT_DIR}"
log_info "Manifest file: ${MANIFEST_FILE}"
log_info "Summary file: ${SUMMARY_FILE}"

exit 0
