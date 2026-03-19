#!/bin/bash

# 1. Dynamically find the active connected monitor
MONITOR=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)

# Safety check
if [ -z "$MONITOR" ]; then
    notify-send -u critical "Display Error" "No connected monitor found!"
    exit 1
fi

# 2. Define Resolution
RESOLUTION="1920x1080"

# 3. Get Current Refresh Rate (CORRECTED)
# grep -o matches ONLY the exact pattern "numbers + dot + numbers + *" (e.g., 60.00*)
# sed removes the asterisk
CURRENT_RATE=$(xrandr | grep -A 20 "$MONITOR" | grep -o "[0-9.]\+\*" | sed 's/\*//')

# Convert to integer (truncating decimals)
RATE_INT=${CURRENT_RATE%.*}

# Debugging (Uncomment to test if needed)
# notify-send "Debug" "Detected: $RATE_INT Hz"

# 4. Toggle Logic
# We use 60 as the baseline. If it's effectively 60 (or 59), go high.
# If it's anything clearly higher than 60, go low.
if [ "$RATE_INT" -gt 80 ]; then
    # Currently High -> Switch to 60Hz
    xrandr --output "$MONITOR" --mode "$RESOLUTION" --rate 60
    notify-send -u low "Battery Saver ($MONITOR)" "Switched to 60Hz"
else
    # Currently Low -> Switch to 144Hz
    xrandr --output "$MONITOR" --mode "$RESOLUTION" --rate 144
    notify-send -u normal "Performance ($MONITOR)" "Switched to 144Hz"
fi

if [ -f "$HOME/.config/polybar/docku/launch.sh" ]; then
    "$HOME/.config/polybar/dock/launch.sh" &
