#!/usr/bin/env bash

# Start/stop/toggle the isolated seat1 streaming session.
# Mirrors the status/toggle contract of hypridle.sh & co. so a statusbar
# button can poll it. Passwordless via polkit rule (installed by install.sh).

UNIT="sunshine-seat1.service"

is_active() { systemctl is-active --quiet "$UNIT"; }

case "${1:-toggle}" in
status)
    if is_active; then
        echo '{"text": "", "alt": "active", "class": "active", "tooltip": "Remote stream session running"}'
    else
        echo '{"text": "", "alt": "notactive", "class": "notactive", "tooltip": "Remote stream session stopped"}'
    fi
    ;;
start)
    systemctl start "$UNIT" && notify-send "Sunshine seat1" "Remote stream session started (port 48989)"
    ;;
stop)
    systemctl stop "$UNIT" && notify-send "Sunshine seat1" "Remote stream session stopped"
    ;;
toggle)
    if is_active; then
        "$0" stop
    else
        "$0" start
    fi
    ;;
*)
    echo "Usage: $0 [status|start|stop|toggle]" >&2
    exit 1
    ;;
esac
