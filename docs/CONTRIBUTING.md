# 🤝 Contributing to A21s-KernelSU-Next

**This guide explains how to report bugs, write patches, test builds, and contribute code or ports to the A21s-KernelSU-Next project — a custom Linux kernel with KernelSU-Next root for the Samsung Galaxy A21s (SM-A217F) running LineageOS 24.**

---

## 🗺️ Jump to What You Need

| I want to… | Go to |
|---|---|
| Report a bug | [🐛 Bug Reporting](#-bug-reporting) |
| Submit a patch or new feature | [🔀 Submitting a Pull Request](#-submitting-a-pull-request) |
| Run the full dev workflow | [🛠️ Development Workflow](#️-development-workflow) |
| Check what to test before submitting | [✅ Testing Checklist](#-testing-checklist) |
| Port to another Samsung Exynos device | [📲 Porting to Other Devices](#-porting-to-other-devices) |
| Understand the code style rules | [💅 Code Style](#-code-style) |
| See what contributions are welcome | [💡 How You Can Contribute](#-how-you-can-contribute) |

---

## 🏁 Before You Begin (Prerequisites)

Before contributing, make sure you have the following set up:

- **Hardware:** A physical Samsung Galaxy A21s (SM-A217F, SM-A217M, or SM-A217N) for on-device testing.
- **OS:** LineageOS 24 installed and booted on the device.
- **Host OS:** Linux (Ubuntu 22.04 LTS or later recommended).
- **Toolchain:** ARM64 cross-compiler (e.g. `aarch64-linux-gnu-gcc` or Clang/LLVM as used by the build scripts).
- **Dependencies:** All packages installed via the setup script (see [🛠️ Development Workflow](#️-development-workflow)).
- **Git:** Familiarity with basic Git — fork, branch, commit, patch, pull request.
- **Account:** A GitHub account for submitting issues and pull requests.

> [!NOTE]
> You do **not** need to be a kernel developer to contribute. Testing on hardware, writing clear bug reports, and trying builds on variant devices are just as valuable as writing code.

---

## 💡 How You Can Contribute

There are several ways to get involved, regardless of your skill level:

### 🧪 Testing on Device Variants

The Galaxy A21s ships in multiple regional variants. If you have access to one, testing builds and reporting results is enormously helpful:

| Variant | Region |
|---|---|
| SM-A217F | Global / Europe |
| SM-A217M | Latin America |
| SM-A217N | South Korea |

Even a simple "boot confirmed, `su` works, no regressions noticed" report on a variant is a meaningful contribution.

### 🔀 Submitting Patches

- Keep commits **modular and descriptive** — one logical change per commit.
- **Separate** build-system fixes from core kernel patches.
- Do **NOT** commit binary build artifacts (`*.img`, `*.tar`, `*.zip`) to the Git repository.
- Reference related issues in your commit message (e.g. `Fixes #42`).

### 📲 Porting to Other Devices

The manual hooks pattern developed here applies to all Exynos non-GKI devices. See [📲 Porting to Other Devices](#-porting-to-other-devices) for guidance.

### 📝 Documentation

Spotted a typo? An outdated step? A missing explanation? Open a PR against any file in `docs/`. Documentation improvements are always welcome.

---

## 🐛 Bug Reporting

Good bug reports save enormous time. Please follow this etiquette before opening an issue.

### Before You File

1. **Search existing issues** — your bug may already be tracked or resolved.
2. **Reproduce it** — confirm the bug happens consistently, not just once.
3. **Narrow it down** — does it happen with stock KernelSU-Next but not this kernel? After a specific patch? Note that.
4. **Check the latest build** — make sure you are on the most recent release before reporting.

### What to Include in Your Report

A complete bug report should contain the following:

```
**Device variant:** SM-A217F / SM-A217M / SM-A217N
**LineageOS 24 build date:**
**Kernel build / commit hash:**
**KernelSU-Next version:**

**Describe the bug:**
A clear and concise description of what happened.

**Steps to reproduce:**
1. ...
2. ...
3. ...

**Expected behaviour:**
What you expected to happen.

**Actual behaviour:**
What actually happened.

**Logs / dmesg / kernel panic output:**
(paste here or attach as a file)

**Additional context:**
(magisk modules, Xposed/LSPosed, modified system apps, etc.)
```

> [!IMPORTANT]
> Always include the **kernel commit hash** (`git -C a21s-kernel log --oneline -1`) and the **KernelSU-Next version** (`ksud --version` on-device). Without these, it is very difficult to reproduce issues.

### Collecting Logs

```bash
# Capture dmesg immediately after a bug occurs (run on-device via ADB):
adb shell dmesg > dmesg_$(date +%Y%m%d_%H%M%S).txt

# Capture a kernel panic log from the last boot:
adb shell cat /proc/last_kmsg > last_kmsg.txt

# Check KernelSU-Next daemon status:
adb shell ksud log
```

> [!WARNING]
> Scrub your logs for sensitive information (Wi-Fi passwords, accounts, tokens) before attaching them to a public issue.

---

## 🛠️ Development Workflow

Follow these steps to go from fork to pull request:

1. **Fork the repository** on GitHub and clone your fork locally:

   ```bash
   git clone https://github.com/<your-username>/A21s-KernelSU-Next.git
   cd A21s-KernelSU-Next
   ```

2. **Set up the development environment:**

   ```bash
   ./scripts/setup_env.sh
   ```

   This installs required packages and configures the cross-compilation toolchain.

3. **Create a feature branch** — never work directly on `main`:

   ```bash
   git checkout -b feat/my-feature-name
   ```

4. **Make your kernel modifications** inside `a21s-kernel/`.

5. **Build locally** to verify no compilation errors:

   ```bash
   ./scripts/build.sh
   ```

6. **Flash and test on physical hardware.** See [✅ Testing Checklist](#-testing-checklist) for what to verify before you submit.

7. **Export your patch:**

   ```bash
   git -C a21s-kernel diff > patches/my-feature.patch
   ```

8. **Commit your changes** with a clear, descriptive message:

   ```bash
   git add patches/my-feature.patch
   git commit -m "kernel: short description of what this patch does

   Longer explanation of why this change is needed, what problem it
   solves, and any caveats or known side-effects.

   Fixes #<issue-number>"
   ```

9. **Push and open a Pull Request** against the `main` branch. See [🔀 Submitting a Pull Request](#-submitting-a-pull-request) for the PR template.

---

## ✅ Testing Checklist

Run through every item below before marking your PR as "ready for review." Check each item by flashing your build to a physical Galaxy A21s.

### Boot & Stability

- [ ] Device boots to LineageOS 24 without bootloop.
- [ ] Device boots within normal time (not significantly slower than stock kernel).
- [ ] No kernel panic on fresh boot (check `dmesg` after first boot).
- [ ] ADB accessible over USB after boot.

### KernelSU-Next Functionality

- [ ] KernelSU-Next app shows root access granted.
- [ ] `adb shell su` grants a root shell.
- [ ] `ksud --version` reports the expected KernelSU-Next version.
- [ ] Root apps (e.g. a file manager with root access) function correctly.
- [ ] Module installation and uninstallation works via the KernelSU-Next app.

### Core Hardware

- [ ] Wi-Fi connects and maintains a stable connection.
- [ ] Mobile data (LTE) connects and works.
- [ ] Bluetooth pairs and transfers data.
- [ ] Camera (rear and front) opens and captures photos/video.
- [ ] Audio playback (speaker, earpiece, headphone jack if applicable).
- [ ] Microphone captures audio during a call.
- [ ] Calls can be placed and received.
- [ ] USB connectivity (MTP, ADB, charging).
- [ ] GPS acquires a fix.
- [ ] Fingerprint sensor unlocks the device.

### Power & Thermal

- [ ] Device enters deep sleep (verify with `adb shell dumpsys batterystats`).
- [ ] No significant battery drain regression compared to the previous build.
- [ ] Device does not overheat under moderate workload (browsing, 10-minute video).

### Regression Check

- [ ] All existing functionality that your patch does **not** touch still works.
- [ ] Run the build on at least one additional variant (SM-A217M or SM-A217N) if possible.

> [!TIP]
> You do not need to pass every hardware item if your patch does not touch those drivers. Clearly note in your PR which items you tested and which you could not verify.

---

## 💅 Code Style

Follow these conventions to keep the patch history clean and reviewable.

### Commit Messages

Use the standard kernel commit message format:

```
subsystem: short imperative description (max 72 chars)

Body explaining what the patch does and why. Wrap at 72 characters.
Reference any relevant upstream commits, CVEs, or issue numbers.

Fixes #<issue>
Closes #<issue>
```

Examples of **good** subject lines:
```
kernelsu: add manual hook for sys_execve on Exynos 850
build: fix clang LTO flag for Android 14 compat
drivers/battery: reduce charge current logging verbosity
```

### Patch Organisation

- One logical change per commit — do **not** bundle unrelated fixes.
- If fixing a bug introduced by one of your own earlier commits in the same PR, squash it before submission.
- Patches touching `a21s-kernel/` go into `patches/`.
- Build-system changes (scripts, Makefiles, CI configs) are committed separately from kernel code changes.

### Code Formatting

- Follow the **Linux kernel coding style** (`Documentation/process/coding-style.rst`) for all C code.
- Use tabs (not spaces) for indentation in C files.
- Run `scripts/checkpatch.pl` against your patch before submitting:

  ```bash
  ./a21s-kernel/scripts/checkpatch.pl patches/my-feature.patch
  ```

- Shell scripts must pass `shellcheck`:

  ```bash
  shellcheck scripts/my-script.sh
  ```

> [!NOTE]
> `checkpatch.pl` warnings about line length in strings or comments are advisory — fix them if you can, but they will not block a PR merge on their own.

---

## 🔀 Submitting a Pull Request

### PR Title Format

```
[type] Short description of the change
```

Where `[type]` is one of:

| Type | Use for |
|---|---|
| `[feat]` | New feature or capability |
| `[fix]` | Bug fix |
| `[build]` | Build system or CI change |
| `[docs]` | Documentation only |
| `[refactor]` | Code cleanup with no behaviour change |
| `[port]` | Adaptation for a new device or variant |

### PR Description Template

Copy and fill in this template when opening your pull request:

```markdown
## Summary
<!-- One paragraph describing what this PR does and why. -->

## Changes
<!-- Bullet list of the files / subsystems changed. -->
- 

## Testing
<!-- Describe how you tested this. Device variant, build hash, specific scenarios verified. -->
- Device: SM-A217___
- Kernel build: (commit hash)
- KernelSU-Next version:
- Testing checklist: (link to or paste completed checklist)

## Screenshots / Logs
<!-- Attach dmesg, screenshots, or other evidence if relevant. -->

## Related Issues
<!-- e.g. Closes #42 -->
```

### Review Process

1. A maintainer will review your PR within a reasonable time.
2. Address requested changes with new commits — do **not** force-push during active review unless asked.
3. Once approved, a maintainer will squash-merge or rebase-merge depending on the change type.
4. Your name will appear in the commit history — make sure your Git author details are correct.

> [!IMPORTANT]
> PRs that include binary files (`*.img`, `*.zip`, `*.tar`) will be closed immediately. Keep the repository source-only.

---

## 📲 Porting to Other Devices

The **manual hooks pattern** developed for the Galaxy A21s (SM-A217F / Exynos 850) is applicable to all Samsung Exynos non-GKI devices — that is, any Exynos SoC running a 4.x kernel that does not support the Generic Kernel Image interface.

### Known Compatible Exynos Families

| SoC | Example Devices |
|---|---|
| Exynos 850 | Galaxy A21s (this project), Galaxy A12 (SM-A127F), Galaxy M12 |
| Exynos 9611 | Galaxy A51, Galaxy M31 |
| Exynos 9820 | Galaxy S10, Galaxy Note 10 |
| Exynos 7884B | Galaxy A10, Galaxy A20 |

> [!NOTE]
> GKI devices (Exynos 1080, 1280, 2200 and newer) do **not** need manual hooks — KernelSU-Next supports them natively. The porting guidance here applies only to non-GKI targets.

### Steps to Port

1. **Identify your kernel source** — find or extract the Samsung open-source kernel for your target device.
2. **Study our patch set** in `patches/` — the manual hook patches are the ones labelled `kernelsu-*.patch`.
3. **Apply the patches** to your kernel tree:

   ```bash
   git am patches/kernelsu-manual-hooks.patch
   ```

   Expect conflicts; resolve them against your SoC's specific system-call entry points.

4. **Adapt the hook sites** — the exact function names and call sites differ per SoC. Use `grep` to locate `sys_execve`, `sys_faccessat`, and `sys_openat` equivalents in your kernel.
5. **Adjust the Makefile / Kconfig** entries as needed for your device's defconfig.
6. **Test KernelSU-Next detection** — boot and confirm `ksud` sees the hooks via `adb shell ksud status`.
7. **Share your work** — open a Discussion or link your fork in the project's GitHub Discussions. If your port is stable, consider a cross-reference PR to `docs/PORTING.md`.

> [!TIP]
> Join the community discussion or open a GitHub Discussion thread before you start a port — others may already be working on the same device and can save you significant effort.

---

## 🌱 Community Guidelines

- **Be respectful.** Everyone here — from first-time testers to kernel veterans — deserves courtesy.
- **Be patient.** Maintainers contribute in their free time. Allow reasonable time for review.
- **Be specific.** Vague reports ("it doesn't work") are very hard to act on. The more detail, the better.
- **Search first.** Check open and closed issues before filing a new one.
- **No spam.** Do not bump issues repeatedly or ping maintainers unnecessarily.

---

## 📚 Related Docs

| Document | Description |
|---|---|
| [README](../README.md) | Project overview, quick-start build instructions |
| [BUILD](BUILD.md) | Detailed build environment setup and compilation guide |
| [FLASHING](FLASHING.md) | How to flash the kernel to your Galaxy A21s |
| [TROUBLESHOOTING](TROUBLESHOOTING.md) | Common issues and fixes |

---

*Thank you for contributing to A21s-KernelSU-Next — every test report, patch, and improvement makes this project better for the entire Galaxy A21s community.* 🙌
