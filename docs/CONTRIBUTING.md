[← Documentation Hub](README.md) · [Main README](../README.md)

# Contributing to A21s-KernelSU-Next

> How to report bugs with full logs, edit or export clean kernel patches, test on Galaxy A21s variants (`SM-A217F` / `M` / `N`), and port manual hooks to other Exynos non-GKI devices.

---

## Jump to What You Need

| I want to… | Go to… |
| :--- | :--- |
| See all ways to contribute (testing, patches, docs, ports) | [How You Can Contribute](#how-you-can-contribute) |
| Report a bug or bootloop cleanly | [Bug Reporting](#bug-reporting) |
| Run the local patch & build dev workflow | [Development Workflow](#development-workflow) |
| Verify hardware & KSU behavior before opening a PR | [Testing Checklist](#testing-checklist) |
| Check commit message, patch & shell formatting rules | [Code Style](#code-style) |
| Submit a Pull Request | [Submitting a Pull Request](#submitting-a-pull-request) |
| Port manual hooks to another Exynos 4.19 device | [Porting to Other Devices](#porting-to-other-devices) |

---

## Before You Begin (Prerequisites)

- **Hardware:** Physical Samsung Galaxy A21s (`SM-A217F`, `SM-A217M`, or `SM-A217N`) running [LineageOS 24](https://github.com/LineageOS/android_device_samsung_a21s).
- **Host Tools:** Linux host (or [Docker](../docker-compose.yml) / [GitHub Actions CI](../.github/workflows/build-kernel.yml)) + `git`, `python3`, `shellcheck`.
- **Workspace:** Configured automatically via [`./scripts/setup_env.sh`](../scripts/setup_env.sh).

> [!NOTE]
> You do **not** need to write C kernel code to contribute — variant hardware test reports, reproducible bug logs, and documentation fixes are just as valuable.

---

## How You Can Contribute

- **Testing on Variants:** Report boot, `su`, SUSFS, and hardware status on **SM-A217F** (Global), **SM-A217M** (Latin America), or **SM-A217N** (South Korea).
- **Kernel & Build Fixes:** Keep commits modular, keep binary outputs (`*.img`, `*.tar`, `*.zip`) out of Git, and validate sequential patch order ([`patches/`](../patches/) `0001`–`0004`).
- **Documentation & Tooling:** Open PRs against [`docs/`](../docs/), [`build.py`](../build.py), or [`scripts/`](../scripts/).

---

## Bug Reporting

1. Search existing [Open](https://github.com/rebeeh/A21s-KernelSU-Next/issues) and [Closed Issues](https://github.com/rebeeh/A21s-KernelSU-Next/issues?q=is%3Aissue+is%3Aclosed) first.
2. Verify whether the bug still reproduces on the [latest release](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest).
3. Collect logs with the 1-click reporter:
   ```bash
   python3 build.py report-issue
   ```
   *(Works in both booted Android and Recovery/TWRP! For manual commands, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#method-c-manual-log-extraction-via-adb).)*
4. Open a [New Bug Report](https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?template=bug_report.md) using [`.github/ISSUE_TEMPLATE/bug_report.md`](../.github/ISSUE_TEMPLATE/bug_report.md).

> [!WARNING]
> Always scrub Wi-Fi credentials, accounts, or private keys (`keybox.xml` material) before attaching public logs.

---

## Development Workflow

1. **Fork & clone** the repository:
   ```bash
   git clone https://github.com/<your-username>/A21s-KernelSU-Next.git
   cd A21s-KernelSU-Next
   ```
2. **Initialize the external build workspace** (`build/a21s-kernel`, `KernelSU-Next`, `clang-r416183b`, `magiskboot`, and sequential `0001`–`0004` patch verification):
   ```bash
   ./scripts/setup_env.sh
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feat/my-change
   ```
4. **Edit kernel files** in `build/a21s-kernel/` (or `build/a21s-kernel/KernelSU-Next/`) and **build/test on hardware** *(passing baseline `boot.img` as documented in [BUILD.md](BUILD.md))*:
   ```bash
   ./scripts/build.sh boot.img
   ./scripts/package_anykernel3.sh
   ```
5. **Export clean patches** back into [`patches/`](../patches/) (do **not** duplicate hunks across patches — verify on a fresh clone with `git apply --check`), commit, and open a PR against `main`.

---

## Testing Checklist

Confirm relevant items on physical hardware before marking a PR ready:

<details>
<summary><strong>Expand full PR verification checklist (Boot, KernelSU-Next, SUSFS, Hardware, Power)</strong></summary>

- **Boot & Stability:** Clean boot to LineageOS 24, normal boot time, no panics in `dmesg`, ADB responsive.
- **KernelSU-Next & SUSFS:** Manager shows `Working [BUILT-IN (GKI1)]` / `Manual` / `UAPI 5` / `SuSFS v1.5.5 (NON-GKI)`, `ksud` boot scripts (`post-fs-data` / `services`) run automatically, `adb shell su` works when granted.
- **Core Hardware:** Wi-Fi, LTE mobile data, Bluetooth, Camera (front/rear), Audio & Mic, USB (ADB/MTP/charging), GPS, Fingerprint sensor.
- **Power & Regression:** Deep sleep functional, no new battery drain or thermal spike, unrelated subsystems unaffected.

</details>

---

## Code Style

- **Commits:** Imperative subject `<= 72` chars (`subsystem: concise summary`, e.g. `kernelsu: guard prctl handler to GLOBAL_ROOT_UID`), one logical change per commit.
- **C Code:** Linux kernel style (`./build/a21s-kernel/scripts/checkpatch.pl` advisories checked).
- **Shell Scripts:** Validate changes in [`scripts/`](../scripts/) and [`tools/`](../tools/) with `shellcheck`.
- **Never commit build binaries:** Keep `*.img`, `*.tar`, and `.zip` build artifacts out of Git ([`.gitignore`](../.gitignore)).

---

## Submitting a Pull Request

- Prefix PR titles clearly: `[feat]`, `[fix]`, `[build]`, `[docs]`, `[refactor]`, or `[port]`.
- Summarize what changed, why, which `SM-A217*` variant + kernel build you tested on, and link related issues (`Fixes #<number>`).

---

## Porting to Other Devices

The compile-time Manual Hook + Dynamic UAPI + DAK SELinux pattern translates cleanly to other non-GKI Samsung Exynos 4.x kernels:

| SoC | Example Devices | Notes |
| :--- | :--- | :--- |
| **Exynos 850** | Galaxy A21s (this repo), Galaxy A12 (`SM-A127F`), Galaxy M12 | Shares `universal850` / TZASC behavior |
| **Exynos 9611** | Galaxy A51, Galaxy M31 | Non-GKI 4.14/4.19 |
| **Exynos 9820** | Galaxy S10, Galaxy Note 10 | Non-GKI 4.14 |
| **Exynos 7884B** | Galaxy A10, Galaxy A20 | Non-GKI 4.4 |

> [!NOTE]
> GKI 2.0 devices (`5.10+`) do not need manual hooks — consult upstream [`KernelSU-Next`](https://github.com/KernelSU-Next/KernelSU-Next) directly.

**Quick Porting Steps:**
1. Obtain your target device's kernel tree and inspect our ordered patches:
   - [`patches/0001-build-host-openssl-3-compat.patch`](../patches/0001-build-host-openssl-3-compat.patch)
   - [`patches/0002-kernelsu-manual-hooks-and-backports.patch`](../patches/0002-kernelsu-manual-hooks-and-backports.patch)
   - [`patches/0003-kernelsu-next-samsung-fixes.patch`](../patches/0003-kernelsu-next-samsung-fixes.patch)
   - [`patches/0004-susfs-v1.5.5-kernel-4.19.patch`](../patches/0004-susfs-v1.5.5-kernel-4.19.patch)
2. Test-apply with `git apply --check`, adapt `fs/` (`exec.c`, `open.c`, `read_write.c`, `stat.c`), `kernel/reboot.c`, and `fs/namespace.c` (`vfs_create_mount` vs `vfs_kern_mount`) to match your tree.
3. Update [`tools/anykernel3/anykernel.sh`](../tools/anykernel3/anykernel.sh) (`block=`, `is_slot_device=`, `device.name*`) and defconfig (`CONFIG_KSU=y`, `CONFIG_KSU_MANUAL_HOOK=y`).
4. Share your fork or porting findings by opening a [Feature / Enhancement Issue](https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?template=feature_request.md).

---

## Related Docs

| Document | Description |
| :--- | :--- |
| [User Installation Guide](USER_GUIDE.md) | First-time installation, stealth modules, and Duck Detector |
| [Flashing Guide](FLASHING_GUIDE.md) | AnyKernel3, `samloader`, Odin, and Heimdall |
| [Kernel Build Guide](BUILD.md) | Compilation pipelines & `susfs4ksu-v1.5.5.zip` packaging |
| [OTA Updates Survival](OTA_AND_UPDATES.md) | Retaining root across LineageOS updates |
| [Technical Architecture](ARCHITECTURE.md) | Exynos 850 TZASC, Manual Hooks, Dynamic UAPI, and SUSFS |
| [Technical Research Report](RESEARCH.md) | Crash dumps, device tree alignment, and workspace design |
| [Troubleshooting & Diagnostics](TROUBLESHOOTING.md) | Crash reporter, `ramoops`, Blindspots 1–5 |
| [Documentation Hub](README.md) | Master index and navigation hub |
