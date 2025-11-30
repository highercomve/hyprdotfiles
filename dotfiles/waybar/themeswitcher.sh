#!/bin/bash

# Define paths
WAYBAR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THEMES_DIR="$WAYBAR_DIR/themes"
THEME_SETTING_FILE="$HOME/.config/hypr/user_settings/waybar-theme.sh"

# Check if themes directory exists
if [ ! -d "$THEMES_DIR" ]; then
    echo "Themes directory not found: $THEMES_DIR"
    exit 1
fi

# List themes
THEMES=$(ls -1 "$THEMES_DIR")

# Select theme using rofi
SELECTED_THEME=$(echo "$THEMES" | rofi -dmenu -p "Select Waybar Theme")

# If a theme was selected
if [ -n "$SELECTED_THEME" ]; then
    # Validate selection
    if [ -d "$THEMES_DIR/$SELECTED_THEME" ]; then
        # Update setting file
        mkdir -p "$(dirname "$THEME_SETTING_FILE")"
        echo "$SELECTED_THEME" > "$THEME_SETTING_FILE"
        
        # Restart Waybar
        "$WAYBAR_DIR/launch.sh"
        
        # Notify user (optional, using notify-send if available)
        if command -v notify-send &> /dev/null; then
            notify-send "Waybar Theme" "Switched to $SELECTED_THEME"
        fi
    else
        echo "Invalid theme selected."
        exit 1
    fi
fi
