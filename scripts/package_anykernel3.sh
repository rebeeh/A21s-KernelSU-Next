#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# AnyKernel3 Packaging Script for Samsung Galaxy A21s
# Creates a recovery-flashable ZIP that patches the kernel on-device!
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${HOME}/Android/Kernel}"
KERNEL_IMAGE="${WORK_DIR}/a21s-kernel/arch/arm64/boot/Image"
AK3_DIR="${PROJECT_ROOT}/tools/anykernel3"
OUT_DIR="${WORK_DIR}/out"

if [ ! -f "${KERNEL_IMAGE}" ]; then
    echo "[-] Error: Kernel Image not found at ${KERNEL_IMAGE}"
    echo "    Run ./scripts/build.sh first!"
    exit 1
fi

mkdir -p "${OUT_DIR}"
BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

echo "[+] Copying AnyKernel3 template..."
cp -r "${AK3_DIR}"/* "${BUILD_TMP}/"

echo "[+] Staging kernel Image..."
cp "${KERNEL_IMAGE}" "${BUILD_TMP}/Image"

ZIP_NAME="KernelSU-Next-A21s-universal850-AnyKernel3.zip"
echo "[+] Creating flashable zip: ${OUT_DIR}/${ZIP_NAME}..."
cd "${BUILD_TMP}"
zip -r9 "${OUT_DIR}/${ZIP_NAME}" ./* -x "*.git*" "README.md" "*placeholder"

echo "[✓] Successfully created AnyKernel3 zip:"
ls -lh "${OUT_DIR}/${ZIP_NAME}"
