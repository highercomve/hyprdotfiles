#!/bin/bash
clear
aur_helper="$(cat ~/.config/hyprconfig/dotfiles/hypr/user_settings/aur.sh)"
figlet -f smslant "Cleanup"
echo
$aur_helper -Scc
