#!/usr/bin/env bash
#
# setup-toolchain.sh
#
# Download (or use local archive), verify (optional), extract, and place
# the Motorola device toolchain into toolchains/motorola/
#
# Usage:
#   ./scripts/setup-toolchain.sh [OPTIONS]
#
# Options:
#   --url URL              URL to download the toolchain archive
#   --local-archive PATH   Use a local archive file instead of downloading
#   --checksum HASH        Optional SHA256 checksum to verify the archive
#   --force                Force re-extraction even if toolchain exists
#   --help                 Show this help message
#
# Environment Variables:
#   TOOLCHAIN_URL          Default URL if --url not provided
#   TOOLCHAIN_CHECKSUM     Default checksum if --checksum not provided
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default paths
TOOLCHAIN_DIR="${REPO_ROOT}/toolchains/motorola"
DOWNLOAD_DIR="${REPO_ROOT}/.toolchain-downloads"

# Default values
TOOLCHAIN_URL="${TOOLCHAIN_URL:-}"
LOCAL_ARCHIVE=""
CHECKSUM="${TOOLCHAIN_CHECKSUM:-}"
FORCE=false

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Download (or use local archive), verify (optional), extract, and place
the Motorola device toolchain into toolchains/motorola/

Options:
  --url URL              URL to download the toolchain archive
  --local-archive PATH   Use a local archive file instead of downloading
  --checksum HASH        Optional SHA256 checksum to verify the archive
  --force                Force re-extraction even if toolchain exists
  --help                 Show this help message

Environment Variables:
  TOOLCHAIN_URL          Default URL if --url not provided
  TOOLCHAIN_CHECKSUM     Default checksum if --checksum not provided

Examples:
  # Download from URL
  $(basename "$0") --url https://example.com/toolchain.tar.gz

  # Use local archive
  $(basename "$0") --local-archive /path/to/toolchain.tar.gz

  # With checksum verification
  $(basename "$0") --url https://example.com/toolchain.tar.gz --checksum abc123...

  # Force re-extraction
  $(basename "$0") --local-archive toolchain.tar.gz --force

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            TOOLCHAIN_URL="$2"
            shift 2
            ;;
        --local-archive)
            LOCAL_ARCHIVE="$2"
            shift 2
            ;;
        --checksum)
            CHECKSUM="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate inputs
if [[ -z "$TOOLCHAIN_URL" && -z "$LOCAL_ARCHIVE" ]]; then
    log_error "Either --url or --local-archive must be provided (or TOOLCHAIN_URL environment variable)"
    usage
fi

if [[ -n "$TOOLCHAIN_URL" && -n "$LOCAL_ARCHIVE" ]]; then
    log_error "Cannot specify both --url and --local-archive"
    usage
fi

# Check if toolchain already exists
if [[ -d "$TOOLCHAIN_DIR" && -n "$(find "$TOOLCHAIN_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    if [[ "$FORCE" != "true" ]]; then
        log_info "Toolchain already exists at: $TOOLCHAIN_DIR"
        log_info "Use --force to re-extract"
        exit 0
    else
        log_warn "Removing existing toolchain (--force specified)"
        rm -rf "$TOOLCHAIN_DIR"
    fi
fi

# Create necessary directories
mkdir -p "$TOOLCHAIN_DIR"
mkdir -p "$DOWNLOAD_DIR"

# Determine archive path
if [[ -n "$LOCAL_ARCHIVE" ]]; then
    # Use local archive
    if [[ ! -f "$LOCAL_ARCHIVE" ]]; then
        log_error "Local archive not found: $LOCAL_ARCHIVE"
        exit 1
    fi
    ARCHIVE_PATH="$LOCAL_ARCHIVE"
    log_info "Using local archive: $ARCHIVE_PATH"
else
    # Download from URL
    ARCHIVE_FILENAME="$(basename "$TOOLCHAIN_URL")"
    ARCHIVE_PATH="${DOWNLOAD_DIR}/${ARCHIVE_FILENAME}"
    
    log_info "Downloading toolchain from: $TOOLCHAIN_URL"
    
    # Download with curl or wget
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$ARCHIVE_PATH" "$TOOLCHAIN_URL" || {
            log_error "Failed to download toolchain"
            exit 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$ARCHIVE_PATH" "$TOOLCHAIN_URL" || {
            log_error "Failed to download toolchain"
            exit 1
        }
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    log_info "Downloaded to: $ARCHIVE_PATH"
fi

# Verify checksum if provided
if [[ -n "$CHECKSUM" ]]; then
    log_info "Verifying checksum..."
    
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL_CHECKSUM=$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        ACTUAL_CHECKSUM=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')
    else
        log_warn "No checksum utility found (sha256sum or shasum). Skipping verification."
        ACTUAL_CHECKSUM=""
    fi
    
    if [[ -n "$ACTUAL_CHECKSUM" ]]; then
        if [[ "$ACTUAL_CHECKSUM" == "$CHECKSUM" ]]; then
            log_info "Checksum verified successfully"
        else
            log_error "Checksum mismatch!"
            log_error "Expected: $CHECKSUM"
            log_error "Actual:   $ACTUAL_CHECKSUM"
            exit 1
        fi
    fi
fi

# Detect archive type and extract
log_info "Extracting toolchain to: $TOOLCHAIN_DIR"

ARCHIVE_LOWER=$(echo "$ARCHIVE_PATH" | tr '[:upper:]' '[:lower:]')

if [[ "$ARCHIVE_LOWER" == *.tar.gz || "$ARCHIVE_LOWER" == *.tgz ]]; then
    tar -xzf "$ARCHIVE_PATH" -C "$TOOLCHAIN_DIR" --strip-components=1 || {
        log_error "Failed to extract tar.gz archive"
        exit 1
    }
elif [[ "$ARCHIVE_LOWER" == *.tar.bz2 || "$ARCHIVE_LOWER" == *.tbz2 ]]; then
    tar -xjf "$ARCHIVE_PATH" -C "$TOOLCHAIN_DIR" --strip-components=1 || {
        log_error "Failed to extract tar.bz2 archive"
        exit 1
    }
elif [[ "$ARCHIVE_LOWER" == *.tar.xz || "$ARCHIVE_LOWER" == *.txz ]]; then
    tar -xJf "$ARCHIVE_PATH" -C "$TOOLCHAIN_DIR" --strip-components=1 || {
        log_error "Failed to extract tar.xz archive"
        exit 1
    }
elif [[ "$ARCHIVE_LOWER" == *.zip ]]; then
    if command -v unzip >/dev/null 2>&1; then
        # Extract to temporary directory first
        TEMP_EXTRACT="${DOWNLOAD_DIR}/temp-extract-$$"
        mkdir -p "$TEMP_EXTRACT"
        unzip -q "$ARCHIVE_PATH" -d "$TEMP_EXTRACT" || {
            log_error "Failed to extract zip archive"
            rm -rf "$TEMP_EXTRACT"
            exit 1
        }
        # Move contents (strip top level if single directory)
        shopt -s dotglob nullglob
        EXTRACTED_ITEMS=("$TEMP_EXTRACT"/*)
        if [[ ${#EXTRACTED_ITEMS[@]} -eq 1 && -d "${EXTRACTED_ITEMS[0]}" ]]; then
            mv "${EXTRACTED_ITEMS[0]}"/* "$TOOLCHAIN_DIR/" 2>/dev/null || true
            mv "${EXTRACTED_ITEMS[0]}"/.[!.]* "$TOOLCHAIN_DIR/" 2>/dev/null || true
        else
            mv "$TEMP_EXTRACT"/* "$TOOLCHAIN_DIR/" 2>/dev/null || true
            mv "$TEMP_EXTRACT"/.[!.]* "$TOOLCHAIN_DIR/" 2>/dev/null || true
        fi
        shopt -u dotglob nullglob
        rm -rf "$TEMP_EXTRACT"
    else
        log_error "unzip command not found. Please install unzip to extract .zip archives."
        exit 1
    fi
else
    log_error "Unsupported archive format: $ARCHIVE_PATH"
    log_error "Supported formats: .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz, .zip"
    exit 1
fi

log_info "Toolchain extracted successfully"

# Verify extraction
if [[ ! -d "$TOOLCHAIN_DIR" || -z "$(find "$TOOLCHAIN_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    log_error "Toolchain directory is empty after extraction"
    exit 1
fi

# Show toolchain contents summary
log_info "Toolchain contents:"
find "$TOOLCHAIN_DIR" -maxdepth 1 -ls 2>/dev/null | head -10

# Find compiler binaries
COMPILERS=$(find "$TOOLCHAIN_DIR" -type f -name "*-gcc" -o -name "*-g++" -o -name "clang*" 2>/dev/null | head -5)
if [[ -n "$COMPILERS" ]]; then
    log_info "Found compiler binaries:"
    echo "$COMPILERS"
fi

log_info "Toolchain setup complete!"
log_info "Toolchain location: $TOOLCHAIN_DIR"

# Show usage hint
cat << EOF

${GREEN}Next steps:${NC}
  1. Add the toolchain to your PATH:
     export PATH="${TOOLCHAIN_DIR}/bin:\$PATH"
  
  2. Set CROSS_COMPILE environment variable (adjust as needed):
     export CROSS_COMPILE=aarch64-linux-android-
  
  3. Build your kernel or modules

EOF

exit 0
