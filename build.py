#!/usr/bin/env python3
"""
A21s KernelSU-Next - Universal Cross-Platform Build & Packaging System
Works seamlessly on Linux, macOS (Intel & Apple Silicon), and Windows.
No external Python dependencies required (standard library only).
"""

import argparse
import datetime
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import urllib.parse
import urllib.request
import webbrowser
import zipfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
OUT_DIR = PROJECT_ROOT / "out"
CONFIG_FILE = PROJECT_ROOT / "configs" / "a21s_ksu_defconfig"
AK3_DIR = PROJECT_ROOT / "tools" / "anykernel3"

HOST_OS = platform.system().lower()  # 'linux', 'darwin', 'windows'
HOST_ARCH = platform.machine().lower()


def log(msg: str):
    print(f"\033[1;32m[+]\033[0m {msg}")


def warn(msg: str):
    print(f"\033[1;33m[!]\033[0m {msg}")


def err(msg: str):
    print(f"\033[1;31m[-]\033[0m {msg}", file=sys.stderr)


def run_cmd(cmd, cwd=None, env=None, check=True):
    shell = isinstance(cmd, str)
    res = subprocess.run(cmd, cwd=cwd, env=env, shell=shell)
    if check and res.returncode != 0:
        err(f"Command failed with exit code {res.returncode}: {cmd}")
        sys.exit(res.returncode)
    return res.returncode


def cmd_doctor():
    """Diagnoses host environment and recommends the best build path."""
    print("=" * 60)
    print(" A21s KernelSU-Next - Host Environment Diagnostics")
    print("=" * 60)
    print(f" Operating System:  {platform.system()} ({platform.release()})")
    print(f" CPU Architecture:  {HOST_ARCH}")
    print(f" Python Version:    {sys.version.split()[0]}")
    print("-" * 60)

    # 1. Check Docker (Recommended for Windows & macOS)
    docker_bin = shutil.which("docker")
    if docker_bin:
        log(f"Docker detected: {docker_bin}")
        try:
            subprocess.run(["docker", "info"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            log("Docker daemon is active and responsive.")
        except Exception:
            warn("Docker CLI is installed, but the daemon is not running (start Docker Desktop).")
    else:
        if HOST_OS in ("windows", "darwin"):
            warn("Docker is NOT installed. On Windows/macOS, Docker is recommended for 1-click local kernel builds.")

    # 2. Check Git
    git_bin = shutil.which("git")
    if git_bin:
        log(f"Git detected: {git_bin}")
    else:
        err("Git is missing. Please install Git.")

    # 3. Check ADB
    adb_bin = shutil.which("adb")
    if adb_bin:
        log(f"ADB detected: {adb_bin}")
    else:
        warn("ADB is not in PATH. Download Android Platform Tools for device flashing.")

    # 4. Check Flashing Tools
    samloader_bin = shutil.which("samloader")
    heimdall_bin = shutil.which("heimdall")
    if samloader_bin:
        log(f"samloader detected: {samloader_bin}")
    if heimdall_bin:
        log(f"Heimdall detected: {heimdall_bin}")

    print("-" * 60)
    if HOST_OS == "linux":
        log("Linux detected: You can build natively via `./scripts/build.sh` or via Docker.")
    elif HOST_OS == "windows":
        log("Windows detected: You can build using `python build.py docker-build` or WSL2.")
        log("For flashing: Use Odin3 for `boot-ksu.tar` or Recovery for AnyKernel3 zip.")
    elif HOST_OS == "darwin":
        log("macOS detected: You can build using `python build.py docker-build`.")
        log("For flashing: Use Heimdall / samloader or Recovery for AnyKernel3 zip.")
    print("=" * 60)


def cmd_package(image_path: str = None):
    """Packages AnyKernel3 recovery zip using native Python zipfile."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    kernel_image = None
    if image_path:
        p = Path(image_path).resolve()
        if p.is_file():
            kernel_image = p

    if not kernel_image:
        candidates = [
            PROJECT_ROOT / "build" / "a21s-kernel" / "arch" / "arm64" / "boot" / "Image",
            PROJECT_ROOT / "a21s-kernel" / "arch" / "arm64" / "boot" / "Image",
            Path.home() / "Android" / "Kernel" / "a21s-kernel" / "arch" / "arm64" / "boot" / "Image",
            OUT_DIR / "Image",
            PROJECT_ROOT / "Image",
        ]
        for c in candidates:
            if c.is_file():
                kernel_image = c
                break

    if not kernel_image or not kernel_image.is_file():
        err("Compiled kernel 'Image' not found! Build the kernel first or pass --image <path>.")
        sys.exit(1)

    zip_name = "KernelSU-Next-A21s-universal850-AnyKernel3.zip"
    zip_path = OUT_DIR / zip_name

    log(f"Staging kernel Image from: {kernel_image}")
    log(f"Building platform-independent AnyKernel3 zip: {zip_path}")

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        # 1. Add all AnyKernel3 template files
        for root, dirs, files in os.walk(AK3_DIR):
            for file in files:
                if file.startswith(".git") or file == "README.md":
                    continue
                file_full = Path(root) / file
                rel_path = file_full.relative_to(AK3_DIR)
                # Preserve executable permissions in zip
                zinfo = zipfile.ZipInfo.from_file(file_full, arcname=str(rel_path))
                if file.endswith((".sh", "magiskpolicy", "magiskboot")):
                    zinfo.external_attr = 0o755 << 16
                zf.writestr(zinfo, file_full.read_bytes())

        # 2. Add the compiled kernel Image
        zinfo = zipfile.ZipInfo.from_file(kernel_image, arcname="Image")
        zinfo.external_attr = 0o644 << 16
        zf.writestr(zinfo, kernel_image.read_bytes())

    size_mb = zip_path.stat().st_size / (1024 * 1024)
    log(f"Successfully generated: {zip_path.name} ({size_mb:.2f} MiB)")


def cmd_make_tar(boot_img: str = None):
    """Creates a standard Odin-flashable boot-ksu.tar archive."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source_img = None
    if boot_img:
        p = Path(boot_img).resolve()
        if p.is_file():
            source_img = p

    if not source_img:
        candidates = [OUT_DIR / "boot-ksu.img", PROJECT_ROOT / "boot-ksu.img"]
        for c in candidates:
            if c.is_file():
                source_img = c
                break

    if not source_img or not source_img.is_file():
        err("Source 'boot-ksu.img' not found! Repack boot image first or pass --boot-img <path>.")
        sys.exit(1)

    tar_path = OUT_DIR / "boot-ksu.tar"
    log(f"Creating Odin tar archive from {source_img} -> {tar_path}")

    with tarfile.open(tar_path, "w") as tar:
        tar.add(source_img, arcname="boot.img")

    size_mb = tar_path.stat().st_size / (1024 * 1024)
    log(f"Successfully created Odin archive: {tar_path.name} ({size_mb:.2f} MiB)")


def cmd_docker_build(stock_boot: str = None):
    """Builds the custom kernel and flashable outputs inside a standardized Docker container."""
    docker_bin = shutil.which("docker")
    if not docker_bin:
        err("Docker is not installed or not in PATH. Please install Docker Desktop.")
        sys.exit(1)

    tag = "a21s-ksu-builder:latest"
    log("Building Docker container image...")
    run_cmd(["docker", "build", "-t", tag, "-f", str(PROJECT_ROOT / "Dockerfile"), str(PROJECT_ROOT)])

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    mount_out = f"{OUT_DIR.resolve()}:/workspace/out"

    cmd = [
        "docker", "run", "--rm",
        "-v", mount_out,
    ]

    if stock_boot and Path(stock_boot).is_file():
        boot_path = Path(stock_boot).resolve()
        cmd.extend(["-v", f"{boot_path}:/workspace/boot.img:ro"])
        cmd.extend([tag, "bash", "-c", "./scripts/build.sh /workspace/boot.img"])
    else:
        cmd.extend([tag, "bash", "-c", "./scripts/build.sh"])

    log("Running kernel compilation inside Docker container...")
    run_cmd(cmd)
    log("Container compilation completed! Artifacts generated in 'out/' folder.")


def cmd_report_issue():
    """Extracts diagnostic and crash logs from connected device via ADB and opens a pre-filled GitHub issue."""
    log("Scanning for connected ADB device...")
    try:
        res = subprocess.run(["adb", "devices"], capture_output=True, text=True, check=True)
    except FileNotFoundError:
        err("`adb` command not found! Please install ADB (Android Platform Tools) or add it to PATH.")
        sys.exit(1)

    lines = [l.strip() for l in res.stdout.splitlines() if l.strip() and not l.startswith("*") and not l.startswith("List")]
    if not lines:
        err("No ADB device detected! Please connect your phone via USB with USB debugging enabled or in Recovery mode.")
        sys.exit(1)

    device_serial, device_state = lines[0].split()
    log(f"Found connected device: {device_serial} [{device_state}]")

    logs_dir = OUT_DIR / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = logs_dir / f"issue_report_{timestamp}.log"

    report_lines = []
    report_lines.append(f"Device Serial: {device_serial}")
    report_lines.append(f"Device State: {device_state}")
    report_lines.append(f"Report Generated: {datetime.datetime.now().isoformat()}\n")

    # 1. Ramoops crash log
    log("Checking for preserved kernel crash log (pstore/ramoops)...")
    ramoops = subprocess.run(["adb", "shell", "cat /sys/fs/pstore/dmesg-ramoops-0 2>/dev/null || true"], capture_output=True, text=True).stdout
    if ramoops.strip():
        report_lines.append("=" * 40 + " RAMOOPS KERNEL PANIC LOG " + "=" * 40)
        report_lines.append(ramoops.strip() + "\n")
        log("[✓] Captured persistent kernel panic log!")

    # 2. Live dmesg
    log("Capturing dmesg log...")
    dmesg = subprocess.run(["adb", "shell", "dmesg 2>/dev/null | tail -n 120 || true"], capture_output=True, text=True).stdout
    if dmesg.strip():
        report_lines.append("=" * 40 + " LIVE DMESG (LAST 120 LINES) " + "=" * 40)
        report_lines.append(dmesg.strip() + "\n")

    # 3. KernelSU Next Info
    log("Checking KernelSU Next status...")
    ksu_info = subprocess.run(["adb", "shell", "/data/adb/ksud debug info 2>/dev/null || true"], capture_output=True, text=True).stdout
    if ksu_info.strip():
        report_lines.append("=" * 40 + " KSUD DEBUG INFO " + "=" * 40)
        report_lines.append(ksu_info.strip() + "\n")

    report_text = "\n".join(report_lines)
    report_file.write_text(report_text)
    log(f"[✓] Diagnostic report created at: {report_file}")

    # Generate an anonymous shareable paste link (no GitHub account required!)
    log("Uploading anonymous log paste (no account required)...")
    paste_url = None
    try:
        req = urllib.request.Request(
            "https://paste.rs",
            data=report_text.encode("utf-8"),
            headers={"User-Agent": "A21s-KSU-Reporter"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            paste_url = resp.read().decode("utf-8").strip()
        log(f"[✓] Shareable Anonymous Link: {paste_url}")
    except Exception as e:
        log(f"[!] Could not upload to anonymous pastebin ({e}). Local file preserved.")

    # GitHub issue prefill
    snippet = ""
    if ramoops.strip():
        snippet = ramoops.strip()[-1200:]
    elif dmesg.strip():
        snippet = dmesg.strip()[-1200:]

    paste_ref = f"\n- **Online Log Link:** {paste_url}" if paste_url else ""

    issue_title = f"[Issue Report] Device {device_state} on SM-A217F"
    issue_body = f"""### Device Information
- **Device Model:** Samsung Galaxy A21s (`SM-A217F`)
- **Connection Mode:** `{device_state}`
- **ROM:** LineageOS 24.0 (Android 17){paste_ref}

### Problem Description
<!-- Describe your problem: bootloop, root not recognized, app crash, etc. -->

### Kernel Diagnostic Summary
```
{snippet}
```

> 📎 **Full Log Saved:** `{report_file.name}` in your `out/logs/` directory. Please attach it to this issue!
"""
    query = urllib.parse.urlencode({
        "title": issue_title,
        "body": issue_body,
        "labels": "bug"
    })
    issue_url = f"https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?{query}"
    log("[+] Opening pre-filled GitHub issue in your browser...")
    webbrowser.open(issue_url)

    print("\n" + "=" * 65)
    print(" 📋 DIAGNOSTIC REPORT SUMMARY")
    print(f" Local File:  {report_file}")
    if paste_url:
        print(f" Web Link:    {paste_url}  (No GitHub account required)")
    print(f" GitHub Link: {issue_url}")
    print("-" * 65)
    print(" 💡 NO GITHUB ACCOUNT? NO PROBLEM:")
    print(" If you don't have a GitHub account or are not logged in:")
    print(" 1. Copy the Web Link above (or the local .log file).")
    print(" 2. Share it directly in the Telegram group, XDA thread, or Discord!")
    print("=" * 65 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="A21s KernelSU-Next Universal Cross-Platform Build System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python build.py doctor                     # Check OS and installed build tools
  python build.py package                    # Package AnyKernel3 recovery zip portably
  python build.py make-tar                   # Create Odin boot-ksu.tar archive portably
  python build.py report-issue               # Extract device crash logs & open pre-filled issue
  python build.py docker-build               # 1-click build via Docker (Windows / Mac / Linux)
  python build.py docker-build --stock-boot boot.img
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # doctor
    subparsers.add_parser("doctor", help="Inspect host OS and recommended tools")

    # package
    pkg_parser = subparsers.add_parser("package", help="Package AnyKernel3 recovery zip")
    pkg_parser.add_argument("--image", help="Path to compiled kernel Image", default=None)

    # make-tar
    tar_parser = subparsers.add_parser("make-tar", help="Create Odin boot-ksu.tar archive")
    tar_parser.add_argument("--boot-img", help="Path to boot-ksu.img", default=None)

    # docker-build
    docker_parser = subparsers.add_parser("docker-build", help="Build kernel inside Docker container")
    docker_parser.add_argument("--stock-boot", help="Path to stock boot.img to repack", default=None)

    # report-issue
    subparsers.add_parser("report-issue", help="Extract crash/diagnostic logs via ADB and open pre-filled issue")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    if args.command == "doctor":
        cmd_doctor()
    elif args.command == "package":
        cmd_package(args.image)
    elif args.command == "make-tar":
        cmd_make_tar(args.boot_img)
    elif args.command == "docker-build":
        cmd_docker_build(args.stock_boot)
    elif args.command == "report-issue":
        cmd_report_issue()


if __name__ == "__main__":
    main()