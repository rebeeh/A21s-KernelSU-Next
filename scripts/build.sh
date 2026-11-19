#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# A21s KernelSU-Next Build & Repack System
# Target Device: Samsung Galaxy A21s (SM-A217F)
# Platform: Samsung Exynos 850 (universal850)
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${HOME}/Android/Kernel}"
KERNEL_DIR="${KERNEL_DIR:-${WORK_DIR}/a21s-kernel}"
TOOLCHAIN_BIN="${TOOLCHAIN_BIN:-${WORK_DIR}/toolchain/clang-r416183b/bin}"
TOOLS_DIR="${TOOLS_DIR:-${WORK_DIR}/tools}"
CONFIG_FILE="${PROJECT_ROOT}/configs/a21s_ksu_defconfig"
OUT_DIR="${OUT_DIR:-${WORK_DIR}/out}"

# Detect stock boot.img
STOCK_BOOT="${STOCK_BOOT:-}"
if [ -z "${STOCK_BOOT}" ]; then
    if [ -f "/home/ebiza/Downloads/lineage os/lineage-24.0-20261117-nightly-a21s-signed/boot.img" ]; then
        STOCK_BOOT="/home/ebiza/Downloads/lineage os/lineage-24.0-20261117-nightly-a21s-signed/boot.img"
    elif [ -f "${WORK_DIR}/stock/boot.img" ]; then
        STOCK_BOOT="${WORK_DIR}/stock/boot.img"
    fi
fi

echo "=================================================="
echo " Building KernelSU-Next for Galaxy A21s (Exynos 850)"
echo " Kernel Dir:    ${KERNEL_DIR}"
echo " Toolchain:     ${TOOLCHAIN_BIN}"
echo " Output Dir:    ${OUT_DIR}"
echo "=================================================="

# Check toolchain
if [ ! -f "${TOOLCHAIN_BIN}/clang" ]; then
    echo "[-] Error: Clang binary not found at ${TOOLCHAIN_BIN}/clang"
    echo "    Run '${PROJECT_ROOT}/scripts/setup_env.sh' first."
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

# Step 1: Kernel Build
echo "[+] Step 1: Compiling kernel Image using $(nproc) threads..."
make -j"$(nproc)" Image

IMAGE="${KERNEL_DIR}/arch/arm64/boot/Image"
if [ ! -f "${IMAGE}" ]; then
    echo "[-] Error: Compilation failed. Image not found!"
    exit 1
fi
echo "[✓] Kernel compiled successfully: $(ls -lh "${IMAGE}" | awk '{print $5}')"

# Step 2: Repack boot.img
mkdir -p "${OUT_DIR}/repack"
if [ -n "${STOCK_BOOT}" ] && [ -f "${STOCK_BOOT}" ]; then
    echo "[+] Step 2: Repacking boot.img using ${STOCK_BOOT}..."
    cd "${OUT_DIR}/repack"
    rm -rf ./*
    "${TOOLS_DIR}/magiskboot" unpack "${STOCK_BOOT}"
    cp "${IMAGE}" ./kernel
    "${TOOLS_DIR}/magiskboot" repack "${STOCK_BOOT}" "${OUT_DIR}/boot-ksu.img"
    echo "[✓] Created: ${OUT_DIR}/boot-ksu.img"

    # Step 3: Create Odin-flashable tar
    echo "[+] Step 3: Creating Odin boot.tar archive..."
    cd "${OUT_DIR}"
    tar -cvf "${OUT_DIR}/boot-ksu.tar" boot-ksu.img
    echo "[✓] Created: ${OUT_DIR}/boot-ksu.tar"

    # Step 4: Package AnyKernel3 Zip
    echo "[+] Step 4: Creating AnyKernel3 recovery zip..."
    bash "${PROJECT_ROOT}/scripts/package_anykernel3.sh"
else
    echo "[!] Warning: Stock boot.img not found. Copied bare Image to out directory."
    cp "${IMAGE}" "${OUT_DIR}/Image"
    bash "${PROJECT_ROOT}/scripts/package_anykernel3.sh"
fi

echo "=================================================="
echo " BUILD COMPLETE!"
echo " Artifacts:"
ls -lh "${OUT_DIR}/boot-ksu.img" "${OUT_DIR}/boot-ksu.tar" "${OUT_DIR}/"*.zip 2>/dev/null || true
echo "=================================================="
