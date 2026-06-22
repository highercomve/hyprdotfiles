#!/usr/bin/env bash

# Enable/disable suspend-on-monitor-off by starting/stopping the
# monitor-off-suspend listener. Mirrors hypridle.sh's status/toggle contract
# so the ags ToolsWidget can poll and toggle it.

LISTENER="monitor-off-suspend"
LISTENERS_SH="$HOME/.config/hypr/scripts/listeners.sh"
SCRIPT_PATH="$HOME/.config/hypr/scripts/listeners/$LISTENER.sh"

is_running() { pgrep -f "$SCRIPT_PATH" >/dev/null; }

print_status() {
    if is_running; then
        printf '%s\n' '{"text": "ON", "class": "active", "tooltip": "Suspend on monitor off: ON\nClick to disable"}'
    else
        printf '%s\n' '{"text": "OFF", "class": "notactive", "tooltip": "Suspend on monitor off: OFF\nClick to enable"}'
    fi
}

case "$1" in
    status)
        print_status
        ;;
    toggle)
        if is_running; then
            "$LISTENERS_SH" --stop "$LISTENER" >/dev/null 2>&1
        else
            "$LISTENERS_SH" --start "$LISTENER" >/dev/null 2>&1
        fi
        print_status
        ;;
    *)
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac
