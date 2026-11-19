# 🗺️ Documentation Hub — Galaxy A21s KernelSU-Next

**Everything you need to build, flash, root, update, debug, and contribute to the Galaxy A21s (`SM-A217F`) KernelSU-Next project on LineageOS 24 — in one place.**

---

## ⚡ Jump to What You Need

| I want to… | Go here |
| :--- | :--- |
| Get root on my A21s for the first time | [User Installation Guide](USER_GUIDE.md) |
| Flash the kernel ZIP via recovery | [AnyKernel3 method](FLASHING_GUIDE.md#method-3-using-anykernel3-recovery-zip-recommended) |
| Flash via Linux terminal (`samloader`) | [samloader method](FLASHING_GUIDE.md#method-1-using-samloader-on-linux-recommended--fastest) |
| Survive a LineageOS OTA update | [OTA & Updates Survival](OTA_AND_UPDATES.md) |
| Debug a bootloop or pull kernel logs | [Troubleshooting & Diagnostics](TROUBLESHOOTING.md) |
| Understand how the kernel/KSU integration works | [Technical Architecture](ARCHITECTURE.md) |
| Read the full research & implementation analysis | [Research & Implementation Report](RESEARCH.md) |
| Submit a patch or contribute code | [Contributing Guidelines](CONTRIBUTING.md) |

---

## 📚 Documentation Index

| Document | Target Audience | Summary |
| :--- | :--- | :--- |
| **[User Installation Guide](USER_GUIDE.md)** | End Users | Step-by-step beginner guide to getting root on LineageOS 24 via recovery ZIP or PC. |
| **[Flashing Guide](FLASHING_GUIDE.md)** | All Users | Detailed flashing instructions using `AnyKernel3`, `samloader`, `Heimdall`, and `Odin`. |
| **[OTA & Updates Survival](OTA_AND_UPDATES.md)** | All Users | How to survive LineageOS nightly/weekly updates without losing data or root. |
| **[Technical Architecture](ARCHITECTURE.md)** | Developers / Engineers | Deep-dive on Samsung Exynos 850 TrustZone (TZASC IRQ 160) and manual hooks implementation. |
| **[Research & Implementation Report](RESEARCH.md)** | Developers / Researchers | Comprehensive analysis of Exynos 850 kernel trees, dynamic kprobes vs manual hooks, and UAPI 5 parity. |
| **[Troubleshooting & Bug Reporting](TROUBLESHOOTING.md)** | All Users | Extracting `ramoops`, `dmesg`, `logcat`, and `ksud` logs, bootloop recovery, and issue templates. |
| **[Contributing Guidelines](CONTRIBUTING.md)** | Contributors | How to contribute code, submit patches, and verify kernel builds. |

---

## 🧭 Reading Flow — Where to Start

Use this visual map to follow the right path based on your goal.

```
                      ┌─────────────────────────────────────┐
                      │  New to the project?                │
                      │  Start → USER_GUIDE.md              │
                      └────────────┬────────────────────────┘
                                   │
              ┌────────────────────▼────────────────────────┐
              │  Ready to flash?                            │
              │  FLASHING_GUIDE.md                          │
              │  (AnyKernel3 ZIP  /  samloader  /  Odin)   │
              └────────────────────┬────────────────────────┘
                                   │
         ┌─────────────────────────▼──────────────────────────┐
         │  Got root? Want to keep it across OTA updates?     │
         │  OTA_AND_UPDATES.md                                │
         └──────────┬────────────────────────┬────────────────┘
                    │                        │
     ┌──────────────▼──────────┐  ┌──────────▼──────────────────┐
     │ Something broke?        │  │ Want to go deeper?           │
     │ TROUBLESHOOTING.md      │  │ ARCHITECTURE.md              │
     │ (logs, bootloops,       │  │ RESEARCH.md                  │
     │  issue templates)       │  │ (Exynos 850, kprobes, hooks) │
     └─────────────────────────┘  └──────────────────────────────┘
                                           │
                               ┌───────────▼───────────────────┐
                               │ Want to contribute?           │
                               │ CONTRIBUTING.md               │
                               └───────────────────────────────┘
```

> [!TIP]
> **Junior users** — follow the flow top-to-bottom starting with the User Installation Guide.
> **Kernel developers** — jump straight to `ARCHITECTURE.md` or `RESEARCH.md` and use the other docs as reference.

---

## 🔍 Upstream & Reference Trees

This project builds upon and integrates with the following key open-source repositories:

1. **Exynos 850 Kernel Tree for LineageOS 24:**
   - Repository: [`samsungexynos850/android_kernel_samsung_exynos850`](https://github.com/samsungexynos850/android_kernel_samsung_exynos850)
   - Branch: `lineage-24.0` (Linux 4.19.325, commit `b8c71b7aecec`)
   - Role: Upstream base kernel tree utilized for compilation and our KernelSU-Next patchset.

2. **Official LineageOS Device Tree for Galaxy A21s:**
   - Repository: [`LineageOS/android_device_samsung_a21s`](https://github.com/LineageOS/android_device_samsung_a21s)
   - Role: Hardware definitions, partition geometry (`boot` size: 36 MiB limit), header version (2), page size (2048), and init scripts.

3. **Official LineageOS Prebuilt Toolchain:**
   - Repository: [`LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b`](https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b)
   - Branch: `lineage-20.0`
   - Role: Clang 12.0.5 compiler with integrated LLVM assembler and LLD linker.

4. **KernelSU-Next Upstream:**
   - Repository: [`KernelSU-Next/KernelSU-Next`](https://github.com/KernelSU-Next/KernelSU-Next)
   - Branch: `legacy` (v3.4.0-legacy)
   - Role: Next-generation kernel-based root solution for Android with GKI1 / Non-GKI support.

---

## 🛠️ Before You Begin

> [!IMPORTANT]
> Review these prerequisites before flashing or building anything.

- **Device:** Samsung Galaxy A21s (`SM-A217F`, codename `a21s`, SoC `universal850` / Exynos 850)
- **ROM:** LineageOS 24 (Android 14) — this project is built and tested against LineageOS 24 only
- **Unlocked bootloader** — required to flash a custom kernel
- **Custom recovery** (e.g. TWRP or LineageOS Recovery) — required for the AnyKernel3 ZIP method
- **USB debugging enabled** — required for `adb` / `fastboot` / `samloader` workflows
- **A full backup of your data** — flashing carries risk; always back up first

> [!CAUTION]
> Flashing the wrong image can result in a soft-brick. Always verify the build matches your exact device model (`SM-A217F`) before proceeding.

---

## 📋 Related Docs (Next Steps)

After reading this hub, the natural next stop is the **[User Installation Guide](USER_GUIDE.md)**. From there, follow the reading flow above based on what you need.

| If you just finished… | Read next… |
| :--- | :--- |
| This README | [User Installation Guide](USER_GUIDE.md) |
| User Installation Guide | [Flashing Guide](FLASHING_GUIDE.md) |
| Flashing Guide | [OTA & Updates Survival](OTA_AND_UPDATES.md) |
| OTA & Updates Survival | [Troubleshooting & Bug Reporting](TROUBLESHOOTING.md) |
| Troubleshooting | [Technical Architecture](ARCHITECTURE.md) |
| Technical Architecture | [Research & Implementation Report](RESEARCH.md) |
| Research Report | [Contributing Guidelines](CONTRIBUTING.md) |
