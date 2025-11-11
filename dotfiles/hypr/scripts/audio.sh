#!/bin/bash

CLASS="org.pulseaudio.pavucontrol"

# 1. Check if already running
if hyprctl clients | grep -q "class: $CLASS"; then
    # If it is running, focus it and then close it.
    hyprctl dispatch focuswindow "class:^($CLASS)$"
    hyprctl dispatch killactive
    # The script will then continue to launch a new instance.
    exit 0
fi

hyprctl dispatch exec -- pavucontrol
