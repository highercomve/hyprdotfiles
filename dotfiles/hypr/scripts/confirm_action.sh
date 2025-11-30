#!/bin/bash
# Usage: confirm_action.sh "Action Command" "Prompt Text"

ACTION="$1"
PROMPT="$2"

if [ -z "$PROMPT" ]; then
    PROMPT="Are you sure?"
fi

# Rofi confirmation dialog
# We use a small window with 2 lines for Yes/No
CONFIRM=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "$PROMPT" -config /home/projects/personal/hyprconfig/dotfiles/rofi/config-short.rasi)

if [ "$CONFIRM" == "Yes" ]; then
    eval "$ACTION"
fi
