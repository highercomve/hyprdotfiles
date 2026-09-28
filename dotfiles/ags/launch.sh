#!/bin/bash

# Kill any running instances
pkill statusbar
pkill gjs
pkill swaync

HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r --arg sig "${HYPRLAND_INSTANCE_SIGNATURE:-}" --arg wl "${WAYLAND_DISPLAY:-}" '
    # Sunshine runs a second (headless seat1) Hyprland, so .[0] may be the wrong
    # one: keep our inherited instance, else the one owning our wayland socket.
    (map(select(.instance == $sig)) + map(select(.wl_socket == $wl)) + .)[0].instance')
HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" ~/.config/ags/statusbar &
