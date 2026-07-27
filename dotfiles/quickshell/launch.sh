#!/bin/bash

set -euo pipefail

# Kill any running instances
qs kill 2>/dev/null || true
pkill -x qs 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true
pkill -x statusbar 2>/dev/null || true
pkill -x gjs 2>/dev/null || true
pkill -x swaync 2>/dev/null || true

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl not found; is Hyprland running?" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; please install jq" >&2
    exit 1
fi

HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')

if [ -z "$HYPRLAND_SIGNATURE" ] || [ "$HYPRLAND_SIGNATURE" = "null" ]; then
    echo "Could not determine Hyprland instance signature" >&2
    exit 1
fi

export HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE"

# ~/.config/quickshell is a multi-config dir; run this config by its own path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec qs -d -p "$SCRIPT_DIR"
