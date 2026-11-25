[← Documentation Hub](README.md) · [Main README](../README.md)

# Troubleshooting & Diagnostics Guide

> Diagnose, collect crash logs, recover from module bootloops, and resolve root/Play Integrity issues on the **Samsung Galaxy A21s (`SM-A217F` / Exynos 850)** running **LineageOS 24**.

---

## Quick Diagnosis

| Symptom | Jump To |
| :--- | :--- |
| Manager shows **"Unsupported \| Not Integrated"** | [Issue 1: Manager Shows "Unsupported \| Not Integrated"](#issue-1-manager-shows-unsupported--not-integrated) |
| Pink banner: **"Manager version too low / high"** | [Issue 2: Pink Banner — "Manager Version Too Low/High"](#issue-2-pink-banner--manager-version-too-lowhigh) |
| Device **bootloops** on Samsung logo | [Issue 3: Device Bootloops on Samsung Logo](#issue-3-device-bootloops-on-samsung-logo) |
| **Root lost** after LineageOS update | [Issue 4: Root Lost After LineageOS OTA Update](#issue-4-root-lost-after-lineageos-ota-update) |
| Root Checker says **"not properly installed"** | [Issue 5: Root Checker Says "Root Not Properly Installed"](#issue-5-root-checker-says-root-not-properly-installed) |
| Manager shows **"ZYGISK REQUIRED"** on active modules | [Issue 6: Manager Shows "ZYGISK REQUIRED" Badge on Active Modules](#issue-6-manager-shows-zygisk-required-badge-on-active-modules) |
| Modules or `post-fs-data.d` / `service.d` scripts don't start on boot | [Issue 7: `ksud` Boot Scripts or Modules Not Executing](#issue-7-ksud-boot-scripts-or-modules-not-executing) |
| `adb shell su` returns **"inaccessible or not found"** | [Blindspot 1: `adb shell su` Fails](#blindspot-1-adb-shell-su-fails) |
| A **module** causes a bootloop | [Blindspot 2: Incompatible Module Causing Bootloop](#blindspot-2-incompatible-module-causing-bootloop) |
| Future Manager APK updates / UAPI lock | [Blindspot 3: Future Manager APK Updates (The UAPI Version Lock)](#blindspot-3-future-manager-apk-updates-the-uapi-version-lock) |
| **Play Integrity / Banking / Keymaster DAK (`-932`) / Duck Detector** | [Blindspot 4: Google Play Integrity, Knox Tripping & Hardware Attestation](#blindspot-4-google-play-integrity-knox-tripping--hardware-attestation) |
| Root disappears after **every LineageOS nightly** | [Blindspot 5: Dynamic Partitions & LineageOS Nightly Updates](#blindspot-5-dynamic-partitions--lineageos-nightly-updates) |
| None of the above — report a bug | [Section 4: How to Report an Issue](#section-4--how-to-report-an-issue) |

---

## Before You Begin

Confirm these baselines before debugging:

1. **Kernel release:** Latest build from [GitHub Releases (`latest`)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) (`v1.2.0+`).
2. **Manager APK:** [KernelSU-Next Manager `v3.4.2`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) (`33355-5`, UAPI `5`).
3. **Device & ROM:** Galaxy A21s (`SM-A217F` / `M` / `N`), unlocked bootloader, **LineageOS 24** *(not Stock OneUI)*.
4. **USB Debugging:** Enabled under *Settings → About Phone → tap Build Number 7× → Developer Options → USB Debugging*.

---

## Section 1 — Log Extraction

Logs are required for diagnosing panics, bootloops, or hook regressions. Choose whichever method matches your device state.

### Method A: 1-Click Desktop Reporter (`python3 build.py report-issue`)

> [!TIP]
> **Recommended** whenever a PC is available — works whether the phone is booted into Android (`su -c`) or Recovery / TWRP (`mount -t pstore` fallback in [`build.py`](../build.py)).

1. Connect your Galaxy A21s via USB and run:
   ```bash
   python3 build.py report-issue
   ```
2. [`build.py`](../build.py) automatically:
   - Extracts preserved kernel panics (`/sys/fs/pstore/dmesg-ramoops-0` / `console-ramoops-0`), `dmesg`, `logcat`, and `ksud debug info`.
   - Saves everything locally under `out/logs/issue_report_<timestamp>.log`.
   - Uploads to [paste.rs](https://paste.rs) (if available) and opens a pre-filled [GitHub Bug Report](https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?template=bug_report.md).
3. Drag and drop the saved `.log` file onto the GitHub issue form before submitting.

### Method B: On-Device Boot Crash Popup Reporter

> [!NOTE]
> Runs automatically on-device after rebooting from a kernel panic — implemented in [`tools/crash_reporter/00_ksu_crash_reporter.sh`](../tools/crash_reporter/00_ksu_crash_reporter.sh).

**One-time install:**
```bash
adb push tools/crash_reporter/00_ksu_crash_reporter.sh /data/adb/service.d/00_ksu_crash_reporter.sh
adb shell chmod +x /data/adb/service.d/00_ksu_crash_reporter.sh
```

On boot, it checks `/sys/fs/pstore/dmesg-ramoops-0`, archives crashes to `/sdcard/Download/ksu_crash_<timestamp>.log`, uploads an anonymous paste to [paste.rs](https://paste.rs), and posts a **Kernel Crash Detected** Android notification.

### Method C: Manual Log Extraction via ADB

<details>
<summary><strong>Expand manual ADB log commands (<code>pstore</code>, <code>dmesg</code>, <code>logcat</code>, <code>ksud</code>)</strong></summary>

1. **Kernel Crash / Bootloop (`pstore` / `ramoops`) from Recovery (`Volume Up + Power`):**
   ```bash
   adb shell "cat /sys/fs/pstore/dmesg-ramoops-0 2>/dev/null || (mkdir -p /tmp/pstore && mount -t pstore pstore /tmp/pstore && cat /tmp/pstore/dmesg-ramoops-0)" > ramoops.log
   adb shell cat /sys/fs/pstore/console-ramoops-0 >> ramoops.log 2>/dev/null || true
   ```
2. **Live Kernel Log (`dmesg`):**
   ```bash
   adb shell su -c dmesg > dmesg.log
   ```
3. **Android System Log (`logcat`):**
   ```bash
   adb logcat -d > logcat.log
   ```
4. **KernelSU-Next Daemon & SUSFS Status (`ksud` / `ksu_susfs`):**
   ```bash
   adb shell su -c "/data/adb/ksud -V && /data/adb/ksud feature list" > ksu_features.log
   adb shell su -c "/data/adb/ksu/bin/ksu_susfs show version" >> ksu_features.log 2>/dev/null || true
   ```

</details>

> [!TIP]
> **No GitHub account?** Both [`build.py report-issue`](../build.py) and [`00_ksu_crash_reporter.sh`](../tools/crash_reporter/00_ksu_crash_reporter.sh) save local `.log` archives and [paste.rs](https://paste.rs) URLs that you can share directly on [XDA](https://xdaforums.com) or community channels.

---

## Section 2 — Common Issues & Solutions

### Issue 1: Manager Shows "Unsupported | Not Integrated"

| | |
| :--- | :--- |
| **Cause** | Kernel was built without `CONFIG_KSU_MANUAL_HOOK=y` or without [`patches/`](../patches/) applied. |
| **Fix** | Verify [`configs/a21s_ksu_defconfig`](../configs/a21s_ksu_defconfig) has `CONFIG_KSU_MANUAL_HOOK=y` and rebuild with [`./scripts/build.sh`](../scripts/build.sh), or flash the official [release zip](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip). |

---

### Issue 2: Pink Banner — "Manager Version Too Low/High"

| | |
| :--- | :--- |
| **Cause** | UAPI version mismatch between kernel driver and Manager APK. |
| **Fix** | Our 3-tier Dynamic UAPI Engine ([`0003-kernelsu-next-samsung-fixes.patch`](../patches/0003-kernelsu-next-samsung-fixes.patch)) handles UAPI 4–16 automatically. If you rebuilt from upstream without it, pin [KernelSU-Next Manager `v3.4.2`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk). See [Blindspot 3](#blindspot-3-future-manager-apk-updates-the-uapi-version-lock). |

---

### Issue 3: Device Bootloops on Samsung Logo

| | |
| :--- | :--- |
| **Cause** | `CONFIG_KSU_KPROBES_HOOK=y` was enabled. Dynamic kprobes trigger Exynos 850 TZASC `irq/160-tzasc` hardware panics at boot. |
| **Fix** | Never use kprobes on Exynos 850. Flash a build compiled with `CONFIG_KSU_MANUAL_HOOK=y` ([`0002-kernelsu-manual-hooks-and-backports.patch`](../patches/0002-kernelsu-manual-hooks-and-backports.patch)). |

> [!CAUTION]
> Always pull `ramoops.log` from Recovery before re-flashing if a panic occurs — it immediately pinpoints `irq-160 tzasc` vs another driver fault.

---

### Issue 4: Root Lost After LineageOS OTA Update

| | |
| :--- | :--- |
| **Cause** | LineageOS OTA overwrote `/dev/block/by-name/boot` with the stock upstream `boot.img`. |
| **Fix** | Boot Recovery immediately after the OTA and flash [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip). See [OTA_AND_UPDATES.md](OTA_AND_UPDATES.md). |

---

### Issue 5: Root Checker Says "Root Not Properly Installed"

| | |
| :--- | :--- |
| **Cause** | KernelSU-Next enforces strict per-app kernel allowlisting — ungranted apps receive `-ENOENT` when checking `/system/bin/su`. |
| **Fix** | Open **KernelSU Next** → **Superuser (Shield)** → select the app → toggle **Superuser** **ON**. See [USER_GUIDE.md](USER_GUIDE.md#why-root-checker-shows-not-properly-installed-at-first). |

---

### Issue 6: Manager Shows "ZYGISK REQUIRED" Badge on Active Modules

| | |
| :--- | :--- |
| **Cause** | Standalone Zygisk injectors ([`ReZygisk`](https://github.com/PerformanC/ReZygisk)) inject via `ptrace` into Zygote rather than exporting `ZYGISK_ENABLED` inside the Manager app's process. The chip is purely cosmetic. |
| **Verification** | Run `adb shell su -c cat /data/adb/modules/rezygisk/module.prop` to confirm `[Monitor: ✅, ReZygisk 64-bit: ✅, ReZygisk 32-bit: ✅]`. |

---

### Issue 7: `ksud` Boot Scripts or Modules Not Executing

| | |
| :--- | :--- |
| **Cause** | Pre-`v1.2.0` manual hook builds hooked `newfstatat` (`stat.c`) without hooking `SYSCALL_DEFINE2(newfstat)` (`ksu_handle_newfstat_ret`). Android 14–17 `init` (`ReadFdToString`) calls `fstat`/`newfstat` when sizing `init.rc`, so `KERNEL_SU_RC` was truncated before triggering `ksud post-fs-data` / `services` / `boot-completed`. |
| **Fix** | Upgrade to release [`v1.2.0+`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) (which includes `ksu_handle_newfstat_ret` in [`0002-kernelsu-manual-hooks-and-backports.patch`](../patches/0002-kernelsu-manual-hooks-and-backports.patch)). Verify with `adb shell su -c "ls /data/adb/modules_update"` (should be empty after boot migration) and `logcat \| grep ksud`. |

---

## Section 3 — Critical Blindspots & Edge-Case Management

### Blindspot 1: `adb shell su` Fails

**Symptom:** `/system/bin/sh: su: inaccessible or not found`

**Root Cause:** ADB shell executes as `com.android.shell` (UID `2000`), which KernelSU-Next isolates until allowed.

**Fix:**
- **Option A:** Open **KernelSU Next → Superuser → ⋮ → Show system apps → Shell (`2000`) → ON**.
- **Option B:** Open **KernelSU Next → Settings → ADB Root → ON**, then reconnect ADB.

---

### Blindspot 2: Incompatible Module Causing Bootloop

> [!IMPORTANT]
> You do **not** need to wipe `/data` or re-flash your ROM to recover from a broken module.

- **Option A (Hardware Safe Mode):** Power on → when the **Samsung Galaxy** splash appears, hold **Volume Down** continuously until vibration / lockscreen. KernelSU-Next creates `/data/adb/modules/.disable` cleanly.
- **Option B (Via Recovery ADB):** Boot Recovery → run `adb shell touch /data/adb/modules/.disable` → reboot to system → remove the faulty module in Manager and delete `.disable`.

---

### Blindspot 3: Future Manager APK Updates (The UAPI Version Lock)

Our patch [`0003-kernelsu-next-samsung-fixes.patch`](../patches/0003-kernelsu-next-samsung-fixes.patch) embeds a **3-Layer Dynamic UAPI Resolution Engine** (`4 <= UAPI <= 16`, default `5`) so Manager APK updates don't lock out Superuser/Modules:

1. **Layer 1 (`CHANGE_UAPIVER = 10013`):** Root runtime override via reboot supercall (`syscall(__NR_reboot, 0xDEADBEEF, 10013, 6, &reply)`).
2. **Layer 2 (Caller Reflection):** `KSU_IOCTL_GET_INFO` mirrors valid caller `in_cmd.uapi_version` values automatically.
3. **Layer 3 (Kernel Bootarg):** `ksu.uapi=6` via `module_param_named(uapi, ksu_uapi_override, uint, 0)`.

As a fallback, pin [KernelSU-Next Manager `v3.4.2`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk).

---

### Blindspot 4: Google Play Integrity, Knox Tripping & Hardware Attestation

1. **Kernel Stealth & Built-in DAK SELinux Fix:**
   - [`0003-kernelsu-next-samsung-fixes.patch`](../patches/0003-kernelsu-next-samsung-fixes.patch) embeds `hal_keymaster_default` SELinux permissions for `/mnt/vendor/efs/DAK/` (`prov_efs_file` / `efs_file`) directly into KernelSU-Next `rules.c` (`KSU_MANAGER_PACKAGE := com.rifsxd.ksunext`), eliminating `keymaster_tee: Cannot open /mnt/vendor/efs/DAK/GAK_RSA.private, ret -932` (`UNEVALUATED`) cleanly at boot without custom `post-fs-data.d` scripts.
   - [`0004-susfs-v1.5.5-kernel-4.19.patch`](../patches/0004-susfs-v1.5.5-kernel-4.19.patch) restricts `prctl(0xDEADBEEF)` to `GLOBAL_ROOT_UID` in `kernel/sys.c`, eliminating `KernelSU prctl: Response` detections in Duck Detector.
2. **All-in-One Integrity Module ([AlwaysStrong](https://gitlab.com/Evokerr/AlwaysStrong/-/releases)):**
   - Use **AlwaysStrong** (`AlwaysStrong-v1.0.6.1.zip`) alone — **do not stack** duplicate modules (`PlayIntegrityFix`/`Fork`, standalone `Tricky Store`, or `Yurikey`), which conflict on keystore hooks.
   - Once AlwaysStrong loads an active keybox (or a private OEM `keybox.xml`), Google Play Integrity passes **`MEETS_BASIC_INTEGRITY`**, **`MEETS_DEVICE_INTEGRITY`**, and **`MEETS_STRONG_INTEGRITY`**.
3. **LineageOS `userdebug` & Duck Detector Notes:**
   - Ensure `/data/local/tmp/` does not contain leftover `ksud` or setup binaries (Duck Detector scans `/data/local/tmp/`).
   - `ADB Runtime` flags while USB Debugging is enabled — disable USB Debugging when testing target banking/integrity apps.
   - Because Samsung's cloud-verified attestation checks hardware OEM RSA chains, the kernel alone cannot forge `MEETS_STRONG_INTEGRITY` without a valid unrevoked keybox handled by AlwaysStrong/TEESimulator.

---

### Blindspot 5: Dynamic Partitions & LineageOS Nightly Updates

The Galaxy A21s stores `/system`, `/vendor`, and `/product` inside `super`, while `/dev/block/by-name/boot` is a standalone **A-only** partition overwritten on every OTA. Keep [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) on storage and re-flash it right after every OTA (~5 s) — see [OTA_AND_UPDATES.md](OTA_AND_UPDATES.md).

---

## Section 4 — How to Report an Issue

1. Check [Closed Issues](https://github.com/rebeeh/A21s-KernelSU-Next/issues?q=is%3Aissue+is%3Aclosed) and verify you are on the [latest release](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest).
2. Capture logs via `python3 build.py report-issue` or [Method C](#method-c-manual-log-extraction-via-adb).
3. Submit using our [Bug Report Template](https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?template=bug_report.md) ([`.github/ISSUE_TEMPLATE/bug_report.md`](../.github/ISSUE_TEMPLATE/bug_report.md)).

> [!IMPORTANT]
> Scrub Wi-Fi credentials, accounts, or private keys (`keybox.xml` details) before uploading public logs.

---

## Related Docs

| Document | Description |
| :--- | :--- |
| [User Installation Guide](USER_GUIDE.md) | First-time setup, downloads, AlwaysStrong, ReZygisk & Duck Detector |
| [Flashing Guide](FLASHING_GUIDE.md) | AnyKernel3, `samloader`, Odin, Heimdall, and `dd` |
| [Kernel Build Guide](BUILD.md) | Source compilation & `susfs4ksu-v1.5.5.zip` packaging |
| [OTA Updates Survival](OTA_AND_UPDATES.md) | Retain root across LineageOS nightlies |
| [Technical Architecture](ARCHITECTURE.md) | Hardware TZASC, Manual Hooks, Dynamic UAPI, and SUSFS |
| [Contributing Guidelines](CONTRIBUTING.md) | Submitting fixes and porting to other Exynos devices |
| [Documentation Hub](README.md) | Master documentation index |
