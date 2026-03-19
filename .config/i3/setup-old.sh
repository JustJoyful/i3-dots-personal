#!/bin/bash

# --- 1. SETUP ENVIRONMENT ---
# Ensure the script can find 'wal' and 'calc'
export PATH="$HOME/.local/bin:$PATH"

# Kill existing instances
killall -q polybar nitrogen

# Wait for them to die (prevents conflicts)
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# --- 2. SETUP MONITORS ---
xrandr --output DP-2 --primary --mode 1920x1080 --rate 144 --output HDMI-0 --mode 1366x768 --rate 60 --left-of DP-2
sleep 1

# --- 3. GENERATE COLORS (The Critical Step) ---
# We run this in the FOREGROUND (no '&' at the end).
# The script waits here until colors.ini is fully updated.
# IGNORE "Remote control disabled" errors here. It is normal.
/usr/bin/bash ~/.config/polybar/docky/scripts/pywal.sh /home/joydeepwm/Pictures/wallpaper.png

# --- 4. LAUNCH POLYBAR ---
# Now that colors.ini is ready, we launch the bar.
# Ensure 'docky' matches the name in your config [bar/docky]
polybar -q docky -c ~/.config/polybar/pamela/launch.sh &

# --- 5. WALLPAPER ---
#nitrogen --restore &

echo "Bars launched..."
