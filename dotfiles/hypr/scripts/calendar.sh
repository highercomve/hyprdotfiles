#!/bin/bash

CLASS="org.gnome.Calendar"
TAG="calendar-waybar"

# 1. Check if already running
if hyprctl clients | grep -q "class: $CLASS"; then
    # If it is running, focus it and then close it.
    hyprctl dispatch focuswindow "class:^($CLASS)$"
    hyprctl dispatch killactive
    # The script will then continue to launch a new instance.
    exit 0
fi

# 2. Define path to your command file
# (Using $HOME is safer than ~ in scripts)
CMD_FILE="$HOME/.config/hypr/user_settings/calendar.sh"

# 3. Read the command from the file
# This reads the first non-comment/non-empty line
COMMAND_TO_RUN=$(grep -v '^[[:space:]]*#' "$CMD_FILE" | grep -v '^$' | head -n 1)

# 4. Check if we read anything
if [ -z "$COMMAND_TO_RUN" ]; then
    # Fallback in case the file is empty or missing
    COMMAND_TO_RUN="gnome-calendar"
fi

# 5. Launch the command WITH THE TAG
# We leave $COMMAND_TO_RUN unquoted on purpose.
# This allows the shell to split it into a command and arguments
# (e.g., if it were "gnome-calendar --some-flag").
hyprctl dispatch exec "[tags:$TAG] $COMMAND_TO_RUN"
