#!/usr/bin/env bash
#
if [[ "$1" == "stop" ]]; then
    killall blueman-applet
    exit 0
fi
if [[ "$1" == "toggle" ]]; then
    if pgrep -x "blueman-applet" >/dev/null; then # Uses exit code of pgrep (0 if running, 1 if not)
        echo "Running"
        killall blueman-applet
    else
        echo "Stopped"
        blueman-applet &
    fi
fi

blueman-applet &
