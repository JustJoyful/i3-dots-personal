#!/usr/bin/env bash

# Force the theme
theme="$HOME/.config/rofi/powermenu/glass.rasi"

# DEFINE OPTIONS WITH ICONS
# Format: "Text Label \0icon\x1f Icon-Name-In-Papirus"
shutdown="Shutdown\0icon\x1fsystem-shutdown"
reboot="Reboot\0icon\x1fsystem-reboot"
lock="Lock\0icon\x1fsystem-lock-screen"
suspend="Suspend\0icon\x1fsystem-suspend"
logout="Logout\0icon\x1fsystem-log-out"

# COMMAND
# -markup-rows enables the icon syntax
rofi_cmd="rofi -dmenu -theme $theme -p Power -markup-rows -selected-row 2"

# RUN
chosen="$(echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$logout" | $rofi_cmd)"

# ACTIONS (Strip the icon code to check the result)
case $chosen in
    *Shutdown*) systemctl poweroff ;;
    *Reboot*)   systemctl reboot ;;
    *Lock*)     i3lock -c 000000 ;;
    *Suspend*)  systemctl suspend ;;
    *Logout*)   i3-msg exit ;;
esac
