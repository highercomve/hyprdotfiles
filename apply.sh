#!/bin/bash

# This script applies the dotfiles using GNU Stow.

echo "Applying dotfiles using stow..."

# Check if stow is installed
if ! command -v stow &> /dev/null
then
    echo "Error: stow is not installed. Please install it to continue."
    exit 1
fi

# Define the root directory of the dotfiles repository
# This assumes the script is run from the root of the repository
REPO_ROOT="$(dirname "$(readlink -f "$0")")"

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# List of items to stow, with their source path (relative to REPO_ROOT) and target directory
declare -a STOW_ITEMS=(
    ".bashrc:$HOME"
    "dotfiles/starship.toml:$HOME/.config"
)

# Dynamically add all subdirectories of dotfiles/ to STOW_ITEMS
# These will be stowed into ~/.config/
while IFS= read -r dir; do
    STOW_ITEMS+=("dotfiles/$dir:$HOME/.config")
done < <(find "$REPO_ROOT/dotfiles" -maxdepth 1 -mindepth 1 -type d -printf "%f\n")


# Function to handle stowing for a single item
stow_item() {
    local source_path="$1" # e.g., ".bashrc" or "dotfiles/alacritty"
    local target_dir="$2"  # e.g., "$HOME" or "$HOME/.config"

    local stow_package
    stow_package=$(basename "$source_path") # e.g., ".bashrc" or "alacritty"
    local stow_dir
    stow_dir=$(dirname "$source_path")      # e.g., "." or "dotfiles"

    echo "Processing $source_path to $target_dir..."

    # Determine the full path of the item in the target directory
    local target_item="$target_dir/$stow_package"

    # Handle existing files/directories at the target
    if [ -e "$target_item" ] || [ -L "$target_item" ]; then
        if [ -L "$target_item" ]; then
            echo "Removing existing symlink: $target_item"
            rm "$target_item"
        else
            # It's a file or directory that needs backing up
            local backup_path="${target_item}.bak"
            if [ -e "$backup_path" ]; then
                read -r -p "Backup for $target_item already exists at $backup_path. Overwrite? [y/N] " response
                if [[ ! "$response" =~ ^[yY]$ ]]; then
                    echo "Skipping $stow_package: Backup exists and overwrite denied."
                    return
                fi
                echo "Overwriting existing backup..."
                rm -rf "$backup_path"
            fi
            
            echo "Backing up existing item: $target_item"
            mv "$target_item" "$backup_path"
        fi
    fi

    # Perform the stow operation
    # -v: verbose
    # -R: restow (remove existing links and create new ones)
    # -t: target directory
    # -d: stow directory (where the package resides)
    if ! stow -v -R -t "$target_dir" -d "$REPO_ROOT/$stow_dir" "$stow_package"; then
        echo "Error stowing $source_path. Check for conflicts or permissions."
    fi
    echo "" # Newline for better readability
}

# Unstow all known items first to clean up any old links
echo "Attempting to unstow all previously managed dotfiles..."
for item_def in "${STOW_ITEMS[@]}"; do
    IFS=':' read -r source_path target_dir <<< "$item_def"
    stow_package=$(basename "$source_path")
    stow_dir=$(dirname "$source_path")
    stow -v -D -t "$target_dir" -d "$REPO_ROOT/$stow_dir" "$stow_package" 2>/dev/null || true
done
echo ""

# Now, stow all items
for item_def in "${STOW_ITEMS[@]}"; do
    IFS=':' read -r source_path target_dir <<< "$item_def"
    stow_item "$source_path" "$target_dir"
done

echo "Dotfile application complete."
