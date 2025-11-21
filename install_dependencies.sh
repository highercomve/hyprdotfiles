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

    yay -S --noconfirm \
        automake \
        fakeroot

    # Install core dependencies
    yay -S --noconfirm \
        rofi \
        ttf-jetbrains-mono-nerd \
        ttf-nerd-fonts-symbols \
        stow \
        gnome-calendar \
        hyprland \
        hypridle \
        hyprlock \
        hyprpaper \
        xdg-desktop-portal-hyprland \
        polkit-gnome \
        alacritty \
        wofi \
        go \
        waybar \
        pamixer \
        brightnessctl \
        playerctl \
        swaync \
        grim \
        slurp \
        cliphist \
        nwg-look \
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
        wlogout \
        wl-clipboard \
        network-manager-applet \
        procps-ng \
        pinta \
        wireplumber \
        pipewire \
        pipewire-pulse \
        gnome-themes-extra \
        qogir-icon-theme \
        libnotify \
        imagemagick \
        nwg-dock-hyprland \
        figlet \
        pavucontrol \
        fastfetch \
        gnome-calculator \
        nautilus \
        evolution \
        pinta \
        htop \
        bluez \
        networkmanager \
        bluez-utils \
        gnome-bluetooth-3.0

else
    echo "Unsupported distribution. Please install the following packages manually:"
    echo "  - ttf-jetbrains-mono-nerd"
    echo "  - stow"
    echo "  - hyprland"
    echo "  - wl-clipboard"
    echo "  - polkit-gnome"
    echo "  - network-manager-applet"
    echo "  - procps-ng"
    echo "  - wireplumber"
    echo "  - pipewire"
    echo "  - pipewire-pulse"
    echo "  - gnome-themes-extra"
    echo "  - qogir-icon-theme"
    echo "  - libnotify"
    echo "  - imagemagick"
    echo "  - nwg-dock-hyprland"
    echo "  - figlet"
    echo "  - pavucontrol"
    echo "  - fastfetch"
    echo "  - gnome-calculator"
    echo "  - nautilus"
    echo "  - evolution"
    echo "  - pinta"
    echo "  - htop"
    echo "  - nmtui"
    echo "  - bluez"
    echo "  - bluez-utils"
    echo "  - gnome-bluetooth-3.0"
fi

git clone https://github.com/LazyVim/starter dotfiles/nvim
rm -rf dotfiles/nvim/.git

echo "Installing waybar-music..."
if command -v curl &>/dev/null && command -v jq &>/dev/null; then
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/highercomve/waybar-music-zig/releases/latest | jq -r '.assets[] | select(.name == "waybar-music") | .browser_download_url')
    if [ -n "$DOWNLOAD_URL" ] && [ "$DOWNLOAD_URL" != "null" ]; then
        echo "Downloading from $DOWNLOAD_URL..."
        curl -L -o /tmp/waybar-music "$DOWNLOAD_URL"
        chmod +x /tmp/waybar-music
        sudo mv /tmp/waybar-music /usr/local/bin/waybar-music
        echo "waybar-music installed successfully to /usr/local/bin/waybar-music"
    else
        echo "Error: Could not find download URL for waybar-music."
    fi
else
    echo "Error: curl or jq not found. Cannot install waybar-music."
fi

echo "Dependency installation script finished."

cp ~/.config/gtk-3.0/bookmarks dotfiles/gtk-3.0/bookmarks
cp ~/.config/gtk-4.0/servers dotfiles/gtk-4.0/servers
