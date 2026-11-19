# LineageOS OTA Updates & Kernel Lifecycle

A common question among custom kernel users:
> **"When a new LineageOS OTA update arrives, what happens? Do I have to recompile and rerun all steps from scratch every single update?"**

**Short Answer:** **NO.** You do NOT have to re-run all compilation steps, and you are NOT forced to rebuild the project every LineageOS release.

Here is an explanation of what happens during an OTA update and how to maintain root seamlessly.

---

## 1. How LineageOS OTA Works on Galaxy A21s

The Samsung Galaxy A21s is an **A-only** (non-A/B) device (`ro.build.ab_update = false`).

When LineageOS installs an OTA update:
1. The update ZIP contains new `system`, `vendor`, and **stock `boot.img`** images.
2. The Lineage Recovery writes the stock `boot.img` over your boot partition.
3. Therefore, rebooting after an OTA will temporarily return you to the unmodified stock kernel (KernelSU will show `Not Installed`).

---

## 2. How to Retain Root Across OTA Updates (10 Seconds)

Because our kernel is built for the **Linux 4.19.325** universal850 base, you do **not** need to recompile the kernel when a weekly LineageOS nightly is installed.

You have two fast ways to restore root:

### Method A: Flash AnyKernel3 via Recovery (No PC Required!)

1. Keep `KernelSU-Next-A21s-universal850-AnyKernel3.zip` saved on your phone’s internal storage or microSD card.
2. Let LineageOS download and apply the OTA update.
3. Before rebooting to system (or after rebooting into recovery):
   - In Recovery, select **Install** / **Apply Update** -> Choose `KernelSU-Next-A21s-universal850-AnyKernel3.zip`.
   - AnyKernel3 dynamically pulls the new LineageOS ramdisk, injects our KernelSU kernel `Image`, and writes it back to `boot` in 5 seconds.
4. Reboot into system. Root access, modules, and app profiles are fully preserved!

### Method B: Flash `boot-ksu.img` via `samloader` / Odin (1 Second)

If you have a PC connected:
```bash
adb reboot download
samloader flash --partition BOOT boot-ksu.img
```
Your phone reboots immediately with KernelSU-Next restored.

---

## 3. When DOES the Project Need an Update?

You only need to rebuild or update the repository when:

| Scenario | Rebuild Needed? | What to Do |
|---|---|---|
| **Regular LineageOS Weekly Nightly** | ❌ **No** | Flash existing `AnyKernel3.zip` or `boot-ksu.img` |
| **Major Android Version Bump** (e.g., Lineage 24 -> 25) | ⚠️ **Yes** | Re-run `./scripts/build.sh` against the new branch |
| **Upstream LineageOS Kernel Update** (e.g. security patch bump) | ⚠️ **Optional** | Trigger `./scripts/build.sh` or GitHub Actions |
| **New KernelSU-Next Manager Release** (e.g. v3.5.0 / UAPI 6) | ❌ **No** | Dynamic UAPI Resolution in the kernel automatically handles version matching via supercall or bootargs! |

---

## 4. Automated Cloud Builds via GitHub Actions

To make maintenance effortless, this repository includes a **GitHub Actions CI/CD Pipeline** (`.github/workflows/build-kernel.yml`).

Whenever you push an update or trigger the workflow:
1. GitHub runners spin up an Ubuntu 24.04 environment.
2. The latest LineageOS tree and toolchain are fetched.
3. Our patches are applied, and the kernel is compiled.
4. The output `Image`, `boot.img`, and `AnyKernel3.zip` are automatically generated and published as GitHub Release artifacts!
