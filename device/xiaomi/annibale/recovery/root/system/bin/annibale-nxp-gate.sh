#!/system/bin/sh
# Prepare K90 security services for FBE credential verification.
# Keep Qualcomm default KeyMint/SharedSecret alive for keystore2, while ensuring
# the NXP StrongBox/Weaver chain is stable before TWRP asks for credentials.

LOG=/tmp/recovery.log

log_msg() {
    echo "annibale-nxp-gate: $1" >> "$LOG"
    log -t annibale_nxp_gate "$1" 2>/dev/null || true
}

wait_stable_running() {
    name="$1"
    stable_needed="$2"
    limit="$3"
    stable=0
    i=0
    while [ "$i" -lt "$limit" ]; do
        if [ "$(getprop "init.svc.$name")" = "running" ]; then
            stable=$((stable + 1))
            [ "$stable" -ge "$stable_needed" ] && return 0
        else
            stable=0
            start "$name" 2>/dev/null || true
        fi
        sleep 1
        i=$((i + 1))
    done
    return 1
}

power_on_nxp_ese() {
    log_msg "power on NXP eSE via NFC VEN gpio"

    # annibale dmesg reports: irq 587, ven 546, clkreq 547, dwl -2.
    # Recovery has no /sys/class/nfc/nfc0 nodes, so use the confirmed VEN GPIO.
    echo 546 > /sys/class/gpio/export 2>/dev/null || true
    if [ -d /sys/class/gpio/gpio546 ]; then
        echo out > /sys/class/gpio/gpio546/direction 2>/dev/null || true
        echo 0 > /sys/class/gpio/gpio546/value 2>/dev/null || true
        sleep 0.10
        echo 1 > /sys/class/gpio/gpio546/value 2>/dev/null || true
        sleep 0.80
        log_msg "gpio546 value=$(cat /sys/class/gpio/gpio546/value 2>/dev/null)"
    else
        log_msg "gpio546 sysfs not available"
    fi
}

reset_nxp_chain() {
    stop vendor.weaver_nxp 2>/dev/null || true
    stop vendor.keymint-strongbox 2>/dev/null || true
    stop se_omapi 2>/dev/null || true
    stop vendor.secure_element 2>/dev/null || true
    sleep 1
    power_on_nxp_ese
    start vendor.secure_element 2>/dev/null || true
    sleep 2
    start se_omapi 2>/dev/null || true
    sleep 1
    start vendor.keymint-strongbox 2>/dev/null || true
    sleep 2
    start vendor.weaver_nxp 2>/dev/null || true
}

ese_transport_failed() {
    logcat -b all -d -t 220 2>/dev/null | grep -Eiq         'eSE not powered|secure element not found|isSecureElementPresent: 0|Unknown eSE vendor|Transceive failed|interface reset failed|GetSlots Failed|Failed to retreive slots info|Failed to retrieve slots info|sendData'
}

setprop twrp.annibale.nxp_gate_started 1
setprop twrp.annibale.nxp_gate_error ""
setprop twrp.annibale.weaver_ready 0
setprop twrp.annibale.nxp_gate_attempt 0
log_msg "start balanced Qualcomm+NXP security chain"

# Qualcomm side: keystore2 needs the default KeyMint/SharedSecret services.
start vendor.qseecomd
start vendor.minkdaemon
start qseecom-service
start minkipcbinder-service
start vendor.keymint-qti
start vendor.keymint
start vendor.secretkeeper

# NXP side: lock credential verification uses NXP StrongBox/Weaver on annibale.
# The HAL can be running while the eSE is still off; force VEN high first.
logcat -c 2>/dev/null || true
reset_nxp_chain

if wait_stable_running vendor.qseecomd 1 10; then
    log_msg "vendor.qseecomd running"
else
    log_msg "vendor.qseecomd not stable; continuing"
fi

if wait_stable_running vendor.minkdaemon 1 10; then
    log_msg "vendor.minkdaemon running"
else
    log_msg "vendor.minkdaemon not stable; continuing"
fi

if wait_stable_running vendor.keymint-qti 2 18; then
    log_msg "vendor.keymint-qti running"
else
    log_msg "vendor.keymint-qti not stable; continuing"
fi

if wait_stable_running vendor.secure_element 2 18; then
    log_msg "vendor.secure_element running"
else
    log_msg "vendor.secure_element not stable; continuing"
fi

if wait_stable_running vendor.keymint-strongbox 2 18; then
    log_msg "vendor.keymint-strongbox running"
else
    log_msg "vendor.keymint-strongbox not stable; continuing"
fi

round=0
while [ "$round" -lt 3 ]; do
    i=0
    stable=0
    while [ "$i" -lt 18 ]; do
        setprop twrp.annibale.nxp_gate_attempt "$((round * 18 + i + 1))"
        if [ "$(getprop init.svc.vendor.weaver_nxp)" = "running" ]; then
            stable=$((stable + 1))
        else
            stable=0
            start vendor.weaver_nxp 2>/dev/null || true
        fi

        if [ "$stable" -ge 4 ]; then
            sleep 1
            if ese_transport_failed; then
                log_msg "NXP eSE transport failed after services became stable; retrying"
                setprop twrp.annibale.nxp_gate_error ese_transport_not_ready
                logcat -c 2>/dev/null || true
                reset_nxp_chain
                break
            fi
            setprop twrp.annibale.weaver_ready 1
            setprop twrp.annibale.nxp_gate_error ""
            log_msg "NXP eSE/Weaver transport ready for FBE"
            exit 0
        fi
        sleep 1
        i=$((i + 1))
    done
    round=$((round + 1))
done

if [ "$(getprop init.svc.vendor.weaver_nxp)" != "running" ]; then
    setprop twrp.annibale.nxp_gate_error weaver_nxp_not_stable
    log_msg "vendor.weaver_nxp did not stay running"
else
    setprop twrp.annibale.nxp_gate_error ese_transport_not_ready
    log_msg "NXP eSE/Weaver transport did not become usable"
fi
setprop twrp.annibale.weaver_ready 0
exit 0
