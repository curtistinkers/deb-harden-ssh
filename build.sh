#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
TARGET_INPUT="package"
PROJECT_ROOT="$(pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/build"

# --- Validation ---
if [ -z "${TARGET_INPUT}" ]; then
    echo "Error: Please provide a directory name."
    echo "Usage: $0 <directory_name>"
    exit 1
fi

if [ ! -d "${TARGET_INPUT}" ]; then
    echo "Error: Directory '${TARGET_INPUT}' does not exist."
    exit 1
fi

# Convert to absolute path so cd calls don't break paths
TARGET_DIR="$(cd "${TARGET_INPUT}" && pwd)"

# Ensure it is a valid Debian source directory
if [ ! -d "${TARGET_DIR}/debian" ]; then
    echo "Error: '${TARGET_DIR}' is not a valid Debian package directory (missing 'debian/' folder)."
    exit 1
fi

# Extract the actual package name declared in debian/control
PACKAGE_NAME="$(awk '/^Package:/ {print $2; exit}' "${TARGET_DIR}/debian/control")"

if [ -z "${PACKAGE_NAME}" ]; then
    echo "Error: Could not determine Package name from '${TARGET_DIR}/debian/control'."
    exit 1
fi

# Parent directory where debuild places build artifacts
PARENT_DIR="$(dirname "${TARGET_DIR}")"

# --- Main Logic ---
echo "Starting build process for package: ${PACKAGE_NAME} (Directory: ${TARGET_INPUT})"

# Create output directory for binaries if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

echo "Created output directory for build artifacts: ${OUTPUT_DIR}"

# Navigate into the package directory
cd "${TARGET_DIR}"

echo "Changing to package directory: ${TARGET_DIR}"

# Clean any existing artifacts before build
debuild --no-tgz-check -- clean >/dev/null 2>&1 || true

echo "# Clean any existing artifacts before build"

# Run debuild to create binary package (-b) without signing changes/dsc (-us -uc)
echo "Running debuild..."
debuild -b -us -uc

# Navigate back to project root
cd "${PROJECT_ROOT}"

echo "Moving build artifacts for ${PACKAGE_NAME} to ${OUTPUT_DIR}..."
# Use find to locate artifacts safely without triggering glob-splitting warnings
find "${PARENT_DIR}" -maxdepth 1 -type f -name "${PACKAGE_NAME}_*.deb" -exec mv {} "${OUTPUT_DIR}/" \; 2>/dev/null || true

echo "Cleaning up temporary build logs..."
find "${PARENT_DIR}" -maxdepth 1 -type f \( -name "${PACKAGE_NAME}_*.changes" -o -name "${PACKAGE_NAME}_*.buildinfo" -o -name "${PACKAGE_NAME}_*.build" \) -exec rm -f {} \; 2>/dev/null || true

# --- Final Source Clean ---
echo "Cleaning up source directory..."
cd "${TARGET_DIR}"
debuild --no-tgz-check -- clean >/dev/null 2>&1 || true

echo "Success! Built artifacts are in: ${OUTPUT_DIR}"