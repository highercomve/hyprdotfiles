#!/usr/bin/env bash

cd "$(dirname "$0")"

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate and install dependencies
source .venv/bin/activate
echo "Installing dependencies (ytmusicapi, yt-dlp)..."
pip install --upgrade pip
pip install ytmusicapi yt-dlp

echo "Dependencies installed successfully in .venv/"
