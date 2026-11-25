#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# A21s KernelSU-Next Build & Repack System
# Target Device: Samsung Galaxy A21s (SM-A217F)
# Platform: Samsung Exynos 850 (universal850)
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${PROJECT_ROOT}/build}"
KERNEL_DIR="${KERNEL_DIR:-${WORK_DIR}/a21s-kernel}"
TOOLCHAIN_BIN="${TOOLCHAIN_BIN:-${WORK_DIR}/toolchain/clang-r416183b/bin}"
TOOLS_DIR="${TOOLS_DIR:-${WORK_DIR}/tools}"
CONFIG_FILE="${PROJECT_ROOT}/configs/a21s_ksu_defconfig"
OUT_DIR="${OUT_DIR:-${PROJECT_ROOT}/out}"

# Parse Stock boot.img from argument $1 or standard paths
STOCK_BOOT="${1:-${STOCK_BOOT:-}}"
if [ -z "${STOCK_BOOT}" ]; then
    if [ -f "${PROJECT_ROOT}/boot.img" ]; then
        STOCK_BOOT="${PROJECT_ROOT}/boot.img"
    elif [ -f "boot.img" ]; then
        STOCK_BOOT="$(pwd)/boot.img"
    elif [ -f "${WORK_DIR}/stock/boot.img" ]; then
        STOCK_BOOT="${WORK_DIR}/stock/boot.img"
    fi
fi

echo "=================================================="
echo " Building KernelSU-Next for Galaxy A21s (Exynos 850)"
echo " Kernel Dir:    ${KERNEL_DIR}"
echo " Toolchain:     ${TOOLCHAIN_BIN}"
echo " Output Dir:    ${OUT_DIR}"
if [ -n "${STOCK_BOOT}" ]; then
    echo " Stock Boot:    ${STOCK_BOOT}"
fi
echo "=================================================="

# Check toolchain
if [ ! -f "${TOOLCHAIN_BIN}/clang" ]; then
    echo "[-] Error: Clang binary not found at ${TOOLCHAIN_BIN}/clang"
    echo "    Please run './scripts/setup_env.sh' or set TOOLCHAIN_BIN."
    exit 1
fi

export PATH="${TOOLCHAIN_BIN}:${PATH}"
export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-

cd "${KERNEL_DIR}"

# Ensure .config exists
if [ ! -f "${KERNEL_DIR}/.config" ]; then
    echo "[+] Installing validated defconfig from configs/a21s_ksu_defconfig..."
    cp "${CONFIG_FILE}" "${KERNEL_DIR}/.config"
fi

# Step 1: Kernel Compilation
echo "[+] Step 1: Compiling kernel Image using $(nproc) threads..."
make -j"$(nproc)" Image

IMAGE="${KERNEL_DIR}/arch/arm64/boot/Image"
if [ ! -f "${IMAGE}" ]; then
    echo "[-] Error: Compilation failed. Image not found!"
    exit 1
fi
echo "[✓] Kernel compiled successfully: $(ls -lh "${IMAGE}" | awk '{print $5}')"

mkdir -p "${OUT_DIR}"

# Step 2: Repack boot.img if stock boot.img is available
if [ -n "${STOCK_BOOT}" ] && [ -f "${STOCK_BOOT}" ]; then
    REPACK_TMP=$(mktemp -d)
    trap 'rm -rf "${REPACK_TMP}"' EXIT
    echo "[+] Step 2: Repacking boot.img using ${STOCK_BOOT}..."
    cd "${REPACK_TMP}"
    "${TOOLS_DIR}/magiskboot" unpack "${STOCK_BOOT}"
    cp "${IMAGE}" ./kernel
    "${TOOLS_DIR}/magiskboot" repack "${STOCK_BOOT}" "${OUT_DIR}/boot-ksu.img"
    echo "[✓] Created: ${OUT_DIR}/boot-ksu.img"

    # Step 3: Create Odin-flashable tar
    echo "[+] Step 3: Creating Odin boot-ksu.tar archive..."
    cd "${OUT_DIR}"
    cp -f boot-ksu.img boot.img
    tar -cvf "${OUT_DIR}/boot-ksu.tar" boot.img
    rm -f boot.img
    echo "[✓] Created: ${OUT_DIR}/boot-ksu.tar"

    # Step 4: Package AnyKernel3 Zip
    echo "[+] Step 4: Creating AnyKernel3 recovery zip..."
    bash "${PROJECT_ROOT}/scripts/package_anykernel3.sh"
else
    echo "[!] Notice: No stock boot.img provided. Copied compiled Image to ${OUT_DIR}/Image"
    cp "${IMAGE}" "${OUT_DIR}/Image"
    echo "[+] Creating AnyKernel3 recovery zip from compiled Image..."
    bash "${PROJECT_ROOT}/scripts/package_anykernel3.sh"
fi

echo "=================================================="
echo " BUILD COMPLETE!"
echo " Output files in: ${OUT_DIR}"
ls -lh "${OUT_DIR}/boot-ksu.img" "${OUT_DIR}/boot-ksu.tar" "${OUT_DIR}/"*.zip 2>/dev/null || true
echo "=================================================="