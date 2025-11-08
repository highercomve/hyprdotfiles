#!/usr/bin/env bash
#                    __
#  _    _____ ___ __/ /  ___ _____
# | |/|/ / _ `/ // / _ \/ _ `/ __/
# |__,__/\_,_/\_, /_.__/\_,_/_/
#            /___/
#

# -----------------------------------------------------
# Prevent duplicate launches: only the first parallel
# invocation proceeds; all others exit immediately.
# -----------------------------------------------------

exec 200>/tmp/waybar-launch.lock
flock -n 200 || exit 0

# -----------------------------------------------------
# Quit all running waybar instances
# -----------------------------------------------------

killall waybar || true
pkill waybar || true
sleep 0.5

# -----------------------------------------------------
# Default theme: /THEMEFOLDER;/VARIATION
# -----------------------------------------------------

default_theme="light"
themestyle=$default_theme
# -----------------------------------------------------
# Get current theme information from ~/.config/hypr/user_settings/waybar-theme.sh
# -----------------------------------------------------

if [ -f ~/.config/hypr/user_settings/waybar-theme.sh ]; then
    themestyle=$(cat ~/.config/hypr/user_settings/waybar-theme.sh)
else
    touch ~/.config/hypr/user_settings/waybar-theme.sh
    echo "$default_theme" >~/.config/hypr/user_settings/waybar-theme.sh
    themestyle=$default_theme
fi

if [ ! -f ~/.config/waybar/themes/$themestyle/style.css ]; then
    themestyle=$default_theme
fi

# -----------------------------------------------------
# Loading the configuration
# -----------------------------------------------------

config_file="config"
style_file="style.css"

# Standard files can be overwritten with an existing config-custom or style-custom.css
if [ -f ~/.config/waybar/themes/$themestyle/config-custom ]; then
    config_file="config-custom"
fi
if [ -f ~/.config/waybar/themes/$themestyle/style-custom.css ]; then
    style_file="style-custom.css"
fi

# Check if waybar-disabled file exists
if [ ! -f $HOME/.config/hypr/user_settings/waybar-disabled ]; then
    HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
    HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" waybar -c ~/.config/waybar/themes/$themestyle/$config_file -s ~/.config/waybar/themes/$themestyle/$style_file &
    # env GTK_DEBUG=interactive waybar -c ~/.config/waybar/themes/$themestyle/$config_file -s ~/.config/waybar/themes/$themestyle/$style_file &
else
    echo ":: Waybar disabled"
fi

# Explicitly release the lock (optional) -> flock releases on exit
flock -u 200
exec 200>&-
