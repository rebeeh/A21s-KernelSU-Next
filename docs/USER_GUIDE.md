# 📖 User Guide — KernelSU-Next on Galaxy A21s

**TL;DR:** Flash a pre-built KernelSU-Next kernel onto your Samsung Galaxy A21s (SM-A217F) running LineageOS 24, install the manager app, and get kernel-level root — no compilation required.

---

## 🗺️ Jump to What You Need

| I want to… | Go to |
| :--- | :--- |
| Download the files | [📦 Downloads](#-downloads) |
| Check if my ROM is supported | [📱 ROM Compatibility](#-rom--boot-image-compatibility-matrix) |
| Flash using recovery (easiest, no PC) | [Method 1 — Recovery Flash](#method-1-recovery-flash-recommended--no-pc-needed) |
| Flash using `samloader` on Linux/Mac | [Method 2 — samloader](#method-2-flash-via-samloader-linux--mac) |
| Flash using Odin on Windows | [Method 3 — Odin](#method-3-flash-via-odin-windows) |
| Install the manager & grant root | [🔑 Setting Up the Manager](#-setting-up-the-manager--granting-root) |
| Understand why root checkers show "not installed" | [🔒 Root Checker Note](#-why-root-checker-shows-not-properly-installed-at-first) |

---

## 🛠️ Before You Begin

Before flashing anything, make sure you have all of the following in place:

- **Device:** Samsung Galaxy A21s (`SM-A217F`)
- **ROM:** LineageOS 24 (Android 17) installed and booting correctly
  > [!WARNING]
  > Stock Samsung OneUI (OneUI 2, 3, or 4) is **not supported**. The kernel ABI is incompatible. Do not attempt to flash on stock firmware.
- **Recovery** (for Method 1): [TWRP](https://twrp.me), [OrangeFox](https://orangefox.download), or Lineage Recovery already installed
- **USB debugging** enabled *(Settings → About Phone → tap Build Number 7× → Developer Options → USB Debugging)*
- **ADB** installed on your PC if you plan to use a PC method — [platform-tools download](https://developer.android.com/tools/releases/platform-tools)
- A **full backup** of your data — flashing a kernel carries a small risk; always back up first

---

## 📦 Downloads

Download the latest pre-compiled release files from the [GitHub Releases](https://github.com/rebeeh/A21s-KernelSU-Next/releases) page:

| File | Purpose | Flashing Tool |
| :--- | :--- | :--- |
| [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.0.0/KernelSU-Next-A21s-universal850-AnyKernel3.zip) | Flashable ZIP — easiest method, works with any AOSP ROM | Lineage Recovery / [TWRP](https://twrp.me) / [OrangeFox](https://orangefox.download) |
| [`boot-ksu.tar`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.0.0/boot-ksu.tar) | Odin AP package — for Windows users | [Samsung Odin](https://odindownload.com) |
| [`boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.0.0/boot-ksu.img) | Raw boot partition image — for Linux/Mac users | [`samloader`](https://github.com/topjohnwu/samloader-rs) / [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall) |
| [`KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) | Official KernelSU-Next root manager app | Android Package Installer / ADB |

> [!TIP]
> **Not sure which file to grab?** If you're on LineageOS 24 and just want the simplest path, download the `.zip` and the `.apk` — that's all you need for Method 1.

---

## 📱 ROM & Boot Image Compatibility Matrix

| ROM | AnyKernel3 Zip | `boot-ksu.img` / `boot-ksu.tar` | Notes |
| :--- | :---: | :---: | :--- |
| **LineageOS 24 (Android 17)** | ✅ Supported | ✅ Supported | Native target ROM. The prebuilt `boot-ksu.img` was built against the LineageOS 24 ramdisk. |
| **Other AOSP ROMs** (crDroid, PixelOS, LineageOS 20/21) | ✅ Supported | ⚠️ Requires Repack | Flash via the **AnyKernel3 Zip** in recovery — it preserves your ROM's own ramdisk. Do **not** flash `boot-ksu.img` directly on these ROMs. |
| **Stock Samsung OneUI** (OneUI 2, 3, 4) | ❌ Not Compatible | ❌ Not Compatible | Incompatible kernel ABI. Stock OneUI requires Samsung's proprietary DEFEX, Knox, and 32-bit Binder IPC drivers. |

> [!IMPORTANT]
> If you are on **any ROM other than LineageOS 24**, always use the **AnyKernel3 Zip** method (Method 1). Flashing the raw `boot-ksu.img` on a different ROM will brick your boot partition.

---

## ⚡ Installation Methods

### Method 1: Recovery Flash (Recommended — No PC needed!)

This is the easiest method. It works on-device using TWRP, OrangeFox, or Lineage Recovery.

1. Copy `KernelSU-Next-A21s-universal850-AnyKernel3.zip` to your phone's internal storage or SD card.
2. Reboot into Recovery using one of the following:
   - **Hardware keys:** Power off the phone, then hold `Volume Up` + `Power` simultaneously until the recovery screen appears.
   - **ADB (if phone is on and USB-connected):**
     ```bash
     adb reboot recovery
     ```
3. Flash the zip file from within your recovery:
   - **[TWRP](https://twrp.me) or [OrangeFox](https://orangefox.download):**
     1. Tap **Install**.
     2. Navigate to and select `KernelSU-Next-A21s-universal850-AnyKernel3.zip`.
     3. Swipe to Flash.
   - **Lineage Recovery:**
     1. Tap **Apply update** → **Apply from ADB**.
     2. On your PC, run:
        ```bash
        adb sideload KernelSU-Next-A21s-universal850-AnyKernel3.zip
        ```
     > [!NOTE]
     > If Lineage Recovery prompts **"Signature verification failed. Install anyway?"**, choose **Yes** — this is expected for third-party zips.
4. Once flashing completes, tap **Reboot system now**.

---

### Method 2: Flash via [`samloader`](https://github.com/topjohnwu/samloader-rs) (Linux / Mac)

Use this method if you are on Linux or macOS and prefer a command-line tool.

1. Put the phone into Download Mode:
   ```bash
   adb reboot download
   ```
2. Flash the boot image:
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```
3. The phone will reboot automatically once flashing is complete.

> [!NOTE]
> Alternatively, you can use [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall) with `boot-ksu.img` if you prefer that tool.

---

### Method 3: Flash via Odin (Windows)

Use this method if you are on Windows.

1. Put the phone into Download Mode (power off, then hold `Volume Down` + `Bixby` + `USB connected`, or run `adb reboot download`).
2. Launch **[Odin3 v3.14.4](https://odindownload.com)** on your PC.
3. Verify that your phone appears under the `ID:COM` section in Odin (it should show a blue box with a port number).
4. Click the **AP** button and select `boot-ksu.tar`.
5. Click **Start** and wait for the green **`PASS!`** message — your phone will reboot automatically.

> [!CAUTION]
> Do **not** enable any extra Odin options (Re-Partition, Auto-Reboot toggling, etc.). Use the default Odin settings to avoid unintended side effects.

---

## 🔑 Setting Up the Manager & Granting Root

After your phone has booted into LineageOS 24 with the new kernel, install the KernelSU-Next manager app:

1. Install the Manager APK using **one** of these two ways:
   - **Via ADB (PC required):**
     ```bash
     adb install KernelSU_Next_v3.4.2.apk
     ```
   - **Directly on the phone:** [Download `KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) in your phone's browser and open it to install.

2. Open the **KernelSU Next** app.
3. Confirm the kernel is active — you should see:
   - **Status:** `Working [BUILT-IN (GKI1)]`
   - **Hook mode:** `Manual`
4. Tap the **Superuser (Shield)** icon in the bottom navigation bar to manage root access for your apps.

> [!TIP]
> If the status does not show `Working`, double-check that the kernel was flashed correctly by repeating the installation step and rebooting again.

---

## 🔒 Why Root Checker Shows "Not Properly Installed" at First

If you install a root detection app like **Root Checker Basic** from the Play Store and open it immediately after setup, it will show:

> ❌ *"Sorry! Root access is not properly installed on this device."*

**This is completely normal and by design.** Here is why:

### KernelSU-Next vs. Magisk: Two Different Security Models

| | Magisk (Legacy) | KernelSU-Next |
| :--- | :--- | :--- |
| **How root is exposed** | Installs `/system/bin/su` globally — any app can see it | Hides `su` at the kernel level from all unapproved apps |
| **What an unapproved app sees** | Root present (detectable) | `-ENOENT` (File Not Found) — looks completely unrooted |
| **Banking apps / Google Wallet** | Often detected and blocked | Run natively without detection |
| **Security model** | Global, opt-out | Per-app allowlist, opt-in |

KernelSU-Next uses a **kernel driver** that completely hides `su` and all root capabilities from any app that has not been explicitly granted access. When an unapproved app checks for root, the kernel returns `-ENOENT` (File Not Found) — the app believes the device is 100% unrooted.

### How to Grant Root Access to an App

1. Open the **KernelSU Next** app.
2. Tap the **Superuser (Shield)** tab at the bottom.
3. Locate the app you want to grant root to (e.g., **Root Checker Basic**).
4. Tap the app entry and toggle **Superuser** to **ON**.
5. Switch back to that app — it will now have full root permissions:
   > ✅ *"Congratulations! Root access is properly installed on this device!"*

> [!NOTE]
> This per-app grant system is what keeps banking apps, Google Wallet, games, and work profiles running without root detection — only apps you explicitly trust ever know root exists.

---

## 🔗 Related Docs

| Document | Description |
| :--- | :--- |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | How to compile the kernel from source |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute patches and improvements |
| [README.md](../README.md) | Project overview, feature list, and changelog |
