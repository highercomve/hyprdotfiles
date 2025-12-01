#!/bin/bash
#    __ __              _    ____   
#   / // /_ _____  ____(_)__/ / /__ 
#  / _  / // / _ \/ __/ / _  / / -_)
# /_//_/\_, / .__/_/ /_/\_,_/_/\__/ 
#      /___/_/                      
# 

SERVICE="hypridle"

print_status() {
    if pgrep -x "$SERVICE" >/dev/null ; then
        printf '%s\n' '{"text": "RUNNING", "class": "active", "tooltip": "Screen locking active\nLeft: Deactivate\nRight: Lock Screen"}'
    else
        printf '%s\n' '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "Screen locking deactivated\nLeft: Activate\nRight: Lock Screen"}'
    fi
}

case "$1" in
    status)
        # Add a tiny delay to avoid race condition on startup
        sleep 0.2
        print_status
        ;;
    toggle)
        if pgrep -x "$SERVICE" >/dev/null ; then
            killall "$SERVICE"
            # Wait for the process to stop
            while pgrep -x "$SERVICE" >/dev/null; do
                sleep 0.1
            done
        else
            "$SERVICE" &
        fi
        # Send signal to waybar to update the module
        pkill -RTMIN+10 waybar
        print_status
        ;;
    *)
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac