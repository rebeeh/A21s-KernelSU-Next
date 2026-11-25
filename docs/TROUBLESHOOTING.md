# 🛠️ Troubleshooting & Diagnostics Guide

> Diagnose, log, and fix common issues with KernelSU-Next on the Galaxy A21s / SM-A217F running LineageOS 24.

---

## ⚡ Quick Diagnosis

Use this table to jump straight to your symptom:

| Symptom | Jump To |
|---|---|
| Manager shows **"Unsupported \| Not Integrated"** | [Issue 1 — Manager Not Integrated](#-issue-1-manager-shows-unsupported--not-integrated) |
| Pink banner: **"Manager version too low / high"** | [Issue 2 — UAPI Version Mismatch](#-issue-2-pink-banner-manager-version-too-lowhigh) |
| Device **bootloops** on Samsung logo | [Issue 3 — Bootloop on Samsung Logo](#-issue-3-device-bootloops-on-samsung-logo) |
| **Root lost** after LineageOS update | [Issue 4 — Root Lost After OTA Update](#-issue-4-root-lost-after-lineageos-ota-update) |
| Root Checker says **"not properly installed"** | [Issue 5 — Root Checker Fails](#-issue-5-root-checker-says-root-not-properly-installed) |
| `adb shell su` returns **"inaccessible or not found"** | [Blindspot 1 — ADB Shell su Fails](#-blindspot-1-adb-shell-su-fails) |
| A **module** causes a bootloop | [Blindspot 2 — Module-Induced Bootloop](#-blindspot-2-incompatible-module-causing-bootloop) |
| Manager shows **"ZYGISK REQUIRED"** on active modules | [Issue 6 — Zygisk Required Badge in Manager](#-issue-6-manager-shows-zygisk-required-badge-on-active-modules) |
| **Banking / Play Integrity** apps fail / UNEVALUATED | [Blindspot 4 — Play Integrity, Knox & Keybox](#-blindspot-4-google-play-integrity-knox-tripping--hardware-attestation) |
| Root disappears after **every LineageOS nightly** | [Blindspot 5 — Dynamic Partitions & OTA Updates](#-blindspot-5-dynamic-partitions--lineageos-nightly-updates) |
| None of the above — need to report a bug | [How to Report an Issue](#-how-to-report-an-issue) |

---

## 🔰 Before You Begin

Before diving into diagnostics, confirm the following:

1. **Kernel version** — You are running the latest `KernelSU-Next-A21s` release from the [releases page](https://github.com/rebeeh/A21s-KernelSU-Next/releases).
2. **Manager APK** — The KernelSU Next Manager APK on your phone matches the kernel's UAPI version (or pin to `v3.4.2 (33355-5)` if unsure).
3. **ROM** — Your device is running **LineageOS 24** on a **Galaxy A21s (SM-A217F)** with an unlocked bootloader.
4. **USB Debugging** — Enabled in *Settings → About Phone → (tap Build Number 7×) → Developer Options → USB Debugging*.

---

## 📋 Section 1 — Log Extraction

When reporting any kernel crash, bootloop, or unexpected root behavior, **logs are mandatory**. Three methods are available — choose what works for your situation.

---

### 🖥️ Method A: 1-Click Desktop Reporter (`python build.py report-issue`)

> [!TIP]
> **Recommended** when your PC is nearby — works whether the phone is booted into Android, Recovery, or TWRP.

**Steps:**

1. Connect your Galaxy A21s to your PC via USB.
2. Open a terminal in the project root and run:
   ```bash
   python build.py report-issue
   ```
3. The script automatically:
   - Detects your device via ADB.
   - Extracts preserved kernel panics (`/sys/fs/pstore/dmesg-ramoops-0`), live kernel messages (`dmesg`), Android framework logs (`logcat`), and KernelSU-Next daemon status (`ksud debug info`).
   - Packages everything into a timestamped archive: `out/logs/issue_report_<timestamp>.log`.
   - Opens your browser with a **pre-filled GitHub bug report** containing your device model, LineageOS version, and the fatal crash stack trace.
4. Drag and drop the generated log file onto the GitHub issue form and submit.

---

### 📱 Method B: On-Device Boot Crash Popup Reporter

> [!NOTE]
> Works **directly on your phone** after recovering from a bootloop or crash — no PC required.

This uses the autonomous service script: [`tools/crash_reporter/00_ksu_crash_reporter.sh`](../tools/crash_reporter/00_ksu_crash_reporter.sh).

**Setup (one-time):**

Install the script to KernelSU-Next's service directory:
```bash
adb push tools/crash_reporter/00_ksu_crash_reporter.sh /data/adb/service.d/00_ksu_crash_reporter.sh
adb shell chmod +x /data/adb/service.d/00_ksu_crash_reporter.sh
```

**What it does on every boot:**

1. Checks if a kernel panic occurred on the prior boot (`/sys/fs/pstore/dmesg-ramoops-0`).
2. If a crash is detected, copies the full crash dump to your storage:
   ```
   /sdcard/Download/ksu_crash_<timestamp>.log
   ```
3. Uploads an anonymous log paste (no account required) via [paste.rs](https://paste.rs) and triggers a persistent **"Kernel Crash Detected"** system notification containing the web link.
4. Opens your browser with a **pre-filled GitHub issue draft** containing the panic trace.

---

### 🔧 Method C: Manual Log Extraction via ADB

Use this method if you prefer full control or if the automated methods are unavailable.

#### C1 — Kernel Crash / Bootloop Log (`pstore` / `ramoops`)

Linux saves kernel panics into persistent RAM (`pstore`) automatically. Retrieve it after a crash:

1. Boot your phone into **Recovery Mode** (hold `Volume Up` + `Power`).
2. Connect the phone to your PC via USB.
3. Pull the preserved crash log:
   ```bash
   adb shell cat /sys/fs/pstore/dmesg-ramoops-0 > ramoops.log
   adb shell cat /sys/fs/pstore/console-ramoops-0 >> ramoops.log 2>/dev/null || true
   ```
4. Attach `ramoops.log` to your GitHub issue.

#### C2 — Live Kernel Log (`dmesg`)

Use this when the phone boots normally but root or a module isn't working:
```bash
adb shell dmesg > dmesg.log
```

#### C3 — Android System Log (`logcat`)

Use this to capture Android framework errors or app-level root rejections:
```bash
adb logcat -d > logcat.log
```

#### C4 — KernelSU-Next Daemon Log (`ksud`)

Use this to inspect the status of the `ksud` daemon and enabled features:
```bash
adb shell "/data/adb/ksud feature list" > ksu_features.log
adb shell "/data/adb/ksud -V" >> ksu_features.log
```

---

### 🔗 No GitHub Account? No Problem.

Both `build.py report-issue` and `00_ksu_crash_reporter.sh` generate an **anonymous online log link** via [paste.rs](https://paste.rs) (e.g. `https://paste.rs/xyz123`) — no account needed.

Your raw log is also always saved locally:
- **On phone:** `/sdcard/Download/ksu_crash_<timestamp>.log`
- **On PC:** `out/logs/`

> [!TIP]
> No GitHub account? Share the paste.rs link or the log file in community support channels: [XDA Developers](https://xdaforums.com) thread, Telegram group, or Discord.

If you do have a GitHub account but aren't logged in, GitHub will show its login screen. The `return_to` parameter in the URL preserves your entire draft — just log in and you'll land right back on the pre-filled issue form.

---

## 🐛 Section 2 — Common Issues & Solutions

---

### 🔴 Issue 1: Manager Shows "Unsupported | Not Integrated"

| | |
|---|---|
| **Cause** | Kernel was compiled without `CONFIG_KSU_MANUAL_HOOK=y` or without manual hook patches applied. |
| **Fix** | Verify `CONFIG_KSU_MANUAL_HOOK=y` is set in your `.config`, then rebuild: `./scripts/build.sh` |

**Steps to verify:**
1. In your build environment, run:
   ```bash
   grep CONFIG_KSU_MANUAL_HOOK out/.config
   ```
2. Expected output: `CONFIG_KSU_MANUAL_HOOK=y`
3. If missing or set to `n`, update `.config` and rebuild.

---

### 🟡 Issue 2: Pink Banner — "Manager Version Too Low/High"

| | |
|---|---|
| **Cause** | UAPI version mismatch between the kernel driver and the Manager APK. |
| **Fix** | The kernel's **Dynamic UAPI Resolution Engine** handles this automatically. If the banner persists, pin your Manager APK to `v3.4.2 (33355-5)`. |

> [!NOTE]
> See [Blindspot 3 — UAPI Version Lock](#-blindspot-3-future-manager-apk-updates-the-uapi-version-lock) for a full technical breakdown of how the Dynamic UAPI Engine works.

---

### 🔴 Issue 3: Device Bootloops on Samsung Logo

| | |
|---|---|
| **Cause** | `CONFIG_KSU_KPROBES_HOOK=y` was used. Dynamic kprobes trigger Samsung's hardware TZASC IRQ 160 on the Exynos 850, causing an unrecoverable bootloop. |
| **Fix** | Flash `boot-ksu.img` built with `CONFIG_KSU_MANUAL_HOOK=y`. **Never use dynamic kprobes on the Exynos 850.** |

> [!CAUTION]
> Do not flash a kprobes-based kernel image on the Galaxy A21s (SM-A217F). The Exynos 850 platform is incompatible with dynamic kprobes hooks.

---

### 🟡 Issue 4: Root Lost After LineageOS OTA Update

| | |
|---|---|
| **Cause** | LineageOS OTA overwrote the `/boot` partition with the stock upstream kernel, removing KernelSU-Next. |
| **Fix** | Re-flash the KernelSU-Next AnyKernel3 zip in Recovery immediately after the OTA completes. |

**Steps:**
1. When the LineageOS updater finishes, **do not tap "Restart"** — boot into Recovery instead.
2. In Recovery, flash:
   [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip)
3. Reboot to system. Root and all module permissions are restored.

> [!TIP]
> Keep this zip saved on your device storage or microSD card at all times so you can re-flash in seconds after any OTA. See [Blindspot 5](#-blindspot-5-dynamic-partitions--lineageos-nightly-updates) for the full workflow.

---

### 🟢 Issue 5: Root Checker Says "Root Not Properly Installed"

| | |
|---|---|
| **Cause** | KernelSU-Next uses a strict **App Isolation & Allowlist model**. By default, all apps that have not been explicitly granted root see `ENOENT` (file not found) when probing for `su`. This is intentional — it's what allows banking apps to pass integrity checks natively. |
| **Fix** | Grant the app Superuser access in the KernelSU Next Manager. |

**Steps:**
1. Open the **KernelSU Next** app on your phone.
2. Tap the **Superuser (Shield)** tab.
3. Find the app (e.g. `Root Checker Basic`) in the list.
4. Toggle **Superuser** to **ON**.
5. Re-run the root checker — it will immediately show verified root access.

---

### 🟢 Issue 6: Manager Shows "ZYGISK REQUIRED" Badge on Active Modules

| | |
|---|---|
| **Cause** | KernelSU-Next Manager checks `getenv("ZYGISK_ENABLED")` in its JNI layer (`is_zygisk_enabled()`). Standalone Zygisk injectors (like ReZygisk) hook Zygote and target apps via ptrace, but do not set this environment variable inside the Manager app's process space. The "ZYGISK REQUIRED" chip is purely a visual indicator from the Manager UI. |
| **Verification** | The modules are **fully operational and active**. ReZygisk shows `[Monitor: ✅, ReZygisk 64-bit: ✅, ReZygisk 32-bit: ✅]`, Vector operates on API Version 102, and HMA-OSS displays `[✅ System service loaded]`. |

**How to verify real Zygisk status:**
1. Run `adb shell cat /data/adb/modules/rezygisk/module.prop` — verify both 64-bit and 32-bit monitors show green checkmarks.
2. Check `adb shell "/data/adb/modules/zygisk_vector/bin/vector-arm64 --version"` — confirms the Vector hooking framework daemon is running.
3. Check HMA-OSS in `module.prop` or open the HMA-OSS app — it confirms `[System service loaded]`.

---

## 🛡️ Section 3 — Critical Blindspots & Edge-Case Management

These are known engineering edge cases when running KernelSU-Next on the Galaxy A21s (SM-A217F) under LineageOS 24, with their built-in mitigations explained.

---

### 🔵 Blindspot 1: `adb shell su` Fails

**Symptom:**
```
/system/bin/sh: su: inaccessible or not found
```

**Root Cause:**

ADB shell runs under `com.android.shell` (UID 2000). KernelSU-Next enforces kernel-level UID stealth isolation for all non-granted UIDs — the kernel returns `-ENOENT` when Shell probes `/system/bin/su` unless it has been explicitly allowed.

**Fix — Option A (Grant Shell Root Access):**

1. Open **KernelSU Next Manager** → tap the **Superuser (Shield)** tab.
2. Tap the **⋮ (3-dot menu)** in the top-right corner → select **Show system apps**.
3. Locate **Shell** (`com.android.shell` / UID 2000).
4. Toggle **Superuser** to **ON**.
5. Run `adb shell su` — you will now land at `root@a21s:/ #`.

**Fix — Option B (Enable ADB Root in Settings):**

1. Open **KernelSU Next Manager** → tap **Settings (⚙️ gear icon)**.
2. Toggle **ADB Root** to **ON**.
3. Reconnect ADB (`adb kill-server && adb start-server`) and run `adb shell su`.

---

### 🔵 Blindspot 2: Incompatible Module Causing Bootloop

**Risk:**

An untested Zygisk/Magisk module (e.g. an outdated audio mod, aggressive font pack, or incompatible Riru module) causes `system_server` or Zygote to crash continuously during boot.

> [!IMPORTANT]
> You do **NOT** need to wipe data, format `/data`, or reinstall the ROM to recover from this.

**Fix — Option A: Hardware Safe Mode (Physical Button)**

1. Power on the device.
2. As soon as the **Samsung Galaxy** splash screen appears, **press and hold `Volume Down`** continuously.
3. Keep holding until the device vibrates and reaches the lockscreen.
4. KernelSU-Next intercepts the key event during early init and creates `/data/adb/modules/.disable`, skipping all module execution.
5. Once in Safe Mode, open **KernelSU Next Manager**, uninstall the problematic module, and reboot normally.

**Fix — Option B: Manual Recovery via TWRP / Lineage Recovery**

If the physical button method is unavailable:

1. Boot into Recovery.
2. Connect USB and run:
   ```bash
   adb shell touch /data/adb/modules/.disable
   ```
3. Reboot to system. All modules are skipped on the next boot.
4. Open KernelSU Next Manager, remove the bad module, delete the `.disable` flag, and reboot.

---

### 🔵 Blindspot 3: Future Manager APK Updates (The UAPI Version Lock)

**Risk:**

An automated app updater or manual upgrade installs a Manager APK that expects a different UAPI version (e.g. UAPI 6 instead of UAPI 5).

**Symptom:**

The Manager displays a pink warning banner:
> *"The current KernelSU-Next manager version is too low/high for KernelSU-Next to work properly."*

The Superuser and Module tabs become disabled.

**Solution — Dynamic UAPI Resolution Engine (3-Layer System):**

The kernel integrates a 3-layer Dynamic UAPI Engine so that a full kernel recompile is never required just because the Manager APK was updated:

**Layer 1 — Dynamic Supercall Runtime Override (`CHANGE_UAPIVER = 10013`):**

Root can dynamically reconfigure the kernel's reported UAPI version on demand without rebooting:
```c
// Switch reported UAPI version to 6 at runtime
syscall(__NR_reboot, 0xDEADBEEF, 10013, 6, &reply);
```
The kernel immediately updates its internal state and responds to all subsequent queries with the new version.

**Layer 2 — Caller Auto-Negotiation Reflection:**

When a caller issues `ioctl(fd, KSU_IOCTL_GET_INFO, &info)` with `info.uapi_version` initialized to a supported version (4 ≤ UAPI ≤ 16), the kernel driver inspects `in_cmd` via `copy_from_user` and dynamically reflects the requested version back — providing instant forward and backward compatibility with no user action required.

**Layer 3 — Kernel Command-Line Boot Parameter (`ksu.uapi=X`):**

The kernel exposes the `uapi` parameter via `module_param_named(uapi, ksu_uapi_override, uint, 0)`. Specify the target version directly in bootargs without modifying source code:
```
ksu.uapi=6
```

> [!NOTE]
> As a last resort, you can always pin the Manager APK to `v3.4.2 (33355-5)`, which is fully validated against this kernel build.

---

### 🔵 Blindspot 4: Google Play Integrity, Knox Tripping & Hardware Attestation

**Architecture Background:**

1. **Kernel-Level (Ring 0) Concealment**:
   - **KernelSU-Next + SUSFS** operates inside kernel space. It makes the root implementation, `/system/bin/su`, overlay mounts, and Zygisk injection completely invisible to userspace scanners.
   - Built-in features active in this build:
     | Feature | Supercall ID | Effect |
     |---|---|---|
     | `kernel_umount` | `ID=1` | Unmounts module namespaces for unauthorized apps |
     | `selinux_hide` | `ID=4` | Sanitizes `/sys/fs/selinux` access results per app UID |
     | `avc_spoof` | `ID=10003` | Suppresses SELinux audit logs that leak root context |
     | `susfs_vfs` | `0xFAFAFAFA` | Kernel VFS-level directory and path concealment |

2. **The Cryptographic Barrier: Knox efuse (0x1) & Hardware Attestation**:
   - On custom ROMs (LineageOS), Samsung's `hal_keymaster_default` is initially blocked by SELinux from accessing `/mnt/vendor/efs/DAK/`:
     ```text
     avc: denied { search } for name="DAK" dev="mmcblk0p1" scontext=u:r:hal_keymaster_default:s0 tcontext=u:object_r:prov_efs_file:s0
     keymaster_tee: Cannot open /mnt/vendor/efs/DAK/GAK_RSA.private, ret -932
     ```
   - When SELinux blocks DAK access or if the physical Knox warranty bit (`0x1`) is tripped without fallback, Keymaster returns error `-932`.
   - **Resolution applied (built into kernel)**: These SELinux policy rules are embedded directly in `KernelSU-Next/kernel/selinux/rules.c` (`patches/0003-kernelsu-next-samsung-fixes.patch`) so they apply automatically at boot on all custom ROMs without manual `post-fs-data.d` scripts:
     ```text
     allow hal_keymaster_default prov_efs_file dir { search read open getattr }
     allow hal_keymaster_default prov_efs_file file { read open getattr }
     allow hal_keymaster_default efs_file dir { search read open getattr }
     allow hal_keymaster_default efs_file file { read open getattr }
     ```
   - **Recommended Module Setup (No Redundant Modules)**: Use **[AlwaysStrong](https://gitlab.com/Evokerr/AlwaysStrong/-/releases)** (`AlwaysStrong-v1.0.6.1.zip`) as a single all-in-one Play Integrity module instead of stacking separate `PlayIntegrityFork` + `Tricky Store` + `Yurikey` modules (which duplicate hooks and can conflict). If using standalone Tricky Store instead, never leave its default `DeviceID="sw"` keybox or a revoked public keybox active, as that forces `UNEVALUATED`.
   - With Keymaster DAK access restored, Play Integrity elevates from `UNEVALUATED` (3 Red X's) to:
     - `MEETS_BASIC_INTEGRITY`: **PASSED (Green Checkmark)**
     - `appRecognitionVerdict`: **`PLAY_RECOGNIZED`**
     - `appLicensingVerdict`: **`LICENSED`**
     - `playProtectVerdict`: **`NO_ISSUES`**
     - `deviceActivityLevel`: **`LEVEL_1`**

**Why the Kernel Alone Cannot Forge Strong Integrity:**

- KernelSU-Next and SUSFS hide root, process trees, and filesystem modifications from userspace apps.
- However, Google's `MEETS_STRONG_INTEGRITY` verdict is evaluated on **Google's cloud servers**, which verify the asymmetric RSA signature against Google's trusted hardware OEM root certificates.
- The kernel cannot forge Google's cloud-validated cryptographic signature.
- As detailed in the deployment specification:
  > *"A valid keybox environment passes MEETS_STRONG_INTEGRITY through Google Play Integrity. The server receives a hardware-backed cryptographic verdict that matches an untouched device baseline... Ensure your keybox is configured and Google Play Integrity returns a passing device verdict."*
- To pass `MEETS_STRONG_INTEGRITY`, an unrevoked, private OEM `keybox.xml` must be loaded by the hardware keystore attestation injector. Public keyboxes get banned by Google within days. Once a valid private keybox is configured and Google Play Services is authenticated, `MEETS_DEVICE_INTEGRITY` and `MEETS_STRONG_INTEGRITY` pass cleanly.

---

### 🔵 Blindspot 5: Dynamic Partitions & LineageOS Nightly Updates

**Architecture Background:**

The Galaxy A21s (SM-A217F) uses Samsung dynamic partitions — a `super` block device holding `/system`, `/vendor`, and `/product`. However, the `/boot` partition is a **standalone, non-A/B partition** (`/dev/block/by-name/boot`).

**The Blindspot:**

Every LineageOS nightly or weekly OTA completely overwrites `/boot` with the upstream stock kernel, which removes KernelSU-Next until you re-flash it.

**The 5-Second Solution:**

1. Keep [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) saved on your device storage or microSD card.
2. When the LineageOS updater finishes, **boot into Recovery** before restarting into system.
3. Flash [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) from Recovery.
4. AnyKernel3 extracts the new LineageOS ramdisk, swaps the kernel `Image`, and repacks the partition on the fly in approximately 5 seconds.
5. Reboot to system. Root, modules, and all app permissions remain 100% intact.

> [!TIP]
> Set a reminder or use the LineageOS updater's pre-install script hook to automate this step so you never lose root after an OTA.

---

## 📣 Section 4 — How to Report an Issue

Before opening a GitHub issue, run through this checklist:

1. **Search closed issues first** — check [Closed Issues](https://github.com/rebeeh/A21s-KernelSU-Next/issues?q=is%3Aissue+is%3Aclosed) to see if a fix already exists.
2. **Update to the latest release** — confirm you are on the most recent kernel build from the [releases page](https://github.com/rebeeh/A21s-KernelSU-Next/releases).
3. **Collect your logs** — use [Method A](#️-method-a-1-click-desktop-reporter-python-buildpy-report-issue), [Method B](#-method-b-on-device-boot-crash-popup-reporter), or [Method C](#-method-c-manual-log-extraction-via-adb) above.
4. **Open a new issue** using the **Bug Report Template** and include:

   | Field | Example |
   |---|---|
   | Device Model | `SM-A217F` |
   | LineageOS Build Date | From *Settings → About Phone* |
   | Log file | `ramoops.log` (bootloop/crash) or `dmesg.log` (runtime issue) |

> [!IMPORTANT]
> Issues submitted without logs may be closed without investigation. The automated reporters (Methods A & B) make this a one-click step.

---

## 🔗 Related Docs

| Document | Description |
|---|---|
| [📖 User Installation Guide](USER_GUIDE.md) | Beginner-friendly installation and root setup |
| [⚡ Flashing Methods Guide](FLASHING_GUIDE.md) | Step-by-step flashing guide for AnyKernel3 zip, samloader, Odin, and Heimdall |
| [🛠️ Kernel Build Guide](BUILD.md) | Full kernel build instructions, Docker, and CI options |
| [🔄 OTA Updates Survival](OTA_AND_UPDATES.md) | Retain root across LineageOS updates |
| [🏗️ Technical Architecture](ARCHITECTURE.md) | Deep dive on Exynos 850 TrustZone, TZASC, and SUSFS |
| [🔬 Research & Implementation Report](RESEARCH.md) | Engineering analysis, kprobe disassembly, and UAPI |
| [🤝 Contributing Guidelines](CONTRIBUTING.md) | How to submit patches, report bugs, and test variants |
| [📚 Documentation Hub](README.md) | Master index and navigation hub |