#!/system/bin/sh
# ==============================================================================
# KernelSU-Next Automated Boot Crash & Issue Reporter
# Target: Samsung Galaxy A21s (SM-A217F)
# Runs as root on boot_completed via KernelSU (/data/adb/service.d/)
# ==============================================================================

# Wait 5 seconds for userland & UI to stabilize
sleep 5

# Check if a persistent kernel crash/panic occurred from prior boot
if [ -f /sys/fs/pstore/dmesg-ramoops-0 ]; then
    LOG_DIR="/sdcard/Download"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="${LOG_DIR}/ksu_crash_${TIMESTAMP}.log"

    mkdir -p "${LOG_DIR}" 2>/dev/null
    cat /sys/fs/pstore/dmesg-ramoops-0 > "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"

    # Extract panic / fault signature
    PANIC_TRACE=$(grep -E -m 3 "Kernel panic|Unable to handle|irq-160|tzasc|Call trace" "${LOG_FILE}" | head -n 2)
    
    # URL encode parameters
    TITLE="[Crash+Report]+Kernel+Panic+detected+on+SM-A217F"
    BODY="###+Crash+Detected%0A%0AA+kernel+crash+was+preserved+in+pstore+after+reboot.%0A%0A**Panic+Signature:**%0A%60%60%60%0A${PANIC_TRACE}%0A%60%60%60%0A%0A%3E+Full+crash+log+saved+to:+%60Download/ksu_crash_${TIMESTAMP}.log%60.+Please+drag-and-drop+it+into+this+issue!"

    ISSUE_URL="https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?title=${TITLE}&body=${BODY}&labels=bug"

    # Launch browser on Android with pre-filled issue
    am start -a android.intent.action.VIEW -d "${ISSUE_URL}" >/dev/null 2>&1 || true
fi
