[← Documentation Hub](README.md) · [Main README](../README.md)

# OTA Updates & Root Retention — Galaxy A21s / KernelSU-Next

> **TL;DR:** When a routine LineageOS OTA lands, you do **not** need to recompile anything — re-flash one recovery zip (or one boot image) and KernelSU-Next root plus all modules are back in seconds.

---

## Jump to What You Need

| I want to… | Go to… |
| :--- | :--- |
| Understand what an OTA changes on the Galaxy A21s | [How LineageOS OTA Works on Galaxy A21s](#how-lineageos-ota-works-on-galaxy-a21s) |
| Restore root after an OTA with no PC | [Method A: `AnyKernel3` via Recovery](#method-a-anykernel3-via-recovery-no-pc-required) |
| Restore root via PC (`samloader` / `Odin`) | [Method B: `boot-ksu.img` via `samloader` / `Odin`](#method-b-boot-ksuimg-via-samloader--odin-pc-required) |
| Know when a kernel rebuild is actually needed | [When Does the Project Need an Update?](#when-does-the-project-need-an-update) |
| Automate new builds in the cloud | [Automated Cloud Builds via GitHub Actions](#automated-cloud-builds-via-github-actions) |

---

## Before You Begin

- **Device:** Samsung Galaxy A21s (`SM-A217F` / `M` / `N`) on **LineageOS 24** (`universal850`, Linux `4.19.325`).
- **Keep on your phone at all times:** [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) stored in internal storage or microSD before installing any OTA.

---

## How LineageOS OTA Works on Galaxy A21s

The Galaxy A21s is an **A-only** (non-A/B) device (`is_slot_device=0` in [`tools/anykernel3/anykernel.sh`](../tools/anykernel3/anykernel.sh)), so OTA packages overwrite `/dev/block/by-name/boot` directly:

1. The LineageOS OTA flashes updated `system`, `vendor`, and the **upstream stock `boot.img`**.
2. Because KernelSU-Next lives inside the kernel `Image` on `/boot`, the stock OTA kernel leaves KernelSU-Next temporarily inactive (**"Not installed"** in [KernelSU-Next Manager](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v3.4.2)).
3. Re-flashing our `AnyKernel3` zip (or updated `boot-ksu.img`) restores the KernelSU-Next + SUSFS kernel immediately.

> [!NOTE]
> Your `/data` partition — including apps, Superuser allowlists, `/data/adb/modules/` (`susfs4ksu`, `ReZygisk`, `Vector`, `HMA-OSS`, `AlwaysStrong`), and keybox config — is **never wiped** by restoring `/boot`.

---

## How to Retain Root Across OTA Updates

For regular LineageOS weekly/nightly builds on the same major Android base, the ramdisk stays compatible across builds. Pick either method below.

### Method A: `AnyKernel3` via Recovery (No PC Required!)

> [!TIP]
> **Recommended for almost everyone** — preserves any ramdisk changes introduced by the new LineageOS OTA automatically.

1. Let LineageOS Updater download and apply the OTA normally.
2. When Recovery asks to reboot, **stay in Recovery** *(or reboot to Recovery immediately with **Volume Up + Power** from off, or `adb reboot recovery`)*.
3. Flash [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) from storage (or `adb sideload`).
4. [`tools/anykernel3/anykernel.sh`](../tools/anykernel3/anykernel.sh) automatically extracts the **new** OTA ramdisk, injects our patched kernel `Image`, and flashes `/dev/block/by-name/boot` in ~5 seconds.
5. Tap **Reboot system now**. Root, SUSFS, and all modules return cleanly.

### Method B: `boot-ksu.img` via `samloader` / `Odin` (PC Required)

> [!TIP]
> Fastest option when already plugged into a PC — see [Flashing Guide](FLASHING_GUIDE.md) for [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall) and [Odin](https://odindownload.com) (`boot-ksu.tar`).

1. Enter Download Mode (`adb reboot download`, or power off → hold **Volume Up + Volume Down** + USB cable).
2. Flash [`boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.img) using [`samloader`](https://github.com/topjohnwu/samloader-rs):
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```
3. The phone reboots directly with root restored.

---

## When Does the Project Need an Update?

| Scenario | Rebuild Needed? | Recommended Action |
| :--- | :---: | :--- |
| Routine LineageOS 24 nightly / weekly OTA | No | Re-flash existing [`AnyKernel3` zip](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) |
| New KernelSU-Next Manager APK release | No | Kernel's 3-tier [Dynamic UAPI Engine](ARCHITECTURE.md#uapi-versioning--manager-parity) negotiates automatically (`UAPI 4–16`) |
| Upstream kernel CVE / LineageOS kernel bump | Optional | Re-run [`./scripts/build.sh`](../scripts/build.sh) or trigger [GitHub Actions CI](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml) |
| Major Android / LineageOS bump (e.g. LineageOS 24 → 25) | Yes | Rebase [`patches/`](../patches/) on the new kernel branch via [BUILD.md](BUILD.md) |

> [!IMPORTANT]
> On a **major LineageOS version upgrade** (e.g., 24 → 25), the Android framework/Binder/SELinux policy ABI changes. Always rebuild against the new kernel branch rather than flashing an older `boot-ksu.img`.

---

## Automated Cloud Builds via GitHub Actions

This repository includes a CI/CD workflow at [`.github/workflows/build-kernel.yml`](../.github/workflows/build-kernel.yml):

1. Open [GitHub Actions → Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml).
2. Trigger **Run workflow** manually at any time — no local toolchain required.
3. The runner builds on `ubuntu-24.04`, applies [`patches/`](../patches/) (`0001`–`0004`), packages `AnyKernel3.zip` (plus optional `boot-ksu.img` / `boot-ksu.tar`), compiles `ksu_susfs_arm64` from source via Android NDK into `susfs4ksu-v1.5.5.zip`, and attaches all assets automatically on `v*` tag pushes.

---

## Related Docs

| Document | Description |
| :--- | :--- |
| [User Installation Guide](USER_GUIDE.md) | First-time installation, downloads, and stealth module stack |
| [Flashing Guide](FLASHING_GUIDE.md) | Step-by-step instructions for AnyKernel3, `samloader`, Odin, and Heimdall |
| [Kernel Build Guide](BUILD.md) | Compile the kernel and `susfs4ksu-v1.5.5.zip` from source |
| [Troubleshooting & Diagnostics](TROUBLESHOOTING.md) | Bootloop recovery, log extraction, and Play Integrity |
| [Technical Architecture](ARCHITECTURE.md) | TZASC, Manual Hooks, Dynamic UAPI, and SUSFS internals |
| [Documentation Hub](README.md) | Master documentation index |
