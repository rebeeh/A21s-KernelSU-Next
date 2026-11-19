---
name: Bug report
about: Create a report to help us improve A21s KernelSU-Next
title: '[BUG] '
labels: bug
assignees: ''

---

**Device Information:**
- Device Model: [e.g. SM-A217F, SM-A217M]
- LineageOS Build Date / Version: [e.g. LineageOS 24 (2026-11-17)]
- KernelSU-Next Version: [e.g. v3.4.0-legacy]
- KernelSU-Next Manager Version: [e.g. v3.4.2 (33355-5)]

**Describe the Bug:**
A clear and concise description of what the bug is.

**To Reproduce:**
Steps to reproduce the behavior:
1. Boot into...
2. Open app...
3. See error...

**Expected Behavior:**
A clear and concise description of what you expected to happen.

**Logs (MANDATORY):**
Please attach the relevant log file:
- Bootloop / Panic: `adb shell cat /sys/fs/pstore/dmesg-ramoops-0`
- Runtime issue: `adb shell dmesg`
- App error: `adb logcat -d`

*(Drag and drop log files here)*
