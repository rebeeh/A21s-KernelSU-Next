#!/usr/bin/env bash
set -euo pipefail

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${HOME}/Android/Kernel"
TOOLCHAIN_DIR="${WORK_DIR}/toolchain/clang-r416183b"
TOOLS_DIR="${WORK_DIR}/tools"
KERNEL_DIR="${WORK_DIR}/a21s-kernel"

echo "=== A21s KernelSU-Next Environment Setup ==="

# 1. Ensure required directories
mkdir -p "${WORK_DIR}/toolchain" "${TOOLS_DIR}" "${WORK_DIR}/out"

# 2. Toolchain Setup (LineageOS / Android Clang r416183b)
if [ ! -d "${TOOLCHAIN_DIR}/bin" ]; then
    echo "[+] Cloning prebuilt Clang r416183b toolchain..."
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r416183b.tar.gz "${WORK_DIR}/toolchain/clang-archive" || true
    if [ ! -f "${TOOLCHAIN_DIR}/bin/clang" ]; then
        echo "[+] Alternative: Cloning from LineageOS GitLab mirror..."
        git clone --depth=1 https://gitlab.com/rebeeh/clang-r416183b.git "${TOOLCHAIN_DIR}" || \
        git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/clang-r416183b "${TOOLCHAIN_DIR}"
    fi
else
    echo "[✓] Toolchain clang-r416183b found."
fi

# 3. magiskboot Setup
if [ ! -f "${TOOLS_DIR}/magiskboot" ]; then
    echo "[+] Setting up magiskboot..."
    # Download standalone prebuilt magiskboot for Linux x86_64
    curl -L "https://github.com/magiskboot-x86_64/magiskboot/releases/latest/download/magiskboot" -o "${TOOLS_DIR}/magiskboot" 2>/dev/null || true
    chmod +x "${TOOLS_DIR}/magiskboot"
else
    echo "[✓] magiskboot tool found."
fi

# 4. Kernel Source Setup
if [ ! -d "${KERNEL_DIR}" ]; then
    echo "[+] Kernel directory not found at ${KERNEL_DIR}."
    echo "[*] Please clone the LineageOS kernel tree into ${KERNEL_DIR}:"
    echo "    git clone -b lineage-24.0 https://github.com/LineageOS/android_kernel_samsung_universal850.git ${KERNEL_DIR}"
    exit 0
fi

# 5. KernelSU-Next Legacy Setup
if [ ! -d "${KERNEL_DIR}/KernelSU-Next" ]; then
    echo "[+] Cloning KernelSU-Next legacy branch..."
    git clone -b legacy --depth=1 https://github.com/KernelSU-Next/KernelSU-Next.git "${KERNEL_DIR}/KernelSU-Next"
fi

if [ ! -L "${KERNEL_DIR}/drivers/kernelsu" ]; then
    echo "[+] Symlinking drivers/kernelsu..."
    ln -sf "${KERNEL_DIR}/KernelSU-Next/kernel" "${KERNEL_DIR}/drivers/kernelsu"
fi

# 6. Apply Patches
echo "[+] Checking and applying patches..."
cd "${KERNEL_DIR}"
if git apply --check "${PROJECT_ROOT}/patches/0001-build-host-openssl-3-compat.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0001-build-host-openssl-3-compat.patch"
    echo "[✓] Applied 0001-build-host-openssl-3-compat.patch"
fi

if git apply --check "${PROJECT_ROOT}/patches/0002-kernelsu-manual-hooks-and-backports.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0002-kernelsu-manual-hooks-and-backports.patch"
    echo "[✓] Applied 0002-kernelsu-manual-hooks-and-backports.patch"
fi

cd "${KERNEL_DIR}/KernelSU-Next"
if git apply --check "${PROJECT_ROOT}/patches/0003-kernelsu-next-samsung-fixes.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0003-kernelsu-next-samsung-fixes.patch"
    echo "[✓] Applied 0003-kernelsu-next-samsung-fixes.patch"
fi

echo "[✓] Environment is fully configured and ready for compilation!"
