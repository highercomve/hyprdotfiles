#!/bin/bash

# This script installs necessary dependencies for the Hyprland dotfiles.
# It currently supports Arch Linux (using yay).
# Users on other distributions will need to adapt the package installation commands.

echo "Starting dependency installation..."

# Check if running on Arch Linux
if [ -f /etc/arch-release ]; then
    echo "Arch Linux detected. Using yay for package installation."

    # Check if yay is installed
    if ! command -v yay &>/dev/null; then
        echo "yay not found. Installing yay..."
        sudo pacman -S --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    fi

    # Install core dependencies
    yay -S --noconfirm \
        ttf-jetbrains-mono-nerd \
        stow \
        hyprland \
        gnome-gnome-calendar \
        hypridle \
        hyprlock \
        hyprpaper \
        xdg-desktop-portal-hyprland \
        hyprpolkitagent \
        alacritty \
        wofi \
        waybar \
        pamixer \
        brightnessctl \
        playerctl \
        swaync \
        grim slurp \
        cliphist \
        nwg-look \
        qt5ct qt6ct \
        neovim \
        lazygit \
        zed \
        zellij \
        starship \
        gum \
        hyprpicker \
        jq \
        eza \
        matugen \
        wlogout

    echo "Please ensure you have a Nerd Font installed for proper icon display (e.g., 'ttf-nerd-fonts-symbols' or 'ttf-jetbrains-mono-nerd')."
    echo "You can install one using: yay -S ttf-jetbrains-mono-nerd"

else
    echo "Unsupported distribution. Please install the following packages manually:"
    echo "  - ttf-jetbrains-mono-nerd"
    echo "  - stow"
    echo "  - hyprland"
    echo "  - gnome-gnome-calendar"
    echo "  - hypridle"
    echo "  - hyprlock"
    echo "  - hyprpaper"
    echo "  - xdg-desktop-portal-hyprland"
    echo "  - hyprpolkitagent"
    echo "  - alacritty"
    echo "  - wofi"
    echo "  - waybar"
    echo "  - pamixer"
    echo "  - brightnessctl"
    echo "  - playerctl"
    echo "  - swaync"
    echo "  - grim, slurp"
    echo "  - cliphist"
    echo "  - nwg-look"
    echo "  - qt5ct, qt6ct"
    echo "  - neovim"
    echo "  - lazygit"
    echo "  - zed"
    echo "  - zellij"
    echo "  - starship"
    echo "  - gum"
    echo "  - hyprpicker"
    echo "  - jq"
    echo "  - eza"
    echo "  - matugen"
    echo "  - wlogout"
fi

git clone https://github.com/LazyVim/starter dotfiles/nvim
rm -rf dotfiles/nvim/.git

echo "Dependency installation script finished."
