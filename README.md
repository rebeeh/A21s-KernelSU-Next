<div align="center">

# A21s-KernelSU-Next

**Custom Linux 4.19.325 kernel for the Samsung Galaxy A21s (`SM-A217F`) on LineageOS 24 — with KernelSU-Next, SUSFS v1.5.5, and Exynos 850 TrustZone/TZASC Manual Hooks.**

[![Latest Release](https://img.shields.io/github/v/release/rebeeh/A21s-KernelSU-Next?color=blue&label=Latest%20Release)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest)
[![Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml)
[![Device: Galaxy A21s](https://img.shields.io/badge/Device-Samsung%20Galaxy%20A21s%20(SM--A217F)-green.svg)](https://github.com/LineageOS/android_device_samsung_a21s)
[![Kernel: 4.19.325](https://img.shields.io/badge/Kernel-Linux%204.19.325-orange.svg)](https://github.com/samsungexynos850/android_kernel_samsung_exynos850/tree/lineage-24.0)
[![Root: KernelSU-Next](https://img.shields.io/badge/Root-KernelSU--Next%20Legacy-teal.svg)](https://github.com/KernelSU-Next/KernelSU-Next/tree/legacy)
[![SUSFS: v1.5.5](https://img.shields.io/badge/SUSFS-v1.5.5%20NON--GKI-purple.svg)](https://gitlab.com/simonpunk/susfs4ksu/-/tree/kernel-4.19)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

[**Download Latest Release**](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) · [**User Guide**](docs/USER_GUIDE.md) · [**Flashing Guide**](docs/FLASHING_GUIDE.md) · [**Build Guide**](docs/BUILD.md) · [**Troubleshooting**](docs/TROUBLESHOOTING.md) · [**Architecture**](docs/ARCHITECTURE.md)

</div>

---

## Jump to What You Need

| I want to… | Go to… |
| :--- | :--- |
| Download prebuilt flashable images (latest) | [GitHub Releases (`latest`)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) |
| Flash the kernel right now (no compiling) | [End-User Installation Guide](docs/USER_GUIDE.md) |
| Choose a flashing tool (`AnyKernel3`, `samloader`, `Odin`, `Heimdall`) | [Flash to Your Device](#flash-to-your-device) · [Flashing Guide](docs/FLASHING_GUIDE.md) |
| Build the kernel or `susfs4ksu-v1.5.5.zip` from source | [Kernel Compilation & Build Guide](docs/BUILD.md) |
| Survive a LineageOS OTA update without losing root | [OTA & Updates Guide](docs/OTA_AND_UPDATES.md) |
| Understand TZASC manual hooks, UAPI 5, SUSFS & DAK SELinux | [Engineering Highlights](#engineering-highlights) · [Architecture](docs/ARCHITECTURE.md) |
| Pull crash logs (`ramoops` / `dmesg`) or fix Play Integrity | [Troubleshooting Guide](docs/TROUBLESHOOTING.md) |
| Port manual hooks or submit a pull request | [Contributing Guidelines](docs/CONTRIBUTING.md) |

---

## Engineering Highlights

These are the core hardware and Android integration problems solved to make [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) + [SUSFS v1.5.5](https://gitlab.com/simonpunk/susfs4ksu/-/tree/kernel-4.19) run cleanly on the Exynos 850:

- **TrustZone / TZASC Bypass via Manual Hooks** — Samsung's Exynos 850 enforces hardware memory protection (TZASC / RKP) that traps runtime `kprobes`, triggering `irq/160-tzasc` kernel panics and bootloops. Compile-time manual hooks (`CONFIG_KSU_MANUAL_HOOK=y`) are patched cleanly across `fs/exec.c`, `fs/open.c`, `fs/read_write.c`, `fs/stat.c` (including `ksu_handle_newfstat_ret` so Android 14–17 `init` injects `KERNEL_SU_RC` and starts `ksud` boot scripts automatically), and `kernel/reboot.c` ([`0002-kernelsu-manual-hooks-and-backports.patch`](patches/0002-kernelsu-manual-hooks-and-backports.patch)).
- **Integrated SUSFS v1.5.5 (NON-GKI)** — Kernel-level SUSFS v1.5.5 ([`0004-susfs-v1.5.5-kernel-4.19.patch`](patches/0004-susfs-v1.5.5-kernel-4.19.patch)) integrated with Samsung's backported `fs_context` mount API (`vfs_create_mount`, `clone_mnt`), providing mount hiding, path hiding, `kstat` spoofing, `uname` spoofing, and zygote umount. Reported as `SuSFS version: Supported | v1.5.5 (NON-GKI)` in [KernelSU-Next Manager](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v3.4.2).
- **Built-in Keymaster DAK SELinux & `prctl` Stealth** — [`0003-kernelsu-next-samsung-fixes.patch`](patches/0003-kernelsu-next-samsung-fixes.patch) embeds `hal_keymaster_default` SELinux rules for Samsung Device Attestation Keys (`/mnt/vendor/efs/DAK/`), preventing `ret -932` (`UNEVALUATED`) on LineageOS without external boot scripts, while `kernel/sys.c` restricts `prctl(0xDEADBEEF)` to `GLOBAL_ROOT_UID` so non-root detectors receive `-EINVAL` instead of `0`. See [Architecture](docs/ARCHITECTURE.md) and [Troubleshooting](docs/TROUBLESHOOTING.md).
- **Dynamic UAPI Resolution & Exact Driver Version Parity** — Compiled with `KSU_VERSION_OVERRIDE=33355` and a 3-tier UAPI resolution engine (default `UAPI 5`), aligning cleanly with [KernelSU-Next Manager v3.4.2](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) while supporting runtime (`CHANGE_UAPIVER = 10013`), caller auto-reflection (`4 ≤ UAPI ≤ 16`), and bootarg (`ksu.uapi=X`) switching.
- **Linux 4.19 Backports & OpenSSL 3.x Host Fixes** — Backports `can_umount()` and `path_umount()` from Linux 5.9 into `fs/namespace.c`, resolves `copy_to_kernel_nofault` macro collisions, and fixes OpenSSL 3.0+ `<openssl/engine.h>` host build failures ([`0001-build-host-openssl-3-compat.patch`](patches/0001-build-host-openssl-3-compat.patch)) for modern distros (Fedora 40+, Ubuntu 22.04+).

---

## Device Specifications

| Specification | Details |
| :--- | :--- |
| **Device** | Samsung Galaxy A21s (`SM-A217F`, also compatible with `SM-A217M` / `SM-A217N`) |
| **SoC / Platform** | Samsung Exynos 850 (`universal850`, ARM64 `aarch64`) |
| **Target ROM** | [LineageOS 24](https://github.com/LineageOS/android_device_samsung_a21s) (Android 17 / SDK 37) & AOSP ROMs *(not Stock OneUI)* |
| **Kernel Base** | Linux `4.19.325` ([`samsungexynos850/android_kernel_samsung_exynos850`](https://github.com/samsungexynos850/android_kernel_samsung_exynos850/tree/lineage-24.0) @ `b8c71b7aecec`) |
| **Compiler** | [AOSP Clang 12.0.5 (`clang-r416183b`)](https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b) + `LLVM=1` |
| **Root Driver** | [KernelSU-Next (`legacy`)](https://github.com/KernelSU-Next/KernelSU-Next/tree/legacy) · `CONFIG_KSU_MANUAL_HOOK=y` · Driver `33355` · UAPI `5` |
| **Stealth Extension** | [SUSFS v1.5.5 (`NON-GKI`)](https://gitlab.com/simonpunk/susfs4ksu/-/tree/kernel-4.19) + [AlwaysStrong](https://gitlab.com/Evokerr/AlwaysStrong/-/releases) (`BASIC` / `DEVICE` / `STRONG_INTEGRITY` verified) |

> [!IMPORTANT]
> This kernel targets **LineageOS 24** and AOSP-based custom ROMs only. It is **not compatible** with Samsung Stock OneUI firmware. Use the [`AnyKernel3` zip](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) if you are on a non-LineageOS AOSP ROM so your ROM's ramdisk is preserved.

---

## Before You Begin

Before building or flashing:

- Unlocked bootloader on a **Samsung Galaxy A21s** (`SM-A217F` / `SM-A217M` / `SM-A217N`) running **LineageOS 24**.
- Custom recovery (**LineageOS Recovery**, [TWRP](https://twrp.me), or [OrangeFox](https://orangefox.download)) for the recommended `AnyKernel3` method.
- **USB Debugging** enabled (*Settings → About Phone → tap Build Number 7× → Developer Options → USB Debugging*) for ADB, [`samloader`](https://github.com/topjohnwu/samloader-rs), [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall), or [Odin](https://odindownload.com).
- A clean backup of your stock `boot.img` stored off-device.

---

## Build the Kernel

Choose any of four reproducible build methods (full details in [docs/BUILD.md](docs/BUILD.md)):

### Method A — Cloud Build (GitHub Actions, Zero Local Setup)

1. Open [GitHub Actions → Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml) ([`.github/workflows/build-kernel.yml`](.github/workflows/build-kernel.yml)).
2. Click **Run workflow** on `main` *(optionally pass `stock_boot_url` to repack `boot-ksu.img` & `boot-ksu.tar`)*.
3. CI automatically builds `Image` + `KernelSU-Next-A21s-universal850-AnyKernel3.zip` and compiles `ksu_susfs_arm64` from source via Android NDK into `susfs4ksu-v1.5.5.zip`. Download everything from workflow artifacts (or [Releases](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) on tag pushes).

### Method B — Docker / Compose (Windows / macOS / Linux)

Uses [`Dockerfile`](Dockerfile) and [`docker-compose.yml`](docker-compose.yml):

1. Place your baseline LineageOS `boot.img` in the repository root.
2. Run:
   ```bash
   docker compose up --build
   ```
3. Artifacts are written directly into `out/`.

### Method C — Universal Python CLI (Cross-Platform)

Uses [`build.py`](build.py) (`doctor`, `package`, `make-tar`, `docker-build`, `report-issue`):

```bash
python3 build.py doctor        # Check host tools, ADB, and Docker availability
python3 build.py package       # Repack AnyKernel3 recovery zip
python3 build.py make-tar      # Wrap out/boot-ksu.img into Odin boot-ksu.tar
python3 build.py docker-build  # Run full containerized kernel build
```

### Method D — Native Linux / WSL2

Uses [`scripts/setup_env.sh`](scripts/setup_env.sh), [`scripts/build.sh`](scripts/build.sh), and [`scripts/package_anykernel3.sh`](scripts/package_anykernel3.sh):

```bash
./scripts/setup_env.sh         # Clone Clang r416183b, magiskboot, kernel, KSU-Next, and apply patches 0001-0004
./scripts/build.sh boot.img    # Build Image with configs/a21s_ksu_defconfig, repack boot-ksu.img & boot-ksu.tar
./scripts/package_anykernel3.sh
```

> [!TIP]
> Want to rebuild the version-matched [`susfs4ksu-v1.5.5.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/susfs4ksu-v1.5.5.zip) module yourself? See [BUILD.md — Building the SUSFS v1.5.5 Companion Module](docs/BUILD.md#building-the-susfs-v155-companion-module-susfs4ksu-v155zip).

---

## Flash to Your Device

| Target / Platform | Recommended Tool | Release Asset |
| :--- | :--- | :--- |
| **Any OS / Recovery** *(Recommended)* | [LineageOS Recovery](https://wiki.lineageos.org/adb_fastboot_guide), [TWRP](https://twrp.me), or [OrangeFox](https://orangefox.download) | [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) |
| **Windows (Odin)** | [Samsung Odin3 v3.14+](https://odindownload.com) (Slot: **AP**) | [`boot-ksu.tar`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.tar) |
| **Linux / macOS (CLI)** | [`samloader`](https://github.com/topjohnwu/samloader-rs) / [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall) | [`boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.img) |
| **Manager App** | Android / `adb install` | [`KernelSU_Next_v3.4.2.apk`](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.2/KernelSU_Next_v3.4.2.apk) |
| **SUSFS Companion** | KernelSU-Next Manager → Modules | [`susfs4ksu-v1.5.5.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/susfs4ksu-v1.5.5.zip) |

```bash
# Quick CLI flash in Download Mode (Linux/macOS):
adb reboot download
samloader flash --partition BOOT boot-ksu.img
# Or via Heimdall:
heimdall flash --BOOT boot-ksu.img --no-reboot
```

> [!TIP]
> The **AnyKernel3 zip** method preserves your installed ROM's ramdisk and works with zero PC setup after recovery is installed. Full instructions for every tool live in [docs/FLASHING_GUIDE.md](docs/FLASHING_GUIDE.md) and [docs/USER_GUIDE.md](docs/USER_GUIDE.md).

> [!CAUTION]
> Flashing a mismatched `boot-ksu.img` onto a non-LineageOS 24 ROM will likely bootloop. Verify your ROM base before flashing raw images.

---

## Verification Milestones

Validated live on physical **Samsung Galaxy A21s (`SM-A217F`)** running **LineageOS 24**:

- [x] Reproducible source build from LineageOS `universal850` (`4.19.325-gb8c71b7aecec`) with AOSP Clang 12.0.5 (`LLVM=1`)
- [x] Diagnosed Exynos 850 TrustZone TZASC `irq/160-tzasc` crash with dynamic kprobes
- [x] Implemented compile-time Manual Hooks across `fs/` (`exec.c`, `open.c`, `read_write.c`, `stat.c` incl. `newfstat`) & `kernel/reboot.c`
- [x] Backported `path_umount` (`fs/namespace.c`) and resolved OpenSSL 3.0+ host tool errors
- [x] Integrated SUSFS `v1.5.5 (NON-GKI)` with Samsung `fs_context` mount adaptation & `prctl(0xDEADBEEF)` root guard
- [x] Embedded `hal_keymaster_default` DAK SELinux rules directly into KernelSU-Next `rules.c`
- [x] Aligned driver version (`33355`) & UAPI `5` parity with [KernelSU-Next Manager v3.4.2](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v3.4.2)
- [x] Verified live root, automatic `ksud` boot scripts, stealth stack ([ReZygisk](https://github.com/PerformanC/ReZygisk) + [Vector](https://github.com/JingMatrix/Vector) + [HMA-OSS](https://github.com/frknkrc44/HMA-OSS) + [AlwaysStrong](https://gitlab.com/Evokerr/AlwaysStrong/-/releases)), and `MEETS_BASIC` / `DEVICE` / `STRONG_INTEGRITY`

---

## Project Structure

<details>
<summary><strong>Expand repository tree with direct links to patches, scripts, configs, and docs</strong></summary>

```text
A21s-KernelSU-Next/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md                                  # Structured bug report template
│   │   └── feature_request.md                             # Enhancement request template
│   └── workflows/
│       └── build-kernel.yml                               # GitHub Actions cloud build pipeline
├── configs/
│   ├── a21s_ksu_defconfig                                 # Full validated Exynos 850 KSU + SUSFS defconfig
│   └── a21s_ksu_minimal_defconfig                           # Minimal defconfig fragment
├── docs/
│   ├── README.md                                          # Documentation navigation hub
│   ├── USER_GUIDE.md                                      # Beginner setup, stealth stack & AlwaysStrong
│   ├── FLASHING_GUIDE.md                                  # AnyKernel3, samloader, Odin, Heimdall guide
│   ├── BUILD.md                                           # Source compilation + SUSFS module packaging
│   ├── OTA_AND_UPDATES.md                                 # Retaining root across LineageOS nightlies
│   ├── TROUBLESHOOTING.md                                 # Diagnostics, pstore/ramoops, Play Integrity
│   ├── ARCHITECTURE.md                                    # TZASC, Manual Hooks, UAPI, SUSFS design
│   ├── RESEARCH.md                                        # Engineering report & device-tree notes
│   └── CONTRIBUTING.md                                    # Contribution & porting guide
├── patches/
│   ├── 0001-build-host-openssl-3-compat.patch             # OpenSSL 3.0+ host compiler fixes
│   ├── 0002-kernelsu-manual-hooks-and-backports.patch     # 6 manual hooks (incl. newfstat) & path_umount
│   ├── 0003-kernelsu-next-samsung-fixes.patch             # Dynamic UAPI, copy_to_kernel_nofault & DAK SELinux
│   └── 0004-susfs-v1.5.5-kernel-4.19.patch                # SUSFS v1.5.5 VFS, fs_context & prctl root guard
├── scripts/
│   ├── setup_env.sh                                       # Clones toolchain, magiskboot, kernel, KSU-Next & patches
│   ├── build.sh                                           # Compiles Image & repacks boot-ksu.img / boot-ksu.tar
│   └── package_anykernel3.sh                              # Packages AnyKernel3 recovery zip
├── tools/
│   ├── anykernel3/anykernel.sh                            # Exynos 850 A-only AnyKernel3 installer script
│   └── crash_reporter/00_ksu_crash_reporter.sh            # On-device post-bootloop pstore crash notifier
├── build.py                                               # Cross-platform CLI (doctor, package, make-tar, report-issue)
├── Dockerfile                                             # Reproducible Ubuntu build environment
├── docker-compose.yml                                     # One-command container build config
└── LICENSE                                                # GPL-2.0 license
```

Quick file links: [`build.py`](build.py) · [`.github/workflows/build-kernel.yml`](.github/workflows/build-kernel.yml) · [`configs/a21s_ksu_defconfig`](configs/a21s_ksu_defconfig) · [`tools/anykernel3/anykernel.sh`](tools/anykernel3/anykernel.sh) · [`tools/crash_reporter/00_ksu_crash_reporter.sh`](tools/crash_reporter/00_ksu_crash_reporter.sh)

</details>

---

## Documentation & Guides

| Guide | Who It's For | Summary |
| :--- | :--- | :--- |
| [Documentation Hub](docs/README.md) | Everyone | Guided reading map, upstream repo links, and topic index |
| [User Installation Guide](docs/USER_GUIDE.md) | End users | No-compile flashing, root allowlisting, ReZygisk, Vector, HMA-OSS, AlwaysStrong |
| [Flashing Methods](docs/FLASHING_GUIDE.md) | All users | Detailed AnyKernel3, `samloader`, Odin, and Heimdall walkthroughs |
| [Kernel Build Guide](docs/BUILD.md) | Builders / Developers | Cloud CI, Docker, Python CLI, native Clang, and `susfs4ksu-v1.5.5.zip` packaging |
| [OTA Updates & Lifecycle](docs/OTA_AND_UPDATES.md) | Daily drivers | Keep root & modules intact across LineageOS updates in ~5 seconds |
| [Troubleshooting & Diagnostics](docs/TROUBLESHOOTING.md) | Debugging issues | 1-click issue reporter, `ramoops` log capture, blindspots, and Play Integrity |
| [Technical Architecture](docs/ARCHITECTURE.md) | Kernel developers | Deep dive into Exynos 850 TZASC, Manual Hooks, Dynamic UAPI, SUSFS, and Zygisk |
| [Technical Research Report](docs/RESEARCH.md) | Researchers / Porters | Crash analysis, device tree geometry, and overlay workspace architecture |
| [Contributing Guidelines](docs/CONTRIBUTING.md) | Contributors | Patch rules, testing checklist, and porting to other Exynos non-GKI devices |

---

## License

- **Kernel patches & modifications:** [GPL-2.0](LICENSE)
- **Build scripts & documentation:** GPL-3.0-or-later
