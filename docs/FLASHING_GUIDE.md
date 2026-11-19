# Flashing & Installation Guide: Galaxy A21s

This guide provides tested instructions for flashing the KernelSU-Next custom kernel onto the **Samsung Galaxy A21s (`SM-A217F`)**.

---

## Prerequisites

- Samsung Galaxy A21s with **unlocked bootloader**.
- Installed ROM: **LineageOS 24 (Android 17 / SDK 37)**.
- USB cable and PC running Linux or Windows.
- Backup of stock `boot.img`.

---

## Method 1: Using `samloader` on Linux (Recommended & Fastest)

`samloader` flashes partitions directly in Samsung Download Mode in ~1 second.

1. Reboot your phone into Download Mode:
   ```bash
   adb reboot download
   ```
   *(Alternatively: Power off, hold `Volume Up` + `Volume Down`, and plug in the USB cable connected to PC).*

2. Flash the boot image:
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```

3. The phone will automatically reboot into LineageOS.

---

## Method 2: Using AnyKernel3 in Recovery (No PC Required!)

1. Copy `KernelSU-Next-A21s-universal850-AnyKernel3.zip` to internal storage or SD card.
2. Boot into Recovery (TWRP / OrangeFox / Lineage Recovery).
3. Select **Install** / **Apply Update** -> flash the `.zip`.
4. Reboot system.

---

## Method 3: Using Odin on Windows

1. Boot device into Download Mode.
2. Open **Odin v3.14.4** on Windows.
3. Verify that your device is detected (blue `[COM:XX]` box in Odin).
4. Click **AP** and select the generated archive:
   `boot-ksu.tar`
5. Uncheck **Auto Reboot** (optional).
6. Click **Start**. Once `PASS!` is displayed, reboot the phone.

---

## Method 4: Using Heimdall on macOS & Linux

1. Boot device into Download Mode.
2. Verify device detection:
   ```bash
   heimdall detect
   ```
3. Flash the boot partition:
   ```bash
   heimdall flash --BOOT boot-ksu.img --no-reboot
   ```
4. Hold `Volume Down` + `Power` to reboot normally.

---

## Post-Boot Verification

1. Install the official **KernelSU-Next Manager APK**:
   ```bash
   adb install KernelSU_Next_v3.4.2.apk
   ```
2. Open the **KernelSU Next** app from your launcher.
3. Verify the home card displays:
   - **Status:** `Working [BUILT-IN (GKI1)]`
   - **Hook mode:** `Manual`
   - **Manager version:** `v3.4.2 (33355-5)`
4. Navigate to the **Superuser (Shield)** tab to manage root access for apps.
