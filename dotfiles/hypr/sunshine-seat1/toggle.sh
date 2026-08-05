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
autostart)
    # Called from conf/autostart.lua at login. The unit is deliberately not
    # enabled at boot — a logind session that already exists when the greeter
    # runs makes GDM answer the login with "there is already a session
    # running" (see sunshine-seat1.service). Starting it from the desktop
    # session instead keeps the greeter unaware of it.
    #
    # Silent no-op when the unit isn't installed (install.sh never run) or
    # when parked with user_settings/sunshine-seat1-disabled.
    [ -f /etc/systemd/system/"$UNIT" ] || exit 0
    [ -f "$HOME/.config/hypr/user_settings/sunshine-seat1-disabled" ] && exit 0
    is_active && exit 0
    exec "$0" start
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
