#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# AnyKernel3 Packaging Script for Samsung Galaxy A21s
# Creates a recovery-flashable ZIP that patches the kernel on-device!
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${PROJECT_ROOT}/build}"
OUT_DIR="${OUT_DIR:-${PROJECT_ROOT}/out}"

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

AK3_DIR="${PROJECT_ROOT}/tools/anykernel3"

if [ -z "${KERNEL_IMAGE}" ] || [ ! -f "${KERNEL_IMAGE}" ]; then
    echo "[-] Error: Kernel Image not found!"
    echo "    Run ./scripts/build.sh first or pass KERNEL_IMAGE=/path/to/Image."
    exit 1
fi

mkdir -p "${OUT_DIR}"
BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

echo "[+] Copying AnyKernel3 template..."
cp -r "${AK3_DIR}"/* "${BUILD_TMP}/"

echo "[+] Staging kernel Image from ${KERNEL_IMAGE}..."
cp "${KERNEL_IMAGE}" "${BUILD_TMP}/Image"

ZIP_NAME="KernelSU-Next-A21s-universal850-AnyKernel3.zip"
echo "[+] Creating flashable zip: ${OUT_DIR}/${ZIP_NAME}..."
cd "${BUILD_TMP}"
zip -r9 "${OUT_DIR}/${ZIP_NAME}" ./* -x "*.git*" "README.md" "*placeholder"

echo "[✓] Successfully created AnyKernel3 zip:"
ls -lh "${OUT_DIR}/${ZIP_NAME}"
