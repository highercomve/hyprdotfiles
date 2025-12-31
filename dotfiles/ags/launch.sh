#!/bin/bash

# Kill any running instances
pkill statusbar
pkill gjs
pkill swaync

HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" ~/.config/ags/statusbar &
