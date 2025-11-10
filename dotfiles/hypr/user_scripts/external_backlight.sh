#!/bin/bash

# This script controls the backlight of an external monitor.
# Usage: ./external_backlight.sh [up|down|value]

# Device name for the external monitor's backlight.
# You can find the device name by running `brightnessctl --list`.
# It might be something like 'ddcutil_bus2'.
DEVICE="ddcutil_bus2"

# Step size for increasing/decreasing brightness
STEP=5

# Get the current brightness
get_brightness() {
    brightnessctl --device=$DEVICE get
}

# Get the maximum brightness
get_max_brightness() {
    brightnessctl --device=$DEVICE max
}

# Set the brightness
set_brightness() {
    brightnessctl --device=$DEVICE set "$1"
}

# Main logic
case "$1" in
up)
    brightnessctl --device=$DEVICE set "+${STEP}%"
    ;;
down)
    brightnessctl --device=$DEVICE set "${STEP}%-"
    ;;
*)
    # Check if the argument is a number (percentage)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        set_brightness "$1%"
    else
        echo "Usage: $0 {up|down|<percentage>}"
        exit 1
    fi
    ;;
esac

# Get the new brightness to show a notification (optional)
NEW_BRIGHTNESS=$(get_brightness)
notify-send "Brightness" "External monitor brightness: $NEW_BRIGHTNESS" -h int:value:$NEW_BRIGHTNESS -h string:x-canonical-private-synchronous:brightness
