# A21s-KernelSU-Next

[![Latest Release](https://img.shields.io/github/v/release/rebeeh/A21s-KernelSU-Next?color=blue&label=Latest%20Release)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest)
[![Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](LICENSE)
[![Device: Galaxy A21s](https://img.shields.io/badge/Device-Samsung%20Galaxy%20A21s%20(SM--A217F)-green.svg)](https://github.com/rebeeh/A21s-KernelSU-Next)
[![Kernel: 4.19.325](https://img.shields.io/badge/Kernel-Linux%204.19.325-orange.svg)](https://github.com/LineageOS/android_kernel_samsung_universal850)
[![Root: KernelSU-Next](https://img.shields.io/badge/Root-KernelSU--Next%20Legacy-teal.svg)](https://github.com/KernelSU-Next/KernelSU-Next)

> A production-grade custom Linux kernel for the **Samsung Galaxy A21s (SM-A217F)** with integrated **KernelSU-Next**, tailored for **LineageOS 24** — solving real Exynos 850 TrustZone/TZASC hardware constraints to deliver stable, full-featured root.

---

## 🗺️ Jump to What You Need

| I want to… | Go to… |
| :--- | :--- |
| Download prebuilt flashable images (latest) | [GitHub Releases (latest)](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest) |
| Flash the kernel right now (no compiling) | [End-User Installation Guide](docs/USER_GUIDE.md) |
| Build from source | [Kernel Compilation Guide](docs/BUILD.md) |
| Flash to my device | [📲 Flash to Your Device](#-flash-to-your-device) |
| Understand what makes this kernel special | [🌟 Engineering Highlights](#-engineering-highlights) |
| Troubleshoot a boot issue | [Troubleshooting Guide](docs/TROUBLESHOOTING.md) |
| Survive a LineageOS OTA update | [OTA & Updates Guide](docs/OTA_AND_UPDATES.md) |
| Contribute or port to another device | [Contributing Guidelines](docs/CONTRIBUTING.md) |

---

## 🌟 Engineering Highlights

These are the core technical problems solved to make KernelSU-Next work reliably on the Galaxy A21s:

- **Integrated SUSFS v1.5.5 Support** — Native kernel-level SUSFS (Super User Secret File System) v1.5.5 integrated into the Linux 4.19 VFS layer and KernelSU-Next manual hooks, adapted for Samsung's `fs_context` architecture (`vfs_create_mount`, `clone_mnt`). Includes suspicious mount hiding, path hiding, kstat spoofing, uname spoofing, and automatic umount. Reported as `SuSFS version: Supported | v1.5.5 (NON-GKI)` directly in the KernelSU Next Manager dashboard.
- **Exact Driver Version Matching (33355)** — Kernel driver version override aligned with userspace `ksud 3.4.2` (`33355`), eliminating module installer mismatch warnings (e.g. in HMA-OSS Zygisk).
- **TrustZone / TZASC Bypass via Manual Hooks** — The Samsung Exynos 850 uses hardware memory protection (TZASC / RKP) that traps dynamic runtime kprobes, triggering `irq/160-tzasc` kernel panics and bootloops. Compile-time, scope-minimized manual hooks are implemented across `fs/exec.c`, `fs/open.c`, `fs/read_write.c`, `fs/stat.c` (including `newfstat` for Android 14–17 `init.rc` `ksud` boot injection), and `kernel/reboot.c`, delivering 100% stable execution without memory tampering.
- **Built-in Keymaster DAK SELinux & `prctl` Stealth** — KernelSU-Next `rules.c` embeds `hal_keymaster_default` access to Samsung Device Attestation Keys (`/mnt/vendor/efs/DAK/`), preventing `ret -932` (`UNEVALUATED`) on LineageOS, while `kernel/sys.c` guards `prctl(0xDEADBEEF)` to `GLOBAL_ROOT_UID` so non-root detectors receive `-EINVAL` instead of `0`. See [Architecture](docs/ARCHITECTURE.md) and [Troubleshooting](docs/TROUBLESHOOTING.md).
- **Strict UAPI 5 Parity** — Supercall interfaces are aligned with the official KernelSU-Next Manager `v3.4.2` and embedded `ksud (uapi: 5)`, eliminating manager warning banners and unlocking full Superuser and Module management tabs.
- **Linux 4.19 Backports** — `path_umount` from Linux 5.9+ has been backported into `fs/namespace.c` to enable native KernelSU module mount hiding without kernel crashes.
- **Modern Host Compatibility** — OpenSSL 3.0+ certificate extraction compilation issues on modern Linux build systems (Fedora 40+, Ubuntu 22.04+) are fully resolved.

---

## 📱 Device Specifications

| Specification | Details |
| :--- | :--- |
| **Device** | Samsung Galaxy A21s |
| **Model** | SM-A217F (also compatible with SM-A217M/N) |
| **Chipset** | Samsung Exynos 850 (universal850) |
| **Architecture** | ARM64 (`aarch64-linux-gnu`) |
| **ROM Base** | LineageOS 24 (Android 17 / SDK 37) & AOSP Custom ROMs *(not for Stock OneUI)* |
| **Kernel Version** | Linux `4.19.325-gb8c71b7aecec` |
| **Compiler** | Google AOSP Clang 12.0.5 (`clang-r416183b`) + `LLVM=1` |
| **Root Solution** | KernelSU-Next (`v3.4.0-legacy` / UAPI 5 aligned) |
| **Hook Mode** | Manual Hook Mode (`CONFIG_KSU_MANUAL_HOOK=y`) |

> [!IMPORTANT]
> This kernel is built for **LineageOS 24** and AOSP-based custom ROMs only. It is **not compatible** with Samsung Stock OneUI firmware.

---

## 🛠️ Before You Begin

Make sure you have the following before building or flashing:

- A **Samsung Galaxy A21s (SM-A217F / SM-A217M / SM-A217N)** running **LineageOS 24**.
- A **custom recovery** installed (LineageOS Recovery or TWRP) if flashing via AnyKernel3 zip.
- **Developer options** and **USB debugging** enabled on your device if using ADB/Odin/Heimdall.
- A **backed-up stock `boot.img`** in case you need to restore — extract it from your LineageOS 24 build or pull it via `adb shell dd`.
- For building: a Linux, macOS, or Windows machine (or use the zero-setup cloud build — see below).

---

## ⚡ Build the Kernel

This project is designed to be **100% platform-independent**. Choose whichever method works for you.

### Method A — ☁️ Cloud Build (Zero Local Setup, Recommended for Most Users)

No PC setup needed. Trigger a build directly from your browser:

1. Open [GitHub Actions → Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml).
2. Click **Run workflow**.
3. Wait for the build to complete, then download the prebuilt `.zip`, `.img`, and `.tar` artifacts.

### Method B — 🐳 Docker / Compose (Windows / macOS / Linux)

Guarantees a byte-for-byte identical build on any OS:

1. Place your stock `boot.img` in the repository root.
2. Run:
   ```bash
   docker compose up --build
   ```
3. Artifacts are automatically placed in the `out/` directory.

### Method C — 🐍 Universal Python CLI (Windows / macOS / Linux)

No external dependencies required:

```bash
# 1. Check your host environment
python3 build.py doctor

# 2. Package AnyKernel3 recovery zip portably
python3 build.py package

# 3. Create Odin boot-ksu.tar portably
python3 build.py make-tar

# 4. One-click build inside a standardised Docker container
python3 build.py docker-build
```

### Method D — 🐧 Native Linux / WSL2

```bash
# 1. Set up toolchains, fetch magiskboot, and apply patches
./scripts/setup_env.sh

# 2. Build the kernel, repack boot.img, and produce the Odin .tar
./scripts/build.sh boot.img
```

---

## 📲 Flash to Your Device

Choose the method that matches your OS and tools:

| Platform | Recommended Tool | Target File |
| :--- | :--- | :--- |
| **Any OS / No PC** | [LineageOS Recovery](https://wiki.lineageos.org/adb_fastboot_guide) or [TWRP](https://twrp.me) | [`KernelSU-Next-A21s-universal850-AnyKernel3.zip`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/KernelSU-Next-A21s-universal850-AnyKernel3.zip) |
| **Windows** | [Samsung Odin3 v3.14+](https://odindownload.com) (Slot: AP) | [`out/boot-ksu.tar`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.tar) |
| **Linux** | [`samloader`](https://github.com/topjohnwu/samloader-rs) | [`out/boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.img) |
| **macOS / Linux** | [`heimdall`](https://github.com/Benjamin-Dobell/Heimdall) | [`out/boot-ksu.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot-ksu.img) |
| **Raw Block** | `dd` / fastboot | [`out/boot.img`](https://github.com/rebeeh/A21s-KernelSU-Next/releases/latest/download/boot.img) |

**Quick reference commands:**

```bash
# samloader (Linux)
samloader flash --partition BOOT out/boot-ksu.img

# heimdall (macOS / Linux)
heimdall flash --BOOT out/boot-ksu.img
```

> [!TIP]
> The **AnyKernel3 zip** method (via recovery) is the easiest and safest approach for most users — no drivers, no Odin, no cables required beyond the initial recovery install.

> [!CAUTION]
> Flashing the wrong `boot.img` or `.tar` for your ROM base will likely result in a bootloop. Always verify you are on **LineageOS 24** before flashing.

For detailed, step-by-step instructions for every method, see the [Flashing Guide](docs/FLASHING_GUIDE.md).

---

## 🎯 Verification Milestones

All of the following have been validated on a real SM-A217F device:

- [x] Obtain exact source tree matching LineageOS 24 (`b8c71b7aecec`)
- [x] Set up AOSP Clang 12.0.5 (`clang-r416183b`) toolchain with `LLVM=1`
- [x] Identify TrustZone TZASC IRQ 160 crash root cause with dynamic kprobes
- [x] Implement compile-time Manual Hooks in `fs/` and `kernel/`
- [x] Backport `path_umount` for safe module unmounting
- [x] Resolve OpenSSL 3.0+ host build tool collisions
- [x] Compile kernel and repack boot image using `magiskboot`
- [x] Boot device into LineageOS 24 without panics
- [x] Align UAPI to version 5 for full parity with Manager `v3.4.2`
- [x] Verify live root execution, `ksud`, and Superuser / Module management tabs

---

## 📂 Project Structure

```
A21s-KernelSU-Next/
├── .github/
│   └── workflows/
│       └── build-kernel.yml        # GitHub Actions automated cloud build pipeline
├── configs/
│   └── a21s_ksu_defconfig         # Validated kernel configuration (KSU + Manual Hooks enabled)
├── docs/
│   ├── README.md                  # Documentation navigation hub & repository index
│   ├── ARCHITECTURE.md            # Hardware security, TZASC breakdown & technical design
│   ├── BUILD.md                   # Kernel compilation guide (Clang, Docker, Python CLI, CI)
│   ├── CONTRIBUTING.md            # Community contribution & porting guidelines
│   ├── FLASHING_GUIDE.md          # Flashing instructions via AnyKernel3, samloader, Odin, and Heimdall
│   ├── OTA_AND_UPDATES.md         # Preserving root across LineageOS OTA updates
│   ├── RESEARCH.md                # In-depth technical research & engineering report
│   ├── TROUBLESHOOTING.md         # Diagnostic log extraction & troubleshooting
│   └── USER_GUIDE.md              # End-user installation guide (no compiling required)
├── patches/
│   ├── 0001-build-host-openssl-3-compat.patch          # OpenSSL 3 host fixes
│   ├── 0002-kernelsu-manual-hooks-and-backports.patch  # 5 manual hooks & path_umount
│   └── 0003-kernelsu-next-samsung-fixes.patch          # Dynamic UAPI engine, UAPI 5 default & copy_to_kernel_nofault
├── scripts/
│   ├── build.sh                   # Builds kernel Image, repacks boot.img and Odin .tar
│   ├── package_anykernel3.sh      # Creates recovery-flashable AnyKernel3 zip
│   └── setup_env.sh               # Fetches toolchains, magiskboot & applies patches
├── README.md
└── LICENSE
```

---

## 📖 Documentation & Guides

| Guide | Description |
| :--- | :--- |
| 📚 [Documentation Hub & Index](docs/README.md) | Full index of all project docs |
| 🧑‍💻 [End-User Installation & Root Guide](docs/USER_GUIDE.md) | No compiling needed — start here if you just want root |
| ⚡ [Flashing Methods](docs/FLASHING_GUIDE.md) | AnyKernel3, samloader, Odin, Heimdall — step by step |
| 🛠️ [Kernel Compilation & Build Guide](docs/BUILD.md) | Build from source with Clang, Docker, Python CLI, or GitHub Actions |
| 🔄 [OTA Updates & Kernel Lifecycle](docs/OTA_AND_UPDATES.md) | How to survive LineageOS OTA updates without losing root |
| 🛠️ [Troubleshooting & Diagnostics](docs/TROUBLESHOOTING.md) | Log extraction, common errors, and fixes |
| 🏗️ [Hardware Architecture & TZASC Analysis](docs/ARCHITECTURE.md) | Deep dive into Exynos 850 TrustZone constraints |
| 🔬 [Technical Research & Engineering Report](docs/RESEARCH.md) | In-depth engineering decisions and findings |
| 🤝 [Contributing Guidelines](docs/CONTRIBUTING.md) | How to contribute patches or port to another device |

---

## 📜 License

- **Kernel patches & modifications:** [GPL-2.0](LICENSE)
- **Build scripts & documentation:** GPL-3.0-or-later
