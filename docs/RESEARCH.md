[← Documentation Hub](README.md) · [Main README](../README.md)

# Technical Research & Kernel Engineering Report

> Engineering research log documenting every design decision behind **A21s-KernelSU-Next** on the **Samsung Galaxy A21s (`SM-A217F` / Exynos 850)** running **LineageOS 24 (`4.19.325`)** — from TZASC crash dumps through Manual Hooks, Dynamic UAPI, Keymaster DAK SELinux, and SUSFS v1.5.5.

---

## Table of Contents

1. [Background & The Non-GKI Challenge](#1-background--the-non-gki-challenge)
2. [Root Cause Analysis: Why Dynamic Kprobes Fail on Samsung Exynos](#2-root-cause-analysis-why-dynamic-kprobes-fail-on-samsung-exynos)
3. [The Solution: Compile-Time Manual Hooks (5 Source Files / 6 Sites)](#3-the-solution-compile-time-manual-hooks-5-source-files--6-sites)
4. [Protocol Lockstep: The UAPI Version Contract & Dynamic Resolution](#4-protocol-lockstep-the-uapi-version-contract--dynamic-resolution)
5. [Kernel Backports & Keymaster SELinux Embedding](#5-kernel-backports--keymaster-selinux-embedding)
6. [Upstream Kernel Tree (`android_kernel_samsung_exynos850`)](#6-upstream-kernel-tree-android_kernel_samsung_exynos850)
7. [LineageOS Device Tree Alignment (`android_device_samsung_a21s`)](#7-lineageos-device-tree-alignment-android_device_samsung_a21s)
8. [Build Workspace Hierarchy & Repository Separation](#8-build-workspace-hierarchy--repository-separation)
9. [Outcomes & Takeaways](#9-outcomes--takeaways)

---

## Before You Begin

This document is an **engineering research log**, not a flashing walkthrough. For end-user flashing, start at [USER_GUIDE.md](USER_GUIDE.md) or [Main README](../README.md).

| I want to… | Go to… |
| :--- | :--- |
| Understand the `irq/160-tzasc` kprobe crash | [§2 Root Cause Analysis](#2-root-cause-analysis-why-dynamic-kprobes-fail-on-samsung-exynos) |
| Inspect the exact patched C hook sites | [§3 Manual Hooks](#3-the-solution-compile-time-manual-hooks-5-source-files--6-sites) |
| Review the UAPI dynamic engine & DAK SELinux embed | [§4 UAPI Contract](#4-protocol-lockstep-the-uapi-version-contract--dynamic-resolution) · [§5 Backports & SELinux](#5-kernel-backports--keymaster-selinux-embedding) |
| Check Exynos 850 partition limits (`36 MiB` / header v2) | [§7 Device Tree Alignment](#7-lineageos-device-tree-alignment-android_device_samsung_a21s) |

---

## 1. Background & The Non-GKI Challenge

Android 12+ introduced **GKI 2.0** (Generic Kernel Image) for 5.10+ kernels. Devices shipping **Linux 4.19** — such as the Samsung Exynos 850 (`SM-A217F`), Exynos 9611, and Snapdragon 845 — are **non-GKI / GKI 1.0** targets.

Upstream KernelSU ended legacy non-GKI support; **[KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next/tree/legacy)** preserves non-GKI devices through its dedicated `legacy` branch when integrated with clean source hooks.

---

## 2. Root Cause Analysis: Why Dynamic Kprobes Fail on Samsung Exynos

Compiling with dynamic kprobes (`CONFIG_KSU_KPROBES_HOOK=y`) causes an immediate early-boot loop on the Galaxy A21s. Reading preserved kernel panic logs from LineageOS Recovery (`/sys/fs/pstore/dmesg-ramoops-0`) exposes the fatal EL3 hardware trap:

```text
[ 1.196687] [0: irq/160-tzasc: 69] irq-160 : 1 tzasc
```

**Trap sequence:**
1. Dynamic kprobes invoke `patch_text()` to overwrite live kernel `.text` instructions with `BRK` breakpoints on `do_execve`, `vfs_read`, etc.
2. Samsung's **TZASC** (TrustZone Address Space Controller) monitors DRAM transactions across Non-Secure (`EL0`–`EL2`) and Secure (`EL3`) boundaries.
3. Any runtime write into executable kernel pages trips interrupt `160` (`irq/160-tzasc`), halting execution before `init` can start.

> [!CAUTION]
> Never enable `CONFIG_KSU_KPROBES_HOOK=y` on Exynos 850 kernels. Always use `CONFIG_KSU_MANUAL_HOOK=y`.

---

## 3. The Solution: Compile-Time Manual Hooks (5 Source Files / 6 Sites)

All hooks in [`0002-kernelsu-manual-hooks-and-backports.patch`](../patches/0002-kernelsu-manual-hooks-and-backports.patch) are guarded compile-time calls (`BL` instructions emitted by Clang 12), performing **zero runtime text patching**:

1. **`fs/exec.c` (`do_execve` & `compat_do_execve`):** Calls `ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags)` to intercept `su` invocations and transition allowed processes.
2. **`fs/open.c` (`faccessat`):** Calls `ksu_handle_faccessat(&dfd, &filename, &mode, NULL)` so unprivileged root-check probes receive `-ENOENT`.
3. **`fs/read_write.c` (`SYSCALL_DEFINE3(read)`):** Calls `ksu_handle_sys_read(fd, &buf, &count)` to inject `KERNEL_SU_RC` when `init` finishes reading `init.rc`.
4. **`fs/stat.c` (`SYSCALL_DEFINE4(newfstatat)` & `SYSCALL_DEFINE2(newfstat)`):** Calls `ksu_handle_stat(&dfd, &filename, &flag)` for `/system/bin/su` visibility and **`ksu_handle_newfstat_ret(&fd, &statbuf)`** on `newfstat` so Android 14–17 `init` (`ReadFdToString`) reads the injected `KERNEL_SU_RC` size accurately and automatically executes `ksud post-fs-data`, `services`, and `boot-completed`.
5. **`kernel/reboot.c` (`SYSCALL_DEFINE4(reboot)`):** Calls `ksu_handle_sys_reboot(magic1, magic2, cmd, &arg)` to service `ksud` supercall magics (`0xDEADBEEF` / `0xCAFEBABE`).

Additionally, [`0004-susfs-v1.5.5-kernel-4.19.patch`](../patches/0004-susfs-v1.5.5-kernel-4.19.patch) guards `prctl(0xDEADBEEF)` in `kernel/sys.c` with `uid_eq(current_uid(), GLOBAL_ROOT_UID)` so non-root probes cannot fingerprint KernelSU/SUSFS via `prctl` responses.

---

## 4. Protocol Lockstep: The UAPI Version Contract & Dynamic Resolution

Upstream `KernelSU-Next` (`legacy` HEAD) bumped `KERNEL_SU_UAPI_VERSION` to `6`, whereas official stable [KernelSU-Next Manager v3.4.2](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v3.4.2) expects **UAPI 5** (`KSU_VERSION=33355`). Mismatches trigger a restriction banner and lock Superuser/Module management.

Our [`0003-kernelsu-next-samsung-fixes.patch`](../patches/0003-kernelsu-next-samsung-fixes.patch) fixes this permanently with `KSU_VERSION_OVERRIDE=33355` and a **3-tier Dynamic UAPI Engine**:

- **Caller Reflection (`dispatch.c`):** Mirrors `in_cmd.uapi_version` whenever a caller requests a valid supported UAPI version (`4 <= UAPI <= 16`).
- **Runtime Override (`CHANGE_UAPIVER = 10013`):** Root supercall updates `ksu_uapi_override` dynamically without rebooting.
- **Bootarg Override (`ksu.uapi=<ver>`):** `module_param_named(uapi, ksu_uapi_override, uint, 0)` selects UAPI on early boot.

> [!TIP]
> Precedence order: **Caller arg (Tier 2) > Runtime supercall (Tier 1) > Kernel bootarg (Tier 3) > Compiled default (`UAPI 5`)**.

---

## 5. Kernel Backports & Keymaster SELinux Embedding

- **`path_umount` (`fs/namespace.c`):** Linux 5.9's `can_umount()` and `path_umount()` backported in [`0002`](../patches/0002-kernelsu-manual-hooks-and-backports.patch) so module mounts unmount cleanly for untrusted UIDs.
- **Built-in Keymaster DAK SELinux (`KernelSU-Next/kernel/selinux/rules.c`):** LineageOS SELinux initially denies `hal_keymaster_default` access to `/mnt/vendor/efs/DAK/` (`ret -932`, forcing Play Integrity `UNEVALUATED`). [`0003`](../patches/0003-kernelsu-next-samsung-fixes.patch) embeds `prov_efs_file` and `efs_file` read/search rules directly in kernel SELinux policy alongside `KSU_MANAGER_PACKAGE := com.rifsxd.ksunext`, eliminating external `post-fs-data.d` policy scripts.
- **OpenSSL 3.x Host Fixes (`scripts/`):** Guarded `<openssl/engine.h>` in [`0001`](../patches/0001-build-host-openssl-3-compat.patch).
- **SUSFS `v1.5.5` on Samsung `fs_context` (`fs/namespace.c`):** Adapted Linux 4.19 SUSFS mount tracking from upstream `vfs_kern_mount` to Samsung's backported `vfs_create_mount` / `clone_mnt` in [`0004`](../patches/0004-susfs-v1.5.5-kernel-4.19.patch).

---

## 6. Upstream Kernel Tree (`android_kernel_samsung_exynos850`)

| Property | Value |
| :--- | :--- |
| **Repository** | [`samsungexynos850/android_kernel_samsung_exynos850`](https://github.com/samsungexynos850/android_kernel_samsung_exynos850/tree/lineage-24.0) |
| **Branch / HEAD** | `lineage-24.0` · `4.19.325` @ `b8c71b7aecec` |
| **Target ABI** | Android 17 (SDK 37) LineageOS 24 userland & Binder IPC |

> [!IMPORTANT]
> All four patches in [`patches/`](../patches/) (`0001`–`0004`) are validated sequentially against commit **`b8c71b7aecec`** in both [`scripts/setup_env.sh`](../scripts/setup_env.sh) and [`.github/workflows/build-kernel.yml`](../.github/workflows/build-kernel.yml).

---

## 7. LineageOS Device Tree Alignment (`android_device_samsung_a21s`)

Aligned with [`LineageOS/android_device_samsung_a21s`](https://github.com/LineageOS/android_device_samsung_a21s):

| Parameter | Value | Impact |
| :--- | :--- | :--- |
| `BOARD_BOOTIMAGE_PARTITION_SIZE` | `37748736` (`36 MiB`) | Maximum `boot-ksu.img` size enforced before flashing |
| `BOARD_BOOT_HEADER_VERSION` | `2` | Separate DTB & ramdisk sections preserved by `magiskboot` |
| `BOARD_KERNEL_PAGESIZE` | `2048` | Page alignment maintained during repack |
| **Slot scheme** | A-only (`is_slot_device=0`) | Maps to `/dev/block/by-name/boot` in [`tools/anykernel3/anykernel.sh`](../tools/anykernel3/anykernel.sh) |

---

## 8. Build Workspace Hierarchy & Repository Separation

To keep [`rebeeh/A21s-KernelSU-Next`](https://github.com/rebeeh/A21s-KernelSU-Next) fast to clone (~1 MB instead of ~4 GB), the upstream kernel (`~2.5 GB`) and AOSP Clang (`~1.5 GB`) are fetched cleanly on demand into an external `build/` workspace by [`scripts/setup_env.sh`](../scripts/setup_env.sh), [`Dockerfile`](../Dockerfile), or [`.github/workflows/build-kernel.yml`](../.github/workflows/build-kernel.yml).

```text
Git Repository (Lightweight Distribution Layer)
├── .github/workflows/build-kernel.yml   # Automated CI build pipeline
├── configs/a21s_ksu_defconfig           # Exynos 850 KSU + SUSFS kernel config
├── patches/0001..0004-*.patch           # Ordered host, hook, UAPI/SELinux & SUSFS patches
├── scripts/setup_env.sh                 # Fetches kernel, KSU-Next, Clang, magiskboot & applies patches
├── scripts/build.sh & package_anykernel3.sh
├── tools/anykernel3/anykernel.sh        # Recovery flasher for /dev/block/by-name/boot
└── build.py                             # Cross-platform CLI & pstore bug reporter

External Workspace (build/ — Git-ignored)
├── a21s-kernel/                         # LineageOS 24 source + KernelSU-Next (legacy)
└── toolchain/clang-r416183b/            # AOSP Clang 12.0.5
```

---

## 9. Outcomes & Takeaways

| # | Milestone | Technical Resolution |
| :---: | :--- | :--- |
| 1 | **TZASC Crash Elimination** | Replaced runtime kprobes (`irq/160-tzasc`) with compile-time Manual Hooks (`0002`) |
| 2 | **`ksud` Auto-Boot Hook** | Added `ksu_handle_newfstat_ret` in `fs/stat.c` (`0002`) so Android 14–17 `init` starts `ksud` scripts |
| 3 | **UAPI & Driver Parity** | Dynamic UAPI `4–16` (`UAPI 5` default) + `KSU_VERSION_OVERRIDE=33355` (`0003`) |
| 4 | **Built-in DAK SELinux** | Embedded `hal_keymaster_default` DAK rules directly in `rules.c` (`0003`) |
| 5 | **SUSFS v1.5.5 + `prctl` Stealth** | Samsung `fs_context` mount hooks + `GLOBAL_ROOT_UID` `prctl(0xDEADBEEF)` guard (`0004`) |

---

## Related Docs

| Document | Description |
| :--- | :--- |
| [Technical Architecture](ARCHITECTURE.md) | Architectural diagrams and userspace stealth pipeline |
| [Kernel Build Guide](BUILD.md) | CI, Docker, Python CLI, native Clang, and `susfs4ksu-v1.5.5.zip` builds |
| [User Installation Guide](USER_GUIDE.md) | Prebuilt downloads, AlwaysStrong, ReZygisk, and Duck Detector |
| [Flashing Methods Guide](FLASHING_GUIDE.md) | AnyKernel3, `samloader`, Odin, and Heimdall instructions |
| [Troubleshooting & Diagnostics](TROUBLESHOOTING.md) | Log collection, Blindspots 1–5, and Play Integrity |
| [Contributing Guidelines](CONTRIBUTING.md) | Submitting patches and porting to other Exynos targets |
| [Documentation Hub](README.md) | Master documentation index |
