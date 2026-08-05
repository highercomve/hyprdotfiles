#!/bin/bash

# Ensure rofi and wl-copy are available
if ! command -v rofi &>/dev/null; then
  echo "Error: rofi is not installed. Please install it to use this script."
  exit 1
fi

if ! command -v wl-copy &>/dev/null; then
  echo "Error: wl-copy is not installed. Please install it to use this script."
  exit 1
fi

ROFI_CFG="$HOME/.config/rofi/config-compact.rasi"
USER_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/user_settings"

# Custom device names live outside the repo: they are machine specific.
# Format, one per line: <device-key>=<custom name>
# The key is the USB serial (ID_SERIAL_SHORT) when the device exposes one, or
# "path:<ID_PATH>" (the physical USB port) for devices without a serial, so a
# name sticks to the device and not to the /dev/ttyUSBX number, which is
# reassigned on every reboot / replug.
ALIAS_FILE="$USER_SETTINGS/ttyusb-aliases.conf"

MANAGE_ENTRY="⚙  Manage custom names…"
BACK_ENTRY="←  Back"
EDIT_FILE_ENTRY="✎  Edit aliases file in editor"

notify() { command -v notify-send &>/dev/null && notify-send "$@"; }

menu() { # menu <prompt> [extra rofi args...]; entries on stdin
  local prompt="$1"
  shift
  rofi -config "$ROFI_CFG" -dmenu -p "$prompt" "$@"
}

# ---------------------------------------------------------------- aliases ---

declare -A ALIASES=()

load_aliases() {
  ALIASES=()
  [ -f "$ALIAS_FILE" ] || return 0
  local line key name
  while IFS= read -r line || [ -n "$line" ]; do
    # skip comments and blank lines
    case "$line" in '' | '#'*) continue ;; esac
    key="${line%%=*}"
    name="${line#*=}"
    [ -n "$key" ] && [ "$key" != "$line" ] && ALIASES["$key"]="$name"
  done <"$ALIAS_FILE"
}

ensure_alias_file() {
  [ -f "$ALIAS_FILE" ] && return 0
  mkdir -p "$(dirname "$ALIAS_FILE")"
  cat >"$ALIAS_FILE" <<'EOF'
# Custom names for USB serial devices, used by hypr/scripts/ttyusb.sh.
# One entry per line: <device-key>=<custom name>
# The key is the USB serial number, or "path:<usb-port-path>" for devices that
# do not expose one. It is stable across reboots; /dev/ttyUSBX is not.
EOF
}

save_alias() { # save_alias <key> <name>; empty name deletes the entry
  local key="$1" name="$2" tmp
  ensure_alias_file
  tmp=$(mktemp)
  # drop any existing entry for this key, then append the new one.
  # index()==1 is an exact prefix match: keys contain '.' and ':', so a regex
  # would match too much.
  awk -v k="$key=" 'index($0, k) != 1' "$ALIAS_FILE" >"$tmp"
  [ -n "$name" ] && printf '%s=%s\n' "$key" "$name" >>"$tmp"
  mv "$tmp" "$ALIAS_FILE"
  load_aliases
}

prompt_name() { # prompt_name <key> -> prints the entered name
  local key="$1" current="${ALIASES[$key]}" name
  # rofi -dmenu with no entries returns whatever is typed; -filter pre-fills the
  # input with the current name so a rename is an edit, not a retype.
  name=$(printf '%s' "" | menu "Name for $key" -filter "$current")
  # strip surrounding whitespace
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  printf '%s' "$name"
}

rename_key() { # rename_key <key>
  local key="$1" name
  name=$(prompt_name "$key")
  if [ -z "$name" ]; then
    echo "No name entered. Operation cancelled."
    return 1
  fi
  save_alias "$key" "$name"
  notify "ttyUSB name saved" "$key → $name"
}

# ---------------------------------------------------------------- devices ---

declare -A DEV_KEY=()    # /dev/ttyUSBX -> identity key
declare -A DEV_DESC=()   # /dev/ttyUSBX -> hardware description (no alias)
declare -A DEV_BY_KEY=() # identity key  -> /dev/ttyUSBX (connected devices)
DEVICE_LINES=""

scan_devices() {
  local device vendor model serial serial_long id_path key display_name desc label
  DEV_KEY=() DEV_DESC=() DEV_BY_KEY=() DEVICE_LINES=""
  shopt -s nullglob
  for device in /dev/ttyUSB*; do
    [ -c "$device" ] || continue

    vendor="" model="" serial="" serial_long="" id_path=""
    while IFS='=' read -r prop value; do
      case "$prop" in
      ID_VENDOR) vendor="$value" ;;
      ID_MODEL) model="$value" ;;
      ID_SERIAL_SHORT) serial="$value" ;;
      ID_SERIAL) serial_long="$value" ;;
      ID_PATH) id_path="$value" ;;
      esac
    done < <(udevadm info -q property -n "$device")

    # Identity key: prefer the USB serial, fall back to the physical port path.
    if [ -n "$serial" ]; then
      key="$serial"
    elif [ -n "$id_path" ]; then
      key="path:$id_path"
    else
      key="dev:$(basename "$device")"
    fi

    # Hardware description, used when no custom name is set.
    display_name="$vendor"
    [ -n "$model" ] && display_name="${display_name:+$display_name }$model"
    [ -n "$display_name" ] || display_name="$serial_long"

    desc="$display_name"
    [ -n "$serial" ] && desc="${desc:+$desc }($serial)"
    [ -n "$desc" ] || desc="$(basename "$device")"

    DEV_KEY["$device"]="$key"
    DEV_DESC["$device"]="$desc"
    DEV_BY_KEY["$key"]="$device"

    if [ -n "${ALIASES[$key]}" ]; then
      label="${ALIASES[$key]}"
      # keep the serial visible so the device stays identifiable
      [ -n "$serial" ] && label="$label ($serial)"
    else
      label="$desc"
    fi

    DEVICE_LINES="${DEVICE_LINES}$device - ${label}"$'\n'
  done
}

# ------------------------------------------------------------ alias editor ---

edit_alias_file() {
  local term editor
  term=$(cat "$USER_SETTINGS/terminal.sh" 2>/dev/null)
  editor=$(cat "$USER_SETTINGS/editor.sh" 2>/dev/null)
  command -v "$term" &>/dev/null || term=alacritty
  command -v "$editor" &>/dev/null || editor="${EDITOR:-nano}"
  ensure_alias_file
  "$term" --title "ttyusb-aliases" -e "$editor" "$ALIAS_FILE"
}

manage_aliases() {
  local -a keys
  local -A line_key
  local key line entries selected action

  while :; do
    keys=() line_key=() entries=""
    while IFS= read -r key; do
      [ -n "$key" ] || continue
      keys+=("$key")
    done < <(printf '%s\n' "${!ALIASES[@]}" | sort)

    for key in "${keys[@]}"; do
      if [ -n "${DEV_BY_KEY[$key]}" ]; then
        line="${ALIASES[$key]}  ·  $key  ·  ${DEV_BY_KEY[$key]}"
      else
        line="${ALIASES[$key]}  ·  $key  ·  not connected"
      fi
      line_key["$line"]="$key"
      entries="${entries}${line}"$'\n'
    done

    [ -n "$entries" ] || entries="(no custom names yet)"$'\n'
    entries="${entries}${EDIT_FILE_ENTRY}"$'\n'"${BACK_ENTRY}"

    selected=$(printf '%s' "$entries" | menu "Custom names")
    case "$selected" in
    '' | "$BACK_ENTRY") return ;;
    "$EDIT_FILE_ENTRY")
      edit_alias_file
      load_aliases
      scan_devices
      continue
      ;;
    '(no custom names yet)') continue ;;
    esac

    key="${line_key[$selected]}"
    [ -n "$key" ] || continue

    action=$(printf '%s\n' "Rename" "Delete" "$BACK_ENTRY" | menu "${ALIASES[$key]}")
    case "$action" in
    Rename) rename_key "$key" ;;
    Delete)
      save_alias "$key" ""
      notify "ttyUSB name removed" "$key"
      ;;
    esac
    scan_devices
  done
}

# ------------------------------------------------------------------- main ---

load_aliases
scan_devices

if [ -z "$DEVICE_LINES" ]; then
  echo "No ttyUSB devices found."
  notify "No ttyUSB Devices" "No /dev/ttyUSB* devices were detected."
  # still allow managing names for devices that are currently unplugged
  [ ${#ALIASES[@]} -gt 0 ] && manage_aliases
  exit 0
fi

# Use rofi to let the user select a ttyUSB device
selected_ttyusb_info=$(printf '%s%s' "$DEVICE_LINES" "$MANAGE_ENTRY" | menu "Select a ttyUSB device:")

case "$selected_ttyusb_info" in
'')
  # User closed rofi or did not make a selection.
  echo "No ttyUSB device selected. Operation cancelled."
  exit 0
  ;;
"$MANAGE_ENTRY")
  manage_aliases
  exit 0
  ;;
esac

# Extract the /dev/path part, which is the first field in our formatted string.
dev_path=$(echo "$selected_ttyusb_info" | awk '{print $1}')
dev_key="${DEV_KEY[$dev_path]}"
current_name="${ALIASES[$dev_key]}"

# Ask for action
actions="Open console"$'\n'"Copy path"$'\n'"Copy stable by-id path"
if [ -n "$current_name" ]; then
  actions="${actions}"$'\n'"Rename (currently: $current_name)"$'\n'"Remove custom name"
else
  actions="${actions}"$'\n'"Set custom name"
fi
actions="${actions}"$'\n'"$MANAGE_ENTRY"
selected_action=$(printf '%s' "$actions" | menu "Action for $dev_path")

case "$selected_action" in
"Open console")
  # Get the path to the device console script.
  device_console_script_path="$HOME/.config/hypr/scripts/device_console"

  if [ ! -f "$device_console_script_path" ]; then
    echo "Error: Device console script not found at $device_console_script_path"
    notify -u critical "Script Error" "Device console script not found."
    exit 1
  fi

  # Get the terminal command
  terminal_cmd=$(cat "$USER_SETTINGS/terminal.sh")
  terminal_cmd=alacritty
  # Execute the device console script in a new terminal
  # $terminal_cmd --title "device-console-applet" -e sudo "$device_console_script_path" "$dev_path"
  window_title="device-console-applet"
  [ -n "$current_name" ] && window_title="$current_name"
  $terminal_cmd --title "$window_title" -e "$device_console_script_path" "$dev_path"
  ;;
"Copy path")
  # Copy the /dev path to the Wayland clipboard using wl-copy.
  if wl-copy "$dev_path"; then
    notify "ttyUSB /dev path copied" "Copied: $dev_path"
  else
    echo "Error: Failed to copy '$dev_path' to clipboard. wl-copy might have failed."
    notify -u critical "Clipboard Error" "Failed to copy '$dev_path' to clipboard."
  fi
  ;;
"Copy stable by-id path")
  # /dev/serial/by-id/* survives reboots, unlike the ttyUSBX number.
  by_id=""
  for link in /dev/serial/by-id/*; do
    if [ "$(readlink -f "$link")" = "$dev_path" ]; then
      by_id="$link"
      break
    fi
  done
  if [ -z "$by_id" ]; then
    echo "Error: no /dev/serial/by-id entry for $dev_path"
    notify -u critical "No by-id path" "$dev_path has no /dev/serial/by-id entry."
    exit 1
  fi
  wl-copy "$by_id" && notify "ttyUSB by-id path copied" "Copied: $by_id"
  ;;
"Set custom name" | "Rename"*)
  rename_key "$dev_key"
  ;;
"Remove custom name")
  save_alias "$dev_key" ""
  notify "ttyUSB name removed" "$dev_path is back to ${DEV_DESC[$dev_path]}"
  ;;
"$MANAGE_ENTRY")
  manage_aliases
  ;;
*)
  echo "No action selected. Operation cancelled."
  ;;
esac
