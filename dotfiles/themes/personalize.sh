#!/bin/bash

# Paths
CONFIG_FILE="$HOME/.config/themes/config.json"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
MATUGEN_TEMPLATES="$DOTFILES_DIR/matugen/templates"
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
        
        # Check if source is same as destination (canonicalize paths to be safe)
        if [ "$(readlink -f "$src")" == "$(readlink -f "$dest_dir")" ]; then
            echo "Current theme is already $target_name. Skipping copy to preserve layout."
            return
        fi

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
# copy_theme "wlogout" "$HOME/.config/wlogout/layout" "personalize" "dir" 
# Note: wlogout link points to 'layout' inside the theme folder usually.
# themeswitcher.sh: ln -sf .../themes/$theme/layout .../layout
# So readlink .../layout gives .../themes/$theme/layout. Dirname gives theme folder.
WLOGOUT_SRC=$(readlink -f "$HOME/.config/wlogout/layout")
WLOGOUT_THEME_DIR=$(dirname "$WLOGOUT_SRC")
WLOGOUT_DEST_DIR="$HOME/.config/wlogout/themes/personalize"

if [ "$(readlink -f "$WLOGOUT_THEME_DIR")" != "$(readlink -f "$WLOGOUT_DEST_DIR")" ]; then
    rm -rf "$WLOGOUT_DEST_DIR"
    cp -r "$WLOGOUT_THEME_DIR" "$WLOGOUT_DEST_DIR"
    echo "Copied wlogout theme to $WLOGOUT_DEST_DIR"
else
    echo "Current wlogout theme is already personalize. Skipping copy."
fi

# Rofi
copy_theme "rofi" "$HOME/.config/rofi/current.rasi" "personalize.rasi" "file"

# Waypaper
# themeswitcher.sh: ln -sf .../themes/$theme/config.ini .../config.ini
WAYPAPER_SRC=$(readlink -f "$HOME/.config/waypaper/config.ini")
WAYPAPER_THEME_DIR=$(dirname "$WAYPAPER_SRC")
WAYPAPER_DEST_DIR="$HOME/.config/waypaper/themes/personalize"

if [ "$(readlink -f "$WAYPAPER_THEME_DIR")" != "$(readlink -f "$WAYPAPER_DEST_DIR")" ]; then
    rm -rf "$WAYPAPER_DEST_DIR"
    cp -r "$WAYPAPER_THEME_DIR" "$WAYPAPER_DEST_DIR"
    echo "Copied waypaper theme to $WAYPAPER_DEST_DIR"
else
    echo "Current waypaper theme is already personalize. Skipping copy."
fi


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
    
    # Corrected Rofi theme modification using sed
    # First, delete the entire * { ... } block
    sed -i '/\* {/,/}/d' "$ROFI_PERSONALIZE"

    # Then, insert the @import statement after the 'configuration { font: ... };' line.
    # Assuming 'configuration { font: ... };' is a unique line to anchor to.
    # Use a temporary file to construct the replacement text to avoid quoting hell
    NON_COLORS_CONTENT=$(cat "$MATUGEN_TEMPLATES/rofi-non-colors.rasi")
    # Escape newlines and backslashes for sed
    NON_COLORS_CONTENT="${NON_COLORS_CONTENT//\\/\\\\}"
    NON_COLORS_CONTENT="${NON_COLORS_CONTENT//$'\n'/\\n}"
    
    sed -i "/^configuration { font: \"FiraCode Nerd Font 10\"; }/a \\
@import \"~/.config/rofi/themes/personalize_colors.rasi\"\\
\\
$NON_COLORS_CONTENT" "$ROFI_PERSONALIZE"
fi

# 3. Generate Matugen Config
# Ensure output directories exist
mkdir -p "$HOME/.config/waybar/themes/personalize"
mkdir -p "$HOME/.config/swaync/themes/personalize"
mkdir -p "$HOME/.config/wlogout/themes/personalize"
mkdir -p "$HOME/.config/rofi/themes"

MATUGEN_CONFIG_TMP=$(mktemp)
cat <<EOF > "$MATUGEN_CONFIG_TMP"
[config]

[templates]
waybar = { input_path = "$MATUGEN_TEMPLATES/colors-waybar.css", output_path = "$HOME/.config/waybar/themes/personalize/colors.css" }
swaync = { input_path = "$MATUGEN_TEMPLATES/colors-swaync.css", output_path = "$HOME/.config/swaync/themes/personalize/colors.css" }
wlogout = { input_path = "$MATUGEN_TEMPLATES/colors-wlogout.css", output_path = "$HOME/.config/wlogout/themes/personalize/colors.css" }
rofi = { input_path = "$MATUGEN_TEMPLATES/colors-rofi.rasi", output_path = "$HOME/.config/rofi/themes/personalize_colors.rasi" }
EOF

# 4. Run Matugen
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
