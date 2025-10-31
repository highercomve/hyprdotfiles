#!/usr/bin/env bash
#  ____  _          _ _
# / ___|| |__   ___| | |
# \___ \| '_ \ / _ \ | |
#  ___) | | | |  __/ | |
# |____/|_| |_|\___|_|_|
#

sleep 1

clear
figlet -f smslant "Shell"

echo ":: Please select your preferred shell"
echo
shell=$(gum choose "bash" "Cancel")
# -----------------------------------------------------
# Activate bash
# -----------------------------------------------------
if [[ $shell == "bash" ]]; then

    # Change shell to bash
    while ! chsh -s "$(which bash)"; do
        echo "ERROR: Authentication failed. Please enter the correct password."
        sleep 1
    done
    echo ":: Shell is now bash."

    gum spin --spinner dot --title "Please reboot your system." -- sleep 3

# -----------------------------------------------------
# Cencel
# -----------------------------------------------------
else
    echo ":: Changing shell canceled"
    exit
fi
