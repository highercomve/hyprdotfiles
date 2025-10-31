#!/bin/bash

# This script backs up existing configuration files before deploying new dotfiles.

echo "Starting backup of existing dotfiles..."

# Define backup directory
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backup directory created: $BACKUP_DIR"

# List of directories to backup
CONFIG_DIRS=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/wofi"
    "$HOME/.config/kitty"
    "$HOME/.config/alacritty"
    "$HOME/.config/ghostty"
    "$HOME/.config/nvim"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/gtk-4.0"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Backing up $dir to $BACKUP_DIR/"
        cp -r "$dir" "$BACKUP_DIR/"
    else
        echo "Directory $dir does not exist, skipping."
    fi
done

echo "Backup process finished. Your existing configurations are saved in $BACKUP_DIR"
