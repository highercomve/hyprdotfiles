#!/usr/bin/env bash
#                                      __
#   ___ ____ ___ _  ___ __ _  ___  ___/ /__
#  / _ `/ _ `/  ' \/ -_)  ' \/ _ \/ _  / -_)
#  \_, /\_,_/_/_/_/\__/_/_/_/\___/\_,_/\__/
# /___/
#

cache_folder="$HOME/.cache/hyprland-dotfiles"
gamemode_monitor="$HOME/.config/hypr/conf/monitors/gamemode.conf"

if [ -f "$HOME"/.config/hypr/user_settings/gamemode-enabled ]; then
    if [ -f "$cache_folder"/last_monitor.conf ]; then
        cat "$cache_folder"/last_monitor.conf >"$HOME"/.config/hypr/conf/monitor.conf
        rm "$cache_folder"/last_monitor.conf
    fi
    if [ -f "$cache_folder"/restart-wpauto ]; then
        rm "$cache_folder"/restart-wpauto
        "$HOME"/.config/hypr/scripts/wallpaper-automation.sh &
    fi
    hyprctl reload
    rm "$HOME"/.config/hypr/user_settings/gamemode-enabled
    notify-send "Gamemode deactivated" "Animations and blur enabled"
else
    if [ -f "$gamemode_monitor" ]; then
        cat "$HOME"/.config/hypr/conf/monitor.conf >"$cache_folder"/last_monitor.conf
        echo "source = $gamemode_monitor" >"$HOME"/.config/hypr/conf/monitor.conf
    fi
    if [ -f "$cache_folder"/wallpaper-automation ]; then
        touch "$cache_folder"/restart-wpauto
        "$HOME"/.config/hypr/scripts/wallpaper-automation.sh
    fi
    hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:shadow:enabled 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0;\
    keyword general:gaps_out 0;\
    keyword general:border_size 1;\
    keyword decoration:rounding 0"
    touch "$HOME"/.config/hypr/user_settings/gamemode-enabled
    notify-send "Gamemode activated" "Animations and blur disabled"
fi
