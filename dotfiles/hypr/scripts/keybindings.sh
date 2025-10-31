#!/usr/bin/env bash

# -----------------------------------------------------
# Get main keybindings config file location
# -----------------------------------------------------
# Determine the directory of the script
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Determine the root of the hypr config directory
hypr_dir=$(dirname "$script_dir")/

main_config_file="${hypr_dir}conf/keybinding.conf"

# -----------------------------------------------------
# Collect all keybinding config files (main + sourced)
# -----------------------------------------------------

# Initialize an array with the main config file
declare -a files_to_read=("$main_config_file")

# and add the sourced files to the array
if [[ -f "$main_config_file" ]]; then
    while IFS= read -r line; do
        # Look for lines like "source = ~/.config/hypr/conf/keybindings/default.conf"
        if [[ "$line" =~ ^[[:space:]]*source[[:space:]]*=[[:space:]]*(.*) ]]; then
            sourced_path="${BASH_REMATCH[1]}"
            # Expand path based on script location
            if [[ "$sourced_path" == "~/.config/hypr/"* ]]; then
                sourced_path="${hypr_dir}${sourced_path#"~/.config/hypr/"}"
            # Expand ~ to $HOME for other paths
            elif [[ "$sourced_path" == "~/"* ]]; then
                sourced_path="$HOME/${sourced_path#~/}"
            fi
            # Add to the array if the file exists and is readable
            if [[ -f "$sourced_path" ]]; then
                files_to_read+=("$sourced_path")
            fi
        fi
    done <"$main_config_file"
fi

echo "Reading from: ${files_to_read[@]}"

# Determine mainMod value from config files
# The last definition of mainMod encountered across all files will be used,
# mimicking Hyprland\'s configuration loading behavior.
MAIN_MOD_VALUE="SUPER" # Default value
for file in "${files_to_read[@]}"; do
    if [[ -f "$file" ]]; then
        while IFS= read -r line; do
            # Look for lines like "$mainMod = SUPER"
            if [[ "$line" =~ ^[[:space:]]*\$mainMod[[:space:]]*=[[:space:]]*(.*) ]]; then
                temp_mod_value="${BASH_REMATCH[1]}"
                # Remove comments and trim trailing whitespace
                temp_mod_value="${temp_mod_value%%#*}"
                temp_mod_value="${temp_mod_value%"${temp_mod_value##*[![:space:]]}"}"
                if [[ -n "$temp_mod_value" ]]; then
                    MAIN_MOD_VALUE="$temp_mod_value" # Update, last definition wins
                fi
            fi
        done <"$file"
    fi
done

# Initialize keybinds string
keybinds=""

# Process each file individually to add section headers and their respective keybinds
for file in "${files_to_read[@]}"; do
    if [[ -f "$file" ]]; then

        # Run awk on the single file to extract its keybindings
        file_keybinds=$(awk -F'=' -v main_mod_val="$MAIN_MOD_VALUE" '\
            /^[[:space:]]*bind(m|e|le)?[[:space:]]*=/ {
                # Split value and comment
                val_comment = $2
                comment = ""
                if (index(val_comment, "#")) {
                    split(val_comment, arr, "#")
                    val = arr[1]
                    comment = arr[2]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", comment)
                } else {
                    val = val_comment
                }

                gsub(/\$mainMod/, main_mod_val, val)
                gsub(/^[[:space:]]+/, "", val)

                n = split(val, parts, ",")
                for (i=1; i<=n; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
                }

                keys = ""
                if (parts[1] != "") {
                    keys = parts[1]
                }
                if (n > 1 && parts[2] != "") {
                    if (keys != "") {
                        keys = keys " + " parts[2]
                    } else {
                        keys = parts[2]
                    }
                }

                command = ""
                if (n > 2) {
                    command = parts[3]
                    for (i = 4; i <= n; i++) {
                        command = command "," parts[i]
                    }
                }
                sub(/,$/, "", command)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", command)


                if (comment != "") {
                    print keys "\r" comment
                } else {
                    print keys "\r" command
                }
            }
        \' "$file")

        # Append keybindings from this file to the main keybinds string
        if [[ -n "$file_keybinds" ]]; then
            keybinds+="$file_keybinds\n"
        fi
    fi
done

# Trim any trailing newline from keybinds to prevent an empty entry in Rofi
keybinds="${keybinds%\n}"

echo "keybinds: $keybinds"

sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" -config ~/.config/rofi/config-compact.rasi <<<"$keybinds"
