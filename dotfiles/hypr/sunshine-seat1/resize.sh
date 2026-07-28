#!/usr/bin/env bash

# global_prep_cmd of the seat1 Sunshine: match the virtual display to the
# Moonlight client's requested resolution/FPS before the app launches.

W="${SUNSHINE_CLIENT_WIDTH:-1920}"
H="${SUNSHINE_CLIENT_HEIGHT:-1080}"
FPS="${SUNSHINE_CLIENT_FPS:-60}"

hyprctl keyword monitor "HEADLESS-1,${W}x${H}@${FPS},0x0,1"
logger -t sunshine-seat1 "virtual display set to ${W}x${H}@${FPS}"
