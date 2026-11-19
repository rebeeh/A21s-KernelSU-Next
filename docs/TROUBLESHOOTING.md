# Troubleshooting & Diagnostics Guide

This guide explains how to troubleshoot issues, extract critical kernel logs, and properly report bugs to the repository maintainers.

---

## 1. Automated 1-Click Log Extraction & Issue Reporting

When reporting any kernel crash, bootloop, or unexpected root behavior, **logs are mandatory**. We provide two automated workflows so you don't have to fiddle with manual shell commands:

### Method A: 1-Click Desktop Reporter (`python build.py report-issue`)
*(Recommended if connected to PC / in Recovery / during Bootloop)*

Connect your device via USB (whether booted into Android, Recovery, or TWRP) and run:
```bash
python build.py report-issue
```
**What this does automatically:**
1. Detects your connected device via ADB.
2. Extracts preserved kernel panics (`/sys/fs/pstore/dmesg-ramoops-0`), live kernel messages (`dmesg`), Android framework logs (`logcat`), and KernelSU status (`ksud debug info`).
3. Packages everything cleanly into a timestamped file: `out/logs/issue_report_<timestamp>.log`.
4. Automatically opens your desktop browser to GitHub with a **pre-filled bug report** containing your device model, LineageOS version, and the fatal crash stack trace! All you need to do is drag-and-drop the generated log file.

---

### Method B: On-Device Boot Crash Popup Reporter
*(Works directly on your phone after recovering from a bootloop or crash)*

Our repository provides an autonomous service script: [`tools/crash_reporter/00_ksu_crash_reporter.sh`](../tools/crash_reporter/00_ksu_crash_reporter.sh).

When installed to `/data/adb/service.d/00_ksu_crash_reporter.sh`:
1. Whenever your phone boots, it checks if a kernel panic occurred on the prior boot (`/sys/fs/pstore/dmesg-ramoops-0`).
2. If a crash is detected, it automatically copies the full crash dump to your user storage:
   `/sdcard/Download/ksu_crash_<timestamp>.log`
3. It uploads an anonymous log paste (no account required) and triggers a **persistent Android system notification** (`Kernel Crash Detected`) with the web link.
4. It pops up your default browser with a **pre-filled GitHub Issue draft** with the panic trace and link!

---

### 💡 What If You Don't Have a GitHub Account or Are Not Logged In?

If a user doesn't have a GitHub account or isn't logged in on their phone/PC browser:

1. **What GitHub Does:**
   * GitHub displays its standard login screen: `https://github.com/login?return_to=...`.
   * The `return_to` parameter preserves the entire draft! Once you sign in (or sign up), GitHub automatically forwards you to the issue creation page with all fields populated.
2. **Zero-Account Alternative (No Login Required):**
   * Both `build.py report-issue` and `00_ksu_crash_reporter.sh` automatically generate an **anonymous online log link** via `https://paste.rs` (e.g. `https://paste.rs/xyz123`).
   * The raw file is also always preserved locally on the phone (`/sdcard/Download/ksu_crash_<timestamp>.log`) and on PC (`out/logs/`).
   * Users without GitHub can simply copy the link or file and drop it into community support channels (Telegram group, XDA Developers thread, or Discord)!

---

### Method C: Manual Log Extraction via ADB

If you prefer extracting files manually:

#### A. Kernel Crash / Bootloop Log (`pstore / ramoops`)
If your device crashes or bootloops, Linux automatically saves the panic log into persistent RAM (`pstore`).

1. Boot your phone into **Recovery Mode** (hold `Volume Up` + `Power`).
2. Connect phone to PC via USB.
3. Pull the preserved crash log:
   ```bash
   adb shell cat /sys/fs/pstore/dmesg-ramoops-0 > ramoops.log
   adb shell cat /sys/fs/pstore/console-ramoops-0 >> ramoops.log 2>/dev/null || true
   ```
4. Attach `ramoops.log` to your issue.

#### B. Live Kernel Log (`dmesg`)
If the phone boots but root or a specific module isn't functioning:
```bash
adb shell dmesg > dmesg.log
```

#### C. Android System Log (`logcat`)
To capture Android framework errors or app-level root rejection:
```bash
adb logcat -d > logcat.log
```

#### D. KernelSU Userspace Daemon Log (`ksud`)
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
- **Solution:** Our kernel includes the **Dynamic UAPI Engine** (see Blindspot 3 below) which resolves this automatically. Alternatively, keep Manager pinned to `v3.4.2 (33355-5)`.

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

## 🛡️ Critical Blindspots & Edge-Case Management

Below is the complete engineering breakdown of potential blindspots when running KernelSU-Next on Samsung Galaxy A21s (Android 17 / LineageOS 24) and their built-in solutions:

---

### Blindspot 1: `adb shell su` Fails with `"su: inaccessible or not found"`
* **The Symptom:** When connecting your PC and executing `adb shell su`, the terminal outputs:
  ```
  /system/bin/sh: su: inaccessible or not found
  ```
* **The Root Cause:** In Android, ADB shell executes under the context of `com.android.shell` (UID 2000). Because KernelSU enforces kernel-level UID stealth isolation across all non-root UIDs, the kernel returns `-ENOENT` when Shell probes `/system/bin/su` unless explicitly granted.
* **The Fix:**
  1. Open **KernelSU Next Manager** -> tap the **Superuser (Shield)** tab.
  2. Tap the 3 dots in the top-right corner -> select **Show system apps**.
  3. Locate **Shell** (`com.android.shell` / UID 2000) and toggle **Superuser** to **ON**.
  4. *Alternative:* In KernelSU Next Manager **Settings (gear icon)**, toggle **ADB Root** to **ON**.
  5. Subsequent `adb shell su` commands will immediately enter the root shell (`root@a21s:/ #`).

---

### Blindspot 2: Incompatible KernelSU / Magisk Module Causing Bootloops
* **The Risk:** A user installs an untested or incompatible Zygisk/Magisk module (e.g., an outdated audio mod, aggressive font pack, or incompatible Riru module) that causes `system_server` or Zygote to crash continuously during boot.
* **Hardware Rescue Mode (Safe Mode):**
  * You do **NOT** need to wipe data, format `/data`, or reinstall the ROM.
  * During power on, as soon as the **Samsung Galaxy** splash screen appears, **press and hold the physical Volume Down button** continuously until the device vibrates and reaches the lockscreen.
  * KernelSU intercepts key events during early init and automatically creates `/data/adb/modules/.disable`, skipping module execution.
  * Once booted in Safe Mode, launch KernelSU Next Manager, uninstall the problematic module, and reboot normally.
* **Manual Recovery Rescue (TWRP / Lineage Recovery):**
  If physical buttons are unavailable, boot into Recovery, connect USB, and run:
  ```bash
  adb shell touch /data/adb/modules/.disable
  ```
  Then reboot to system.

---

### Blindspot 3: Future KernelSU Manager APK Updates (The UAPI Version Lock)
* **The Risk:** An automated app updater or user upgrades the Manager APK to a future release that expects a different UAPI version (e.g. UAPI 6 instead of UAPI 5).
* **The Symptom:** The Manager displays a pink warning banner:
  > *"The current KernelSU-Next manager version is too low/high for KernelSU-Next to work properly."*
  Superuser and Module tabs become disabled.
* **The Dynamic Solution (Dynamic UAPI Resolution Engine):**
  To prevent requiring a full kernel recompile whenever the Manager APK is updated, our kernel integrates a 3-layer **Dynamic UAPI Engine**:
  1. **Dynamic Supercall Runtime Override (`CHANGE_UAPIVER = 10013`):**
     Root can dynamically reconfigure the kernel's reported UAPI version on demand without rebooting:
     ```c
     // Invokes kernel supercall 10013 to switch reported UAPI version to 6
     syscall(__NR_reboot, 0xDEADBEEF, 10013, 6, &reply);
     ```
     The kernel immediately updates its internal state and responds to subsequent queries with the target version.
  2. **Caller Auto-Negotiation Reflection:**
     When a caller issues `ioctl(fd, KSU_IOCTL_GET_INFO, &info)` with `info.uapi_version` initialized to a supported version ($4 \le \text{UAPI} \le 16$), the kernel driver inspects `in_cmd` via `copy_from_user` and dynamically reflects the requested version back, providing instant forward/backward compatibility.
  3. **Kernel Command-Line Boot Parameter (`ksu.uapi=X`):**
     The kernel exposes the `uapi` parameter (`module_param_named(uapi, ksu_uapi_override, uint, 0)`). You can specify `ksu.uapi=6` or `ksu.uapi=5` directly in bootargs without modifying source code.

---

### Blindspot 4: Google Play Integrity & Banking Apps on Android 17
* **Current Status:**
  Our kernel has hardware root hiding built-in:
  - `kernel_umount (ID=1)`: Unmounts module namespaces for unauthorized apps.
  - `selinux_hide (ID=4)`: Sanitizes `/sys/fs/selinux` access results for app UIDs.
  - `avc_spoof (ID=10003)`: Suppresses SELinux audit logs that leak root context.
  Banking apps performing basic file/permission checks pass natively without extra configuration.
* **The Blindspot:**
  Advanced apps querying Google's **Play Integrity API** (`MEETS_DEVICE_INTEGRITY`) detect that the bootloader is unlocked (`ro.boot.verifiedbootstate=orange`).
* **The Complete Setup:**
  1. In KernelSU Next Manager -> Install **Zygisk-Next** module.
  2. Install **PlayIntegrityFix** (PIF) module.
  3. Reboot device.
  4. Verify using Play Integrity API Checker app: both `MEETS_BASIC_INTEGRITY` and `MEETS_DEVICE_INTEGRITY` pass cleanly on Android 17.

---

### Blindspot 5: Dynamic Partitions & LineageOS Nightly Updates
* **The Architecture:**
  The Samsung Galaxy A21s uses Samsung dynamic partitions (`super` holding `/system`, `/vendor`, `/product`), but the `/boot` partition is a **standalone, non-A/B partition** (`/dev/block/by-name/boot`).
* **The Blindspot:**
  Every LineageOS nightly/weekly OTA completely overwrites `/boot` with the upstream stock kernel, which temporarily removes KernelSU.
* **The 5-Second Solution:**
  1. Keep `KernelSU-Next-A21s-universal850-AnyKernel3.zip` saved on your device storage or microSD card.
  2. When the LineageOS updater finishes, boot into Recovery before restarting into system.
  3. Flash `KernelSU-Next-A21s-universal850-AnyKernel3.zip`.
  4. AnyKernel3 extracts the new LineageOS ramdisk, swaps the kernel `Image`, and repacks the partition on the fly in ~5 seconds.
  5. Reboot. Root, modules, and all app permissions remain 100% intact!

---

## 3. How to Report an Issue

Before opening an issue on GitHub:
1. Check the [Closed Issues](https://github.com/rebeeh/A21s-KernelSU-Next/issues?q=is%3Aissue+is%3Aclosed) to see if a solution exists.
2. Ensure you are running the latest release.
3. Create a new issue using our **Bug Report Template** and attach:
   - Device Model (e.g., `SM-A217F`)
   - LineageOS Build Date (from *Settings -> About Phone*)
   - `ramoops.log` (if bootloop/crash) or `dmesg.log` (if runtime issue)
