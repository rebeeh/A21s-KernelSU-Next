# Architecture & Technical Design: A21s KernelSU-Next

This document details the architectural decisions, hardware constraints, and kernel modifications required to run **KernelSU-Next** on the **Samsung Galaxy A21s (`SM-A217F`)** running **LineageOS 24 (Linux kernel 4.19.325)**.

---

## 1. Hardware & Security Constraints: Samsung Exynos 850 (universal850)

The Samsung Galaxy A21s is powered by the **Exynos 850** SoC (ARM Cortex-A55 octa-core, ARMv8.2-A).

Samsung implements hardware-level TrustZone protections on the memory bus:
- **TZASC (TrustZone Address Space Controller):** Constantly audits and enforces memory access permissions to DRAM segments assigned to the secure world vs the non-secure world.
- **RKP (Real-time Kernel Protection) / DEFEX:** Monitored via EL3 TrustZone interrupts (`irq/160-tzasc`).

### Why Dynamic Kprobes (`CONFIG_KSU_KPROBES_HOOK=y`) Fail
Standard KernelSU installations on generic Android devices rely on **Kprobes**. Kprobes function by dynamically replacing CPU instruction opcodes in memory with breakpoint instructions (`BRK` / `AARCH64_BREAK_MON`) or patching jump instructions at runtime.

On the Exynos 850:
1. When `CONFIG_KSU_KPROBES_HOOK=y` registers a probe on `sys_execve` or `vfs_read`, it calls `patch_text()` to modify executable kernel pages in RAM.
2. The hardware TZASC immediately traps this write as an unauthorized modification of kernel code space:
   ```
   [ 1.196687] [0: irq/160-tzasc: 69] irq-160 : 1 tzasc
   ```
3. The Exynos security monitor halts CPU execution and triggers an unrecoverable kernel panic, resulting in an immediate bootloop.

---

## 2. The Solution: Compile-Time Scope-Minimized Manual Hooks

To completely eliminate dynamic instruction patching, we configure the kernel with:
```kconfig
CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
# CONFIG_KSU_KPROBES_HOOK is not set
```

In Manual Hook mode, all hook call-sites are resolved statically at compile time by Clang. The CPU executes normal, unmodified branch instructions (`BL`), which never triggers TZASC.

### The 5 Manual Hook Call Sites

| Function | File | Lineage Hook Placement | Upstream Purpose |
|---|---|---|---|
| `do_execve` | `fs/exec.c` | Before process credentials commit | Intercepts `su` requests and swaps process context to root (`ksu` domain). |
| `faccessat` | `fs/open.c` | Before permission check | Intercepts `access("/system/bin/su")` checks from root-seeking apps and redirects to `/system/bin/sh`. |
| `read` | `fs/read_write.c` | In `SYSCALL_DEFINE3(read)` | Intercepts file reads for safety and allowlist lookups. |
| `newfstatat` | `fs/stat.c` | In `SYSCALL_DEFINE4(newfstatat)` | Returns stat info for `/system/bin/su` when requested by authorized apps. |
| `reboot` | `kernel/reboot.c` | In `SYSCALL_DEFINE4(reboot)` | Intercepts reboot supercall magics to install driver file descriptors. |

---

## 3. UAPI Versioning & Manager Parity

KernelSU-Next maintains an explicit UAPI (User-Kernel API) version counter in `uapi/supercall.h`.

### The Version Check Mechanism
When the Manager app (`com.rifsxd.ksunext`) launches, it calls the `KSU_IOCTL_GET_INFO` supercall to query the running driver:
```kotlin
// manager/app/src/main/java/com/rifsxd/ksunext/Natives.kt
fun isFullFeatured(): Boolean {
    return isManager && kernelUAPIVersion == managerUAPIVersion && rootAvailable()
}
```

```kotlin
// manager/app/src/main/java/com/rifsxd/ksunext/ui/screen/Home.kt
val requiresNewManager = isManager && kernelUAPIVersion != null && managerUAPIVersion < kernelUAPIVersion
if (requiresNewManager) {
    WarningCard(stringResource(id = R.string.require_manager_version, managerUAPIVersion, kernelUAPIVersion!!))
}
```

### Protocol Alignment
- **KernelSU-Next Manager `v3.4.2`** (the latest official stable release) was built with **UAPI 5**.
- The `origin/legacy` git HEAD recently bumped the constant to **UAPI 6** for experimental preinit/symbol lookups (unsupported on non-GKI 4.19).
- Maintaining `#define KERNEL_SU_UAPI_VERSION 5` guarantees seamless compatibility with stable Manager `v3.4.2` and its embedded `ksud 3.4.2 (uapi: 5)`.

---

## 4. Backports & Host Fixes

1. **`path_umount` Backport (`fs/namespace.c`):**
   Linux 4.19 lacks `path_umount`, which KernelSU uses to cleanly unmount module overlays for unauthorized apps. We backported `can_umount()` and `path_umount()` into `fs/namespace.c`.
2. **OpenSSL 3.x Host Compatibility (`scripts/`):**
   Modern host build systems (Fedora 40+, Ubuntu 22.04+) ship OpenSSL 3.0+, which deprecates `<openssl/engine.h>`. Added preprocessor checks in `scripts/extract-cert.c` and `scripts/sign-file.c` to conditionally bypass deprecated engine headers.
3. **`copy_to_kernel_nofault` Fix (`drivers/kernelsu/hook/patch_memory.c`):**
   Samsung backported `copy_to_kernel_nofault` into their 4.19 kernel branch, causing a macro collision with KernelSU's legacy fallback. Cleanly resolved by removing the duplicate macro.
