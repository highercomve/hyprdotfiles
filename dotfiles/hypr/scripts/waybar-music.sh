#!/bin/bash

# Kill any existing waybar-music processes
pkill -x waybar-music || true

# Start a new waybar-music process with the specified arguments in the background
RETRY_COUNT=0
MAX_RETRIES=5
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # waybar-music --position --autofocus --scroll-width 50 --replace &
    waybar-music listen &
    PID=$!

    # Give the process a moment to establish itself or exit if it failed
    sleep 0.5

    # Check if the process is still running
    if ps -p $PID >/dev/null; then
        # Successfully started and is still running
        break
    else
        # Process with $PID is not running, meaning it likely failed to start or exited quickly.
        RETRY_COUNT=$((RETRY_COUNT + 1))
        # Add a short delay before retrying, unless it's the last attempt
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            sleep 1
        fi
    fi
done
