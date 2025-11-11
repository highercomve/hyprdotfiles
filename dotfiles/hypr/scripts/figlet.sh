#!/usr/bin/env bash
figlet -f smslant "Figlet"
echo
# ------------------------------------------------
# Script to create ascii font based header on user input
# and copy the result to the clipboard
# -----------------------------------------------------

read -r -p "Enter the text for ascii encoding: " mytext

if [ -f ~/figlet.txt ]; then
    touch ~/figlet.txt
fi

{
            echo "cat <<\"EOF\""
            figlet -f smslant "$mytext"
            echo ""
            echo "EOF"
        } >~/figlet.txt

lines=$(cat ~/figlet.txt)
wl-copy "$lines"
xclip -sel clip ~/figlet.txt

echo "Text copied to clipboard!"
