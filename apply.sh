#!/bin/bash

# This script applies the dotfiles using GNU Stow.

echo "Applying dotfiles using stow..."

# Define the dotfiles directory relative to this script
DOTFILES_DIR="$(dirname "$(readlink -f "$0")")/dotfiles"
if [ -n "$1" ]; then
    DOTFILES_DIR="$1/dotfiles"
fi

# Check if the dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# Create .config directory if it doesn't exist
if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi

# Check for existing files that would conflict
echo "Checking for existing files..."

# Get directories from dotfiles folder and backup existing ones
while IFS= read -r dir; do
    if [ -d "$HOME/.config/$dir" ]; then
        echo "Backing up $dir..."
        mv "$HOME/.config/$dir" "$HOME/.config/$dir.bak"
    fi
done < <(find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n")

# Check for existing symlinks and remove them
echo "Checking for existing symlinks..."
config_files=$(find "$HOME/.config" -maxdepth 1 -type l)
for file in $config_files; do
    if [ -L "$file" ]; then
        echo "Removing symlink: $file"
        rm "$file"
    fi
done

# First unstow any existing dotfiles
echo "Removing existing dotfile links..."
stow -v -D -t "$HOME/.config" -d "$(dirname "$DOTFILES_DIR")" "$(basename "$DOTFILES_DIR")" 2>/dev/null || true

# Stow the entire dotfiles directory at once
echo "Stowing new dotfiles..."
stow -v -R -t "$HOME/.config" -d "$(dirname "$DOTFILES_DIR")" "$(basename "$DOTFILES_DIR")"

echo "Dotfile application complete."
