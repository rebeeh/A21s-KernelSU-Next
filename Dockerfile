# syntax=docker/dockerfile:1
# ==============================================================================
# Platform-Independent OCI Docker Container for A21s KernelSU-Next
# Runs identically on Linux, macOS (Intel & Apple Silicon), and Windows.
# ==============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ARCH=arm64
ENV LLVM=1
ENV LLVM_IAS=1
ENV CROSS_COMPILE=aarch64-linux-gnu-

WORKDIR /workspace

# 1. Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    curl \
    flex \
    git \
    gnupg \
    gperf \
    libelf-dev \
    libssl-dev \
    lz4 \
    libncurses5-dev \
    pkg-config \
    python3 \
    rsync \
    tar \
    unzip \
    zip \
    zlib1g-dev \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone official LineageOS Clang toolchain
RUN git clone --depth=1 https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git /workspace/toolchain/clang-r416183b

ENV PATH="/workspace/toolchain/clang-r416183b/bin:${PATH}"

# 3. Download standalone magiskboot
RUN mkdir -p /workspace/tools && \
    curl -sL "https://github.com/magiskboot-x86_64/magiskboot/releases/latest/download/magiskboot" -o /workspace/tools/magiskboot && \
    chmod +x /workspace/tools/magiskboot

# 4. Clone LineageOS 24 kernel tree & KernelSU-Next
RUN git clone -b lineage-24.0 --depth=1 https://github.com/samsungexynos850/android_kernel_samsung_exynos850.git /workspace/a21s-kernel && \
    cd /workspace/a21s-kernel && \
    git clone -b legacy --depth=1 https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU-Next && \
    ln -sf ../KernelSU-Next/kernel drivers/kernelsu

# 5. Copy patches and defconfig from repository context
COPY patches/ /workspace/patches/
COPY configs/ /workspace/configs/
COPY tools/anykernel3/ /workspace/tools/anykernel3/
COPY scripts/ /workspace/scripts/
COPY build.py /workspace/build.py

# 6. Apply patches and install defconfig
RUN cd /workspace/a21s-kernel && \
    git apply /workspace/patches/0001-build-host-openssl-3-compat.patch && \
    git apply /workspace/patches/0002-kernelsu-manual-hooks-and-backports.patch && \
    cd KernelSU-Next && \
    git apply /workspace/patches/0003-kernelsu-next-samsung-fixes.patch && \
    cp /workspace/configs/a21s_ksu_defconfig /workspace/a21s-kernel/.config

VOLUME ["/workspace/out"]

# Entrypoint compiles Image, creates AnyKernel3 zip, and repacks boot-ksu.img/boot-ksu.tar if boot.img is provided
CMD ["bash", "-c", "cd /workspace && ./scripts/build.sh ${STOCK_BOOT:-boot.img}"]
