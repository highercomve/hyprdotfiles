#!/bin/bash

PLAYER_FILE="/tmp/playerctl_current_player"

get_players() {
    playerctl --list-all
}

get_current_player() {
    if [[ -f "$PLAYER_FILE" ]]; then
        cat "$PLAYER_FILE"
    else
        mapfile -t all_players < <(get_players)
        echo "${all_players[0]}"
    fi
}

set_current_player() {
    echo "$1" >"$PLAYER_FILE"
}

cycle_player() {
    mapfile -t players < <(get_players)
    current_player=$(get_current_player)

    if [[ ${#players[@]} -eq 0 ]]; then
        # No players running
        rm -f "$PLAYER_FILE"
        return
    fi

    for i in "${!players[@]}"; do
        if [[ "${players[$i]}" == "$current_player" ]]; then
            next_index=$(((i + 1) % ${#players[@]}))
            set_current_player "${players[$next_index]}"
            return
        fi
    done
    # If current_player is not in the list, set to first available
    set_current_player "${players[0]}"
}

SCROLL_INDEX_FILE="/tmp/playerctl_scroll_index"
LAST_SONG_FILE="/tmp/playerctl_last_song"

# ... (other functions remain the same) ...

player_status() {
    max_width=$1
    current_player=$(get_current_player)

    if [[ -z "$current_player" ]]; then
        echo "{\"text\": \"No Media\", \"tooltip\": \"No media player running\", \"alt\": \"Stopped\"}"
        return
    fi

    if playerctl --player="$current_player" status &>/dev/null; then
        artist=$(playerctl --player="$current_player" metadata artist 2>/dev/null)
        title=$(playerctl --player="$current_player" metadata title 2>/dev/null)
        album=$(playerctl --player="$current_player" metadata album 2>/dev/null)

        # Check if song has changed to reset scroll
        last_song=$(cat "$LAST_SONG_FILE" 2>/dev/null)
        if [[ "$title" != "$last_song" ]]; then
            echo "$title" > "$LAST_SONG_FILE"
            echo "0" > "$SCROLL_INDEX_FILE"
        fi

        position_us=$(playerctl --player="$current_player" position 2>/dev/null)
        duration_us=$(playerctl --player="$current_player" metadata mpris:length 2>/dev/null)

        position_us=${position_us%%.*}
        duration_us=${duration_us%%.*}

        position_s=$position_us
        duration_s=$((duration_us / 1000000))

        position_formatted=$(printf "%02d:%02d" $((position_s / 60)) $((position_s % 60)))
        duration_formatted=$(printf "%02d:%02d" $((duration_s / 60)) $((duration_s % 60)))

        player_status=$(playerctl --player="$current_player" status)

        status_icon="⏹" # Default to stopped
        if [[ "$player_status" == "Playing" ]]; then
            status_icon="▶"
        elif [[ "$player_status" == "Paused" ]]; then
            status_icon="⏸"
        fi

        time_info=""
        if [[ "$duration_s" -gt 0 ]]; then
            time_info=" (${position_formatted} / ${duration_formatted})"
        elif [[ "$position_s" -gt 0 ]]; then
            time_info=" (${position_formatted})"
        fi

        if [[ -n "$title" ]]; then
            display_title=$title
            if [[ -n "$max_width" && "${#title}" -gt "$max_width" ]]; then
                scroll_index=$(cat "$SCROLL_INDEX_FILE" 2>/dev/null || echo 0)
                
                # Add padding for seamless scrolling
                padded_title="$title   "
                
                display_title=$(echo "$padded_title" | cut -c$((scroll_index + 1))-$((scroll_index + max_width)))
                
                scroll_index=$(( (scroll_index + 1) % ${#padded_title} ))
                echo "$scroll_index" > "$SCROLL_INDEX_FILE"
            fi
            
            text="${status_icon} ${display_title}${time_info}"

            tooltip="${title}"
            if [[ -n "$artist" ]]; then
                tooltip="${tooltip}\nby ${artist}"
            fi
            if [[ -n "$album" ]]; then
                tooltip="${tooltip}\nfrom ${album}"
            fi
            tooltip="${tooltip}${time_info}"
            echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\", \"alt\": \"${player_status}\"}"
        else
            echo "{\"text\": \"No Media\", \"tooltip\": \"No media playing\", \"alt\": \"Stopped\"}"
        fi
    else
        echo "{\"text\": \"No Media\", \"tooltip\": \"No media player running\", \"alt\": \"Stopped\"}"
    fi
}

# ... (player_command remains the same) ...

case "$1" in
toggle)
    player_command play-pause
    ;;
next)
    player_command next
    ;;
prev)
    player_command previous
    ;;
player-next)
    cycle_player
    player_status
    ;;
listen)
    max_width=${2:-20} # Default max-width to 20
    last_output=""
    while true; do
        current_output=$(player_status "$max_width")
        if [[ "$current_output" != "$last_output" ]]; then
            echo "$current_output"
            last_output=$current_output
        fi
        sleep 1
    done
    ;;
*)
    player_status
    ;;
esac
