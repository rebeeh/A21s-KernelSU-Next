#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Environment Setup Script for A21s KernelSU-Next
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${PROJECT_ROOT}/build}"
TOOLCHAIN_DIR="${WORK_DIR}/toolchain/clang-r416183b"
TOOLS_DIR="${WORK_DIR}/tools"
KERNEL_DIR="${WORK_DIR}/a21s-kernel"

echo "=== A21s KernelSU-Next Environment Setup ==="
echo "Project Root: ${PROJECT_ROOT}"
echo "Build Root:   ${WORK_DIR}"

# 1. Ensure required directories
mkdir -p "${WORK_DIR}/toolchain" "${TOOLS_DIR}" "${PROJECT_ROOT}/out"

# 2. Toolchain Setup (LineageOS / Android Clang r416183b)
if [ ! -d "${TOOLCHAIN_DIR}/bin" ]; then
    echo "[+] Cloning prebuilt Clang r416183b toolchain..."
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git "${TOOLCHAIN_DIR}"
else
    echo "[✓] Toolchain clang-r416183b found."
fi

# 3. magiskboot Setup
if [ ! -f "${TOOLS_DIR}/magiskboot" ]; then
    echo "[+] Setting up magiskboot..."
    curl -sL "https://github.com/magiskboot-x86_64/magiskboot/releases/latest/download/magiskboot" -o "${TOOLS_DIR}/magiskboot" 2>/dev/null || true
    chmod +x "${TOOLS_DIR}/magiskboot"
else
    echo "[✓] magiskboot tool found."
fi

# 4. Kernel Source Setup
if [ ! -d "${KERNEL_DIR}" ]; then
    echo "[+] Kernel directory not found at ${KERNEL_DIR}."
    echo "[*] Cloning the Exynos 850 LineageOS kernel tree (lineage-24.0)..."
    git clone -b lineage-24.0 --depth=1 https://github.com/samsungexynos850/android_kernel_samsung_exynos850.git "${KERNEL_DIR}"
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

if git apply --check "${PROJECT_ROOT}/patches/0004-susfs-v1.5.5-kernel-4.19.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0004-susfs-v1.5.5-kernel-4.19.patch"
    echo "[✓] Applied 0004-susfs-v1.5.5-kernel-4.19.patch"
fi

cd "${KERNEL_DIR}/KernelSU-Next"
if git apply --check "${PROJECT_ROOT}/patches/0003-kernelsu-next-samsung-fixes.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0003-kernelsu-next-samsung-fixes.patch"
    echo "[✓] Applied 0003-kernelsu-next-samsung-fixes.patch"
fi

if git apply --check "${PROJECT_ROOT}/patches/0005-kernelsu-next-susfs-integration.patch" 2>/dev/null; then
    git apply "${PROJECT_ROOT}/patches/0005-kernelsu-next-susfs-integration.patch"
    echo "[✓] Applied 0005-kernelsu-next-susfs-integration.patch"
fi

echo "[✓] Environment is fully configured and ready for compilation!"
