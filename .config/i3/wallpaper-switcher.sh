#!/usr/bin/env bash

#  ╦ ╦╔═╗╦  ╦  ╔═╗╔═╗╔═╗╔═╗╦═╗  ╔═╗╦ ╦╦╔╦╗╔═╗╦ ╦
#  ║║║╠═╣║  ║  ╠═╝╠═╣╠═╝║╣ ╠╦╝  ╚═╗║║║║║ ║ ║  ╠═╣
#  ╚╩╝╩ ╩╩═╝╩═╝╩  ╩ ╩╩  ╚═╝╩╚═  ╚═╝╚╩╝╩ ╩ ╚═╝╩ ╩
#
#  Wallpaper switcher with pywal16 + optimized color generation
#  
#  Features:
#  - High saturation (0.9) & contrast (1.2) for vibrant, readable colors
#  - Uses bright colors (color9-15) for better visibility
#  - Optimized for VSCode wal theme + terminal readability
#  - Prevents "mushy" low-contrast color schemes
#  - Rofi menu with thumbnail icons

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
I3_CONFIG="$HOME/.config/i3/config"
KITTY_CONF_DIR="$HOME/.config/kitty"
KITTY_MAIN="$KITTY_CONF_DIR/kitty.conf"
KITTY_COLORS="$KITTY_CONF_DIR/colors.conf"
CURRENT_WALL="$HOME/.config/.current_wallpaper"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_msg() { echo -e "${!1}$2${NC}"; }

# List wallpapers
list_wallpapers() {
    print_msg CYAN "═══════════════════════════════════"
    print_msg CYAN "     Available Wallpapers"
    print_msg CYAN "═══════════════════════════════════"
    echo
    
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort))
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        print_msg RED "No wallpapers found!"
        print_msg YELLOW "Add .jpg or .png files to: $WALLPAPER_DIR"
        exit 1
    fi
    
    local current=$(cat "$CURRENT_WALL" 2>/dev/null)
    
    for i in "${!wallpapers[@]}"; do
        local name=$(basename "${wallpapers[$i]}")
        if [ "${wallpapers[$i]}" == "$current" ]; then
            print_msg GREEN "  ➜ $((i+1)). $name (current)"
        else
            echo "    $((i+1)). $name"
        fi
    done
    echo
}

# Apply wallpaper and colors
apply_wallpaper() {
    local wallpaper=$1
    
    if [ ! -f "$wallpaper" ]; then
        print_msg RED "Error: File not found: $wallpaper"
        exit 1
    fi
    
    local name=$(basename "$wallpaper")
    print_msg YELLOW "╭──────────────────────────────────────╮"
    print_msg YELLOW "│  Applying: $name"
    print_msg YELLOW "╰──────────────────────────────────────╯"
    echo
    
    # 1. Generate colors with DIVERSITY FOCUS (especially for monochrome wallpapers)
    print_msg BLUE "  → Generating diverse color palette..."
    
    # STRATEGY for monochrome/low-color wallpapers:
    # - colorz backend extracts more diverse colors from limited palettes
    # - Maximum saturation (1.0) forces vibrant colors even from grayscale
    # - This prevents "all blue" or "all gray" color schemes
    
    print_msg CYAN "    Using colorz backend for maximum color diversity..."
    
    # Primary: colorz with max saturation (best for monochrome images)
    if wal -i "$wallpaper" --backend colorz -n -q --saturate 1.0 2>/dev/null; then
        :
    # Fallback 1: wal backend with very high saturation
    elif wal -i "$wallpaper" --backend wal -n -q --saturate 0.95 2>/dev/null; then
        :
    # Fallback 2: haishoku backend (good color extraction)
    elif wal -i "$wallpaper" --backend haishoku -n -q --saturate 1.0 2>/dev/null; then
        :
    # Final fallback: default with maximum saturation
    else
        wal -i "$wallpaper" -n -q --saturate 1.0 || \
        wal -i "$wallpaper" -n -q
    fi
    
    # Verify colors were generated
    if [ ! -f "$HOME/.cache/wal/colors.sh" ]; then
        print_msg RED "Error: Color generation failed"
        exit 1
    fi
    
    # 2. Set wallpaper
    print_msg BLUE "  → Setting wallpaper..."
    feh --bg-fill "$wallpaper"
    
    # 3. Update i3 colors (SAFE - only replaces content between markers)
    print_msg BLUE "  → Updating i3 colors..."
    source "$HOME/.cache/wal/colors.sh"
    
    # Build the color block (ENHANCED for pywal16 - uses bright colors)
    local color_block="####### PYWAL COLORS #######
# Base colors (0-7)
set \$bg         $color0
set \$red        $color1
set \$green      $color2
set \$yellow     $color3
set \$blue       $color4
set \$purple     $color5
set \$cyan       $color6
set \$fg         $color7

# Bright colors (8-15) - pywal16
set \$bg1        $color8
set \$bred       $color9
set \$bgreen     $color10
set \$byellow    $color11
set \$bblue      $color12
set \$bpurple    $color13
set \$bcyan      $color14
set \$fg1        $color15

# Aliases
set \$bg2        $foreground
set \$grey       $color8
set \$orange     $color3
set \$pink       $color5
set \$aqua       $color6

# target                 title        bg          text        indicator    brdr
client.focused           \$bpurple    \$bpurple   \$bg        \$bpurple    \$bpurple
client.unfocused         \$bg         \$bg1       \$fg        \$bg1        \$bg1
client.urgent            \$bred       \$bred      \$bg        \$bred       \$bred
client.placeholder       \$bg         \$bg        \$fg        \$bg         \$bg
client.background        \$bg
####### END PYWAL COLORS #######"
    
    # Replace content between markers (preserves everything else)
    awk -v new_block="$color_block" '
    /####### PYWAL COLORS #######/ { 
        print new_block
        skip=1
        next 
    }
    /####### END PYWAL COLORS #######/ { 
        skip=0
        next 
    }
    !skip { print }
    ' "$I3_CONFIG" > "${I3_CONFIG}.tmp" && mv "${I3_CONFIG}.tmp" "$I3_CONFIG"
    
    # 4. Update Kitty colors (SAFE - separate colors.conf file)
    print_msg BLUE "  → Updating Kitty colors..."
    
    if [ -f "$HOME/.cache/wal/colors-kitty.conf" ]; then
        cat > "$KITTY_COLORS" << EOF
# Pywal Colors - Auto-generated
# Wallpaper: $name
# Generated: $(date)

EOF
        cat "$HOME/.cache/wal/colors-kitty.conf" >> "$KITTY_COLORS"
    else
        print_msg YELLOW "  Warning: Pywal kitty colors not found"
    fi
    
    # 5. Save current wallpaper
    echo "$wallpaper" > "$CURRENT_WALL"
    
   # 6. Reload i3 (needed for colors) and kitty
    print_msg BLUE "  → Reloading i3 and kitty..."
    i3-msg reload >/dev/null 2>&1
    killall -SIGUSR1 kitty 2>/dev/null || true
    
    # Enforce gaps after reload settles
    print_msg BLUE "  → Enforcing layout..."
    sleep 0.2
    i3-msg gaps top all set 45 >/dev/null 2>&1
    # --- THE SAFETY NET ---
    # Wait for the reload to settle (2 seconds), then force the gaps.
    # This runs AFTER smart_monitor.sh, ensuring the gaps win.
    #print_msg BLUE "  → Enforcing layout..."
    #sleep 2
    # >/dev/null 2>&1

    echo
    print_msg GREEN "✓ Done! Wallpaper and colors applied"
}

# --- ROFI MENU WITH ICONS ---
rofi_select() {
    # 1. Create Thumbnails Directory
    mkdir -p "$THUMB_DIR"
    
    # 2. Build the list with Icons
    # Syntax: "Name \0icon\x1f Path/To/Image"
    local list=""
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort))
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        print_msg RED "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    local current=$(cat "$CURRENT_WALL" 2>/dev/null)
    
    # Loop through wallpapers
    for wall in "${wallpapers[@]}"; do
        local name=$(basename "$wall")
        local thumb="$THUMB_DIR/${name%.*}.jpg"
        
        # Create thumbnail if missing (Resize to 100px for speed)
        if [ ! -f "$thumb" ]; then
            echo -ne "Generating preview for $name...\r"
            convert "$wall" -thumbnail 100x100^ -gravity center -extent 100x100 "$thumb"
        fi
        
        # Mark current wallpaper with checkmark
        if [ "$wall" == "$current" ]; then
            list+="✓ $name\0icon\x1f$thumb\n"
        else
            list+="$name\0icon\x1f$thumb\n"
        fi
    done
    
    echo # Clear progress line
    
    # 3. Show Rofi with icons
    local selected=$(echo -e "$list" | rofi -dmenu -i -show-icons -p "🖼️  Select Wallpaper" -theme ~/.config/rofi/launchers/misc/blurry.rasi)
    
    # 4. Apply Selection
    if [ -n "$selected" ]; then
        # Remove checkmark if present
        selected=$(echo "$selected" | sed 's/^✓ //')
        
        for wall in "${wallpapers[@]}"; do
            if [ "$(basename "$wall")" == "$selected" ]; then
                apply_wallpaper "$wall"
                break
            fi
        done
    fi
}

# Random wallpaper
random_wallpaper() {
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \)))
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        print_msg RED "No wallpapers found!"
        exit 1
    fi
    
    local random_wall="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    apply_wallpaper "$random_wall"
}

# Interactive terminal menu
interactive_select() {
    list_wallpapers
    
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort))
    
    print_msg CYAN "Select wallpaper (1-${#wallpapers[@]}), 'r' for random, or 'q' to quit: "
    read -r choice
    
    case "$choice" in
        q|Q) print_msg YELLOW "Exiting..."; exit 0 ;;
        r|R) random_wallpaper ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#wallpapers[@]}" ]; then
                apply_wallpaper "${wallpapers[$((choice-1))]}"
            else
                print_msg RED "Invalid choice!"
                sleep 1
                interactive_select
            fi
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
Wallpaper Switcher with Pywal16 + Optimized Colors for VSCode & Terminal

Usage: $(basename $0) [OPTION] [FILE]

Options:
    -r, --rofi          Show rofi menu with thumbnail icons
    -l, --list          List available wallpapers
    -a, --apply FILE    Apply specific wallpaper
    -R, --random        Apply random wallpaper
    -t, --thumbs        Regenerate all thumbnails
    -h, --help          Show this help
    
    Without options: Interactive terminal menu

Examples:
    $(basename $0)                              # Interactive menu
    $(basename $0) --rofi                       # Rofi menu with icons
    $(basename $0) --apply ~/Pictures/wall.jpg  # Apply specific
    $(basename $0) --random                     # Random wallpaper

Directory: $WALLPAPER_DIR
Thumbnails: $THUMB_DIR

What it does:
  1. Generates HIGH-CONTRAST colors with pywal16 (--saturate 0.9, --contrast 1.2)
  2. Optimized for readability in VSCode, terminals, and i3
  3. Uses BRIGHT colors (color9-color15) for better visibility
  4. Updates i3 border colors with vibrant, distinct colors
  5. Updates kitty terminal colors (separate colors.conf)
  6. Sets wallpaper with feh
  7. Shows thumbnail icons in rofi menu

Color Optimization:
  - High saturation (0.9) for vibrant, distinct colors
  - Increased contrast (1.2) for better text readability
  - Bright color variants for focused elements
  - Prevents "mushy" colors that reduce readability
  - Perfect for VSCode wal theme extension + terminal use

Requirements:
  - feh (wallpaper setter)
  - imagemagick (thumbnail generation)
  - pywal16 (16-color generation) - installed via pipx
  - rofi (menu with -show-icons support)

Optimized for:
  ✓ VSCode with wal theme extension (clear syntax highlighting)
  ✓ Terminal text readability (kitty, alacritty, etc.)
  ✓ i3 window manager (distinct window borders)
  ✓ Prevents low-contrast "muddy" color schemes

Safe operation:
  - Uses markers in i3 config (####### PYWAL COLORS #######)
  - Separate colors.conf for kitty
  - Preserves all your custom settings

EOF
}

# Main argument handler
case "${1:-}" in
    -r|--rofi)
        rofi_select
        ;;
    -l|--list)
        list_wallpapers
        ;;
    -a|--apply)
        if [ -n "${2:-}" ]; then
            apply_wallpaper "$2"
        else
            print_msg RED "Error: Please specify wallpaper path"
            show_help
        fi
        ;;
    -R|--random)
        random_wallpaper
        ;;
    -t|--thumbs)
        print_msg YELLOW "Regenerating all thumbnails..."
        rm -rf "$THUMB_DIR"
        mkdir -p "$THUMB_DIR"
        print_msg GREEN "✓ Run with --rofi to regenerate on demand"
        ;;
    -h|--help)
        show_help
        ;;
    "")
        interactive_select
        ;;
    *)
        print_msg RED "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
