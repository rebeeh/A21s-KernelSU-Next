#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# AnyKernel3 Packaging Script for Samsung Galaxy A21s
# Creates a complete recovery-flashable ZIP (osm0sis base + A21s anykernel.sh)!
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${PROJECT_ROOT}/build}"
OUT_DIR="${OUT_DIR:-${PROJECT_ROOT}/out}"
AK3_BASE_DIR="${AK3_BASE_DIR:-${WORK_DIR}/anykernel3}"
AK3_OVERLAY_DIR="${PROJECT_ROOT}/tools/anykernel3"

KERNEL_IMAGE="${KERNEL_IMAGE:-}"
if [ -z "${KERNEL_IMAGE}" ]; then
    if [ -f "${WORK_DIR}/a21s-kernel/arch/arm64/boot/Image" ]; then
        KERNEL_IMAGE="${WORK_DIR}/a21s-kernel/arch/arm64/boot/Image"
    elif [ -f "${PROJECT_ROOT}/a21s-kernel/arch/arm64/boot/Image" ]; then
        KERNEL_IMAGE="${PROJECT_ROOT}/a21s-kernel/arch/arm64/boot/Image"
    elif [ -f "${OUT_DIR}/Image" ]; then
        KERNEL_IMAGE="${OUT_DIR}/Image"
    elif [ -f "Image" ]; then
        KERNEL_IMAGE="$(pwd)/Image"
    fi
fi

if [ -z "${KERNEL_IMAGE}" ] || [ ! -f "${KERNEL_IMAGE}" ]; then
    echo "[-] Error: Kernel Image not found!"
    echo "    Run ./scripts/build.sh first or pass KERNEL_IMAGE=/path/to/Image."
    exit 1
fi

if [ ! -f "${AK3_BASE_DIR}/META-INF/com/google/android/update-binary" ]; then
    echo "[+] Cloning osm0sis/AnyKernel3 base runtime into ${AK3_BASE_DIR}..."
    mkdir -p "$(dirname "${AK3_BASE_DIR}")"
    rm -rf "${AK3_BASE_DIR}"
    git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "${AK3_BASE_DIR}"
fi

mkdir -p "${OUT_DIR}"
BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

echo "[+] Staging AnyKernel3 runtime from ${AK3_BASE_DIR}..."
cp -r "${AK3_BASE_DIR}/META-INF" "${BUILD_TMP}/"
cp -r "${AK3_BASE_DIR}/tools" "${BUILD_TMP}/"
[ -d "${AK3_BASE_DIR}/modules" ] && cp -r "${AK3_BASE_DIR}/modules" "${BUILD_TMP}/" || true
[ -d "${AK3_BASE_DIR}/ramdisk" ] && cp -r "${AK3_BASE_DIR}/ramdisk" "${BUILD_TMP}/" || true
[ -d "${AK3_BASE_DIR}/patch" ] && cp -r "${AK3_BASE_DIR}/patch" "${BUILD_TMP}/" || true

echo "[+] Overlaying A21s anykernel.sh configuration..."
cp -f "${AK3_OVERLAY_DIR}/anykernel.sh" "${BUILD_TMP}/anykernel.sh"
chmod 755 "${BUILD_TMP}/anykernel.sh"

echo "[+] Staging kernel Image from ${KERNEL_IMAGE}..."
cp "${KERNEL_IMAGE}" "${BUILD_TMP}/Image"

ZIP_NAME="KernelSU-Next-A21s-universal850-AnyKernel3.zip"
rm -f "${OUT_DIR}/${ZIP_NAME}"
echo "[+] Creating flashable zip: ${OUT_DIR}/${ZIP_NAME}..."
cd "${BUILD_TMP}"
zip -r9 "${OUT_DIR}/${ZIP_NAME}" . -x "*.git*" "*placeholder"

echo "[✓] Successfully created AnyKernel3 zip:"
ls -lh "${OUT_DIR}/${ZIP_NAME}"
