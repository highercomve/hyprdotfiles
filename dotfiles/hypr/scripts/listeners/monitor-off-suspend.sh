#!/usr/bin/env bash

# Suspends the machine when the monitor is powered off.
#
# DisplayPort monitors drop the link when switched off, which makes Hyprland
# emit a "monitorremoved" event on its event socket. When that happens and no
# real monitor is connected anymore after a grace period, the system suspends.
# Turning the monitor back on within the grace period cancels the suspend.
#
# Logs go to the systemd journal: journalctl -t monitor-off-suspend

GRACE_SECONDS=1     # monitor must stay disconnected this long before suspending
COOLDOWN_SECONDS=30 # ignore events right after triggering a suspend (resume noise)

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

log() { logger -t monitor-off-suspend "$*"; }

# Hyprland creates a headless FALLBACK output when the last real monitor
# disappears, so it must be excluded from the count.
active_monitor_count() {
    hyprctl monitors -j 2>/dev/null |
        jq '[.[] | select(.name != "FALLBACK" and (.disabled | not))] | length'
}

if [ ! -S "$SOCKET" ]; then
    log "Hyprland event socket not found: $SOCKET"
    exit 1
fi

log "Started, watching for monitor disconnects"

socat -U - "UNIX-CONNECT:$SOCKET" | while read -r line; do
    case "$line" in
    monitorremoved'>>'*)
        name="${line#monitorremoved>>}"
        log "Monitor removed: $name — checking again in ${GRACE_SECONDS}s"
        sleep "$GRACE_SECONDS"
        count="$(active_monitor_count)"
        if [ "${count:-1}" -eq 0 ]; then
            log "No monitors connected, suspending"
            systemctl suspend
            sleep "$COOLDOWN_SECONDS"
        else
            log "$count monitor(s) still connected, not suspending"
        fi
        ;;
    esac
done
