#!/bin/bash

# Rofi Network Manager
ROFI_CONFIG="${HOME}/.config/rofi/config-nm.rasi"

# Main menu function
main_menu() {
    printf " Exit\n"
    echo "  Wi-Fi connections"
    echo "  All Connections"
    echo "<b>Active Connections</b>" # Added header for active connections
    nmcli -t -f DEVICE,TYPE,STATE device | while read -r line; do
        device=$(echo "$line" | cut -d':' -f1)
        type=$(echo "$line" | cut -d':' -f2)
        state=$(echo "$line" | cut -d':' -f3)

        if [ "$type" = "wifi" ]; then
            icon=" "
        elif [ "$type" = "ethernet" ]; then
            icon=""
        else
            icon="device"
        fi

        if [ "$state" = "connected" ]; then
            connection_info=$(nmcli -t -f NAME,DEVICE connection show --active | grep "^.*:$device$" | cut -d':' -f1)
            echo "$icon $device: $state ($connection_info)"
        # else
        #     echo "$icon $device: $state"
        fi
    done
}

show_details() {
    connection_name="$1"

    device=$(nmcli -t -f DEVICE,NAME con show --active | grep ":$connection_name$" | cut -d':' -f1)

    if [ -z "$device" ]; then
        details_output=$(nmcli connection show "$connection_name" | grep -E "connection.id|ipv4.method|ipv6.method")
        # Add "Back" option at the top for inactive connection details
        echo -e " Back\n\nConnection is not active.\n$details_output" | rofi -config "$ROFI_CONFIG" -dmenu -p "Details for $connection_name" -markup-rows -l 5
        return
    fi

    dev_details=$(nmcli device show "$device")
    con_details=$(nmcli connection show "$connection_name")

    # General
    hwaddr=$(echo "$dev_details" | grep "GENERAL.HWADDR" | awk '{print $2}')
    driver=$(echo "$dev_details" | grep "GENERAL.DRIVER" | awk '{print $2}')
    speed=$(echo "$dev_details" | grep "GENERAL.SPEED" | awk '{print $2}')
    security=$(echo "$con_details" | grep "802-11-wireless-security.key-mgmt" | awk '{print $2}')

    # IPv4
    ip4_info=$(echo "$dev_details" | grep "IP4.ADDRESS" | awk '{print $2}')
    ip4_addr=$(echo "$ip4_info" | cut -d'/' -f1)
    ip4_prefix=$(echo "$ip4_info" | cut -d'/' -f2)
    # Convert prefix to subnet mask
    subnet_mask=""
    if [ -n "$ip4_prefix" ]; then
        c=0
        for i in $(seq 1 "$ip4_prefix"); do
            if [ "$i" -le "$ip4_prefix" ]; then
                c=$((c * 2 + 1))
            else
                c=$((c * 2))
            fi
            if [ $((i % 8)) -eq 0 ]; then
                subnet_mask+="$((c))"
                [ "$i" -lt 32 ] && subnet_mask+="."
                c=0
            fi
        done
    fi
    broadcast=$(ip addr show "$device" | grep "inet " | awk '{print $4}')
    gateway=$(echo "$dev_details" | grep "IP4.GATEWAY" | awk '{print $2}')

    # IPv6
    ip6_info=$(echo "$dev_details" | grep "IP6.ADDRESS" | awk '{print $2}')
    ip6_addr=$(echo "$ip6_info" | cut -d'/' -f1)
    ip6_prefix=$(echo "$ip6_info" | cut -d'/' -f2)
    gateway6=$(echo "$dev_details" | grep "IP6.GATEWAY" | awk '{print $2}')

    # DNS
    dns1=$(echo "$dev_details" | grep "IP4.DNS\[1\]" | awk '{print $2}')
    dns2=$(echo "$dev_details" | grep "IP4.DNS\[2\]" | awk '{print $2}')
    dns6_1=$(echo "$dev_details" | grep "IP6.DNS\[1\]" | awk '{print $2}')
    dns6_2=$(echo "$dev_details" | grep "IP6.DNS\[2\]" | awk '{print $2}')

    # Formatting
    formatted_details=" Back\n" # Add back option here
    formatted_details+="\n<b>General</b>\n"
    formatted_details+="Interface: $device\n"
    [ -n "$hwaddr" ] && formatted_details+="Hardware Address: $hwaddr\n"
    [ -n "$driver" ] && formatted_details+="Driver: $driver\n"
    [ -n "$speed" ] && formatted_details+="Speed: $speed\n"
    [ -n "$security" ] && formatted_details+="Security: $security\n"

    formatted_details+="\n<b>IPv4 Configuration</b>\n"
    [ -n "$ip4_addr" ] && formatted_details+="IP Address: $ip4_addr\n"
    [ -n "$broadcast" ] && formatted_details+="Broadcast: $broadcast\n"
    [ -n "$subnet_mask" ] && formatted_details+="Subnet Mask: $subnet_mask\n"
    [ -n "$gateway" ] && formatted_details+="Gateway: $gateway\n"

    formatted_details+="\n<b>IPv6 Configuration</b>\n"
    [ -n "$ip6_addr" ] && formatted_details+="IP Address: $ip6_addr/$ip6_prefix\n"
    [ -n "$gateway6" ] && formatted_details+="Gateway: $gateway6\n"

    formatted_details+="\n<b>DNS Configuration</b>\n"
    [ -n "$dns1" ] && formatted_details+="DNS 1 (IPv4): $dns1\n"
    [ -n "$dns2" ] && formatted_details+="DNS 2 (IPv4): $dns2\n"
    [ -n "$dns6_1" ] && formatted_details+="DNS 1 (IPv6): $dns6_1\n"
    [ -n "$dns6_2" ] && formatted_details+="DNS 2 (IPv6): $dns6_2\n"

    # Display details. Rofi -dmenu closes upon selection or escape.
    echo -e "$formatted_details" | rofi -config "$ROFI_CONFIG" -dmenu -p "Details for $connection_name" -markup-rows -l 25
    return
}

device_menu() {
    device="$1"
    # Get device type
    device_type=$(nmcli -t -f GENERAL.TYPE device show "$device" | awk -F':' '{print $2}')

    while true; do
        state=$(nmcli -t -f GENERAL.STATE device show "$device" | awk -F':' '{print $2}')
        options=" Back\n"
        if [ "$state" = "100 (connected)" ] || [ "$state" = "80 (connecting)" ]; then
            options+=" Deactivate\n"
            options+=" Details"
            if [ "$device_type" = "wifi" ]; then
                options+="\n Forget" # Add forget option for wifi devices
            fi
        else
            options+=" Activate"
        fi

        # Adjust the number of lines for Rofi based on whether "Forget" is an option
        num_rofi_lines=3 # Default for "Back", "(De)Activate", "Details"
        if [ "$device_type" = "wifi" ] && ([ "$state" = "100 (connected)" ] || [ "$state" = "80 (connecting)" ]); then
            num_rofi_lines=4 # Add one line for "Forget"
        fi

        choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "$device" -i -l "$num_rofi_lines")

        case "$choice" in
        " Activate")
            nmcli device connect "$device"
            ;; 
        " Deactivate")
            nmcli device disconnect "$device"
            ;; 
        " Details")
            connection_name=$(nmcli -t -f NAME,DEVICE connection show --active | grep "^.*:$device$" | cut -d':' -f1)
            show_details "$connection_name"
            ;; 
        " Forget")
            # This option is only available for active Wi-Fi devices as per the condition above.
            # Get the name of the currently active connection on this device.
            connection_name=$(nmcli -t -f NAME,DEVICE connection show --active | grep "^.*:$device$" | cut -d':' -f1)
            if [ -n "$connection_name" ]; then
                nmcli connection delete "$connection_name"
                return # Exit the device menu after forgetting the connection
            fi
            ;; 
        " Back")
            return
            ;; 
        *) # Esc
            return
            ;; 
        esac
    done
}

scan_menu() {
    options=" Back\n"
    options+=" Rescan\n"

    (
        echo "Scanning..."
        tail -f /dev/null
    ) | rofi -config "$ROFI_CONFIG" -dmenu -p "Wi-Fi Scan" &
    rofi_pid=$!

    # Get a list of available Wi-Fi networks and format them
    wifi_list=$(nmcli -t --fields SSID,SECURITY,BARS dev wifi list | awk -F: '!seen[$1]++' | while read -r line; do
        ssid=$(echo "$line" | cut -d':' -f1)
        security=$(echo "$line" | cut -d':' -f2)
        bars=$(echo "$line" | cut -d':' -f3)
        if [[ "$security" == "WPA"* ]] || [[ "$security" == "WEP" ]]; then
            echo " $ssid ($bars)"
        else
            echo " $ssid ($bars)"
        fi
    done)
    options+="$wifi_list"

    kill $rofi_pid
    wait $rofi_pid 2>/dev/null

    choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "Wi-Fi Connections" -i -l 10 -no-sort)

    if [ "$choice" = " Rescan" ]; then
        (
            echo "Scanning..."
            tail -f /dev/null
        ) | rofi -config "$ROFI_CONFIG" -dmenu -p "Wi-Fi Scan" &
        rofi_pid=$!
        nmcli dev wifi rescan
        kill $rofi_pid
        wait $rofi_pid 2>/dev/null
        scan_menu # Recurse to show the new list
    elif [[ "$choice" == " Back" ]]; then
        return
    elif [ -n "$choice" ]; then
        ssid=$(echo "$choice" | sed -E 's/^( | )//; s/ \(.*\)$//; s/^[[:space:]]+|[[:space:]]+$//g')

        # Check if a connection with this SSID exists
        if nmcli -t -f NAME con show | grep -q "^$ssid$"; then
            connection_menu "$ssid"
        else
            # Flag to track if nm-applet was started by this script
            NM_APPLET_WAS_STARTED="false"
            # Check if nm-applet is already running
            if ! pgrep -x "nm-applet" >/dev/null; then
                "${HOME}"/.config/hypr/scripts/nm-applet.sh
                # Give nm-applet a moment to initialize and register for prompts
                sleep 0.5
                NM_APPLET_WAS_STARTED="true"
            fi

            nmcli dev wifi connect "$ssid"

            if [ "$NM_APPLET_WAS_STARTED" = "true" ]; then
                "${HOME}"/.config/hypr/scripts/nm-applet.sh stop
            fi
        fi
    fi
}

connections_menu() {
    options=" Back\n"
    connections_list=$(nmcli -t -f NAME,TYPE,DEVICE con)
    options+=$(echo "$connections_list" | while read -r line; do
        name=$(echo "$line" | cut -d':' -f1)
        type=$(echo "$line" | cut -d':' -f2)
        device=$(echo "$line" | cut -d':' -f3)
        if [ "$type" = "wifi" ]; then
            icon=" "
        elif [ "$type" = "ethernet" ]; then
            icon=""
        else
            icon=""
        fi
        if [ -n "$device" ]; then
            echo "$icon $name ($device)"
        else
            echo "$icon $name"
        fi
    done)

    choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "Connections" -i -l 10)

    if [[ "$choice" == " Back" ]]; then
        return
    elif [ -n "$choice" ]; then
        connection_name=$(echo "$choice" | sed -E 's/^. //' | sed -E 's/ \(.+\)$//')
        connection_menu "$connection_name"
    fi
}

connection_menu() {
    connection_name="$1"
    while true; do
        options=" Back\n"

        # Check if the connection is active
        if nmcli -t -f NAME,DEVICE con show --active | grep -q "^$connection_name:"; then
            options+=" Deactivate\n"
        else
            options+=" Activate\n"
        fi

        options+=" Forget\n"
        options+=" Details"

        choice=$(echo -e "$options" | rofi -config "$ROFI_CONFIG" -dmenu -p "$connection_name" -i -l 4)

        case "$choice" in
        " Activate")
            nmcli con up "$connection_name"
            ;; 
        " Deactivate")
            nmcli con down "$connection_name"
            ;; 
        " Forget")
            nmcli connection delete "$connection_name"
            return # Exit after forgetting
            ;; 
        " Details")
            show_details "$connection_name"
            ;; 
        " Back")
            return
            ;; 
        *) # Esc
            return
            ;; 
        esac
    done
}

# Main loop
while true; do
    choice=$(main_menu | rofi -config "$ROFI_CONFIG" -dmenu -p "Network Manager" -markup-rows -i -l 10)

    if [ "$choice" = " Exit" ]; then
        exit 0
    elif [[ "$choice" == *"Wi-Fi connections"* ]]; then
        # Scan for Wi-Fi networks
        scan_menu
    elif [[ "$choice" == *"All Connections"* ]]; then
        # Show connections
        connections_menu
    elif [ -n "$choice" ]; then
        device=$(echo "$choice" | cut -d':' -f1 | sed 's/.* //')
        device_menu "$device"
    else
        exit 0
    fi
done