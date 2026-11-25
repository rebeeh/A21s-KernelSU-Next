---
name: Bug report
about: Report a crash, bootloop, build issue, or regression on A21s-KernelSU-Next
title: '[BUG] '
labels: bug
assignees: ''

---

**Device Information:**
- Device Model: [e.g. `SM-A217F`, `SM-A217M`, `SM-A217N`]
- ROM / LineageOS Build: [e.g. `LineageOS 24 (Android 17)`]
- Kernel Release / Build: [e.g. `v1.2.0` / output of `uname -r`]
- KernelSU-Next Manager & Driver: [e.g. `v3.4.2 (33355-5)` / `SuSFS v1.5.5 (NON-GKI)`]

**Describe the Bug:**
A clear and concise description of what happened.

**To Reproduce:**
Steps to reproduce the behavior:
1. Flash / boot...
2. Open app / run command...
3. See error...

**Expected Behavior:**
What you expected to happen.

**Logs (MANDATORY — tip: run `python3 build.py report-issue` for 1-click capture):**
Attach the relevant log archive or paste link (`paste.rs` / `out/logs/issue_report_*.log`):
- Bootloop / Panic (`Recovery`): `adb shell cat /sys/fs/pstore/dmesg-ramoops-0`
- Runtime kernel log: `adb shell su -c dmesg`
- Android framework log: `adb logcat -d`
- KernelSU / SUSFS status: `adb shell su -c "/data/adb/ksud -V && /data/adb/ksu/bin/ksu_susfs show version"`

*(Scrub sensitive tokens, Wi-Fi info, or `keybox.xml` secrets before uploading logs.)*
