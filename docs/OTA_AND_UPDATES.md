# 📲 OTA Updates & Root Retention — Galaxy A21s / KernelSU-Next

> **TL;DR:** When a LineageOS OTA lands, you do **NOT** need to recompile anything — just re-flash one zip or one image file and root is back in seconds.

---

## 🗺️ Jump to What You Need

| I want to… | Go to |
|---|---|
| Understand what happens during an OTA | [§ How OTA Works](#-how-lineageos-ota-works-on-galaxy-a21s) |
| Restore root after an OTA (no PC) | [Method A — AnyKernel3 via Recovery](#method-a--anykernel3-via-recovery-no-pc-required) |
| Restore root after an OTA (PC connected) | [Method B — boot-ksu.img via fastboot/Odin](#method-b--boot-ksuimg-via-samloader--odin-pc-required) |
| Know when a full rebuild is needed | [§ When Does the Project Need an Update?](#-when-does-the-project-need-an-update) |
| Set up automated cloud builds | [§ Automated Cloud Builds](#-automated-cloud-builds-via-github-actions) |

---

## ⚙️ Before You Begin

- **Device:** Samsung Galaxy A21s (`SM-A217F`)
- **ROM:** LineageOS 24
- **Kernel + Root:** KernelSU-Next on Linux 4.19.325 (`universal850`)
- **Required file (keep it handy):** [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.1.0/KernelSU-Next-A21s-universal850-AnyKernel3.zip) — save this to your phone's internal storage or microSD card before applying any OTA.

---

## 🔄 How LineageOS OTA Works on Galaxy A21s

The Galaxy A21s is an **A-only** (non-A/B) device (`ro.build.ab_update = false`), which means OTA updates write directly over the active boot partition.

Here is what happens step-by-step when an OTA is applied:

1. The OTA ZIP delivers new `system`, `vendor`, and a **stock `boot.img`**.
2. LineageOS Recovery writes the **stock `boot.img`** over your boot partition, replacing your KernelSU-Next kernel.
3. After the reboot, KernelSU-Next will show **"Not Installed"** — this is expected and temporary.

> [!NOTE]
> This does **not** affect your data, apps, KernelSU-Next modules, or root app profiles. Only the boot partition is overwritten. Restoring root takes under 10 seconds.

---

## ⚡ How to Retain Root Across OTA Updates

Because our kernel is built against the **Linux 4.19.325 `universal850`** base — which does not change between LineageOS weekly nightlies — you do **not** need to recompile the kernel after a routine OTA. Just pick one of the two methods below.

---

### Method A — AnyKernel3 via Recovery (No PC Required!)

> [!TIP]
> This is the recommended method for most users. Keep the zip file on your phone at all times.

**Prerequisites:** `KernelSU-Next-A21s-universal850-AnyKernel3.zip` already on internal storage or SD card.

1. Let LineageOS download and install the OTA update normally.
2. When Recovery prompts you to reboot, **do not reboot to system yet** — stay in Recovery.  
   *(If you already rebooted to system, long-press Power → reboot into Recovery manually.)*
3. In Recovery, tap **Install** (or **Apply Update**) → navigate to and select:  
   [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/download/v1.1.0/KernelSU-Next-A21s-universal850-AnyKernel3.zip)
4. Confirm the flash. AnyKernel3 will:
   - Dynamically read the **new** LineageOS ramdisk from the just-updated boot partition.
   - Inject the KernelSU-Next `Image` into it.
   - Write the patched boot image back — in about 5 seconds.
5. Tap **Reboot System**.

✅ Done. Root access, modules, and all app profiles are fully preserved.

---

### Method B — `boot-ksu.img` via [`samloader`](https://github.com/topjohnwu/samloader-rs) / [Odin](https://odindownload.com) (PC Required)

> [!TIP]
> Fastest option if you have a USB cable and a PC handy — takes about 1 second to flash.

**Prerequisites:** `boot-ksu.img` from the latest release, `adb` and `samloader` (or Odin) installed on your PC.

1. Connect the Galaxy A21s to your PC via USB.
2. Reboot the device into Download Mode:
   ```bash
   adb reboot download
   ```
3. Flash the KernelSU-Next boot image:
   ```bash
   samloader flash --partition BOOT boot-ksu.img
   ```
4. The device reboots automatically with KernelSU-Next restored.

✅ Done. No recovery interaction needed.

---

## 🛠️ When Does the Project Need an Update?

Most OTAs require **no rebuild at all**. Use this table to decide:

| Scenario | Rebuild Needed? | What To Do |
|---|:---:|---|
| Regular LineageOS Weekly Nightly | ❌ No | Flash existing `AnyKernel3.zip` or `boot-ksu.img` (see above) |
| Major Android version bump (e.g., LineageOS 24 → 25) | ⚠️ Yes | Re-run `./scripts/build.sh` against the new branch |
| Upstream LineageOS kernel security patch bump | ⚠️ Optional | Trigger `./scripts/build.sh` or the GitHub Actions workflow |
| New KernelSU-Next Manager release (e.g., v3.5.0 / UAPI 6) | ❌ No | Dynamic UAPI Resolution handles version matching automatically via supercall or bootargs |

> [!IMPORTANT]
> A **major Android version bump** (e.g., LineageOS 24 → 25) changes the kernel ABI and ramdisk format. In that case, re-run the full build pipeline before flashing.

---

## ☁️ Automated Cloud Builds via GitHub Actions

To make maintenance completely effortless, this repository ships a **GitHub Actions CI/CD pipeline** at `.github/workflows/build-kernel.yml`.

Whenever you push an update or manually trigger the workflow:

1. GitHub runners spin up an **Ubuntu 24.04** environment.
2. The latest LineageOS kernel tree and toolchain are fetched automatically.
3. Our KernelSU-Next patches are applied and the kernel is compiled.
4. The output `Image`, `boot.img`, and `AnyKernel3.zip` are published as **GitHub Release artifacts** — ready to download and flash.

> [!NOTE]
> You can trigger a build manually from the **Actions** tab in the repository without touching any code — useful after a KernelSU-Next upstream update or a security patch bump.

---

## 🔗 Related Docs

- [Build Guide](BUILD.md) — How to compile the kernel locally or via CI
- [Installation Guide](INSTALLATION.md) — First-time setup and flashing instructions
- [Troubleshooting](TROUBLESHOOTING.md) — Common issues and fixes
