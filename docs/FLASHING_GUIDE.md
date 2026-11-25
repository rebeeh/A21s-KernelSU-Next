[← Documentation Hub](README.md) · [Main README](../README.md)

# Flashing & Installation Guide — Galaxy A21s KernelSU-Next

> Flash KernelSU-Next onto your **Samsung Galaxy A21s (`SM-A217F` / `M` / `N`)** running **LineageOS 24** using whichever tool fits your OS and workflow.

---

## Jump to What You Need

| Method | Platform | PC Needed? | Speed | Best For |
| :--- | :--- | :---: | :--- | :--- |
| [Method 1: `samloader`](#method-1-samloader-linux--recommended) | Linux / macOS | Yes | ~1 s | Developers, fastest CLI flash |
| [Method 2: `AnyKernel3` (Recovery)](#method-2-anykernel3-via-recovery-no-pc-required) | Any (On-Device) | No | ~5 s | Easiest, preserves custom ROM ramdisk |
| [Method 3: Odin](#method-3-odin-windows) | Windows | Yes | Fast | Windows GUI flashing (`AP` slot) |
| [Method 4: Heimdall](#method-4-heimdall-macos--linux) | macOS / Linux | Yes | Fast | Open-source Odin alternative |
| [Post-Boot Verification](#post-boot-verification) | On-Device | Optional | ~30 s | Confirming `BUILT-IN (GKI1)`, `Manual`, `UAPI 5`, `SUSFS v1.5.5` |

> [!TIP]
> **Not sure which to pick?** Without a PC (or on non-LineageOS 24 AOSP ROMs), use [Method 2 (`AnyKernel3`)](#method-2-anykernel3-via-recovery-no-pc-required). On Linux with a cable, use [Method 1 (`samloader`)](#method-1-samloader-linux--recommended). On Windows, use [Method 3 (`Odin`)](#method-3-odin-windows).

---

## Before You Begin

Verify these prerequisites before starting:

- **Device:** Samsung Galaxy A21s (`SM-A217F`, `SM-A217M`, or `SM-A217N`) with an **unlocked bootloader**.
- **ROM:** [LineageOS 24](https://github.com/LineageOS/android_device_samsung_a21s) (Android 17 / SDK 37) booted cleanly *(for other AOSP ROMs, use Method 2 `AnyKernel3` only)*.
- **Backup:** Store a clean copy of your stock `boot.img` off-device before flashing.
- **Release Files** from [GitHub Releases (`latest`)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest):
  - Methods 1 & 4: [`boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.img)
  - Method 2: [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip)
  - Method 3: [`boot-ksu.tar`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.tar)
  - Post-boot Manager & SUSFS Companion: [`KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) + [`susfs4ksu-v1.5.5.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/susfs4ksu-v1.5.5.zip)

> [!WARNING]
> Flashing modifies `/dev/block/by-name/boot`. Always keep your stock `boot.img` and [`AnyKernel3` zip](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) handy for recovery.

---

## Method 1: `samloader` (Linux) — Recommended

[`samloader`](https://github.com/topjohnwu/samloader-rs) flashes partitions directly over Samsung Download Mode in ~1 second.

1. **Boot into Download Mode:**
   ```bash
   adb reboot download
   ```
   > [!NOTE]
   > Hardware button combo: power the phone off, then hold **Volume Up + Volume Down** simultaneously while plugging in the USB cable connected to your PC.
2. **Flash `boot-ksu.img`:**
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```
3. The phone reboots automatically into LineageOS.

---

## Method 2: `AnyKernel3` via Recovery (No PC Required!)

`AnyKernel3` ([`tools/anykernel3/anykernel.sh`](../tools/anykernel3/anykernel.sh)) unpacks your phone's **current** boot partition, keeps its RAMDisk intact, swaps only the kernel `Image`, and flashes it back automatically.

1. Download [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) to your phone's internal storage or microSD card (or keep it on your PC for ADB sideload).
2. **Boot into Recovery** (`Volume Up + Power` from powered-off, or `adb reboot recovery`):
   - **[TWRP](https://twrp.me) / [OrangeFox](https://orangefox.download):** Tap **Install** → select `KernelSU-Next-A21s-universal850-AnyKernel3.zip` → swipe to confirm.
   - **LineageOS Recovery:** Tap **Apply update** → **Choose from internal storage** → select the `.zip` *(or tap **Apply from ADB** and run `adb sideload KernelSU-Next-A21s-universal850-AnyKernel3.zip`)*. Accept **Yes** if prompted about third-party zip signature verification.
3. Tap **Reboot system now**.

---

## Method 3: Odin (Windows)

[Samsung Odin](https://odindownload.com) flashes `.tar`-wrapped partition images over USB on Windows.

1. **Boot into Download Mode:** Power off → hold **Volume Up + Volume Down** while plugging USB cable (or `adb reboot download`).
2. Open [Odin3 v3.14.4](https://odindownload.com) and confirm a blue `ID:COM` port box appears.
3. Click **AP** and load [`boot-ksu.tar`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.tar).
4. *(Optional)* Uncheck **Auto Reboot** if you want to reboot manually (`Volume Down + Power` for ~7 seconds).
5. Click **Start** and wait for **`PASS!`**.

> [!CAUTION]
> Never check **Re-Partition** in Odin — it alters the partition table and can brick your phone.

---

## Method 4: Heimdall (macOS & Linux)

[Heimdall](https://github.com/Benjamin-Dobell/Heimdall) is an open-source cross-platform flashing utility.

1. **Boot into Download Mode** (`Volume Up + Volume Down` + USB cable, or `adb reboot download`).
2. **Check connection:**
   ```bash
   heimdall detect
   ```
3. **Flash the boot partition:**
   ```bash
   heimdall flash --BOOT boot-ksu.img --no-reboot
   ```
4. **Reboot:** Hold **Volume Down + Power** until the screen turns black and restarts.

<details>
<summary><strong>Alternative: Raw block flash via recovery shell (<code>dd</code>)</strong></summary>

If you are booted in TWRP/OrangeFox recovery with ADB root access and want to flash `boot-ksu.img` directly:

```bash
adb push boot-ksu.img /tmp/boot-ksu.img
adb shell dd if=/tmp/boot-ksu.img of=/dev/block/by-name/boot bs=4096
adb reboot
```

</details>

---

## Post-Boot Verification

1. **Install KernelSU-Next Manager** ([`KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk)):
   ```bash
   adb install KernelSU_Next_v3.4.2.apk
   ```
2. *(Recommended)* In **KernelSU Next → Modules → Install**, flash [`susfs4ksu-v1.5.5.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/susfs4ksu-v1.5.5.zip) and reboot to activate version-matched `ksu_susfs_arm64` hiding rules.
3. Open **KernelSU Next** and verify the home status card:

   | Field | Expected Value |
   | :--- | :--- |
   | **Status** | `Working [BUILT-IN (GKI1)]` |
   | **Hook mode** | `Manual` |
   | **Manager / Driver** | `v3.4.2 (33355-5)` |
   | **SuSFS version** | `Supported | v1.5.5 (NON-GKI)` |

4. Grant root access selectively under **Superuser (Shield)**, and continue to [User Guide — Stealth Isolation Stack](USER_GUIDE.md#advanced-module-setup--stealth-isolation-stack) if configuring Play Integrity (`AlwaysStrong`), `ReZygisk`, `Vector`, and `HMA-OSS`.

> [!NOTE]
> If the Manager shows `Not installed` or `Unsupported`, confirm the boot image matches your LineageOS 24 build and consult [Troubleshooting](TROUBLESHOOTING.md).

---

## Related Docs

| Document | Description |
| :--- | :--- |
| [User Installation Guide](USER_GUIDE.md) | First-time root walkthrough, allowlist model, and stealth module stack |
| [OTA Updates Survival](OTA_AND_UPDATES.md) | Retain root across LineageOS updates in ~5 seconds |
| [Kernel Build Guide](BUILD.md) | Compile kernel & `susfs4ksu-v1.5.5.zip` from source or CI |
| [Troubleshooting & Diagnostics](TROUBLESHOOTING.md) | Log extraction, Safe Mode, and Play Integrity |
| [Technical Architecture](ARCHITECTURE.md) | Exynos 850 TZASC, Manual Hooks, and SUSFS internals |
| [Documentation Hub](README.md) | Master documentation index |
