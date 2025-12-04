#!/bin/bash

# Paths
CONFIG_FILE="$HOME/.config/themes/config.json"
MATUGEN_TEMPLATES="$HOME/projects/personal/hyprconfig/dotfiles/matugen/templates"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

# Ensure jq and matugen are installed
if ! command -v jq &>/dev/null || ! command -v matugen &>/dev/null;
    then
    echo "Error: jq or matugen is not installed."
    exit 1
fi

# Get current wallpaper
if [ -f "$WAYPAPER_CONFIG" ]; then
    # Try to parse wallpaper path. It might be quoted or not, depending on ini parser.
    # Simple grep/cut might be safer if no ini parser.
    # Assuming line: wallpaper = /path/to/image
    WALLPAPER=$(grep "^wallpaper =" "$WAYPAPER_CONFIG" | cut -d'=' -f2 | tr -d ' ')
    # Expand tilde if present
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
else
    echo "Error: Waypaper config not found."
    exit 1
fi

if [ ! -f "$WALLPAPER" ]; then
    echo "Error: Wallpaper file not found: $WALLPAPER"
    exit 1
fi

echo "Generating Personalize theme from: $WALLPAPER"

# Function to copy theme
copy_theme() {
    local component=$1
    local current_link=$2
    local target_name=$3
    local type=$4 # dir or file

    if [ -L "$current_link" ]; then
        local src=$(readlink -f "$current_link")
        local dest_dir="$HOME/.config/$component/themes/$target_name"
        
        if [ "$type" == "dir" ]; then
            rm -rf "$dest_dir"
            cp -r "$src" "$dest_dir"
            echo "Copied $component theme to $dest_dir"
        elif [ "$type" == "file" ]; then
            # For rofi, destination is the file itself
            local dest_file="$HOME/.config/$component/themes/$target_name"
            cp "$src" "$dest_file"
            echo "Copied $component theme to $dest_file"
        fi
    else
        echo "Warning: No current theme link found for $component at $current_link"
    fi
}

# 1. Copy current themes to 'personalize'
copy_theme "waybar" "$HOME/.config/waybar/current" "personalize" "dir"
copy_theme "swaync" "$HOME/.config/swaync/current" "personalize" "dir"
copy_theme "wlogout" "$HOME/.config/wlogout/layout" "personalize" "dir" 
# Note: wlogout link points to 'layout' inside the theme folder usually.
# themeswitcher.sh: ln -sf .../themes/$theme/layout .../layout
# So readlink .../layout gives .../themes/$theme/layout. Dirname gives theme folder.
WLOGOUT_SRC=$(readlink -f "$HOME/.config/wlogout/layout")
WLOGOUT_THEME_DIR=$(dirname "$WLOGOUT_SRC")
rm -rf "$HOME/.config/wlogout/themes/personalize"
cp -r "$WLOGOUT_THEME_DIR" "$HOME/.config/wlogout/themes/personalize"

# Rofi
copy_theme "rofi" "$HOME/.config/rofi/current.rasi" "personalize.rasi" "file"

# Waypaper
# themeswitcher.sh: ln -sf .../themes/$theme/config.ini .../config.ini
WAYPAPER_SRC=$(readlink -f "$HOME/.config/waypaper/config.ini")
WAYPAPER_THEME_DIR=$(dirname "$WAYPAPER_SRC")
rm -rf "$HOME/.config/waypaper/themes/personalize"
cp -r "$WAYPAPER_THEME_DIR" "$HOME/.config/waypaper/themes/personalize"


# 2. Modify Rofi theme to import colors
ROFI_PERSONALIZE="$HOME/.config/rofi/themes/personalize.rasi"
if [ -f "$ROFI_PERSONALIZE" ]; then
    # Remove existing * { ... } block and add import
    # This is a bit risky with simple sed if the block spans multiple lines and has nested braces.
    # But Rofi * block is usually at the top.
    # simpler approach: Rename original to .bak, read it, skip the * block, write new.
    # Or assume standard format.
    
    # Regex attempt: remove * { ... }
    # perl -0777 -i -pe 's/\*\s*\{[^\}]*\}//s' "$ROFI_PERSONALIZE"
    # Insert @import at top
    # echo -e "@import \"personalize_colors.rasi\"\n$(cat $ROFI_PERSONALIZE)" > "$ROFI_PERSONALIZE"
    
    # Better: replace * { ... } with @import "personalize_colors.rasi";
    perl -0777 -i -pe 's/\*\s*\{[^\}]*\}/@import "personalize_colors.rasi"/s' "$ROFI_PERSONALIZE"
fi

# 3. Generate Matugen Config
MATUGEN_CONFIG_TMP=$(mktemp)
cat <<EOF > "$MATUGEN_CONFIG_TMP"
[config]

[templates]
waybar = "$HOME/.config/waybar/themes/personalize/colors.css"
swaync = "$HOME/.config/swaync/themes/personalize/colors.css"
wlogout = "$HOME/.config/wlogout/themes/personalize/colors.css"
rofi = "$HOME/.config/rofi/themes/personalize_colors.rasi"
EOF

# 4. Run Matugen
# We need to point to our source templates in dotfiles/matugen/templates
# But matugen expects the keys in [templates] to map to output paths,
# and the templates themselves need to be located? 
# Wait, matugen config: key = "path".
# If "path" is the OUTPUT path, where does it find the INPUT template?
# Matugen documentation says:
# [templates]
# template_name = "path/to/output"
# And it looks for "template_name.extension" in XDG_CONFIG_HOME/matugen/templates/ ?
# Or does it take a path as value?
# Let's re-read matugen help or assumptions.
# "Templates ... Define paths to your templates" in config.toml comments.
# The comment says: # hyprland = "~/.config/hypr/colors.conf"
# This implies the key is just a name, and the value is the OUTPUT.
# Where are the inputs?
# Matugen usually looks in ~/.config/matugen/templates/ for a file named {key}.{ext}? 
# If so, I need to symlink or copy my templates to ~/.config/matugen/templates/ ?
# OR I can use CLI to specify.

# Let's ensure templates are in ~/.config/matugen/templates/
mkdir -p "$HOME/.config/matugen/templates"
ln -sf "$MATUGEN_TEMPLATES/colors-waybar.css" "$HOME/.config/matugen/templates/waybar"
ln -sf "$MATUGEN_TEMPLATES/colors-waybar.css" "$HOME/.config/matugen/templates/waybar.css"
ln -sf "$MATUGEN_TEMPLATES/colors-swaync.css" "$HOME/.config/matugen/templates/swaync"
ln -sf "$MATUGEN_TEMPLATES/colors-swaync.css" "$HOME/.config/matugen/templates/swaync.css"
ln -sf "$MATUGEN_TEMPLATES/colors-wlogout.css" "$HOME/.config/matugen/templates/wlogout"
ln -sf "$MATUGEN_TEMPLATES/colors-wlogout.css" "$HOME/.config/matugen/templates/wlogout.css"
ln -sf "$MATUGEN_TEMPLATES/colors-rofi.rasi" "$HOME/.config/matugen/templates/rofi"
ln -sf "$MATUGEN_TEMPLATES/colors-rofi.rasi" "$HOME/.config/matugen/templates/rofi.rasi"

# Now run matugen with the temporary config
matugen image "$WALLPAPER" --config "$MATUGEN_CONFIG_TMP"

rm "$MATUGEN_CONFIG_TMP"

# 5. Update config.json if needed
# We need to check if "Personalize" entry exists.
if ! jq -e '.themes.Personalize' "$CONFIG_FILE" > /dev/null;
    then
    # Add it
    TMP_JSON=$(mktemp)
    jq '.themes += {"Personalize": {
        "waybar": "personalize",
        "swaync": "personalize",
        "rofi": "personalize.rasi",
        "wlogout": "personalize",
        "waypaper": "personalize"
    }}' "$CONFIG_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$CONFIG_FILE"
    echo "Added Personalize theme to config.json"
fi

echo "Personalize theme generated."
