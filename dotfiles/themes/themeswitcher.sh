#!/bin/bash
# Theme Switcher for Waybar, SwayNC, Rofi, Wlogout, and Waypaper

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

# Add "Use wallpaper color scheme" option
options="Use wallpaper color scheme\n$options"

# Rofi dmenu
selected=$(echo -e "$options" | rofi -config ~/.config/rofi/config-compact.rasi -dmenu -p "Select Theme")

if [ -z "$selected" ]; then
    exit 0
fi

if [ "$selected" == "Use wallpaper color scheme" ]; then
    # Run personalize script
    SCRIPT_DIR=$(dirname "$0")
    if [ -f "$SCRIPT_DIR/personalize.sh" ]; then
        rofi -e "Generating theme for background... Please wait." -config ~/.config/rofi/config-compact.rasi &
        ROFI_PID=$!
        "$SCRIPT_DIR/personalize.sh"
        kill $ROFI_PID 2>/dev/null
        # Reload config to ensure Personalize theme is available (though it should be already if added by script)
        selected="Personalize"
    else
        echo "Error: personalize.sh not found in $SCRIPT_DIR"
        if command -v notify-send &>/dev/null; then
            notify-send "Error" "personalize.sh not found"
        fi
        exit 1
    fi
fi

# Read theme configuration from JSON
waybar_theme=$(jq -r ".themes.\"$selected\".waybar" "$CONFIG_FILE")
swaync_theme=$(jq -r ".themes.\"$selected\".swaync" "$CONFIG_FILE")
rofi_theme=$(jq -r ".themes.\"$selected\".rofi" "$CONFIG_FILE")
wlogout_theme=$(jq -r ".themes.\"$selected\".wlogout" "$CONFIG_FILE")
waypaper_theme=$(jq -r ".themes.\"$selected\".waypaper" "$CONFIG_FILE")

# Update Waybar
# Assuming ~/.config/waybar is where the dotfiles/waybar is linked or copied
# We link the current folder to the theme folder
if [ -d "$HOME/.config/waybar/themes/$waybar_theme" ]; then
    ln -sfn "$HOME/.config/waybar/themes/$waybar_theme" "$HOME/.config/waybar/current"
    # Restart Waybar
    if [ -f "$HOME/.config/hypr/scripts/launchbar.sh" ]; then
        "$HOME/.config/hypr/scripts/launchbar.sh" &
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

# Update Wlogout
if [ -d "$HOME/.config/wlogout/themes/$wlogout_theme" ]; then
    ln -sf "$HOME/.config/wlogout/themes/$wlogout_theme/layout" "$HOME/.config/wlogout/layout"
    ln -sf "$HOME/.config/wlogout/themes/$wlogout_theme/style.css" "$HOME/.config/wlogout/style.css"
    ln -sf "$HOME/.config/wlogout/themes/$wlogout_theme/colors.css" "$HOME/.config/wlogout/colors.css"
    ln -sfn "$HOME/.config/wlogout/themes/$wlogout_theme/icons" "$HOME/.config/wlogout/icons"
else
    echo "Wlogout theme $wlogout_theme not found"
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "Wlogout theme $wlogout_theme not found"
    fi
fi

# Update Waypaper
if [ -f "$HOME/.config/waypaper/themes/$waypaper_theme/config.ini" ]; then
    ln -sf "$HOME/.config/waypaper/themes/$waypaper_theme/config.ini" "$HOME/.config/waypaper/config.ini"
else
    echo "Waypaper theme $waypaper_theme not found"
    if command -v notify-send &>/dev/null; then
        notify-send "Error" "Waypaper theme $waypaper_theme not found"
    fi
fi

# Notify
if command -v notify-send &>/dev/null; then
    notify-send "Theme Switched" "Applied $selected theme"
fi
