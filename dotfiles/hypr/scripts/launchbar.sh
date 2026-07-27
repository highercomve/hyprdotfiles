#!/bin/bash

set -ex

STATUSBAR_SCRIPT="$HOME/.config/hypr/user_settings/statusbar.sh"
STATUS_BAR_TYPE="waybar"

if [ -f "$STATUSBAR_SCRIPT" ]; then
    if grep -q "quickshell" "$STATUSBAR_SCRIPT"; then
        STATUS_BAR_TYPE="quickshell"
    elif grep -q "ags" "$STATUSBAR_SCRIPT"; then
        STATUS_BAR_TYPE="ags"
    fi
fi

LAUNCH_SCRIPT="$HOME/.config/$STATUS_BAR_TYPE/launch.sh"

# quickshell configs are named subdirs of ~/.config/quickshell
if [ "$STATUS_BAR_TYPE" = "quickshell" ]; then
    LAUNCH_SCRIPT="$HOME/.config/quickshell/hyprconfig/launch.sh"
fi

if [ -f "$LAUNCH_SCRIPT" ]; then
    echo "launching $STATUS_BAR_TYPE"
    "$LAUNCH_SCRIPT" &
fi
