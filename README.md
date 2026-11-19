# A21s KernelSU Next

A custom Linux kernel for the **Samsung Galaxy A21s (SM-A217F)**, featuring KernelSU Next integration.

The goal of this project is to build and maintain a device-specific kernel with modern kernel-based root management for the Samsung Galaxy A21s.

> **Status:** Work in Progress 🚧

## Device Information

| Component | Details |
|---|---|
| Device | Samsung Galaxy A21s |
| Model | SM-A217F |
| SoC | Samsung Exynos 850 |
| Architecture | ARM64 |
| ROM | LineageOS 24 |
| Kernel Version | Linux 4.19.325 |
| Root Solution | KernelSU Next |

## Features

- KernelSU Next integration
- Kernel-level root access management
- Kernel module support
- Custom kernel configuration
- Device-specific kernel builds
- Boot image compilation

Features will be updated as development progresses.

## Project Goals

- [ ] Obtain the exact kernel source matching the installed kernel
- [ ] Set up the kernel build environment
- [ ] Verify the existing kernel configuration
- [ ] Check kprobe compatibility
- [ ] Integrate KernelSU Next
- [ ] Compile the kernel successfully
- [ ] Generate a flashable boot image
- [ ] Test boot stability
- [ ] Verify KernelSU Next functionality
- [ ] Publish tested builds

## Installation

Installation instructions will be provided after a successful and tested build.

**Do not flash experimental builds without a working recovery plan and a backup of your original boot image.**

## Building

Build instructions will be documented after identifying the exact kernel source, toolchain, build configuration, and device-specific compilation requirements.

## Credits

- [KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next) — Kernel-based root solution.
- Samsung — Original device kernel source.
- LineageOS — Custom Android operating system.

## Disclaimer

This is an independent, experimental device-specific kernel project.

It is not an official Samsung, LineageOS, or KernelSU Next release.

Flashing custom kernels carries risks, including bootloops, data loss, and device malfunction. Always maintain a backup of your original boot image.

## License

Licensing will follow the applicable licenses of the original kernel source and incorporated components. Original copyright and license notices will be preserved.