#!/usr/bin/env bash

# Kill old bars
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# ---------------------------------------------------------
# AUTO-DETECT MONITOR
# ---------------------------------------------------------
PRIMARY_MONITOR=$(xrandr --query | grep " connected" | grep -v "HDMI" | head -n1 | cut -d" " -f1)

if [ -z "$PRIMARY_MONITOR" ]; then
  PRIMARY_MONITOR=$(xrandr --query | grep " connected" | head -n1 | cut -d" " -f1)
fi

echo "Detected Monitor: $PRIMARY_MONITOR"

# ---------------------------------------------------------
# LAUNCH THE BARS
# ---------------------------------------------------------

# Export the variable so the config can read it
export MONITOR=$PRIMARY_MONITOR

# Launch your 6 specific bars
# (I grabbed these names directly from your config file)
for bar in main pam2 pam6 pam3 pam4 pam5; do
    polybar -q $bar -c ~/.config/polybar/pamela/config.ini &
done

echo "Bars launched on $PRIMARY_MONITOR"