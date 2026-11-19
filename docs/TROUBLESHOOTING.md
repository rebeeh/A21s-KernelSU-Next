# Troubleshooting & Diagnostics Guide

This guide explains how to troubleshoot issues, extract critical kernel logs, and properly report bugs to the repository maintainers.

---

## 1. Extracting Logs

When reporting any kernel crash, bootloop, or unexpected root behavior, **logs are mandatory**.

### A. Kernel Crash / Bootloop Log (`pstore / ramoops`)
If your device crashes or bootloops, Linux automatically saves the panic log into persistent RAM (`pstore`).

1. Boot your phone into **Recovery Mode** (hold `Volume Up` + `Power`).
2. Connect phone to PC via USB.
3. Pull the preserved crash log:
   ```bash
   adb shell cat /sys/fs/pstore/dmesg-ramoops-0 > ramoops.log
   adb shell cat /sys/fs/pstore/console-ramoops-0 >> ramoops.log 2>/dev/null || true
   ```
4. Attach `ramoops.log` to your issue.

### B. Live Kernel Log (`dmesg`)
If the phone boots but root or a specific module isn't functioning:
```bash
adb shell dmesg > dmesg.log
```

### C. Android System Log (`logcat`)
To capture Android framework errors or app-level root rejection:
```bash
adb logcat -d > logcat.log
```

### D. KernelSU Userspace Daemon Log (`ksud`)
To inspect the status of the `ksud` daemon and feature states:
```bash
adb shell "/data/adb/ksud feature list" > ksu_features.log
adb shell "/data/adb/ksud -V" >> ksu_features.log
```

---

## 2. Common Issues & Solutions

### Issue 1: Device Boots, but Manager Displays "Unsupported | Not Integrated"
- **Cause:** Kernel was compiled without `CONFIG_KSU_MANUAL_HOOK=y` or without manual hooks.
- **Solution:** Verify `CONFIG_KSU_MANUAL_HOOK=y` in `.config` and rebuild using `./scripts/build.sh`.

### Issue 2: Pink Warning: "Manager Version X is too low for KernelSU-Next..."
- **Cause:** UAPI version mismatch between kernel driver and Manager APK.
- **Solution:** Verify that `uapi/supercall.h` defines `KERNEL_SU_UAPI_VERSION 5` to match Manager `v3.4.2`.

### Issue 3: Phone Bootloops on Samsung Logo
- **Cause:** Dynamic kprobes were enabled (`CONFIG_KSU_KPROBES_HOOK=y`), which triggers Samsung hardware TZASC IRQ 160.
- **Solution:** Flash `boot-ksu.img` built with `CONFIG_KSU_MANUAL_HOOK=y`. Do not use dynamic kprobes on Exynos 850.

### Issue 4: Lost Root After LineageOS System Update
- **Cause:** LineageOS OTA overwrote the boot partition with the stock kernel.
- **Solution:** Flash `KernelSU-Next-A21s-universal850-AnyKernel3.zip` in Recovery (or re-flash `boot-ksu.img` via `samloader`).

### Issue 5: Root Checker Says "Root access is not properly installed"
- **Cause:** Unlike Magisk, KernelSU operates on a strict **App Isolation & Allowlist Model**. By default, all ungranted apps are prevented from detecting `su` (the kernel returns `ENOENT` / file not found). This is what enables banking apps to pass detection natively.
- **Solution:** Open the **KernelSU Next** app -> tap the **Superuser (Shield)** tab -> find the target app (e.g. `Root Checker Basic`) -> toggle **Superuser** to **ON**. Re-running the app will immediately show verified root access.

---

## 3. How to Report an Issue

Before opening an issue on GitHub:
1. Check the [Closed Issues](https://github.com/rebeeh/A21s-KernelSU-Next/issues?q=is%3Aissue+is%3Aclosed) to see if a solution exists.
2. Ensure you are running the latest release.
3. Create a new issue using our **Bug Report Template** and attach:
   - Device Model (e.g., `SM-A217F`)
   - LineageOS Build Date (from *Settings -> About Phone*)
   - `ramoops.log` (if bootloop/crash) or `dmesg.log` (if runtime issue)
