#!/usr/bin/env bash

# Function to get the executable from a .desktop file
get_executable_from_desktop_file() {
    if [ -z "$1" ] || ! [[ "$1" == *.desktop ]]; then
        echo ""
        return
    fi

    local desktop_file_path
    desktop_file_path=$(find /usr/share/applications -name "$1" | head -n 1)
    if [ -n "$desktop_file_path" ] && [ -f "$desktop_file_path" ]; then
        local exec_line
        exec_line=$(grep -E "^Exec=" "$desktop_file_path" | head -n 1)
        local exec_command
        exec_command=$(echo "$exec_line" | sed -e 's/^Exec=//' -e 's/ %.*//' -e 's/\s.*//' | xargs basename)
        echo "$exec_command"
    else
        echo ""
    fi
}

# Function to set default application
set_default_app() {
    local app_name=$1
    local config_file=$2
    local app_list=("${@:3}")
    local default_app=""

    for app in "${app_list[@]}"; do
        if command -v "$app" &>/dev/null; then
            default_app="$app"
            break
        fi
    done

    if [ -n "$default_app" ]; then
        echo "Setting default $app_name to: $default_app"
        echo "$default_app" >"$HOME/.config/hypr/user_settings/$config_file"
    else
        echo "Could not determine default $app_name."
    fi
}

# Set default browser
default_browser_desktop=$(xdg-settings get default-web-browser)
default_browser=$(get_executable_from_desktop_file "$default_browser_desktop")
if [ -n "$default_browser" ]; then
    echo "Setting default browser to: $default_browser"
    echo "$default_browser" >"$HOME/.config/hypr/user_settings/browser.sh"
else
    echo "Could not determine default browser."
fi

# Set default file manager
default_file_manager_desktop=$(xdg-mime query default inode/directory)
default_file_manager=$(get_executable_from_desktop_file "$default_file_manager_desktop")
if [ -n "$default_file_manager" ]; then
    echo "Setting default file manager to: $default_file_manager"
    echo "$default_file_manager" >"$HOME/.config/hypr/user_settings/filemanager.sh"
else
    echo "Could not determine default file manager."
fi

# Set default terminal
set_default_app "terminal" "terminal.sh" "alacritty" "kitty" "gnome-terminal"

# Set default AUR helper
set_default_app "AUR helper" "aur.sh" "yay" "paru" "pacman"

# Set default bluetooth manager
set_default_app "bluetooth manager" "bluetooth.sh" "blueman-manager" "blueman-applet"

# Set default calculator
set_default_app "calculator" "calculator.sh" "gnome-calculator" "kcalc"

# Set default calendar
set_default_app "calendar" "calendar.sh" "gnome-calendar" "korganizer"

# Set default editor
set_default_app "editor" "editor.sh" "nvim" "vim" "nano" "gedit" "kate"

# Set default email client
set_default_app "email client" "email.sh" "evolution" "thunderbird"

# Set default network manager
set_default_app "network manager" "networkmanager.sh" "nmtui" "nm-connection-editor" "nm-applet"

# Set default screenshot editor
set_default_app "screenshot editor" "screenshot-editor.sh" "pinta" "gimp" "krita"

# Set default system monitor
set_default_app "system monitor" "system-monitor.sh" "htop" "btop" "top"

echo "Default applications set."
