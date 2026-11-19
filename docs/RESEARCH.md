# 🔬 Technical Research & Kernel Engineering Report

> A deep-dive research log covering every engineering decision made to bring **KernelSU-Next** to the **Samsung Galaxy A21s (SM-A217F / Exynos 850)** running **LineageOS 24 (Linux 4.19.325)** — from crash analysis through patch implementation to build architecture.

---

## 📋 Table of Contents

1. [Background & The Non-GKI Challenge](#1-background--the-non-gki-challenge)
2. [Root Cause Analysis: Why Dynamic Kprobes Fail on Samsung Exynos](#2-root-cause-analysis-why-dynamic-kprobes-fail-on-samsung-exynos)
3. [The Solution: Compile-Time Manual Hooks](#3-the-solution-compile-time-manual-hooks)
4. [Protocol Lockstep: The UAPI Version Contract & Dynamic Resolution](#4-protocol-lockstep-the-uapi-version-contract--dynamic-resolution)
5. [Kernel Backports](#5-kernel-backports)
6. [Upstream Kernel Tree](#6-upstream-kernel-tree-samsungexynos850android_kernel_samsung_exynos850)
7. [LineageOS Device Tree Alignment](#7-lineageos-device-tree-alignment-android_device_samsung_a21s)
8. [Build Workspace Hierarchy & Repository Separation](#8-build-workspace-hierarchy--repository-separation)
9. [Outcomes & Takeaways](#9-outcomes--takeaways)

---

## 🚦 Before You Begin

This document is a **technical research log**, not a build guide. It explains the *why* behind every patch and design choice. If you're here to build or flash, start with the main [README](../README.md) first.

| I want to… | Go to… |
|---|---|
| Understand why kprobes crash the device | [§2 Root Cause Analysis](#2-root-cause-analysis-why-dynamic-kprobes-fail-on-samsung-exynos) |
| See exactly what source files are patched | [§3 Manual Hooks](#3-the-solution-compile-time-manual-hooks) |
| Understand the UAPI version mismatch problem | [§4 UAPI Version Contract](#4-protocol-lockstep-the-uapi-version-contract--dynamic-resolution) |
| Understand the repo/workspace layout | [§8 Build Workspace](#8-build-workspace-hierarchy--repository-separation) |

---

## 1. 🧩 Background & The Non-GKI Challenge

Android 12+ introduced **GKI (Generic Kernel Image) 2.0** with a stable Kernel Module Interface (KMI). However, devices running **Linux 4.19** — such as those powered by the Exynos 850, Exynos 9611, Snapdragon 660, and Snapdragon 845 — are classified as **non-GKI** or **GKI 1.0** targets.

Upstream KernelSU eventually dropped official support for non-GKI devices. The **KernelSU-Next** project was created specifically to maintain non-GKI legacy kernel trees through its dedicated `legacy` branch, keeping root access alive for these devices.

---

## 2. 💥 Root Cause Analysis: Why Dynamic Kprobes Fail on Samsung Exynos

When compiling KernelSU-Next with the default dynamic kprobes hook method (`CONFIG_KSU_KPROBES_HOOK=y`), the Galaxy A21s **bootloops immediately** after kernel load.

### Capturing the Crash

Boot into Lineage Recovery and read the kernel crash dump preserved in `pstore`:

```bash
adb shell cat /sys/fs/pstore/dmesg-ramoops-0
```

This reveals the fatal hardware trap:

```
[ 1.196687] [0: irq/160-tzasc: 69] irq-160 : 1 tzasc
```

### The Mechanism — Step by Step

1. **Dynamic Kprobes patch kernel memory at runtime.**
   Kprobes write breakpoint instructions (`BRK` / `AARCH64_BREAK_MON`) directly into live system call routines such as `do_execve` and `vfs_read` while the kernel is running.

2. **Samsung's TZASC hardware intercepts the write.**
   The Exynos 850 includes the **TrustZone Address Space Controller (TZASC)**. TZASC enforces strict memory isolation between the Secure World (EL3/EL1 TrustZone) and the Non-Secure World (Linux kernel userland).

3. **The collision causes an immediate panic.**
   Any runtime attempt to modify executable kernel code in DRAM is treated by TZASC as an unauthorized code-modification attack. TZASC fires hardware interrupt 160 (`irq/160-tzasc`), halting the CPU and triggering a watchdog kernel panic — before the boot animation even starts.

> [!CAUTION]
> Do **not** enable `CONFIG_KSU_KPROBES_HOOK=y` on any Samsung Exynos 850 device. It will always bootloop regardless of kernel version. Use `CONFIG_KSU_MANUAL_HOOK=y` instead (see §3).

---

## 3. 🛠️ The Solution: Compile-Time Manual Hooks

Instead of patching running memory, **Manual Hook Mode** (`CONFIG_KSU_MANUAL_HOOK=y`) injects direct, static C function calls into the kernel source tree **before compilation**.

Because Clang compiles these into normal branch instructions (`BL`), **no memory is ever altered at runtime**. The CPU executes ordinary static instructions, fully complying with Samsung's TrustZone security boundaries.

### The 5 Core Manual Hook Sites

Each hook is guarded by `#ifdef CONFIG_KSU_MANUAL_HOOK` so it compiles away entirely when the option is off.

---

#### Hook 1 — `fs/exec.c` (`do_execve` & `compat_do_execve`)

```c
#ifdef CONFIG_KSU_MANUAL_HOOK
extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
            void *envp, int *flags);
ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
#endif
```

**Purpose:** Intercepts requests to execute `/system/bin/su` and elevates authorized caller contexts to root (`u:r:su:s0`).

---

#### Hook 2 — `fs/open.c` (`faccessat`)

```c
#ifdef CONFIG_KSU_MANUAL_HOOK
extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
            int *flags);
ksu_handle_faccessat(&dfd, &filename, &mode, NULL);
#endif
```

**Purpose:** Intercepts permission checks from root-seeking apps that query for the existence of `/system/bin/su`.

---

#### Hook 3 — `fs/read_write.c` (`SYSCALL_DEFINE3(read)`)

```c
#ifdef CONFIG_KSU_MANUAL_HOOK
extern int ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr, size_t *count_ptr);
ksu_handle_sys_read(fd, &buf, &count);
#endif
```

**Purpose:** Monitors file read operations to service safe allowlist lookups for the KernelSU-Next daemon.

---

#### Hook 4 — `fs/stat.c` (`SYSCALL_DEFINE4(newfstatat)`)

```c
#ifdef CONFIG_KSU_MANUAL_HOOK
extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
ksu_handle_stat(&dfd, &filename, &flag);
#endif
```

**Purpose:** Fakes inode existence of `/system/bin/su` for authorized apps, enabling root detection without an actual `su` binary on the filesystem.

---

#### Hook 5 — `kernel/reboot.c` (`SYSCALL_DEFINE4(reboot)`)

```c
#ifdef CONFIG_KSU_MANUAL_HOOK
extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);
ksu_handle_sys_reboot(magic1, magic2, cmd, &arg);
#endif
```

**Purpose:** Intercepts reboot magic values (`0xDEADBEEF` / `0xCAFEBABE`) so the userspace daemon (`ksud`) can install kernel driver file descriptors without actually rebooting the device.

---

## 4. 🔗 Protocol Lockstep: The UAPI Version Contract & Dynamic Resolution

KernelSU-Next uses a supercall IOCTL interface defined in `uapi/supercall.h`. The kernel and the Manager app (`com.rifsxd.ksunext`) must agree on a shared **UAPI version number** to unlock full functionality.

### The Version Mismatch Problem

When the Manager app calls `get_kernel_uapi_version()`, it evaluates:

```kotlin
val requiresNewManager = isManager && kernelUAPIVersion != null && managerUAPIVersion < kernelUAPIVersion
if (requiresNewManager) {
    WarningCard(...) // Shows: "manager version 5 is too low for KernelSU-Next..."
}
```

And checks for full feature availability:

```kotlin
fun isFullFeatured(): Boolean {
    return isManager && kernelUAPIVersion == managerUAPIVersion && rootAvailable()
}
```

The upstream `origin/legacy` HEAD bumped `KERNEL_SU_UAPI_VERSION` from **5 → 6** to introduce module preinit actions. However, official stable Manager APK releases (such as `v3.4.2 (33355-5)`) were built against **UAPI 5**.

When the kernel statically reports a version that mismatches the Manager APK, the manager enters **restricted mode** and disables the Superuser and Module management tabs — breaking the user experience even though root itself is working.

> [!WARNING]
> A UAPI version mismatch does **not** mean root is broken — it means the Manager UI is locked. This is a soft protocol failure, not a kernel crash.

### 🚀 The Dynamic UAPI Resolution Engine

To permanently eliminate this version trap — and avoid requiring users to recompile the kernel every time a Manager APK update bumps the UAPI version — our patchset (`patches/0003-kernelsu-next-samsung-fixes.patch`) introduces a **multi-tier dynamic resolution mechanism**:

---

#### Tier 1 — Kernel Supercall Runtime Override (`CHANGE_UAPIVER = 10013`)

```c
// kernel/supercall/supercall.c
uint32_t ksu_uapi_override = 0;
module_param_named(uapi, ksu_uapi_override, uint, 0);

if (magic2 == CHANGE_UAPIVER) {
    if (current_uid().val != 0)
        return 0;
    ksu_uapi_override = cmd;
    copy_to_user((void __user *)*arg, &reply, sizeof(reply));
}
```

Root processes can dynamically change the active UAPI version **at runtime** via:

```c
sys_reboot(0xDEADBEEF, 10013, target_version, &reply);
```

No kernel reboot required.

---

#### Tier 2 — Auto-Adaptive Caller Reflection (`kernel/supercall/dispatch.c`)

```c
/* Dynamic UAPI resolution */
struct ksu_get_info_cmd in_cmd = {0};
if (!copy_from_user(&in_cmd, arg, sizeof(in_cmd)) &&
    in_cmd.uapi_version >= 4 && in_cmd.uapi_version <= 16) {
    cmd.uapi_version = in_cmd.uapi_version;
} else if (ksu_uapi_override) {
    cmd.uapi_version = ksu_uapi_override;
} else {
    cmd.uapi_version = KERNEL_SU_UAPI_VERSION;
}
```

If a client provides its own expected target version in `arg`, the kernel dynamically validates and mirrors it within the safe range $[4, 16]$.

---

#### Tier 3 — Kernel Bootargs Override

Passing `ksu.uapi=<version>` on the kernel command line sets the desired UAPI version at **early boot** without touching the kernel binary. Useful for A/B testing Manager APK compatibility without flashing a new image.

> [!TIP]
> The three tiers have precedence: **Caller arg (Tier 2) > Runtime override (Tier 1) > Bootargs (Tier 3) > Compiled-in default.**

---

## 5. ⬇️ Kernel Backports

### `path_umount` — `fs/namespace.c`

KernelSU-Next's `kernel_umount` feature unmounts module overlay filesystems for non-root apps to defeat root detection. This feature relies on `path_umount`, which was added in **Linux 5.9** — a function that does not exist in the Linux 4.19 kernel shipped with Exynos 850 devices.

We backported the two-function surface:

```c
static int can_umount(const struct path *path, int flags);
int path_umount(struct path *path, int flags);
```

This enables module mount hiding on 4.19 without kernel crashes or missing symbol errors.

---

## 6. 🌐 Upstream Kernel Tree: `samsungexynos850/android_kernel_samsung_exynos850`

| Property | Value |
|---|---|
| **URL** | [https://github.com/samsungexynos850/android_kernel_samsung_exynos850](https://github.com/samsungexynos850/android_kernel_samsung_exynos850) |
| **Branch** | `lineage-24.0` |
| **Linux version** | 4.19.325 |
| **HEAD commit** | `b8c71b7aecec` |

### Role in Development

This is the verified kernel source tree maintaining the `lineage-24.0` branch for Exynos 850 devices, including the Galaxy A21s. It integrates the official Samsung vendor BSP (`universal850`) updated for modern Android 17 (SDK 37) LineageOS userland, Binder IPC, and device drivers.

> [!IMPORTANT]
> All KernelSU-Next patches in `patches/` apply cleanly onto commit **`b8c71b7aecec`** of this tree. Applying them to any other commit may produce conflicts and must be tested independently.

---

## 7. 📐 LineageOS Device Tree Alignment (`android_device_samsung_a21s`)

| Property | Value |
|---|---|
| **URL** | [https://github.com/LineageOS/android_device_samsung_a21s](https://github.com/LineageOS/android_device_samsung_a21s) |

The LineageOS device tree defines board configurations that dictate the build and packaging pipeline. The following parameters are critical:

### Partition Geometry

- `BOARD_BOOTIMAGE_PARTITION_SIZE := 37748736` — an exact **36 MiB** limit.

> [!CAUTION]
> Boot images exceeding 36 MiB **will fail** partition verification or silently overwrite neighbouring partitions. Always verify image size before flashing.

### Boot Header Specifications

| Parameter | Value | Meaning |
|---|---|---|
| `BOARD_BOOT_HEADER_VERSION` | `2` | Header v2: separate DTB and ramdisk sections |
| `BOARD_KERNEL_PAGESIZE` | `2048` | Page alignment enforced during `magiskboot repack` |

### Storage & Slot Configuration

The Galaxy A21s is an **A-only** device — it uses a **single system/boot slot** (not A/B).

- Boot partition block path: `/dev/block/by-name/boot`

These parameters map directly into `tools/anykernel3/anykernel.sh`:

```sh
block=/dev/block/by-name/boot
is_slot_device=0
```

This ensures recovery flashing works correctly and autonomously without user intervention.

---

## 8. 🏗️ Build Workspace Hierarchy & Repository Separation

### Why Separate the Build Workspace from the Git Repository?

| Component | Approximate Size |
|---|---|
| Full Linux kernel source (`a21s-kernel`) + git history | ~2.5 GB |
| Android Clang toolchain (`clang-r416183b`) | ~1.5 GB |

Storing these inside the GitHub repository would make cloning unbearably slow and violate GitHub's recommended (<1 GB) and hard (2 GB) repository size limits.

### The Solution: Overlay Architecture

```
Distribution Repository (rebeeh/A21s-KernelSU-Next)   ~1 MB, lives on GitHub
├── patches/           ← KernelSU-Next + Samsung compatibility patches
├── configs/           ← a21s_ksu_defconfig
├── tools/anykernel3/  ← boot image packager
├── scripts/           ← setup_env.sh (clones kernel + toolchain)
├── .github/workflows/ ← CI automation
└── docs/              ← this documentation suite

External Build Workspace (build/ or ~/Android/Kernel/)  ~4 GB, local or CI runner only
├── a21s-kernel/       ← upstream kernel tree (cloned by setup_env.sh)
└── clang-r416183b/    ← Android Clang toolchain
```

The `scripts/setup_env.sh` script (or GitHub Actions CI) clones the heavy upstream kernel and toolchain into the external workspace, then applies the repository's patches and defconfig on top of the upstream tree cleanly before compiling.

> [!NOTE]
> The distribution repository itself stays lightweight — only patch files, configs, and tooling scripts are committed. The ~4 GB of kernel source and compiler are always fetched fresh on demand.

---

## 9. ✅ Outcomes & Takeaways

This research phase produced five concrete, re-usable engineering outcomes:

| # | Outcome | Detail |
|---|---|---|
| 1 | **Root cause identified** | Samsung TZASC hardware irq-160 fires on any runtime kernel memory write, making `CONFIG_KSU_KPROBES_HOOK=y` permanently incompatible with Exynos 850. |
| 2 | **Compile-time hooks validated** | Five manual hook sites across `fs/` and `kernel/` files provide full KernelSU-Next functionality with zero runtime memory modification. |
| 3 | **Dynamic UAPI resolution shipped** | A three-tier override system decouples kernel UAPI version from Manager APK version, eliminating recompile-on-APK-update cycles permanently. |
| 4 | **`path_umount` backported** | Linux 5.9 API backported to 4.19, enabling module mount hiding and root-detection countermeasures on legacy kernels. |
| 5 | **Overlay workspace architecture defined** | Keeps the distribution repository small (~1 MB) while supporting full reproducible builds against a 4 GB external workspace on any CI runner or local machine. |

### Key Lessons for Non-GKI KernelSU-Next Ports

- **Always audit SoC-specific security hardware before choosing a hook method.** TZASC-equivalent controllers exist on other Samsung, MediaTek, and Kirin SoCs and will cause the same bootloop.
- **UAPI version pinning is a silent footgun.** Any project distributing a kernel binary alongside an APK should implement dynamic resolution from day one.
- **A-only vs. A/B slot detection is mandatory** in AnyKernel3 scripts — getting it wrong silently corrupts the wrong partition.

---

## 📚 Related Docs

| Document | Description |
|---|---|
| [README.md](../README.md) | Project overview, quick-start build & flash guide |
| [PATCHES.md](PATCHES.md) | Detailed description of every patch in `patches/` |
| [BUILD.md](BUILD.md) | Step-by-step local and CI build instructions |
| [CHANGELOG.md](CHANGELOG.md) | Release history and version log |
