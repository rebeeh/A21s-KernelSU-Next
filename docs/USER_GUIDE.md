# End-User Installation & Usage Guide

This guide is for users of the **Samsung Galaxy A21s (`SM-A217F`)** who want to install KernelSU-Next using pre-compiled releases. **No kernel compilation is required.**

---

## Downloads

Download the latest pre-compiled files from the [GitHub Releases](https://github.com/rebeeh/A21s-KernelSU-Next/releases) tab:

| File Name | Purpose | Flashing Tool |
|---|---|---|
| `KernelSU-Next-A21s-universal850-AnyKernel3.zip` | Flashable ZIP (Easiest) | Lineage Recovery / TWRP / OrangeFox |
| `boot-ksu.tar` | Odin AP package | Samsung Odin (Windows) |
| `boot-ksu.img` | Raw boot partition image | `samloader` / `heimdall` (Linux / Mac) |
| `KernelSU_Next_v3.4.2.apk` | Official Root Manager app | Android Package Installer / ADB |

---

## Installation Methods

### Method 1: Recovery Flash (Recommended — No PC needed!)

1. Copy `KernelSU-Next-A21s-universal850-AnyKernel3.zip` to your phone's internal storage or SD card.
2. Reboot into Recovery:
   - Power off, hold `Volume Up` + `Power`, or run:
     ```bash
     adb reboot recovery
     ```
3. In Recovery:
   - **TWRP / OrangeFox:** Tap **Install** -> Select the `.zip` -> Swipe to Flash.
   - **Lineage Recovery:** Tap **Apply update** -> **Apply from ADB** -> On PC run:
     ```bash
     adb sideload KernelSU-Next-A21s-universal850-AnyKernel3.zip
     ```
     *(If prompted "Signature verification failed. Install anyway?", choose **Yes**).*
4. Tap **Reboot system now**.

---

### Method 2: Flash via `samloader` (Linux / Mac)

1. Put the phone into Download Mode:
   ```bash
   adb reboot download
   ```
2. Flash the boot image:
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```
3. The phone will reboot automatically.

---

### Method 3: Flash via Odin (Windows)

1. Put the phone into Download Mode.
2. Launch **Odin3 v3.14.4**.
3. Verify your phone appears under `ID:COM`.
4. Click **AP** and select `boot-ksu.tar`.
5. Click **Start**. Wait for the green `PASS!` text, and your phone will reboot.

---

## Setting Up the Manager & Granting Root

1. After booting into LineageOS, install the Manager APK:
   ```bash
   adb install KernelSU_Next_v3.4.2.apk
   ```
   *(Or download and install it directly using your phone's browser).*
2. Open the **KernelSU Next** app.
3. You will see:
   - **Status:** `Working [BUILT-IN (GKI1)]`
   - **Hook mode:** `Manual`
4. Tap the **Superuser (Shield)** icon on the bottom navigation bar to grant root access to apps!
