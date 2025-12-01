#!/bin/bash
# Theme Switcher for Waybar, SwayNC, and Rofi

CONFIG_FILE="$HOME/.config/themes/config.json"

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "jq is not installed. Please install it to use the theme switcher."
    else
        echo "Error: jq is not installed. Please install it to use the theme switcher."
    fi
    exit 1
fi

# Get available theme names from the JSON config
# Assuming dotfiles/themes is symlinked to ~/.config/themes
options=$(jq -r '.themes | keys | .[]' "$CONFIG_FILE")

# Rofi dmenu
selected=$(echo -e "$options" | rofi -config ~/.config/rofi/config-compact.rasi -dmenu -p "Select Theme")

if [ -z "$selected" ]; then
    exit 0
fi

# Read theme configuration from JSON
waybar_theme=$(jq -r ".themes.\"$selected\".waybar" "$CONFIG_FILE")
swaync_theme=$(jq -r ".themes.\"$selected\".swaync" "$CONFIG_FILE")
rofi_theme=$(jq -r ".themes.\"$selected\".rofi" "$CONFIG_FILE")

# Update Waybar
# Assuming ~/.config/waybar is where the dotfiles/waybar is linked or copied
# We link the current folder to the theme folder
if [ -d "$HOME/.config/waybar/themes/$waybar_theme" ]; then
    ln -sfn "$HOME/.config/waybar/themes/$waybar_theme" "$HOME/.config/waybar/current"
    # Restart Waybar
    if [ -f "$HOME/.config/waybar/launch.sh" ]; then
        "$HOME/.config/waybar/launch.sh" &
    else
        killall waybar
        waybar &
    fi
else
    echo "Waybar theme $waybar_theme not found"
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "Waybar theme $waybar_theme not found"
    fi
fi

# Update SwayNC
if [ -d "$HOME/.config/swaync/themes/$swaync_theme" ]; then
    ln -sfn "$HOME/.config/swaync/themes/$swaync_theme" "$HOME/.config/swaync/current"
    # Reload SwayNC
    swaync-client -R
    swaync-client -rs
else
    echo "SwayNC theme $swaync_theme not found"
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "SwayNC theme $swaync_theme not found"
    fi
fi

# Update Rofi
if [ -f "$HOME/.config/rofi/themes/$rofi_theme" ]; then
    ln -sf "$HOME/.config/rofi/themes/$rofi_theme" "$HOME/.config/rofi/current.rasi"
else
    echo "Rofi theme $rofi_theme not found"
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "Rofi theme $rofi_theme not found"
    fi
fi

# Notify
if command -v notify-send &>/dev/null; then
    notify-send "Theme Switched" "Applied $selected theme"
fi
