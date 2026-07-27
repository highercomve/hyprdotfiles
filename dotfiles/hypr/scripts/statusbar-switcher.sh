#!/bin/bash
#   ____  _        _            ____
#  / ___|| |_ __ _| |_ _   _ __| __ ) __ _ _ __
#  \___ \| __/ _` | __/ | | / __|  _ \ / _` | '__|
#   ___) | || (_| | |_| |_| \__ \ |_) | (_| | |
#  |____/ \__\__,_|\__|\|, |___/____/ \__,_|_|
#

# Script to switch between Waybar, AGS and Quickshell

# Configuration
STATUSBAR_FILE="$HOME/.config/hypr/user_settings/statusbar.sh"
ROFI_CONFIG="$HOME/.config/rofi/config-compact.rasi"

# Ensure the settings file exists
if [ ! -f "$STATUSBAR_FILE" ]; then
    mkdir -p "$(dirname "$STATUSBAR_FILE")"
    touch "$STATUSBAR_FILE"
fi

# Options
option_1="Waybar"
option_2="AGS"
option_3="Quickshell"

# Rofi menu
choice=$(echo -e "$option_1\n$option_2\n$option_3" | rofi -dmenu -config "$ROFI_CONFIG" -p "Select Status Bar")
choice=$(echo "$choice" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
if [ -z "$choice" ]; then
    exit 0
fi

pkill gjs
pkill ags
killall waybar
pkill waybar
pkill waybar-music
pkill swaync
qs kill 2>/dev/null
pkill -x qs
pkill -x quickshell

if [ "$choice" == "Waybar" ]; then
    echo "Setting waybar as statusbar"
    echo "waybar" >"$STATUSBAR_FILE"
    notify-send "Status Bar" "Switched to Waybar."
elif [ "$choice" == "AGS" ]; then
    echo "Setting ags as statusbar"
    echo "ags" >"$STATUSBAR_FILE"
    notify-send "Status Bar" "Switched to AGS."
elif [ "$choice" == "Quickshell" ]; then
    echo "Setting quickshell as statusbar"
    echo "quickshell" >"$STATUSBAR_FILE"
    notify-send "Status Bar" "Switched to Quickshell."
fi

# Give it a moment
sleep 0.5

# Launch the selected bar
"$HOME/.config/hypr/scripts/launchbar.sh" &
