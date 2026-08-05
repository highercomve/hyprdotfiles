#!/usr/bin/env bash

# portal-rebind.sh — make sure xdg-desktop-portal-hyprland is talking to THIS
# Hyprland instance. Run from conf/autostart.lua right after the activation
# environment is imported.
#
# xdph is a single per-user systemd service, but this machine can have two
# concurrent Hyprland instances: the seat0 desktop and the headless
# sunshine-seat1 streaming session. xdph inherits HYPRLAND_INSTANCE_SIGNATURE
# from the systemd --user environment at dbus-activation time and keeps that
# wayland connection for its entire life — it never re-attaches. So whichever
# compositor happened to own the shared environment when the first portal
# request arrived wins, permanently.
#
# At boot that used to be seat1 (it starts ~14s before the GDM login
# completes), and when its short-lived compositor exited, xdph sat polling a
# hung-up socket at ~150% CPU until it was manually restarted.
#
# sunshine-seat1/bin/systemctl now stops that session from touching the shared
# environment at all, so this script should normally find nothing to do. It
# stays as the safety net for anything else that can win the race — a portal
# activated before this session came up, a bypassed shim, a manually launched
# second compositor.

set -u

UNIT="xdg-desktop-portal-hyprland.service"
FRONTEND="xdg-desktop-portal.service"

log() { logger -t portal-rebind "$*"; }

# conf/autostart.lua imports the environment too, but hl.exec_cmd is
# asynchronous — don't depend on that having landed before this runs.
# Idempotent, so doing it twice costs nothing.
dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

ours="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [ -z "$ours" ]; then
    log "HYPRLAND_INSTANCE_SIGNATURE unset — not running under Hyprland, nothing to do"
    exit 0
fi

pid=$(systemctl --user show -p MainPID --value "$UNIT" 2>/dev/null)
if [ -z "$pid" ] || [ "$pid" = 0 ]; then
    # Deliberately do NOT start it here: dbus will activate it on first use,
    # now with the correct environment. Launching it eagerly is what caused
    # the old double-launch race + segfault (see conf/autostart.lua).
    log "xdph not running — leaving it to dbus activation"
    exit 0
fi

bound=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null |
        sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')

if [ "$bound" = "$ours" ]; then
    log "xdph ($pid) already bound to this session"
    exit 0
fi

log "xdph ($pid) bound to '${bound:-<none>}', this session is '$ours' — rebinding"
systemctl --user restart "$UNIT"
# The frontend caches its backend proxies; nudge it so it re-resolves against
# the freshly restarted implementation.
systemctl --user try-restart "$FRONTEND"
