#!/usr/bin/env bash

# Launch Steam Big Picture inside the seat1 session.
#
# Steam is single-instance per user: "steam steam://open/bigpicture" only IPCs
# an already-running Steam, so if Steam is open in the local session, Big
# Picture would pop up THERE. Shut down any Steam running in another session
# first, then start it here.

log() { logger -t sunshine-seat1 "steam: $*"; }

our_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"

foreign_steam_running() {
    local pid sig
    for pid in $(pgrep -x steam); do
        sig="$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null |
            sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')"
        [ "$sig" != "$our_sig" ] && return 0
    done
    return 1
}

if foreign_steam_running; then
    log "Steam is running in another session, shutting it down"
    # Reaches the local user via the shared per-user DBus/notification daemon.
    notify-send "Sunshine seat1" "Closing local Steam — a remote stream is taking it over" || true
    steam -shutdown >/dev/null 2>&1
    for _ in $(seq 1 30); do
        pgrep -x steam >/dev/null || break
        sleep 1
    done
    if foreign_steam_running; then
        log "Steam did not shut down in time, aborting launch"
        exit 1
    fi
fi

log "starting Steam Big Picture in the seat1 session"
exec steam -bigpicture
