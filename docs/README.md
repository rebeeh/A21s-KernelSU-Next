# Documentation Hub - Galaxy A21s KernelSU-Next

Welcome to the documentation suite for the **Galaxy A21s (`SM-A217F` / `universal850`) KernelSU-Next** project.

This directory contains technical architecture documentation, flashing guides for all operating systems, OTA update survival workflows, and debugging manuals.

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

## ⚡ Quick Links & Navigation

- **Need to root immediately?** Head to the **[User Installation Guide](USER_GUIDE.md)**.
- **Flashing via Recovery?** Use **`KernelSU-Next-A21s-universal850-AnyKernel3.zip`** ([Guide](FLASHING_GUIDE.md#method-3-using-anykernel3-recovery-zip-recommended)).
- **Flashing via Linux terminal?** Use `samloader flash --partition BOOT boot-ksu.img` ([Guide](FLASHING_GUIDE.md#method-1-using-samloader-on-linux-recommended--fastest)).
- **Encountered an issue?** Read **[Troubleshooting & Diagnostics](TROUBLESHOOTING.md)** to pull kernel logs before filing a GitHub Issue.
