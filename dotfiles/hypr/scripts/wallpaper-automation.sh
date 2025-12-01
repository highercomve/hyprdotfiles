#!/usr/bin/env bash
#     _         _         __        ______
#    / \  _   _| |_ ___   \ \      / /  _ \
#   / _ \| | | | __/ _ \   \ \ /\ / /| |_) |
#  / ___ \ |_| | || (_) |   \ V  V / |  __/
# /_/   \_\__,_|\__\___/     \_/\_/  |_|
#

cache_folder="$HOME/.config/.cache/hyprland-dotfiles"
# Ensure the cache folder exists
mkdir -p "$cache_folder"

LOCK_FILE="$cache_folder/wallpaper-automation"      # Acts as a general toggle state indicator
PROCESS_IDENTIFIER="hypr_wallpaper_automation_loop" # Unique identifier for the background process

# --- Handle 'sec' variable with a default of 60 ---
wallpaper_settings_source="$HOME/.config/hypr/user_settings/wallpaper-automation.sh"
sec_val=""
if [ -f "$wallpaper_settings_source" ]; then
    sec_val=$(cat "$wallpaper_settings_source")
fi

# Default to 60 if empty, not a number, or less than 1
if ! [[ "$sec_val" =~ ^[0-9]+$ ]] || [ -z "$sec_val" ] || [ "$sec_val" -lt 1 ]; then
    sec_val=60
fi

# --- Main Toggle Logic ---
if [ ! -f "$LOCK_FILE" ]; then
    # Automation is currently OFF (lock file does not exist) - START it

    # First, ensure no old instances are running, even if the lock file was missing (stale state)
    pids_to_kill=$(pgrep -f "$PROCESS_IDENTIFIER")
    if [ -n "$pids_to_kill" ]; then
        echo ":: Found stale background processes: $pids_to_kill. Killing them to ensure single instance."
        # shellcheck disable=SC2086
        kill $pids_to_kill 2>/dev/null
        sleep 0.5 # Give processes a moment to terminate
    fi

    touch "$LOCK_FILE" # Create the lock file to indicate automation is ON
    echo ":: Starting wallpaper automation script"

    # Launch the automation loop in the background.wa
    # We use 'exec -a' inside `bash -c` to set a distinct process name for easy identification with pgrep.
    # This ensures only one such process runs and can be accurately targeted for stopping.
    bash -c "exec -a \"$PROCESS_IDENTIFIER\" bash -c 'while true; do waypaper --random; echo \":: Next wallpaper in $sec_val seconds...\"; sleep $sec_val; done'" &
    NEW_PID=$! # Get the PID of the newly started background process

    notify-send "Wallpaper automation process started" "Wallpaper will be changed every $sec_val seconds."
    echo ":: Wallpaper automation started with PID $NEW_PID, changing every $sec_val seconds."
else
    # Automation is currently ON (lock file exists) - STOP it

    rm "$LOCK_FILE" # Remove the lock file to indicate automation is OFF

    STOPPED_PIDS=""
    # Find and kill the background process using its unique identifier
    pids_to_kill=$(pgrep -f "$PROCESS_IDENTIFIER")

    if [ -n "$pids_to_kill" ]; then
        echo ":: Found and killing wallpaper automation processes: $pids_to_kill"
        # shellcheck disable=SC2086
        kill $pids_to_kill 2>/dev/null
        STOPPED_PIDS="$pids_to_kill"
    else
        echo ":: No wallpaper automation process with identifier '$PROCESS_IDENTIFIER' found to stop."
    fi

    notify-send "Wallpaper automation process stopped." "Wallpaper changes have been paused."
    echo ":: Wallpaper automation script process $STOPPED_PIDS stopped."
fi
