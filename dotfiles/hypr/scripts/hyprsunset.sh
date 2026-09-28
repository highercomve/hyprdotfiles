#!/bin/bash

if [ "$1" == "toggle" ]; then
    if pgrep -x "hyprsunset" > /dev/null; then
        pkill hyprsunset
    else
        setsid -f hyprsunset -t 4500 >/dev/null 2>&1
    fi
    exit 0
fi

if [ "$1" == "status" ]; then
    if pgrep -x "hyprsunset" > /dev/null; then
        echo '{"text": "On", "alt": "active", "tooltip": "Hyprsunset is active (4500K)", "class": "active"}'
    else
        echo '{"text": "Off", "alt": "deactivated", "tooltip": "Hyprsunset is off", "class": "notactive"}'
    fi
    exit 0
fi
