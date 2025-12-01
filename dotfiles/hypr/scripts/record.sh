#!/bin/bash

# Script to record screen using wf-recorder

# Source user settings
source "$HOME/.config/hypr/user_settings/recording-folder.sh"

# Variables
REC_FILE="recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
PID_FILE="/tmp/record.pid"

# Ensure the recording directory exists
mkdir -p "$REC_DIR"

# Function to start recording
start_recording() {
    if [ -f "$PID_FILE" ]; then
        notify-send "🔴 Recording is already in progress."
        exit 1
    fi

    notify-send "🔴 Recording started"
    # wf-recorder -f "$REC_DIR/$REC_FILE" --pixel-format yuv420p &
    gpu-screen-recorder -w screen -o "$REC_DIR/$REC_FILE" &
    echo $! >"$PID_FILE"
    pkill -RTMIN+12 waybar
}

# Function to start recording a selected area
start_recording_area() {
    if [ -f "$PID_FILE" ]; then
        notify-send "🔴 Recording is already in progress."
        exit 1
    fi

    local pid_picker region

    # freeze screen for region selection
    hyprpicker -r -z &
    pid_picker=$!
    trap 'kill "$pid_picker" 2>/dev/null' EXIT
    sleep 0.1

    # user selects region; kill picker on cancel
    region=$(slurp -b "#00000080" -c "#888888ff" -w 1) || exit 0
    [[ -z "$region" ]] && exit 0

    # unfreeze screen
    kill "$pid_picker" 2>/dev/null
    trap - EXIT

    notify-send "🔴 Recording started"
    gpu-screen-recorder -w region -region "$(echo "$region" | sed 's/\([0-9]*\),\([0-9]*\) \([0-9x]*\)/\3+\1+\2/')" -o "$REC_DIR/$REC_FILE" &
    echo $! >"$PID_FILE"
    pkill -RTMIN+12 waybar
}

# Function to stop recording
stop_recording() {
    if [ ! -f "$PID_FILE" ]; then
        notify-send "No recording in progress."
        exit 1
    fi

    pid=$(cat "$PID_FILE")
    kill "$pid"

    # Wait for wf-recorder to finish writing the file
    while ps -p "$pid" >/dev/null; do
        sleep 0.5
    done

    rm "$PID_FILE"
    pkill -RTMIN+12 waybar
    notify-send "✅ Recording stopped" "The recording has been saved in $REC_DIR"

    # Open the recording directory using the filemanager script
    if ! env HYPRLAND_CLASS="dotfiles-floating" ~/.config/hypr/user_settings/filemanager.sh "$REC_DIR"; then
        notify-send "⚠️ Error opening directory" "Failed to execute file manager script: ~/.config/hypr/user_settings/filemanager.sh"
    fi
}

# Function to toggle recording
toggle_recording() {
    if [ -f "$PID_FILE" ]; then
        stop_recording
    else
        start_recording
    fi
}

# Main logic
case "$1" in
start)
    start_recording
    ;;
area)
    start_recording_area
    ;;
stop)
    stop_recording
    ;;
toggle)
    toggle_recording
    ;;
status)
    if [ -f "$PID_FILE" ]; then
        echo "{\"text\": \"recording\", \"class\": \"recording\", \"tooltip\": \"Stop recording\"}"
    else
        echo "{\"text\": \"default\", \"class\": \"not-recording\", \"tooltip\": \"Start recording\"}"
    fi
    ;;
*)
    echo "Usage: $0 {start|area|stop|toggle|status}"
    exit 1
    ;;
esac
