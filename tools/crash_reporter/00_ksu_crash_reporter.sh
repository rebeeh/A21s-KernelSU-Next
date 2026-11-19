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
    
    # Upload to anonymous paste service (zero account required)
    PASTE_URL=""
    if [ -x /system/bin/curl ]; then
        PASTE_URL=$(cat "${LOG_FILE}" | /system/bin/curl -s -X POST --data-binary @- https://paste.rs 2>/dev/null || true)
    fi

    # Post an Android system notification (persists even if browser is closed)
    if [ -n "${PASTE_URL}" ]; then
        cmd notification post -S bigtext -t "Kernel Crash Detected" "ksu_crash" \
            "Crash log saved to Download/ksu_crash_${TIMESTAMP}.log. Anonymous link: ${PASTE_URL}. Tap to report." >/dev/null 2>&1 || true
    else
        cmd notification post -S bigtext -t "Kernel Crash Detected" "ksu_crash" \
            "Crash log saved to Download/ksu_crash_${TIMESTAMP}.log. Tap to report." >/dev/null 2>&1 || true
    fi

    # URL encode parameters for GitHub (if user has GitHub)
    TITLE="[Crash+Report]+Kernel+Panic+detected+on+SM-A217F"
    BODY="###+Crash+Detected%0A%0AA+kernel+crash+was+preserved+in+pstore+after+reboot.%0A%0A**Panic+Signature:**%0A%60%60%60%0A${PANIC_TRACE}%0A%60%60%60%0A%0A**Online+Log+(No+Account+Needed):**+${PASTE_URL}%0A%0A%3E+Full+crash+log+also+saved+to:+%60Download/ksu_crash_${TIMESTAMP}.log%60"

    ISSUE_URL="https://github.com/rebeeh/A21s-KernelSU-Next/issues/new?title=${TITLE}&body=${BODY}&labels=bug"

    # Launch browser with pre-filled issue (GitHub preserves return_to if login required)
    am start -a android.intent.action.VIEW -d "${ISSUE_URL}" >/dev/null 2>&1 || true
fi
