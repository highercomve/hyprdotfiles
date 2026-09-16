#!/usr/bin/env bash
#
# Runs blueman-applet as the systemd user unit (blueman-applet.service) so it
# restarts if it dies and its exit is logged in `journalctl --user -u
# blueman-applet`. It is also the unit D-Bus activates for org.blueman.Applet,
# so there is never a second, unmanaged copy.
#
# Usage: blueman-applet.sh [start|stop|toggle]   (default: start)

UNIT=blueman-applet.service
DROPIN_SRC="$HOME/.config/hypr/systemd/blueman-applet.service.d/restart.conf"
DROPIN_DIR="$HOME/.config/systemd/user/$UNIT.d"

install_dropin() {
    [[ -f "$DROPIN_SRC" ]] || return 0
    if ! cmp -s "$DROPIN_SRC" "$DROPIN_DIR/restart.conf"; then
        mkdir -p "$DROPIN_DIR"
        cp "$DROPIN_SRC" "$DROPIN_DIR/restart.conf"
        systemctl --user daemon-reload
    fi
}

# A copy started outside systemd (older autostart, manual launch) would own
# org.blueman.Applet and make the unit fail to start.
stop_unmanaged() {
    local main
    main=$(systemctl --user show -p MainPID --value "$UNIT")
    for pid in $(pgrep -f '^/usr/bin/python[0-9.]* /usr/bin/blueman-applet'); do
        [[ "$pid" != "$main" ]] && kill "$pid" 2>/dev/null
    done
}

case "${1:-start}" in
stop)
    systemctl --user stop "$UNIT"
    ;;
toggle)
    if systemctl --user is-active -q "$UNIT"; then
        systemctl --user stop "$UNIT"
    else
        install_dropin
        stop_unmanaged
        systemctl --user start "$UNIT"
    fi
    ;;
*)
    install_dropin
    systemctl --user is-active -q "$UNIT" || { stop_unmanaged; systemctl --user reset-failed "$UNIT" 2>/dev/null; systemctl --user start "$UNIT"; }
    ;;
esac
