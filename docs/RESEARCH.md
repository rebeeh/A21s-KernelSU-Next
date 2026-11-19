# Technical Research & Kernel Engineering Report

This document records the full research, kernel debugging, and implementation methodology behind bringing **KernelSU-Next** to the **Samsung Galaxy A21s (`SM-A217F` / Exynos 850)** on **LineageOS 24 (Linux 4.19.325)**.

---

## 1. Background & The Non-GKI Challenge

Android 12+ introduced GKI (Generic Kernel Image) 2.0 with standard kernel modules (KMI). However, devices running Linux 4.19 (such as Exynos 850, 9611, Snapdragon 660/845) are **non-GKI** or **GKI 1.0**.

Upstream KernelSU dropped official support for non-GKI devices. The **KernelSU-Next** project was created to maintain non-GKI legacy trees via its dedicated `legacy` branch.

---

## 2. Root Cause Analysis: Why Dynamic Kprobes Fail on Samsung Exynos

When compiling KernelSU-Next with default dynamic kprobes (`CONFIG_KSU_KPROBES_HOOK=y`), the device bootloops immediately.

By booting into Lineage Recovery and inspecting the kernel crash dump preserved in `pstore`:
```bash
adb shell cat /sys/fs/pstore/dmesg-ramoops-0
```
We captured the fatal hardware trap:
```
[ 1.196687] [0: irq/160-tzasc: 69] irq-160 : 1 tzasc
```

### The Mechanism
1. **Dynamic Kprobes:** Kprobes dynamically patches kernel instructions in memory at runtime, writing breakpoint instructions (`BRK` / `AARCH64_BREAK_MON`) into system call routines (`do_execve`, `vfs_read`).
2. **Samsung TZASC & RKP Protection:** The Samsung Exynos 850 hardware includes the **TrustZone Address Space Controller (TZASC)**. TZASC enforces memory isolation between the Secure World (EL3/EL1 TrustZone) and Non-Secure World (Linux kernel).
3. **The Collision:** Any runtime attempt to modify executable kernel code space in DRAM is intercepted by TZASC as an unauthorized code modification attack. TZASC fires hardware interrupt 160 (`irq/160-tzasc`), halting the CPU and forcing a watchdog kernel panic.

---

## 3. The Solution: Compile-Time Manual Hooks

Instead of patching running memory, **Manual Hook Mode (`CONFIG_KSU_MANUAL_HOOK=y`)** places direct, static C function calls into the kernel source tree before compilation.

Because Clang compiles these into normal branch instructions (`BL`), no memory is ever altered dynamically. The CPU runs normal instructions, completely complying with Samsung TrustZone security boundaries.

### The 5 Core Manual Hooks

1. **`fs/exec.c` (`do_execve` & `compat_do_execve`):**
   ```c
   #ifdef CONFIG_KSU_MANUAL_HOOK
   extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
               void *envp, int *flags);
   ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
   #endif
   ```
   *Purpose:* Intercepts requests to execute `/system/bin/su` and elevates authorized caller contexts to root (`u:r:su:s0`).

2. **`fs/open.c` (`faccessat`):**
   ```c
   #ifdef CONFIG_KSU_MANUAL_HOOK
   extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
               int *flags);
   ksu_handle_faccessat(&dfd, &filename, &mode, NULL);
   #endif
   ```
   *Purpose:* Intercepts permission checks from root-seeking applications checking for `/system/bin/su`.

3. **`fs/read_write.c` (`SYSCALL_DEFINE3(read)`):**
   ```c
   #ifdef CONFIG_KSU_MANUAL_HOOK
   extern int ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr, size_t *count_ptr);
   ksu_handle_sys_read(fd, &buf, &count);
   #endif
   ```
   *Purpose:* Monitors file read operations for safe allowlist lookups.

4. **`fs/stat.c` (`SYSCALL_DEFINE4(newfstatat)`):**
   ```c
   #ifdef CONFIG_KSU_MANUAL_HOOK
   extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
   ksu_handle_stat(&dfd, &filename, &flag);
   #endif
   ```
   *Purpose:* Fakes inode existence of `/system/bin/su` for authorized apps.

5. **`kernel/reboot.c` (`SYSCALL_DEFINE4(reboot)`):**
   ```c
   #ifdef CONFIG_KSU_MANUAL_HOOK
   extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);
   ksu_handle_sys_reboot(magic1, magic2, cmd, &arg);
   #endif
   ```
   *Purpose:* Intercepts reboot magics (`0xDEADBEEF` / `0xCAFEBABE`) to allow the userspace daemon (`ksud`) to install kernel driver file descriptors.

---

## 4. Protocol Lockstep: The UAPI Version Contract

KernelSU-Next uses a supercall IOCTL interface defined in `uapi/supercall.h`.

When Manager app (`com.rifsxd.ksunext`) calls `get_kernel_uapi_version()`, it evaluates:
```kotlin
val requiresNewManager = isManager && kernelUAPIVersion != null && managerUAPIVersion < kernelUAPIVersion
if (requiresNewManager) {
    WarningCard(...) // Shows: "manager version 5 is too low for KernelSU-Next..."
}
```
And:
```kotlin
fun isFullFeatured(): Boolean {
    return isManager && kernelUAPIVersion == managerUAPIVersion && rootAvailable()
}
```

- Upstream `origin/legacy` HEAD bumped `KERNEL_SU_UAPI_VERSION` from 5 to 6 for module preinit actions.
- However, the latest official stable Manager APK is **`v3.4.2 (33355-5)`**, which is built for **UAPI 5**.
- When the kernel returns UAPI 6, the manager detects an ABI mismatch and disables the Superuser and Module management tabs.
- Setting `#define KERNEL_SU_UAPI_VERSION 5` establishes 100% protocol lockstep with Manager `v3.4.2` and its embedded `ksud 3.4.2 (uapi: 5)`.

---

## 5. Kernel Backports

### `path_umount` (`fs/namespace.c`)
KernelSU's `kernel_umount` feature unmounts module overlay filesystems for non-root apps to prevent root detection. Linux 4.19 lacks `path_umount` (added in Linux 5.9). We backported:
```c
static int can_umount(const struct path *path, int flags);
int path_umount(struct path *path, int flags);
```
This enables module mount hiding without kernel crashes.

---

## 6. Upstream Kernel Tree: `samsungexynos850/android_kernel_samsung_exynos850`

- **URL:** [https://github.com/samsungexynos850/android_kernel_samsung_exynos850](https://github.com/samsungexynos850/android_kernel_samsung_exynos850)
- **Branch:** `lineage-24.0` (Linux 4.19.325, HEAD commit `b8c71b7aecec`)

### Role in Development:
This is the verified kernel source tree maintaining the `lineage-24.0` branch for Exynos 850 devices (Galaxy A21s). It integrates the official Samsung vendor BSP (`universal850`) updated for modern Android 17 (SDK 37) LineageOS userland, Binder IPC, and device drivers.

All KernelSU-Next patches in `patches/` apply cleanly onto commit `b8c71b7aecec` of this tree.

---

## 7. LineageOS Device Tree Alignment (`android_device_samsung_a21s`)

- **URL:** [https://github.com/LineageOS/android_device_samsung_a21s](https://github.com/LineageOS/android_device_samsung_a21s)

The device tree defines key board configurations that dictated our build and packaging pipeline:
1. **Partition Geometry:**
   - `BOARD_BOOTIMAGE_PARTITION_SIZE := 37748736` (exact 36 MiB limit). Boot images exceeding 36 MiB will fail partition verification or overwrite neighboring partitions.
2. **Boot Header Specifications:**
   - `BOARD_BOOT_HEADER_VERSION := 2`: Uses header version 2 with separate DTB and ramdisk sections.
   - `BOARD_KERNEL_PAGESIZE := 2048`: Dictates page alignment during `magiskboot repack`.
3. **Storage Partitioning:**
   - Samsung Galaxy A21s is an **A-only** device (single system/boot slot; not A/B).
   - Boot partition block path: `/dev/block/by-name/boot`.
   - These parameters were directly mapped into `tools/anykernel3/anykernel.sh` (`block=/dev/block/by-name/boot; is_slot_device=0;`) to ensure recovery flashing works autonomously.

---

## 8. Build Workspace Hierarchy & Repository Separation

### Why Separate the Build Workspace from the Git Repository?
- The full Linux kernel source (`a21s-kernel`) and git history exceeds **2.5 GB**.
- The Android Clang toolchain (`clang-r416183b`) is **1.5 GB**.
- Storing these massive trees inside the GitHub repository would make cloning unbearably slow and violate GitHub repository size limits (recommended < 1 GB, hard limit 2 GB).

### The Solution: Overlay Architecture
- **Distribution Repository (`rebeeh/A21s-KernelSU-Next`):**
  A lightweight (~1 MB) repository containing our reproducible patches (`patches/`), validated defconfig (`configs/a21s_ksu_defconfig`), AnyKernel3 packager, CI automation, and documentation.
- **Local / CI Build Directory (`build/` or `~/Android/Kernel/`):**
  An external workspace where the heavy upstream kernel and toolchain are cloned by `scripts/setup_env.sh` or GitHub Actions CI. The repository's patches and defconfig are applied on top of the upstream tree cleanly before compiling.

