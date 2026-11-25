---
name: a21s-ksu-integrity
description: >-
  Troubleshooting and verification runbook for Samsung Galaxy A21s (SM-A217F)
  KernelSU-Next 4.19 non-GKI builds, SUSFS v1.5.5, ReZygisk, and Play Integrity.
  Use when debugging ksud boot scripts, module startup, Keymaster DAK SELinux
  denials, or Play Integrity verdicts on a21s.
---

# A21s KernelSU-Next & Play Integrity Runbook

## 1. Verify `ksud` Boot Execution (`newfstat` Hook)
If modules in `/data/adb/modules_update/` are not migrated on boot and ReZygisk/TrickyStore daemons do not start:
1. Check `/data/adb/rezygisk/state.json` timestamp and `ps -ef | grep -E "zygisk|tricky"`.
2. Confirm `fs/stat.c` calls `ksu_handle_newfstat_ret(&fd, &statbuf)` inside `SYSCALL_DEFINE2(newfstat, ...)` (required for Android 14–17 `init` `ReadFdToString` to read appended `KERNEL_SU_RC`).

## 2. Verify Samsung Keymaster DAK SELinux Access
If Play Integrity returns `UNEVALUATED` with `keymaster_tee: Cannot open /mnt/vendor/efs/DAK/GAK_RSA.private, ret -932`:
1. Verify live policy:
   `adb shell 'su -c "/data/adb/ksu/bin/ksud sepolicy check \"allow hal_keymaster_default prov_efs_file dir { search read open getattr }\""'`
2. Ensure the `hal_keymaster_default` → `prov_efs_file` / `efs_file` `ksu_allow` rules are present in `KernelSU-Next/kernel/selinux/rules.c` (`patches/0003-kernelsu-next-samsung-fixes.patch`).

## 3. Verify ReZygisk Status (Ignore Cosmetic Manager Badge)
KernelSU-Next Manager displays `ZYGISK REQUIRED` when `ZYGISK_ENABLED` is absent from `com.rifsxd.ksunext`'s `/proc/<pid>/environ`. Verify real status with:
- `adb shell "su -c 'cat /data/adb/rezygisk/state.json'"` (`state: 1` for `"64"` and `"32"`)
- `adb shell "su -c '/data/adb/ksu/bin/ksud module list'"` (`[Monitor: ✅, ReZygisk 64-bit: ✅, ReZygisk 32-bit: ✅]`)

## 4. Play Integrity (`AlwaysStrong` All-in-One)
- Use **`AlwaysStrong`** (`Evokerr/AlwaysStrong` on GitLab) as the single all-in-one Play Integrity module (bundles `TEESimulator`, `autopif4`, and keybox fetching).
- **Do not** stack redundant `PlayIntegrityFork`, standalone `Tricky Store`, or `Yurikey` modules alongside `AlwaysStrong`.
- If using a personal private OEM `keybox.xml`, import it via AlwaysStrong's WebUI (`Set Custom Keybox`) or place it at `/data/adb/tricky_store/keybox.xml`.
- Verify `prctl(0xDEADBEEF)` is guarded by `uid_eq(current_uid(), GLOBAL_ROOT_UID)` in `kernel/sys.c` (`patches/0004-susfs-v1.5.5-kernel-4.19.patch`) so non-root detectors like Duck Detector receive `-EINVAL` instead of `0`.
