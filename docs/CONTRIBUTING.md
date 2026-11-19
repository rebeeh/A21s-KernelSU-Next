# Contributing to A21s KernelSU-Next

We welcome contributions, bug reports, and optimizations from the community!

---

## How You Can Contribute

1. **Testing on Different Variants:** The Galaxy A21s has variants such as `SM-A217F`, `SM-A217M`, and `SM-A217N`. Testing builds on other variants and reporting results is invaluable.
2. **Submitting Patches:**
   - Keep commits modular and descriptive.
   - Separate build-system fixes from core kernel patches.
   - Do NOT commit binary build artifacts (`*.img`, `*.tar`, `*.zip`) to the git repository.
3. **Porting to Other Samsung Exynos Devices:**
   - The manual hooks pattern developed here applies to all Exynos non-GKI devices (e.g. Exynos 9611 on A51/M31, Exynos 9820 on S10).
   - If you adapt our patches for another device, feel free to open a discussion or link your fork.

---

## Development Workflow

1. Fork the repository.
2. Set up the development tree:
   ```bash
   ./scripts/setup_env.sh
   ```
3. Make your kernel modifications in `a21s-kernel/`.
4. Test compiling locally:
   ```bash
   ./scripts/build.sh
   ```
5. Test on physical hardware.
6. Export your patch:
   ```bash
   git -C a21s-kernel diff > patches/my-feature.patch
   ```
7. Submit a Pull Request with a clear description and testing proof.
