# ⚡ Flashing & Installation Guide — Galaxy A21s KernelSU-Next

Flash the KernelSU-Next custom kernel onto your **Samsung Galaxy A21s (`SM-A217F`)** running **LineageOS 24** using whichever tool fits your platform and comfort level.

---

## 🗺️ Jump To What You Need

| Method | Platform | Requires PC? | Speed | Best For |
|--------|----------|:------------:|-------|----------|
| [Method 1 — `samloader`](#-method-1-samloader-linux--recommended) | Linux | ✅ Yes | ⚡ ~1 s | Developers, fastest flash |
| [Method 2 — AnyKernel3 (Recovery)](#-method-2-anykernel3-via-recovery-no-pc-required) | Any | ❌ No PC needed | 🐢 ~1 min | Easiest, no cable required |
| [Method 3 — Odin](#-method-3-odin-windows) | Windows | ✅ Yes | 🚀 Fast | Windows users |
| [Method 4 — Heimdall](#-method-4-heimdall-macos--linux) | macOS / Linux | ✅ Yes | 🚀 Fast | macOS or Linux, no samloader |

> [!TIP]
> **Not sure which to pick?** On Linux, go with [Method 1](#-method-1-samloader-linux--recommended). On Windows, use [Method 3](#-method-3-odin-windows). No cable handy? Use [Method 2](#-method-2-anykernel3-via-recovery-no-pc-required).

---

## 🔒 Before You Begin (Prerequisites)

Make sure all of the following are true before you start:

- **Device:** Samsung Galaxy A21s (`SM-A217F`) with an **unlocked bootloader**.
- **ROM:** [LineageOS 24](https://lineageos.org/) (Android 17 / SDK 37) is already installed and booting.
- **Backup:** You have a copy of your stock `boot.img` stored safely off-device.
- **Cable:** A working USB cable and a PC running Linux, macOS, or Windows (required for Methods 1, 3, and 4).
- **Files:** Download the correct release asset for your chosen method from the [releases page](https://github.com/rebeeh/A21s-KernelSU-Next/releases):
  - Methods 1, 4: `boot-ksu.img` (or `boot-ksu.tar` for Method 3)
  - Method 2: [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.0.0/KernelSU-Next-A21s-universal850-AnyKernel3.zip)

> [!WARNING]
> Flashing modifies your device's boot partition. Ensure you have a working backup before proceeding. A failed flash on a device with a locked bootloader may brick the device.

---

## 📦 Method 1: `samloader` (Linux) — Recommended

[`samloader`](https://github.com/topjohnwu/samloader-rs) flashes partitions directly in Samsung Download Mode in approximately **1 second** — the fastest approach available on Linux.

1. **Enter Download Mode** on your phone:
   ```bash
   adb reboot download
   ```
   > [!NOTE]
   > Alternatively: power the phone off, then hold **Volume Up + Volume Down** simultaneously while plugging in the USB cable connected to your PC.

2. **Flash the boot image:**
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```

3. **Done.** The phone will automatically reboot into LineageOS.

---

## 🛠️ Method 2: AnyKernel3 via Recovery (No PC Required!)

This method uses a flashable `.zip` applied directly from your custom recovery — no computer needed.

1. **Copy the zip** to your phone's internal storage or SD card:
   - File: [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.0.0/KernelSU-Next-A21s-universal850-AnyKernel3.zip)

2. **Boot into Recovery.** Compatible recoveries:
   - [TWRP](https://twrp.me)
   - [OrangeFox](https://orangefox.download)
   - Lineage Recovery (built-in)

3. **Flash the zip:**
   - In TWRP / OrangeFox: tap **Install** → select the `.zip` → swipe to confirm.
   - In Lineage Recovery: tap **Apply Update** → **Choose from internal storage** → select the `.zip`.

4. **Reboot System** once flashing completes.

---

## 🪟 Method 3: Odin (Windows)

[Odin](https://odindownload.com) is Samsung's official-style PC flashing tool for Windows.

1. **Enter Download Mode** on your phone:
   - Power off → hold **Volume Up + Volume Down** → plug in USB cable to PC.

2. **Open [Odin v3.14.4](https://odindownload.com)** on your Windows PC.

3. **Confirm device detection:** Odin will show a blue `[COM:XX]` box in the top-left panel. If it stays grey, try a different USB port or cable.

4. **Load the boot image:** Click the **AP** button and select:
   ```
   boot-ksu.tar
   ```

5. *(Optional)* Uncheck **Auto Reboot** if you want to manually control when the phone restarts.

6. Click **Start**. Wait for the `PASS!` message in green, then reboot your phone.

> [!CAUTION]
> Do **not** check **Re-Partition** in Odin. This will wipe your device's partition table and can cause a hard brick.

---

## 🐧 Method 4: Heimdall (macOS & Linux)

[Heimdall](https://github.com/Benjamin-Dobell/Heimdall) is a cross-platform open-source alternative to Odin that works on macOS and Linux.

1. **Enter Download Mode** on your phone:
   - Power off → hold **Volume Up + Volume Down** → plug in USB cable to PC.

2. **Verify device detection:**
   ```bash
   heimdall detect
   ```
   You should see output confirming the device is found. If not, check USB permissions or try `sudo`.

3. **Flash the boot partition:**
   ```bash
   heimdall flash --BOOT boot-ksu.img --no-reboot
   ```

4. **Reboot your phone manually:** hold **Volume Down + Power** until the device restarts.

---

## ✅ Post-Boot Verification

After the phone boots into LineageOS, confirm that KernelSU-Next is active:

1. **Install the KernelSU-Next Manager APK** ([download `KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk)):
   ```bash
   adb install KernelSU_Next_v3.4.2.apk
   ```

2. **Open the KernelSU Next app** from your launcher.

3. **Check the home card** — it should display:

   | Field | Expected Value |
   |-------|---------------|
   | **Status** | `Working [BUILT-IN (GKI1)]` |
   | **Hook mode** | `Manual` |
   | **Manager version** | `v3.4.2 (33355-5)` |

4. Navigate to the **Superuser (Shield)** tab to grant or revoke root access for installed apps.

> [!NOTE]
> If the status shows `Not installed` or `Abnormal`, double-check that you flashed the correct `boot-ksu.img` and that it matches your LineageOS 24 build.

---

## 🔗 Related Docs

- [**README**](../README.md) — Project overview, build targets, and feature list.
- [**Build Guide**](BUILD.md) — How to compile the kernel and generate flashable artifacts from source.
- [**Troubleshooting**](TROUBLESHOOTING.md) — Common flashing errors and how to recover.
