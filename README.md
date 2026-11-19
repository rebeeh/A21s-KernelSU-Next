# A21s KernelSU Next

[![Build Kernel](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](LICENSE)
[![Device: Galaxy A21s](https://img.shields.io/badge/Device-Samsung%20Galaxy%20A21s%20(SM--A217F)-green.svg)](https://github.com/rebeeh/A21s-KernelSU-Next)
[![Kernel: 4.19.325](https://img.shields.io/badge/Kernel-Linux%204.19.325-orange.svg)](https://github.com/LineageOS/android_kernel_samsung_universal850)
[![Root: KernelSU-Next](https://img.shields.io/badge/Root-KernelSU--Next%20Legacy-teal.svg)](https://github.com/KernelSU-Next/KernelSU-Next)

A production-grade custom Linux kernel for the **Samsung Galaxy A21s (SM-A217F / universal850)** with integrated **KernelSU-Next**, specifically tailored for **LineageOS 24 (Linux 4.19.325)**.

---

## 🌟 Key Highlights & Engineering Breakthroughs

- **TrustZone / TZASC Bypass via Manual Hooks:** Samsung Exynos 850 features hardware memory protection (TZASC / RKP) that traps dynamic runtime kprobes, triggering `irq/160-tzasc` kernel panics and bootloops. We implemented compile-time scope-minimized manual hooks across `fs/exec.c`, `fs/open.c`, `fs/read_write.c`, `fs/stat.c`, and `kernel/reboot.c`, delivering 100% stable execution without memory tampering.
- **Strict UAPI 5 Parity:** Aligned kernel supercall interfaces to match official KernelSU-Next Manager `v3.4.2` and embedded `ksud (uapi: 5)`, completely eliminating manager warning banners and unlocking full Superuser and Module management tabs.
- **Linux 4.19 Backports:** Integrated `path_umount` from Linux 5.9+ into `fs/namespace.c` to enable native KernelSU module mount hiding without kernel crashes.
- **Modern Host Compatibility:** Resolved OpenSSL 3.0+ certificate extraction compilation issues on modern Linux build systems (Fedora 40+, Ubuntu 22.04+).

---

## 📱 Device Specifications

| Specification | Details |
|---|---|
| **Device** | Samsung Galaxy A21s |
| **Model** | SM-A217F (also compatible with SM-A217M/N) |
| **Chipset** | Samsung Exynos 850 (universal850) |
| **Architecture** | ARM64 (`aarch64-linux-gnu`) |
| **ROM Base** | LineageOS 24 (Android 15) & AOSP Custom ROMs (Not for Stock OneUI) |
| **Kernel Version** | Linux `4.19.325-gb8c71b7aecec` |
| **Compiler** | Google AOSP Clang 12.0.5 (`clang-r416183b`) + `LLVM=1` |
| **Root Solution** | KernelSU-Next (`v3.4.0-legacy` / UAPI 5 aligned) |
| **Hook Mode** | Manual Hook Mode (`CONFIG_KSU_MANUAL_HOOK=y`) |

---

## 📂 Project Architecture

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
│   ├── CONTRIBUTING.md            # Community contribution & porting guidelines
│   ├── FLASHING_GUIDE.md          # Flashing instructions via AnyKernel3, samloader, Odin, and Heimdall
│   ├── OTA_AND_UPDATES.md         # Preserving root across LineageOS OTA updates
│   ├── RESEARCH.md                # In-depth technical research & engineering report
│   ├── TROUBLESHOOTING.md         # Diagnostic log extraction & troubleshooting
│   └── USER_GUIDE.md              # End-user installation guide (no compiling required)
├── patches/
│   ├── 0001-build-host-openssl-3-compat.patch          # OpenSSL 3 host fixes
│   ├── 0002-kernelsu-manual-hooks-and-backports.patch  # 5 manual hooks & path_umount
│   └── 0003-kernelsu-next-samsung-fixes.patch          # UAPI 5 alignment & copy_to_kernel_nofault
├── scripts/
│   ├── build.sh                   # Builds kernel Image, repacks boot.img and Odin .tar
│   ├── package_anykernel3.sh      # Creates recovery-flashable AnyKernel3 zip
│   └── setup_env.sh               # Fetches toolchains, magiskboot & applies patches
├── README.md
└── LICENSE
```

---

## 🚀 Cross-Platform Build & Flashing System

This project is designed from scratch to be **100% platform-independent**. You can build and flash whether you are on **Windows**, **macOS**, or **Linux**, or even without a PC directly on your device.

### Method A: Universal Python CLI (Windows / macOS / Linux)
No external dependencies required:
```bash
# 1. Check your host environment
python3 build.py doctor

# 2. Package AnyKernel3 recovery zip portably
python3 build.py package

# 3. Create Odin boot-ksu.tar portably
python3 build.py make-tar

# 4. 1-Click build inside standardized Docker container
python3 build.py docker-build
```

### Method B: Universal Docker / Compose (Windows / macOS / Linux)
Guarantees a byte-for-byte identical build on any operating system:
```bash
# Place your stock boot.img in the repository root and run:
docker compose up --build
```
Artifacts are automatically placed in the `out/` directory.

### Method C: Cloud Builder (Zero Local Setup)
Trigger the automated build directly from your browser via **[GitHub Actions](https://github.com/rebeeh/A21s-KernelSU-Next/actions/workflows/build-kernel.yml)** (`Run workflow`). Download the prebuilt zip, img, and tar archives in seconds.

### Method D: Native Linux / WSL2
```bash
./scripts/setup_env.sh
./scripts/build.sh boot.img
```

---

## ⚡ Cross-Platform Flashing Options

| Platform | Recommended Flashing Tool | Target File |
| :--- | :--- | :--- |
| **Any OS / No PC** | **LineageOS Recovery / TWRP** | `KernelSU-Next-A21s-universal850-AnyKernel3.zip` |
| **Windows** | **Samsung Odin3 v3.14+** (Slot: AP) | `out/boot-ksu.tar` |
| **Linux** | **`samloader`** (`samloader flash --partition BOOT out/boot-ksu.img`) | `out/boot-ksu.img` |
| **macOS / Linux** | **`heimdall`** (`heimdall flash --BOOT out/boot-ksu.img`) | `out/boot-ksu.img` |

---

## 🎯 Verification Milestones

- [x] Obtain exact source tree matching LineageOS 24 (`b8c71b7aecec`)
- [x] Set up AOSP Clang 12.0.5 (`clang-r416183b`) toolchain with `LLVM=1`
- [x] Identify TrustZone TZASC IRQ 160 crash root cause with dynamic kprobes
- [x] Implement compile-time Manual Hooks in `fs/` and `kernel/`
- [x] Backport `path_umount` for safe module unmounting
- [x] Resolve OpenSSL 3.0+ host build tool collisions
- [x] Compile kernel and repack boot image using `magiskboot`
- [x] Boot device into LineageOS 24 system without panics
- [x] Align UAPI to version 5 to achieve full parity with Manager `v3.4.2`
- [x] Verify live root execution, `ksud`, and Superuser / Module management tabs

---

## 📖 Documentation & Guides

- 📚 [Documentation Hub & Index](docs/README.md)
- 🧑‍💻 [End-User Installation & Root Guide (No compiling needed)](docs/USER_GUIDE.md)
- 🔬 [In-Depth Technical Research & Engineering Report](docs/RESEARCH.md)
- 🔄 [LineageOS OTA Updates & Kernel Lifecycle Guide](docs/OTA_AND_UPDATES.md)
- 🛠️ [Troubleshooting, Log Extraction & Diagnostics](docs/TROUBLESHOOTING.md)
- 🏗️ [Hardware Architecture & TrustZone TZASC Analysis](docs/ARCHITECTURE.md)
- ⚡ [Flashing Methods (AnyKernel3, samloader, Odin, Heimdall)](docs/FLASHING_GUIDE.md)
- 🤝 [Contributing Guidelines](docs/CONTRIBUTING.md)

---

## 📜 License

- **Kernel patches & modifications:** GPL-2.0
- **Build scripts & documentation:** GPL-3.0-or-later
