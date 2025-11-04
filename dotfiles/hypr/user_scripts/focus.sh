#!/bin/bash
#    ____
#   / __/__  ______ _____
#  / _// _ \/ __/ // (_-<
# /_/  \___/\__/\_,_/___/
#

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' is not installed. Please install it to use this script."
    echo "  For Arch Linux: sudo pacman -S jq"
    echo "  For Debian/Ubuntu: sudo apt install jq"
    exit 1
fi

# Ensure awk is installed
if ! command -v awk &>/dev/null; then
    echo "Error: 'awk' is not installed. Please install it to use this script."
    echo "  For Arch Linux: sudo pacman -S gawk"
    echo "  For Debian/Ubuntu: sudo apt install gawk"
    exit 1
fi

# Get all open windows in JSON format
# Filter for mapped (visible) and non-hidden windows
# Format the output for Rofi: "Window Title --HYPRCTL_INFO--<address>--<workspace_id>"
# This allows Rofi to display the title, but the full string (with address and workspace) is passed on selection.
# Function to map Hyprland client class to a Nerd Font icon
# Users can customize this list to add/change icons or use preferred font glyphs.
# Ensure Nerd Fonts are installed and Rofi is configured to use them for this to work.
map_class_to_icon() {
    local class="$1"
    case "$class" in
    "firefox") echo "" ;;                   # Firefox
    "Alacritty") echo "󰆍" ;;                 # Alacritty terminal
    "Code") echo "󰨞" ;;                      # VS Code
    "Thunar") echo "" ;;                    # Thunar file manager
    "kitty") echo "󰆍" ;;                     # Kitty terminal
    "obsidian") echo "󰈄" ;;                  # Obsidian
    "org.wezfurlong.wezterm") echo "󰆍" ;;    # Wezterm terminal
    "steam") echo "" ;;                     # Steam
    "TelegramDesktop") echo "" ;;           # Telegram
    "Spotify") echo "" ;;                   # Spotify
    "Brave-browser") echo "" ;;             # Brave browser
    "Chrome") echo "" ;;                    # Chromium browser (Chrome icon)
    "Chromium") echo "" ;;                  # Chromium browser (Chrome icon)
    "Thorium-browser") echo "" ;;           # Thorium browser (Chrome icon)
    "transmission-qt") echo "" ;;           # Transmission (Torrent)
    "file-roller") echo "" ;;               # Archive Manager
    "Gimp") echo "" ;;                      # GIMP
    "Inkscape") echo "" ;;                  # Inkscape
    "mpv") echo "󰎁" ;;                       # MPV player
    "feh") echo "" ;;                       # Feh image viewer
    "eog") echo "" ;;                       # Eye of Gnome image viewer
    "Rofi") echo "" ;;                      # Rofi
    "org.gnome.Nautilus") echo "" ;;        # Nautilus file manager
    "caprine") echo "" ;;                   # Caprine (Facebook Messenger)
    "Slack") echo "" ;;                     # Slack
    "jetbrains-studio") echo "󰨞" ;;          # JetBrains Android Studio
    "jetbrains-idea") echo "󰨞" ;;            # JetBrains IntelliJ IDEA
    "dev.zed.Zed") echo "󰨞" ;;               # Zed code editor
    "firefox-developer-edition") echo "" ;; # Firefox Developer Edition
    *) echo "" ;;                           # Default general window icon (e.g., a window glyph)
    esac
}

# Get all open windows and extract relevant data, filtered for mapped (visible) and non-hidden.
# Output: class \t initialTitle \t title \t address \t workspace.id
# Using tab as a delimiter to handle titles that might contain spaces or other special characters.
client_raw_data=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true and .hidden == false) |
  "\(.class)\t\(.initialTitle)\t\(.title)\t\(.address)\t\(.workspace.id)"
')

# Initialize arrays to store display options for Rofi and the corresponding window data
declare -a display_options
declare -a window_data

# Accumulate data by iterating over each client
if [ -n "$client_raw_data" ]; then
    while IFS=$'\t' read -r class initial_title current_title address workspace_id; do
        icon=$(map_class_to_icon "$class")
        primary_title=""
        secondary_title=""

        # If initialTitle is a substring of the current title, use the last part of the class as the primary title.
        # This handles cases like browsers or editors where the initial title is generic.
        # An exception is made for chrome web apps, where the class is not human-readable.
        if [ -n "$initial_title" ] && [[ "$current_title" == *"$initial_title"* ]] && [[ "$class" != chrome-*-* ]]; then
            primary_title="${class##*.}"
        else
            # For web apps and other cases, use the initial title as the primary title.
            primary_title="$initial_title"
        fi

        # If the primary title ended up empty but there's a current title, use the current title as primary.
        if [ -z "$primary_title" ] && [ -n "$current_title" ]; then
            primary_title="$current_title"
        # If the current title is different from our determined primary title, show it as secondary info.
        elif [ "$current_title" != "$primary_title" ] && [ -n "$current_title" ]; then
            secondary_title=" ($current_title)"
        fi

        full_display_title="${primary_title}${secondary_title}"
        display_entry="$icon   $full_display_title"

        # Add the formatted entry to the display options array for Rofi
        display_options+=("$display_entry")

        # Store the corresponding address and workspace ID in a separate data array.
        # This data corresponds by index to the display_options array.
        window_data+=("$address--$workspace_id")
    done <<<"$client_raw_data"
fi

# Check if there are any windows to display
if [ ${#display_options[@]} -eq 0 ]; then
    echo "No active windows found."
    exit 0
fi

# Pipe the display options to Rofi
# -dmenu: Rofi's dmenu mode for selection
# -i: Case-insensitive searching
# -window-title: Sets the Rofi window title
# -format i: Makes Rofi output the 0-based index of the selected line instead of the text
selected_index_str=$(printf "%s\n" "${display_options[@]}" | rofi -dmenu -config ~/.config/rofi/config-compact.rasi -i -window-title "Active Window" -format i)

# Check if a selection was made (user didn't press Esc or close Rofi)
if [ -n "$selected_index_str" ]; then
    # Convert index string to an integer
    selected_index=$((selected_index_str))

    # Retrieve the window data (address and workspace) from our data array using the selected index
    selected_info=${window_data[$selected_index]}

    # Now split the info string by '--' to get the address and workspace ID
    selected_address=$(echo "$selected_info" | awk -F '--' '{print $1}')
    selected_workspace_id=$(echo "$selected_info" | awk -F '--' '{print $2}')

    # Trim any potential leading/trailing whitespace using xargs
    selected_address=$(echo "$selected_address" | xargs)
    selected_workspace_id=$(echo "$selected_workspace_id" | xargs)

    # Validate extracted values before dispatching
    if [[ -z "$selected_address" || -z "$selected_workspace_id" ]]; then
        echo "Error: Missing address or workspace ID after parsing."
        echo "Address: '${selected_address}', Workspace ID: '${selected_workspace_id}'"
        exit 1
    fi

    # Validate workspace ID is numeric
    if ! [[ "$selected_workspace_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid workspace ID format: '${selected_workspace_id}' (must be numeric)."
        exit 1
    fi

    # Switch to the selected window's workspace
    hyprctl dispatch workspace "$selected_workspace_id"

    # Add a small delay to ensure Hyprland processes the workspace change before focusing
    sleep 0.05

    # Focus on the selected window using its unique address
    hyprctl dispatch focuswindow "address:$selected_address"
else
    echo "No window selected. Exiting."
fi
