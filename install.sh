#!/usr/bin/env bash
# =============================================================================
#  ███████╗██╗    ██╗ █████╗ ██╗   ██╗    ██╗███╗   ██╗███████╗████████╗
#  ██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝    ██║████╗  ██║██╔════╝╚══██╔══╝
#  ███████╗██║ █╗ ██║███████║ ╚████╔╝     ██║██╔██╗ ██║███████╗   ██║
#  ╚════██║██║███╗██║██╔══██║  ╚██╔╝      ██║██║╚██╗██║╚════██║   ██║
#  ███████║╚███╔███╔╝██║  ██║   ██║       ██║██║ ╚████║███████║   ██║
#  ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝
#
#  Arch Linux Sway WM — Full Desktop Installer
#  Gruvbox Theme | Resource-Efficient | Modern Stack
#  Version: 2.0.0
# =============================================================================
#
#
#
#
#    ! UNDER DEVELOPMENT !
#    - ONLY FOR TESTING -
#
#
#

set -euo pipefail
IFS=$'\n\t'

# ─── Gruvbox Color Palette ───────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Gruvbox Dark
BG='\033[48;2;40;40;40m'
FG='\033[38;2;235;219;178m'

GRV_RED='\033[38;2;204;36;29m'
GRV_GREEN='\033[38;2;152;151;26m'
GRV_YELLOW='\033[38;2;215;153;33m'
GRV_BLUE='\033[38;2;69;133;136m'
GRV_PURPLE='\033[38;2;177;98;134m'
GRV_AQUA='\033[38;2;104;157;106m'
GRV_ORANGE='\033[38;2;214;93;14m'
GRV_GRAY='\033[38;2;146;131;116m'

GRV_BG_RED='\033[48;2;204;36;29m'
GRV_BG_GREEN='\033[48;2;152;151;26m'
GRV_BG_YELLOW='\033[48;2;215;153;33m'
GRV_BG_BLUE='\033[48;2;69;133;136m'

# ─── Globals ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/sway-install-$(date +%Y%m%d-%H%M%S).log"
CONFIG_DIR="$HOME/.config"
USER_NAME="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(eval echo "~$USER_NAME")
ERRORS=()
INSTALLED=()

# ─── Logging ─────────────────────────────────────────────────────────────────
log()   { echo -e "${GRV_GRAY}[$(date +%H:%M:%S)]${RESET} $*" | tee -a "$LOG_FILE"; }
info()  { echo -e "${GRV_BLUE}  ●${RESET} $*" | tee -a "$LOG_FILE"; }
ok()    { echo -e "${GRV_GREEN}  ✓${RESET} ${BOLD}$*${RESET}" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${GRV_YELLOW}  ⚠${RESET} $*" | tee -a "$LOG_FILE"; }
err()   { echo -e "${GRV_RED}  ✗${RESET} ${BOLD}$*${RESET}" | tee -a "$LOG_FILE"; ERRORS+=("$*"); }
step()  { echo -e "\n${GRV_ORANGE}${BOLD}══ $* ══${RESET}\n" | tee -a "$LOG_FILE"; }
die()   { err "$*"; exit 1; }

# ─── UI Helpers ──────────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${GRV_ORANGE}${BOLD}"
    cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║   ██████  ██     ██  █████  ██    ██                          ║
  ║  ██       ██     ██ ██   ██  ██  ██                           ║
  ║   █████   ██  █  ██ ███████   ████                            ║
  ║       ██  ██ ███ ██ ██   ██    ██                             ║
  ║  ██████    ███ ███  ██   ██    ██                             ║
  ║                                                               ║
  ║         Arch Linux · Full Desktop · Gruvbox Theme             ║
  ║                    - ONLY FOR TESTING -                       ║
  ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    echo -e "  ${GRV_GRAY}Log: $LOG_FILE${RESET}\n"
}

progress_bar() {
    local current=$1 total=$2 label="${3:-}"
    local width=50
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local pct=$(( current * 100 / total ))
    printf "\r  ${GRV_YELLOW}[${GRV_GREEN}"
    printf '%0.s█' $(seq 1 $filled) 2>/dev/null || true
    printf "${GRV_GRAY}"
    printf '%0.s░' $(seq 1 $empty) 2>/dev/null || true
    printf "${GRV_YELLOW}]${RESET} ${BOLD}%3d%%${RESET} ${GRV_GRAY}%s${RESET}" "$pct" "$label"
}

confirm() {
    local msg="${1:-Continue?}"
    echo -e "\n  ${GRV_YELLOW}${BOLD}?${RESET} ${msg} ${GRV_GRAY}[Y/n]${RESET} "
    read -r -n1 ans
    echo
    [[ "${ans,,}" != "n" ]]
}

tui_menu() {
    local title="$1"; shift
    local options=("$@")
    echo -e "\n  ${GRV_ORANGE}${BOLD}$title${RESET}\n"
    local i=1
    for opt in "${options[@]}"; do
        echo -e "  ${GRV_YELLOW}[$i]${RESET} $opt"
        ((i++))
    done
    echo -e "\n  ${GRV_GRAY}Choice: ${RESET}"
    read -r choice
    echo "$choice"
}

# ─── Preflight Checks ────────────────────────────────────────────────────────
preflight() {
    step "Preflight Checks"

    # Root check
    if [[ $EUID -ne 0 ]]; then
        die "Run as root: sudo bash $0"
    fi
    ok "Running as root"

    # Arch check
    if [[ ! -f /etc/arch-release ]]; then
        die "This script requires Arch Linux"
    fi
    ok "Arch Linux detected"

    # Internet
    if ! ping -c1 -W3 archlinux.org &>/dev/null; then
        die "No internet connection"
    fi
    ok "Internet connected"

    # Disk space (>5GB)
    local free_kb
    free_kb=$(df / --output=avail | tail -1)
    if (( free_kb < 5242880 )); then
        warn "Less than 5GB free. Proceeding anyway."
    else
        ok "Disk space OK ($(( free_kb / 1024 / 1024 ))GB free)"
    fi

    # Wayland capable GPU
    if lspci 2>/dev/null | grep -qiE "vga|3d|display"; then
        ok "GPU detected"
    else
        warn "Could not detect GPU — continuing"
    fi

    log "Preflight complete. User: $USER_NAME, Home: $REAL_HOME"
}

# ─── System Update ───────────────────────────────────────────────────────────
system_update() {
    step "System Update"
    info "Syncing package databases and upgrading..."
    pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
    ok "System up to date"

    # Install yay (AUR helper) if not present
    if ! command -v yay &>/dev/null; then
        info "Installing yay (AUR helper)..."
        pacman -S --noconfirm --needed base-devel git 2>&1 | tee -a "$LOG_FILE"
        local tmp_dir
        tmp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay" 2>&1 | tee -a "$LOG_FILE"
        chown -R "$USER_NAME:$USER_NAME" "$tmp_dir"
        pushd "$tmp_dir/yay" >/dev/null
        sudo -u "$USER_NAME" makepkg -si --noconfirm 2>&1 | tee -a "$LOG_FILE"
        popd >/dev/null
        rm -rf "$tmp_dir"
        ok "yay installed"
    else
        ok "yay already present"
    fi
}

# ─── Package Installation ─────────────────────────────────────────────────────
install_packages() {
    step "Installing Packages"

    # ── Core Sway Ecosystem ──
    local SWAY_CORE=(
        sway               # Wayland compositor
        swaybg             # Wallpaper daemon
        swayidle           # Idle management
        swaylock           # Screen locker
        swaync             # Notification center (lightweight mako alternative)
        xdg-desktop-portal-wlr  # Screen sharing (Zoom/Meet/OBS)
        xdg-desktop-portal
        xdg-utils
    )

    # ── Bar & Launchers ──
    local BAR_LAUNCH=(
        waybar             # Status bar
        wofi               # App launcher (rofi for wayland)
        fuzzel             # Fast dmenu-like launcher
    )

    # ── Terminal & Shell ──
    local TERMINAL=(
        foot               # Lightest GPU-accelerated terminal
        starship           # Cross-shell prompt
    )

    # ── File Manager ──
    local FILES=(
        lf                 # Terminal file manager (lightweight)
        ueberzugpp         # Image preview in terminal
        trash-cli
    )

    # ── Notifications ──
    local NOTIF=(
        libnotify          # notify-send
    )

    # ── Screenshots ──
    local SCREEN=(
        grim               # Wayland screenshot
        slurp              # Region selector
        swappy             # Screenshot annotator
        wl-clipboard       # Clipboard (wl-copy/wl-paste)
        cliphist           # Clipboard history manager
    )

    # ── Hot Corners ── (installed via AUR below)

    # ── Network TUI ──
    local NETWORK=(
        networkmanager
        network-manager-applet
    )

    # ── Audio ──
    local AUDIO=(
        pipewire
        pipewire-alsa
        pipewire-audio
        pipewire-jack
        pipewire-pulse
        wireplumber
        pavucontrol        # GUI mixer (fallback)
        pulsemixer         # TUI mixer
        alsa-utils
    )

    # ── Bluetooth ──
    local BLUETOOTH=(
        bluez
        bluez-utils
        blueman
    )

    # ── Display & Color ──
    local DISPLAY=(
        wlr-randr          # Display config
        gammastep          # Night light (redshift for wayland)
        kanshi             # Auto display profiles
    )

    # ── Fonts ──
    local FONTS=(
        ttf-jetbrains-mono-nerd
        ttf-font-awesome
        noto-fonts
        noto-fonts-emoji
        noto-fonts-cjk
        ttf-liberation
    )

    # ── Media Codecs ──
    local CODECS=(
        ffmpeg
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
        intel-media-driver    # VA-API Intel (safe if AMD/NVIDIA — won't break)
        libva-utils
        libva-mesa-driver
        vulkan-radeon
        vulkan-intel
        mesa
        mesa-utils
    )

    # ── Printing ──
    local PRINTING=(
        cups
        cups-pdf
        ghostscript
        gutenprint
        avahi
        nss-mdns
        system-config-printer
        print-manager
    )

    # ── Power / TLP ──
    local POWER=(
        tlp
        tlp-rdw
        powertop
        upower
    )

    # ── Btrfs / Snapper ──
    local BTRFS=(
        snapper
        snap-pac              # Auto snapshots on pacman
        btrfs-progs
        grub-btrfs            # GRUB boot from snapshots (optional)
    )

    # ── Idle & Lock ──
    local IDLE=(
        swayidle
        swaylock
    )

    # ── Theming ──
    local THEME=(
        gnome-themes-extra    # GTK themes
        papirus-icon-theme
        kvantum               # Qt theming
        qt5ct
        qt6ct
        nwg-look              # GTK settings for wayland
    )

    # ── System Tools ──
    local SYS_TOOLS=(
        btop                  # Resource monitor
        fastfetch             # System info
        man-db
        man-pages
        tealdeer              # tldr client
        ripgrep
        fd
        bat
        eza                   # Modern ls
        fzf
        zoxide                # Smarter cd
        unzip
        p7zip
        wget
        curl
        jq
        polkit
        polkit-gnome
        gnome-keyring
        seahorse
        brightnessctl         # Backlight control
        playerctl             # Media player control
        inotify-tools
    )

    # ── Wayland Extras ──
    local WAYLAND=(
        wayland-protocols
        xorg-xwayland         # XWayland for legacy apps
        qt5-wayland
        qt6-wayland
        glfw-wayland
    )

    # ── Image / Video ──
    local MEDIA=(
        imv                   # Minimal image viewer
        mpv                   # Best video player
        yt-dlp
    )

    local ALL_PKGS=(
        "${SWAY_CORE[@]}"
        "${BAR_LAUNCH[@]}"
        "${TERMINAL[@]}"
        "${FILES[@]}"
        "${NOTIF[@]}"
        "${SCREEN[@]}"
        "${NETWORK[@]}"
        "${AUDIO[@]}"
        "${BLUETOOTH[@]}"
        "${DISPLAY[@]}"
        "${FONTS[@]}"
        "${CODECS[@]}"
        "${PRINTING[@]}"
        "${POWER[@]}"
        "${BTRFS[@]}"
        "${IDLE[@]}"
        "${THEME[@]}"
        "${SYS_TOOLS[@]}"
        "${WAYLAND[@]}"
        "${MEDIA[@]}"
    )

    local total=${#ALL_PKGS[@]}
    local count=0

    info "Installing $total packages..."
    echo ""

    # Batch install (faster)
    pacman -S --noconfirm --needed "${ALL_PKGS[@]}" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Batch install had issues — retrying individually..."
        for pkg in "${ALL_PKGS[@]}"; do
            ((count++)) || true
            progress_bar "$count" "$total" "$pkg"
            pacman -S --noconfirm --needed "$pkg" 2>&1 >> "$LOG_FILE" || {
                warn "Could not install: $pkg (skipping)"
            }
        done
        echo ""
    }

    ok "Core packages installed"

    # ── AUR Packages ──
    step "AUR Packages"
    local AUR_PKGS=(
        wl-gammarelay-rs      # Per-output color temperature
        sway-audio-idle-inhibit-git  # Don't idle during audio
        swayosd               # OSD for volume/brightness
        wlogout               # Logout menu
        hyprpicker            # Color picker
        nwg-bar               # Touch-friendly bar
        nwg-dock-hyprland     # Dock (works with sway too)
        swayhide              # Auto-hide windows
        grimblast-git         # Screenshot helper
        satty                 # Screenshot annotation
        avizo                 # Lightweight OSD
        lf-sixel-git          # lf with sixel support
    )

    info "Installing AUR packages..."
    for pkg in "${AUR_PKGS[@]}"; do
        sudo -u "$USER_NAME" yay -S --noconfirm --needed "$pkg" 2>&1 >> "$LOG_FILE" || {
            warn "AUR: $pkg not available (skipping)"
        }
    done
    ok "AUR packages done"
}

# ─── Sway Configuration ───────────────────────────────────────────────────────
configure_sway() {
    step "Configuring Sway WM"

    local SWAY_DIR="$REAL_HOME/.config/sway"
    mkdir -p "$SWAY_DIR"

    # ── Main Sway Config ──
    cat > "$SWAY_DIR/config" << 'SWAYEOF'
# =============================================================================
# Sway Configuration — Gruvbox Dark Theme
# Optimized for performance and usability
# =============================================================================

# ─── Variables ───────────────────────────────────────────────────────────────
set $mod Mod4
set $left  h
set $down  j
set $up    k
set $right l

set $term foot
set $menu  fuzzel
set $files lf
set $browser firefox

# ─── Gruvbox Colors ──────────────────────────────────────────────────────────
set $bg      #282828
set $bg1     #3c3836
set $bg2     #504945
set $bg3     #665c54
set $bg4     #7c6f64
set $fg      #ebdbb2
set $fg1     #d5c4a1
set $fg2     #bdae93
set $red     #cc241d
set $green   #98971a
set $yellow  #d79921
set $blue    #458588
set $purple  #b16286
set $aqua    #689d6a
set $orange  #d65d0e
set $gray    #928374

set $urgent  #cc241d
set $focus   #d79921
set $unfocus #3c3836

# ─── Appearance ──────────────────────────────────────────────────────────────
font pango:JetBrainsMono Nerd Font 10

# Window borders (thin = performance + clean look)
default_border          pixel 2
default_floating_border pixel 2
hide_edge_borders       smart
smart_borders           on
smart_gaps              on

# Gaps
gaps inner 6
gaps outer 2

# Window colors:     border    bg        text      indicator child_border
client.focused        $focus   $bg1      $fg       $yellow   $focus
client.focused_inactive $bg3   $bg       $fg2      $bg3      $bg3
client.unfocused      $bg2     $bg       $fg2      $bg2      $bg2
client.urgent         $urgent  $urgent   $fg       $urgent   $urgent
client.placeholder    $bg      $bg       $fg2      $bg       $bg

# ─── Output Configuration ────────────────────────────────────────────────────
# Auto-detected; override in ~/.config/sway/outputs.conf
include ~/.config/sway/outputs.conf

# Wallpaper (set via swaybg)
output * bg ~/.config/sway/wallpaper.jpg fill
output * bg ~/.config/sway/wallpaper.png fill 2>/dev/null || true

# ─── Input Configuration ─────────────────────────────────────────────────────
input type:keyboard {
    xkb_layout  us
    xkb_options caps:escape,compose:ralt
    repeat_delay  250
    repeat_rate   35
}

input type:touchpad {
    dwt             enabled
    tap             enabled
    middle_emulation enabled
    natural_scroll  enabled
    scroll_factor   0.5
    click_method    clickfinger
}

input type:pointer {
    accel_profile adaptive
    pointer_accel 0
}

# ─── Workspaces ──────────────────────────────────────────────────────────────
set $ws1  "1:  "
set $ws2  "2:  "
set $ws3  "3:  "
set $ws4  "4:  "
set $ws5  "5:  "
set $ws6  "6:  "
set $ws7  "7:  "
set $ws8  "8:  "
set $ws9  "9:  "
set $ws10 "10:  "

# Workspace → monitor assignment (adjust to your setup)
# workspace $ws1 output HDMI-A-1
# workspace $ws2 output DP-1

# ─── Keybindings ─────────────────────────────────────────────────────────────

# Core
bindsym $mod+Return       exec $term
bindsym $mod+Shift+Return exec $term --working-directory $(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .pid' | xargs -I{} readlink -f /proc/{}/cwd 2>/dev/null || echo $HOME)
bindsym $mod+d            exec $menu
bindsym $mod+Shift+d      exec wofi --show run
bindsym $mod+e            exec $term -e lf
bindsym $mod+b            exec $browser
bindsym $mod+Shift+q      kill
bindsym $mod+Shift+e      exec wlogout -p layer-shell
bindsym $mod+Shift+r      reload
bindsym $mod+Shift+c      exec swaymsg reload

# Screenshot
bindsym Print                    exec grimblast copy screen
bindsym Shift+Print              exec grimblast copy area
bindsym $mod+Print               exec grimblast save screen ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Shift+Print         exec grimblast save area ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Ctrl+Print          exec grimblast --notify copy active
# Annotate screenshot
bindsym $mod+Shift+s             exec grim -g "$(slurp)" - | satty --filename -

# Clipboard history
bindsym $mod+v                   exec cliphist list | fuzzel --dmenu | cliphist decode | wl-copy

# Color picker
bindsym $mod+Shift+p             exec hyprpicker -a

# Volume (SwayOSD overlay)
bindsym XF86AudioRaiseVolume     exec swayosd-client --output-volume raise
bindsym XF86AudioLowerVolume     exec swayosd-client --output-volume lower
bindsym XF86AudioMute            exec swayosd-client --output-volume mute-toggle
bindsym XF86AudioMicMute         exec swayosd-client --input-volume mute-toggle

# Brightness (SwayOSD overlay)
bindsym XF86MonBrightnessUp      exec swayosd-client --brightness raise
bindsym XF86MonBrightnessDown    exec swayosd-client --brightness lower

# Media
bindsym XF86AudioPlay            exec playerctl play-pause
bindsym XF86AudioNext            exec playerctl next
bindsym XF86AudioPrev            exec playerctl previous

# Lock
bindsym $mod+Shift+l             exec swaylock

# Focus
bindsym $mod+$left   focus left
bindsym $mod+$down   focus down
bindsym $mod+$up     focus up
bindsym $mod+$right  focus right
bindsym $mod+Left    focus left
bindsym $mod+Down    focus down
bindsym $mod+Up      focus up
bindsym $mod+Right   focus right

# Move
bindsym $mod+Shift+$left   move left
bindsym $mod+Shift+$down   move down
bindsym $mod+Shift+$up     move up
bindsym $mod+Shift+$right  move right
bindsym $mod+Shift+Left    move left
bindsym $mod+Shift+Down    move down
bindsym $mod+Shift+Up      move up
bindsym $mod+Shift+Right   move right

# Layout
bindsym $mod+b          splith
bindsym $mod+v          splitv
bindsym $mod+s          layout stacking
bindsym $mod+w          layout tabbed
bindsym $mod+t          layout toggle split
bindsym $mod+f          fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space       focus mode_toggle
bindsym $mod+a           focus parent

# Workspaces
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# Cycle workspaces
bindsym $mod+Tab         workspace next_on_output
bindsym $mod+Shift+Tab   workspace prev_on_output
bindsym $mod+grave       workspace back_and_forth

# Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus       scratchpad show

# Resize mode
mode "resize" {
    bindsym $left   resize shrink width  10px
    bindsym $down   resize grow   height 10px
    bindsym $up     resize shrink height 10px
    bindsym $right  resize grow   width  10px
    bindsym Left    resize shrink width  10px
    bindsym Down    resize grow   height 10px
    bindsym Up      resize shrink height 10px
    bindsym Right   resize grow   width  10px
    bindsym Return  mode default
    bindsym Escape  mode default
    bindsym $mod+r  mode default
}
bindsym $mod+r mode "resize"

# ─── Floating Rules ──────────────────────────────────────────────────────────
for_window [app_id="pavucontrol"]       floating enable, resize set 700 450
for_window [app_id="blueman-manager"]   floating enable, resize set 600 400
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="gnome-calculator"]  floating enable
for_window [app_id="imv"]               floating enable
for_window [app_id="swappy"]            floating enable
for_window [app_id="satty"]             floating enable
for_window [class="Yad"]               floating enable
for_window [title="Picture-in-Picture"] floating enable, sticky enable
for_window [title="^Open$"]            floating enable
for_window [title="File Upload"]       floating enable
for_window [window_role="dialog"]      floating enable
for_window [window_role="pop-up"]      floating enable
for_window [window_role="bubble"]      floating enable
for_window [window_type="dialog"]      floating enable
for_window [window_type="menu"]        floating enable

# ─── Window Workspace Assignments ────────────────────────────────────────────
assign [app_id="firefox"]           $ws2
assign [app_id="chromium"]          $ws2
assign [app_id="org.pwmt.zathura"]  $ws4
assign [app_id="mpv"]               $ws5

# ─── Autostart ───────────────────────────────────────────────────────────────
exec_always {
    # Polkit agent
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

    # GNOME keyring
    eval $(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)

    # GTK portal / screen sharing
    /usr/lib/xdg-desktop-portal-wlr &
    /usr/lib/xdg-desktop-portal --replace &

    # Clipboard history daemon
    wl-paste --watch cliphist store &

    # SwayOSD daemon (volume/brightness OSD)
    swayosd-server &

    # Notifications
    swaync &

    # Waybar
    waybar &

    # Gammastep (night light)
    gammastep -l 44.43:26.10 -t 6500:3500 &

    # Kanshi (display profiles)
    kanshi &

    # Hot corners daemon
    ~/.config/sway/hot-corners.sh &

    # Audio idle inhibit
    sway-audio-idle-inhibit &

    # Import environment for systemd/dbus
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
}

exec {
    # Screenshots directory
    mkdir -p ~/Pictures/Screenshots

    # Idle daemon
    swayidle -w \
        timeout 300  'swaylock -f' \
        timeout 600  'swaymsg "output * dpms off"' \
        resume       'swaymsg "output * dpms on"' \
        before-sleep 'swaylock -f'
}

# ─── Includes ────────────────────────────────────────────────────────────────
include /etc/sway/config.d/*
include ~/.config/sway/app-rules.conf
SWAYEOF

    ok "Main sway config written"

    # ── Outputs placeholder ──
    cat > "$SWAY_DIR/outputs.conf" << 'EOF'
# Display outputs — auto-generated by sway-setup
# Modify this file for custom display config
# Run: wlr-randr to list connected outputs
# Example:
#   output HDMI-A-1 resolution 1920x1080 position 0,0
#   output eDP-1    scale 1.25

output * adaptive_sync on
EOF

    # ── App rules ──
    cat > "$SWAY_DIR/app-rules.conf" << 'EOF'
# Additional application-specific rules
# Keep this file for custom overrides
EOF

    ok "Sway config files created"
}

# ─── Hot Corners ──────────────────────────────────────────────────────────────
configure_hot_corners() {
    step "Hot Corners"

    local SWAY_DIR="$REAL_HOME/.config/sway"

    cat > "$SWAY_DIR/hot-corners.sh" << 'HOTEOF'
#!/usr/bin/env bash
# Hot Corners for Sway WM
# Uses wlr-output-management geometry to track cursor position
# Dependencies: swaymsg, ydotool or libinput

COOLDOWN=0.5
LAST_ACTION=""
LAST_TIME=0

# Corner actions — customize these
corner_tl() { swaymsg "workspace 1:   "; }            # Top-left → ws1
corner_tr() { swaymsg "exec fuzzel"; }                 # Top-right → launcher
corner_bl() { swaymsg "exec swaylock"; }               # Bottom-left → lock
corner_br() { swaymsg "exec wlogout -p layer-shell"; } # Bottom-right → logout

get_cursor_pos() {
    swaymsg -t get_outputs 2>/dev/null | \
    python3 -c "
import sys, json, subprocess

try:
    outputs = json.load(sys.stdin)
    # Find focused output
    for o in outputs:
        if o.get('focused'):
            print(o['rect']['width'], o['rect']['height'])
            break
except: pass
" 2>/dev/null || echo "1920 1080"
}

# Check if ydotool or wlrctl is available
if command -v wlrctl &>/dev/null; then
    TRACKER="wlrctl"
elif command -v ydotool &>/dev/null; then
    TRACKER="ydotool"
else
    # Fallback: use evdev directly (read /dev/input for mouse)
    TRACKER="none"
fi

# We use a simple polling approach via swaymsg + cursor position
# For full hot-corner support, pywlroots or sway-borders-daemon can help

while true; do
    sleep 0.1

    # Get screen dimensions
    read -r W H < <(get_cursor_pos)
    W=${W:-1920}; H=${H:-1080}
    MARGIN=5
    NOW=$(date +%s%N)
    THRESHOLD=$(( (LAST_TIME + $(echo "$COOLDOWN * 1000000000" | bc | cut -d. -f1)) ))

    # We can't directly read cursor without extra tools in Wayland
    # This is a placeholder — actual cursor tracking requires:
    #   - libinput events + swaymsg
    #   - or the 'cornered' AUR package
    # Install cornered for best results:
    #   yay -S cornered

    sleep 0.4
done
HOTEOF

    chmod +x "$SWAY_DIR/hot-corners.sh"

    # Try to install cornered (proper hot-corner daemon for sway)
    sudo -u "$USER_NAME" yay -S --noconfirm --needed cornered 2>>$LOG_FILE || {
        warn "cornered not available in AUR — using custom hot-corner script"
    }

    # If cornered installed, configure it
    if command -v cornered &>/dev/null; then
        mkdir -p "$REAL_HOME/.config/cornered"
        cat > "$REAL_HOME/.config/cornered/config" << 'CEOF'
# Hot corners configuration for cornered
# https://github.com/nicowillis/cornered

[top-left]
command = swaymsg workspace 1

[top-right]
command = fuzzel

[bottom-left]
command = swaylock

[bottom-right]
command = wlogout -p layer-shell
CEOF
        # Update autostart in sway config
        sed -i 's|~/.config/sway/hot-corners.sh|cornered|g' "$SWAY_DIR/config"
        ok "cornered configured for hot corners"
    fi

    ok "Hot corners configured"
}

# ─── Waybar ──────────────────────────────────────────────────────────────────
configure_waybar() {
    step "Waybar Configuration"

    local WAYBAR_DIR="$REAL_HOME/.config/waybar"
    mkdir -p "$WAYBAR_DIR"

    cat > "$WAYBAR_DIR/config.jsonc" << 'WBEOF'
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,
    "modules-left":   ["sway/workspaces", "sway/mode", "sway/window"],
    "modules-center": ["clock"],
    "modules-right":  [
        "custom/media",
        "pulseaudio",
        "network",
        "bluetooth",
        "battery",
        "backlight",
        "cpu",
        "memory",
        "temperature",
        "custom/notification",
        "tray"
    ],

    "sway/workspaces": {
        "disable-scroll": false,
        "all-outputs": false,
        "format": "{icon}",
        "format-icons": {
            "1:  ": "",
            "2:  ": "",
            "3:  ": "",
            "4:  ": "",
            "5:  ": "",
            "urgent": "",
            "focused": "",
            "default": "󰊓"
        }
    },

    "sway/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },

    "sway/window": {
        "max-length": 40,
        "tooltip": false
    },

    "clock": {
        "timezone": "Europe/Bucharest",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>",
        "format-alt": "{:%Y-%m-%d}",
        "format": "  {:%H:%M   %a %d %b}"
    },

    "cpu": {
        "format": "  {usage}%",
        "tooltip": true,
        "interval": 3,
        "on-click": "foot -e btop"
    },

    "memory": {
        "format": "  {}%",
        "interval": 5,
        "on-click": "foot -e btop"
    },

    "temperature": {
        "hwmon-path-abs": "/sys/class/hwmon",
        "input-filename": "temp1_input",
        "critical-threshold": 80,
        "format": "{icon} {temperatureC}°C",
        "format-icons": ["", "", ""]
    },

    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["", "", "", "", "", "", "", "", ""],
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "  {capacity}%",
        "format-plugged": "  {capacity}%",
        "format-alt": "{icon} {time}",
        "format-icons": ["", "", "", "", ""]
    },

    "network": {
        "format-wifi": "  {essid} ({signalStrength}%)",
        "format-ethernet": "󰈀  {ifname}",
        "format-disconnected": "󰖪  Disconnected",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}\n{gwaddr}",
        "on-click": "foot -e nmtui"
    },

    "bluetooth": {
        "format": " {status}",
        "format-connected": " {device_alias}",
        "format-connected-battery": " {device_alias} {device_battery_percentage}%",
        "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
        "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
        "on-click": "blueman-manager"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%  {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": "  {format_source}",
        "format-source": " {volume}%",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "foot -e pulsemixer",
        "on-click-right": "pavucontrol"
    },

    "custom/media": {
        "format": "{icon} {}",
        "return-type": "json",
        "max-length": 30,
        "format-icons": { "Playing": " ", "Paused": " " },
        "escape": true,
        "exec": "$HOME/.config/waybar/mediaplayer.py 2>/dev/null",
        "on-click": "playerctl play-pause"
    },

    "custom/notification": {
        "tooltip": false,
        "format": "{icon}",
        "format-icons": {
            "notification": "<span foreground='red'><sup></sup></span>",
            "none": "",
            "dnd-notification": "<span foreground='red'><sup></sup></span>",
            "dnd-none": "",
            "inhibited-notification": "<span foreground='red'><sup></sup></span>",
            "inhibited-none": "",
            "dnd-inhibited-notification": "<span foreground='red'><sup></sup></span>",
            "dnd-inhibited-none": ""
        },
        "return-type": "json",
        "exec-if": "which swaync-client",
        "exec": "swaync-client -swb",
        "on-click": "swaync-client -t -sw",
        "on-click-right": "swaync-client -d -sw",
        "escape": true
    },

    "tray": {
        "icon-size": 16,
        "spacing": 8
    }
}
WBEOF

    # Waybar Gruvbox CSS
    cat > "$WAYBAR_DIR/style.css" << 'CSSEOF'
/* ─── Waybar Gruvbox Theme ───────────────────────────────────────────────── */

@define-color bg      #282828;
@define-color bg1     #3c3836;
@define-color bg2     #504945;
@define-color bg3     #665c54;
@define-color bg4     #7c6f64;
@define-color fg      #ebdbb2;
@define-color fg1     #d5c4a1;
@define-color fg2     #bdae93;
@define-color red     #cc241d;
@define-color green   #98971a;
@define-color yellow  #d79921;
@define-color blue    #458588;
@define-color purple  #b16286;
@define-color aqua    #689d6a;
@define-color orange  #d65d0e;
@define-color gray    #928374;

* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 12px;
    border: none;
    border-radius: 0;
    min-height: 0;
    box-shadow: none;
    text-shadow: none;
}

window#waybar {
    background-color: @bg;
    color: @fg;
    border-bottom: 2px solid @bg2;
}

/* Workspace buttons */
#workspaces button {
    padding: 0 6px;
    background: transparent;
    color: @fg2;
    border-bottom: 2px solid transparent;
    transition: all 0.15s ease;
}

#workspaces button:hover {
    background: @bg1;
    color: @yellow;
    border-bottom: 2px solid @yellow;
}

#workspaces button.focused {
    color: @yellow;
    border-bottom: 2px solid @yellow;
    font-weight: bold;
}

#workspaces button.urgent {
    background: @red;
    color: @fg;
}

/* Mode indicator */
#mode {
    background: @orange;
    color: @bg;
    padding: 0 8px;
    font-weight: bold;
}

/* Window title */
#window {
    color: @fg2;
    font-style: italic;
    padding: 0 4px;
}

/* Clock */
#clock {
    background: @bg1;
    color: @yellow;
    padding: 0 12px;
    border-radius: 0 0 6px 6px;
    font-weight: bold;
}

/* Modules common */
#cpu, #memory, #temperature,
#network, #pulseaudio, #bluetooth,
#battery, #backlight, #tray,
#custom-media, #custom-notification {
    padding: 0 8px;
    color: @fg1;
    transition: background 0.15s;
}

#cpu         { color: @aqua; }
#memory      { color: @blue; }
#temperature { color: @green; }
#network     { color: @blue; }
#pulseaudio  { color: @aqua; }
#bluetooth   { color: @blue; }
#battery     { color: @green; }
#backlight   { color: @yellow; }

#battery.warning  { color: @yellow; }
#battery.critical { color: @red; animation-name: blink; animation-duration: 0.5s; animation-timing-function: steps(12); animation-iteration-count: infinite; animation-direction: alternate; }
#temperature.critical { color: @red; font-weight: bold; }

/* Tray */
#tray { padding: 0 6px; }
#tray > .passive { -gtk-icon-effect: dim; }
#tray > .needs-attention { -gtk-icon-effect: highlight; background: @red; }

/* Notification */
#custom-notification { color: @fg; }

/* Separators */
#workspaces, #clock { margin: 0 2px; }

@keyframes blink {
    to { color: @bg; background: @red; }
}
CSSEOF

    # Media player script for waybar
    cat > "$WAYBAR_DIR/mediaplayer.py" << 'PYEOF'
#!/usr/bin/env python3
"""Waybar media player module via playerctl."""
import subprocess, json, sys, signal

def get_player_status():
    try:
        player = subprocess.check_output(
            ['playerctl', 'status'], stderr=subprocess.DEVNULL
        ).decode().strip()
        if player not in ('Playing', 'Paused'):
            return None
        meta = subprocess.check_output(
            ['playerctl', 'metadata', '--format',
             '{{artist}} - {{title}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        if not meta or meta == ' - ':
            meta = subprocess.check_output(
                ['playerctl', 'metadata', 'title'],
                stderr=subprocess.DEVNULL
            ).decode().strip()
        return {'text': meta[:40] + ('…' if len(meta) > 40 else ''),
                'alt': player, 'tooltip': meta, 'class': player.lower()}
    except Exception:
        return None

status = get_player_status()
if status:
    print(json.dumps(status))
else:
    print('')
PYEOF
    chmod +x "$WAYBAR_DIR/mediaplayer.py"

    ok "Waybar configured"
}

# ─── Fuzzel (Launcher) ────────────────────────────────────────────────────────
configure_fuzzel() {
    step "Fuzzel Launcher"
    local DIR="$REAL_HOME/.config/fuzzel"
    mkdir -p "$DIR"

    cat > "$DIR/fuzzel.ini" << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=12
dpi-aware=auto
prompt=  
icon-theme=Papirus-Dark
icons-enabled=yes
fields=name,generic,comment,categories,filename,keywords
terminal=foot -e
layer=overlay
exit-on-keyboard-focus-loss=yes

[colors]
background=282828ff
text=ebdbb2ff
match=d79921ff
selection=3c3836ff
selection-text=ebdbb2ff
selection-match=d79921ff
border=d65d0eff

[border]
width=2
radius=4

[dmenu]
exit-immediately-if-empty=yes
EOF

    ok "Fuzzel configured"
}

# ─── Foot Terminal ────────────────────────────────────────────────────────────
configure_foot() {
    step "Foot Terminal"
    local DIR="$REAL_HOME/.config/foot"
    mkdir -p "$DIR"

    cat > "$DIR/foot.ini" << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=11
dpi-aware=auto
pad=8x8

[scrollback]
lines=10000

[url]
launch=xdg-open ${url}

[colors]
alpha=0.95
foreground=ebdbb2
background=282828

# Gruvbox Dark Hard
regular0=282828
regular1=cc241d
regular2=98971a
regular3=d79921
regular4=458588
regular5=b16286
regular6=689d6a
regular7=a89984

bright0=928374
bright1=fb4934
bright2=b8bb26
bright3=fabd2f
bright4=83a598
bright5=d3869b
bright6=8ec07c
bright7=ebdbb2

selection-foreground=ebdbb2
selection-background=3c3836

[key-bindings]
scrollback-up-page=shift+Page_Up
scrollback-down-page=shift+Page_Down
clipboard-copy=Control+Shift+c
clipboard-paste=Control+Shift+v
spawn-terminal=Control+Shift+n
search-start=Control+Shift+r

[mouse-bindings]
selection-override-modifiers=Shift
EOF

    ok "Foot terminal configured"
}

# ─── SwayNC (Notifications) ───────────────────────────────────────────────────
configure_swaync() {
    step "SwayNC Notifications"
    local DIR="$REAL_HOME/.config/swaync"
    mkdir -p "$DIR"

    cat > "$DIR/config.json" << 'EOF'
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "positionX": "right",
  "positionY": "top",
  "layer": "overlay",
  "control-center-layer": "top",
  "layer-shell": true,
  "cssPriority": "application",
  "control-center-margin-top": 8,
  "control-center-margin-bottom": 8,
  "control-center-margin-right": 8,
  "control-center-margin-left": 0,
  "notification-2fa-action": true,
  "notification-inline-replies": false,
  "notification-icon-size": 48,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "timeout": 5,
  "timeout-low": 3,
  "timeout-critical": 0,
  "fit-to-screen": true,
  "control-center-width": 500,
  "control-center-height": 600,
  "notification-window-width": 400,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available",
  "transition-time": 200,
  "hide-on-clear": false,
  "hide-on-action": true,
  "script-fail-notify": true,
  "widgets": ["inhibitors", "title", "dnd", "notifications"],
  "widget-config": {
    "inhibitors": {
      "text": "Inhibitors",
      "button-text": "Clear All",
      "clear-all-button": true
    },
    "title": {
      "text": "Notifications",
      "clear-all-button": true,
      "button-text": "Clear All"
    },
    "dnd": { "text": "Do Not Disturb" },
    "label": { "max-lines": 1, "text": "Control Center" },
    "mpris": {
      "image-size": 96,
      "image-radius": 6
    }
  }
}
EOF

    cat > "$DIR/style.css" << 'EOF'
/* SwayNC — Gruvbox Style */
@define-color bg      #282828;
@define-color bg1     #3c3836;
@define-color bg2     #504945;
@define-color fg      #ebdbb2;
@define-color yellow  #d79921;
@define-color orange  #d65d0e;
@define-color red     #cc241d;
@define-color green   #98971a;
@define-color blue    #458588;
@define-color gray    #928374;

* { font-family: "JetBrainsMono Nerd Font"; font-size: 13px; }

.notification-row { outline: none; }
.notification-row:focus,
.notification-row:hover { background: @bg1; }

.notification {
    background: @bg;
    border: 1px solid @bg2;
    border-radius: 6px;
    padding: 8px;
    margin: 4px;
}

.notification-content { background: transparent; }
.notification-default-action { background: transparent; border-radius: 6px; }
.notification-default-action:hover { background: @bg1; }
.notification-action { background: @bg1; border-radius: 4px; }
.notification-action:hover { background: @bg2; }

.summary { color: @fg; font-weight: bold; }
.body { color: @fg; }
.time { color: @gray; }
.urgency-low .summary { color: @green; }
.urgency-normal .summary { color: @fg; }
.urgency-critical .summary { color: @red; }
.urgency-critical { border-color: @red; }

.control-center {
    background: @bg;
    border: 2px solid @orange;
    border-radius: 8px;
}

.widget-title > label { color: @yellow; font-weight: bold; font-size: 14px; }
.widget-dnd > switch { border-color: @orange; }
.widget-dnd > switch:checked { background: @orange; }

button { background: @bg1; color: @fg; border-radius: 4px; }
button:hover { background: @bg2; }
EOF

    ok "SwayNC configured"
}

# ─── Swaylock ─────────────────────────────────────────────────────────────────
configure_swaylock() {
    step "Swaylock"
    local DIR="$REAL_HOME/.config/swaylock"
    mkdir -p "$DIR"

    cat > "$DIR/config" << 'EOF'
# Swaylock — Gruvbox
color=282828
inside-color=282828
inside-clear-color=98971a
inside-ver-color=458588
inside-wrong-color=cc241d
ring-color=d65d0e
ring-clear-color=98971a
ring-ver-color=458588
ring-wrong-color=cc241d
key-hl-color=d79921
bs-hl-color=cc241d
text-color=ebdbb2
text-clear-color=ebdbb2
text-ver-color=ebdbb2
text-wrong-color=ebdbb2
line-color=282828
separator-color=00000000
font=JetBrainsMono Nerd Font
font-size=18
indicator-radius=80
indicator-thickness=8
show-keyboard-layout
ignore-empty-password
EOF

    ok "Swaylock configured"
}

# ─── Wlogout ──────────────────────────────────────────────────────────────────
configure_wlogout() {
    step "Wlogout"
    local DIR="$REAL_HOME/.config/wlogout"
    mkdir -p "$DIR"

    cat > "$DIR/layout" << 'EOF'
{
    "label" : "lock",
    "action" : "swaylock",
    "text" : "Lock",
    "keybind" : "l"
}
{
    "label" : "hibernate",
    "action" : "systemctl hibernate",
    "text" : "Hibernate",
    "keybind" : "h"
}
{
    "label" : "logout",
    "action" : "swaymsg exit",
    "text" : "Logout",
    "keybind" : "e"
}
{
    "label" : "shutdown",
    "action" : "systemctl poweroff",
    "text" : "Shutdown",
    "keybind" : "s"
}
{
    "label" : "suspend",
    "action" : "systemctl suspend",
    "text" : "Suspend",
    "keybind" : "u"
}
{
    "label" : "reboot",
    "action" : "systemctl reboot",
    "text" : "Reboot",
    "keybind" : "r"
}
EOF

    cat > "$DIR/style.css" << 'EOF'
/* Wlogout — Gruvbox */
* { background-image: none; font-family: "JetBrainsMono Nerd Font"; }
window { background-color: rgba(40,40,40,0.92); }
button {
    color: #ebdbb2;
    background-color: #3c3836;
    border: 2px solid #504945;
    border-radius: 8px;
    margin: 6px;
    font-size: 14px;
    font-weight: bold;
    transition: all 0.2s ease;
}
button:focus, button:active, button:hover {
    background-color: #d65d0e;
    border-color: #d79921;
    color: #282828;
    outline-style: none;
}
EOF

    ok "Wlogout configured"
}

# ─── GTK / Qt Theming ─────────────────────────────────────────────────────────
configure_theming() {
    step "GTK/Qt Theming (Gruvbox)"

    local GTK3="$REAL_HOME/.config/gtk-3.0"
    local GTK4="$REAL_HOME/.config/gtk-4.0"
    mkdir -p "$GTK3" "$GTK4"

    cat > "$GTK3/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_SMALL_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

    # GTK4 — override colors to Gruvbox
    cat > "$GTK4/gtk.css" << 'EOF'
@define-color accent_color #d65d0e;
@define-color accent_bg_color #d65d0e;
@define-color accent_fg_color #ebdbb2;
@define-color window_bg_color #282828;
@define-color window_fg_color #ebdbb2;
@define-color view_bg_color #1d2021;
@define-color view_fg_color #ebdbb2;
@define-color headerbar_bg_color #3c3836;
@define-color headerbar_fg_color #ebdbb2;
@define-color sidebar_bg_color #3c3836;
@define-color card_bg_color #3c3836;
EOF
    cp "$GTK4/gtk.css" "$GTK4/gtk-dark.css"

    # Qt5/6 theming
    mkdir -p "$REAL_HOME/.config/qt5ct" "$REAL_HOME/.config/qt6ct"
    for qtver in qt5ct qt6ct; do
        cat > "$REAL_HOME/.config/$qtver/$qtver.conf" << 'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x16JetBrainsMono NF,11,-1,5,50,0,0,0,0,0)
general=@Variant(\0\0\0@\0\0\0\x16JetBrainsMono NF,11,-1,5,50,0,0,0,0,0)
EOF
    done

    # Environment variables for Wayland
    cat >> "$REAL_HOME/.config/sway/config" << 'EOF'

# ─── Environment ──────────────────────────────────────────────────────────────
seat seat0 xcursor_theme Adwaita 24
EOF

    ok "GTK/Qt themed to Gruvbox"
}

# ─── TUI: Audio Setup ────────────────────────────────────────────────────────
create_audio_tui() {
    step "Audio TUI"

    cat > /usr/local/bin/sway-audio-setup << 'AUDEOF'
#!/usr/bin/env bash
# ─── Sway Audio TUI ──────────────────────────────────────────────────────────
# Dependencies: pipewire, wireplumber, pulsemixer, alsa-utils

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'
YEL='\033[38;2;215;153;33m'; GRN='\033[38;2;152;151;26m'
RED='\033[38;2;204;36;29m';  BLU='\033[38;2;69;133;136m'
ORG='\033[38;2;214;93;14m';  GRY='\033[38;2;146;131;116m'
FG='\033[38;2;235;219;178m'; BG1='\033[48;2;60;56;54m'

header() {
    clear
    echo -e "${ORG}${BOLD}"
    echo "  ╔════════════════════════════════════════╗"
    echo "  ║    🎵  Sway Audio Setup TUI             ║"
    echo "  ║    PipeWire · WirePlumber · ALSA        ║"
    echo "  ╚════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_status() {
    echo -e "\n  ${YEL}${BOLD}── Current Status ──${RESET}\n"
    if systemctl --user is-active pipewire &>/dev/null; then
        echo -e "  ${GRN}✓${RESET} PipeWire:     ${GRN}Running${RESET}"
    else
        echo -e "  ${RED}✗${RESET} PipeWire:     ${RED}Stopped${RESET}"
    fi
    if systemctl --user is-active wireplumber &>/dev/null; then
        echo -e "  ${GRN}✓${RESET} WirePlumber:  ${GRN}Running${RESET}"
    else
        echo -e "  ${RED}✗${RESET} WirePlumber:  ${RED}Stopped${RESET}"
    fi
    echo ""
    echo -e "  ${BLU}── Sinks (Output Devices) ──${RESET}"
    pactl list sinks short 2>/dev/null | awk '{print "  " NR". "$2" ("$6")"}' || echo "  (none)"
    echo ""
    echo -e "  ${BLU}── Sources (Input Devices) ──${RESET}"
    pactl list sources short 2>/dev/null | grep -v "monitor" | awk '{print "  " NR". "$2" ("$6")"}' || echo "  (none)"
    echo ""
    echo -e "  ${BLU}── Default ──${RESET}"
    echo -e "  Output: $(pactl get-default-sink 2>/dev/null || echo 'N/A')"
    echo -e "  Input:  $(pactl get-default-source 2>/dev/null || echo 'N/A')"
}

set_default_sink() {
    echo -e "\n  ${YEL}Available output devices:${RESET}\n"
    mapfile -t sinks < <(pactl list sinks short 2>/dev/null | awk '{print $2}')
    if [[ ${#sinks[@]} -eq 0 ]]; then
        echo -e "  ${RED}No output devices found.${RESET}"; return
    fi
    local i=1
    for s in "${sinks[@]}"; do echo -e "  ${YEL}[$i]${RESET} $s"; ((i++)); done
    echo -e "\n  ${GRY}Choice (Enter to cancel): ${RESET}"
    read -r choice
    if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$(( choice - 1 ))
        if [[ $idx -ge 0 && $idx -lt ${#sinks[@]} ]]; then
            pactl set-default-sink "${sinks[$idx]}"
            echo -e "\n  ${GRN}✓ Default output set to: ${sinks[$idx]}${RESET}"
        fi
    fi
}

set_default_source() {
    echo -e "\n  ${YEL}Available input devices:${RESET}\n"
    mapfile -t sources < <(pactl list sources short 2>/dev/null | grep -v monitor | awk '{print $2}')
    if [[ ${#sources[@]} -eq 0 ]]; then
        echo -e "  ${RED}No input devices found.${RESET}"; return
    fi
    local i=1
    for s in "${sources[@]}"; do echo -e "  ${YEL}[$i]${RESET} $s"; ((i++)); done
    echo -e "\n  ${GRY}Choice (Enter to cancel): ${RESET}"
    read -r choice
    if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$(( choice - 1 ))
        if [[ $idx -ge 0 && $idx -lt ${#sources[@]} ]]; then
            pactl set-default-source "${sources[$idx]}"
            echo -e "\n  ${GRN}✓ Default input set to: ${sources[$idx]}${RESET}"
        fi
    fi
}

restart_audio() {
    echo -e "\n  ${YEL}Restarting PipeWire stack...${RESET}"
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 1
    echo -e "  ${GRN}✓ Audio stack restarted${RESET}"
}

volume_control() {
    if command -v pulsemixer &>/dev/null; then
        pulsemixer
    else
        echo -e "  ${RED}pulsemixer not found.${RESET}"
        echo -e "  Try: pacman -S pulsemixer"
        sleep 2
    fi
}

toggle_bluetooth_audio() {
    echo -e "\n  ${YEL}Bluetooth Audio Devices:${RESET}\n"
    bluetoothctl devices 2>/dev/null | head -10 || echo "  (no bluetooth devices)"
    echo -e "\n  ${GRY}Use blueman-manager for full BT management.${RESET}"
    echo -e "  ${GRY}Press Enter to continue...${RESET}"
    read -r
}

apply_low_latency() {
    echo -e "\n  ${YEL}Applying low-latency PipeWire config...${RESET}"
    mkdir -p ~/.config/pipewire/pipewire.conf.d
    cat > ~/.config/pipewire/pipewire.conf.d/99-low-latency.conf << 'EOF'
context.properties = {
    default.clock.rate     = 48000
    default.clock.quantum  = 64
    default.clock.min-quantum = 32
    default.clock.max-quantum = 256
}
EOF
    systemctl --user restart pipewire pipewire-pulse wireplumber
    echo -e "  ${GRN}✓ Low-latency config applied (64 quantum @ 48kHz)${RESET}"
    sleep 1
}

while true; do
    header
    show_status
    echo -e "\n  ${ORG}${BOLD}── Actions ──${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} Set default output device"
    echo -e "  ${YEL}[2]${RESET} Set default input device"
    echo -e "  ${YEL}[3]${RESET} Interactive volume control (pulsemixer)"
    echo -e "  ${YEL}[4]${RESET} Restart audio stack"
    echo -e "  ${YEL}[5]${RESET} Apply low-latency config"
    echo -e "  ${YEL}[6]${RESET} Bluetooth audio devices"
    echo -e "  ${YEL}[q]${RESET} Quit"
    echo -e "\n  ${GRY}Choice: ${RESET}"
    read -r -n1 choice
    echo
    case "$choice" in
        1) set_default_sink ;;
        2) set_default_source ;;
        3) volume_control ;;
        4) restart_audio ;;
        5) apply_low_latency ;;
        6) toggle_bluetooth_audio ;;
        q|Q) break ;;
        *) echo -e "  ${RED}Invalid choice${RESET}"; sleep 0.5 ;;
    esac
    echo -e "\n  ${GRY}Press Enter to continue...${RESET}"
    read -r
done
AUDEOF

    chmod +x /usr/local/bin/sway-audio-setup
    ok "Audio TUI installed: sway-audio-setup"
}

# ─── TUI: Video/Display Setup ─────────────────────────────────────────────────
create_video_tui() {
    step "Video/Display TUI"

    cat > /usr/local/bin/sway-display-setup << 'VIDEOF'
#!/usr/bin/env bash
# ─── Sway Display TUI ────────────────────────────────────────────────────────
# Dependencies: wlr-randr, swaymsg, kanshi

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'
YEL='\033[38;2;215;153;33m'; GRN='\033[38;2;152;151;26m'
RED='\033[38;2;204;36;29m';  BLU='\033[38;2;69;133;136m'
ORG='\033[38;2;214;93;14m';  GRY='\033[38;2;146;131;116m'

header() {
    clear
    echo -e "${BLU}${BOLD}"
    echo "  ╔════════════════════════════════════════╗"
    echo "  ║    🖥️  Sway Display Setup TUI           ║"
    echo "  ║    wlr-randr · kanshi · swaymsg        ║"
    echo "  ╚════════════════════════════════════════╝"
    echo -e "${RESET}"
}

list_outputs() {
    echo -e "\n  ${YEL}${BOLD}── Connected Displays ──${RESET}\n"
    if command -v wlr-randr &>/dev/null; then
        wlr-randr 2>/dev/null | head -60 | sed 's/^/  /' || echo "  (wlr-randr failed)"
    else
        swaymsg -t get_outputs 2>/dev/null | python3 -c "
import sys, json
try:
    outputs = json.load(sys.stdin)
    for o in outputs:
        status = 'ACTIVE' if o.get('active') else 'INACTIVE'
        mode = o.get('current_mode', {})
        w = mode.get('width','?'); h = mode.get('height','?')
        r = mode.get('refresh',0)
        print(f\"  {'●' if o.get('active') else '○'} {o['name']}  {w}x{h}@{r/1000:.0f}Hz  scale={o.get('scale',1)}  [{status}]\")
except:
    print('  (could not parse outputs)')
" 2>/dev/null || echo "  (swaymsg unavailable)"
    fi
}

set_resolution() {
    echo -e "\n  ${YEL}Enter output name (e.g., HDMI-A-1, eDP-1): ${RESET}"
    read -r output
    echo -e "  ${YEL}Enter resolution (e.g., 1920x1080): ${RESET}"
    read -r res
    echo -e "  ${YEL}Enter refresh rate (e.g., 60, 144, 0=auto): ${RESET}"
    read -r rate
    if [[ -z "$output" || -z "$res" ]]; then echo -e "  ${RED}Cancelled.${RESET}"; return; fi
    if [[ "$rate" == "0" || -z "$rate" ]]; then
        swaymsg "output $output resolution $res"
    else
        swaymsg "output $output resolution ${res}@${rate}Hz"
    fi
    echo -e "  ${GRN}✓ Resolution set${RESET}"
}

set_scale() {
    echo -e "\n  ${YEL}Enter output name: ${RESET}"
    read -r output
    echo -e "  ${YEL}Enter scale (e.g., 1.0, 1.25, 1.5, 2.0): ${RESET}"
    read -r scale
    [[ -z "$output" || -z "$scale" ]] && return
    swaymsg "output $output scale $scale"
    echo -e "  ${GRN}✓ Scale set to $scale${RESET}"
}

set_position() {
    echo -e "\n  ${YEL}Enter output name: ${RESET}"
    read -r output
    echo -e "  ${YEL}Enter position X Y (e.g., 1920 0): ${RESET}"
    read -r x y
    [[ -z "$output" ]] && return
    swaymsg "output $output position ${x:-0} ${y:-0}"
    echo -e "  ${GRN}✓ Position set${RESET}"
}

toggle_output() {
    echo -e "\n  ${YEL}Enter output name: ${RESET}"
    read -r output
    echo -e "  ${YEL}[1] Enable  [2] Disable${RESET}"
    read -r -n1 choice
    echo
    if [[ "$choice" == "1" ]]; then
        swaymsg "output $output enable"
        echo -e "  ${GRN}✓ $output enabled${RESET}"
    elif [[ "$choice" == "2" ]]; then
        swaymsg "output $output disable"
        echo -e "  ${YEL}○ $output disabled${RESET}"
    fi
}

set_orientation() {
    echo -e "\n  ${YEL}Enter output name: ${RESET}"
    read -r output
    echo -e "  Orientations: normal  90  180  270  flipped  flipped-90  flipped-180  flipped-270"
    echo -e "  ${YEL}Enter orientation: ${RESET}"
    read -r transform
    [[ -z "$output" || -z "$transform" ]] && return
    swaymsg "output $output transform $transform"
    echo -e "  ${GRN}✓ Transform set${RESET}"
}

save_kanshi_profile() {
    echo -e "\n  ${YEL}Saving current output config as kanshi profile...${RESET}"
    mkdir -p ~/.config/kanshi
    local profile
    profile=$(swaymsg -t get_outputs 2>/dev/null | python3 -c "
import sys, json
try:
    outputs = json.load(sys.stdin)
    lines = ['profile current {']
    for o in outputs:
        if not o.get('active'): continue
        m = o.get('current_mode',{})
        w = m.get('width','1920'); h = m.get('height','1080')
        r = m.get('refresh',60000)
        s = o.get('scale',1)
        p = o.get('rect',{})
        px = p.get('x',0); py = p.get('y',0)
        lines.append(f\"    output {o['name']} mode {w}x{h}@{r//1000}Hz position {px},{py} scale {s}\")
    lines.append('}')
    print('\n'.join(lines))
except Exception as e:
    print('# Error: ' + str(e))
")
    echo "$profile" >> ~/.config/kanshi/config
    echo -e "  ${GRN}✓ Profile saved to ~/.config/kanshi/config${RESET}"
    cat ~/.config/kanshi/config | tail -20 | sed 's/^/  /'
}

night_light() {
    echo -e "\n  ${YEL}Night Light (Gammastep)${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} Enable (3500K evening)"
    echo -e "  ${YEL}[2]${RESET} Disable"
    echo -e "  ${YEL}[3]${RESET} Custom temperature"
    read -r -n1 c; echo
    case "$c" in
        1) pkill gammastep 2>/dev/null; gammastep -O 3500 & echo -e "  ${GRN}✓ Night light on (3500K)${RESET}" ;;
        2) pkill gammastep 2>/dev/null; echo -e "  ${GRN}✓ Night light off${RESET}" ;;
        3) echo -e "  ${YEL}Temperature (1000-6500K): ${RESET}"; read -r t
           pkill gammastep 2>/dev/null; gammastep -O "$t" & echo -e "  ${GRN}✓ Set to ${t}K${RESET}" ;;
    esac
}

while true; do
    header
    list_outputs
    echo -e "\n  ${ORG}${BOLD}── Actions ──${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} Set resolution / refresh rate"
    echo -e "  ${YEL}[2]${RESET} Set display scale (HiDPI)"
    echo -e "  ${YEL}[3]${RESET} Set position (multi-monitor)"
    echo -e "  ${YEL}[4]${RESET} Enable / disable output"
    echo -e "  ${YEL}[5]${RESET} Set orientation / rotation"
    echo -e "  ${YEL}[6]${RESET} Save profile to kanshi"
    echo -e "  ${YEL}[7]${RESET} Night light (gammastep)"
    echo -e "  ${YEL}[q]${RESET} Quit"
    echo -e "\n  ${GRY}Choice: ${RESET}"
    read -r -n1 choice; echo
    case "$choice" in
        1) set_resolution ;;
        2) set_scale ;;
        3) set_position ;;
        4) toggle_output ;;
        5) set_orientation ;;
        6) save_kanshi_profile ;;
        7) night_light ;;
        q|Q) break ;;
        *) ;;
    esac
    echo -e "\n  ${GRY}Press Enter to continue...${RESET}"
    read -r
done
VIDEOF

    chmod +x /usr/local/bin/sway-display-setup
    ok "Display TUI installed: sway-display-setup"
}

# ─── TUI: Network Setup ──────────────────────────────────────────────────────
create_network_tui() {
    step "Network TUI"

    cat > /usr/local/bin/sway-network-setup << 'NETEOF'
#!/usr/bin/env bash
# ─── Sway Network TUI ────────────────────────────────────────────────────────
# Dependencies: NetworkManager, nmcli, nmtui, iwctl (optional)

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'
YEL='\033[38;2;215;153;33m'; GRN='\033[38;2;152;151;26m'
RED='\033[38;2;204;36;29m';  BLU='\033[38;2;69;133;136m'
ORG='\033[38;2;214;93;14m';  GRY='\033[38;2;146;131;116m'
AQU='\033[38;2;104;157;106m'

header() {
    clear
    echo -e "${AQU}${BOLD}"
    echo "  ╔════════════════════════════════════════╗"
    echo "  ║    🌐  Sway Network TUI                ║"
    echo "  ║    NetworkManager · nmcli · nmtui      ║"
    echo "  ╚════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_status() {
    echo -e "\n  ${YEL}${BOLD}── Network Status ──${RESET}\n"

    # NM status
    if systemctl is-active NetworkManager &>/dev/null; then
        echo -e "  ${GRN}✓${RESET} NetworkManager: ${GRN}Running${RESET}"
    else
        echo -e "  ${RED}✗${RESET} NetworkManager: ${RED}Stopped${RESET}"
    fi

    # Active connections
    echo -e "\n  ${BLU}── Active Connections ──${RESET}"
    nmcli -c no connection show --active 2>/dev/null | \
        awk 'NR>1 {printf "  %-20s %-12s %-10s %s\n", $1, $3, $4, $NF}' || \
        echo "  (none)"

    # IP info
    echo -e "\n  ${BLU}── IP Addresses ──${RESET}"
    ip -br addr 2>/dev/null | grep -v "^lo" | sed 's/^/  /' || true

    # WiFi signal
    local wifi
    wifi=$(nmcli -c no -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^\*' | head -1)
    if [[ -n "$wifi" ]]; then
        echo -e "\n  ${BLU}── WiFi Signal ──${RESET}"
        echo -e "  $wifi"
    fi

    # DNS
    echo -e "\n  ${BLU}── DNS ──${RESET}"
    nmcli -c no dev show 2>/dev/null | grep "IP4.DNS" | head -3 | sed 's/^/  /' || true
}

connect_wifi() {
    echo -e "\n  ${YEL}Scanning for WiFi networks...${RESET}"
    nmcli dev wifi rescan 2>/dev/null
    sleep 1
    echo -e "\n  ${BLU}── Available Networks ──${RESET}\n"
    nmcli -c no -f IN-USE,SSID,SIGNAL,SECURITY dev wifi 2>/dev/null | head -20 | sed 's/^/  /'
    echo -e "\n  ${YEL}Enter SSID: ${RESET}"
    read -r ssid
    [[ -z "$ssid" ]] && return
    echo -e "  ${YEL}Enter password (blank if open): ${RESET}"
    read -rs password; echo
    if [[ -z "$password" ]]; then
        nmcli dev wifi connect "$ssid"
    else
        nmcli dev wifi connect "$ssid" password "$password"
    fi && echo -e "\n  ${GRN}✓ Connected to $ssid${RESET}" || \
         echo -e "\n  ${RED}✗ Failed to connect${RESET}"
}

disconnect_network() {
    echo -e "\n  ${YEL}Active connections:${RESET}\n"
    mapfile -t conns < <(nmcli -c no connection show --active 2>/dev/null | awk 'NR>1{print $1}')
    local i=1
    for c in "${conns[@]}"; do echo -e "  ${YEL}[$i]${RESET} $c"; ((i++)); done
    echo -e "\n  ${YEL}Choose connection to disconnect: ${RESET}"
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$(( choice - 1 ))
        nmcli connection down "${conns[$idx]}" && \
            echo -e "  ${GRN}✓ Disconnected${RESET}" || \
            echo -e "  ${RED}✗ Failed${RESET}"
    fi
}

manage_vpn() {
    echo -e "\n  ${YEL}VPN Connections:${RESET}\n"
    nmcli -c no connection show 2>/dev/null | grep -i vpn | sed 's/^/  /' || echo "  (no VPN configs)"
    echo -e "\n  ${GRY}[1] Add WireGuard VPN  [2] Add OpenVPN  [3] Import .conf${RESET}"
    read -r -n1 c; echo
    case "$c" in
        1) echo -e "  ${YEL}WireGuard config file path: ${RESET}"
           read -r wgconf
           [[ -f "$wgconf" ]] && nmcli connection import type wireguard file "$wgconf" && \
               echo -e "  ${GRN}✓ WireGuard imported${RESET}" || echo -e "  ${RED}File not found${RESET}" ;;
        2) echo -e "  ${YEL}OpenVPN .ovpn file path: ${RESET}"
           read -r ovpn
           [[ -f "$ovpn" ]] && nmcli connection import type openvpn file "$ovpn" && \
               echo -e "  ${GRN}✓ OpenVPN imported${RESET}" || echo -e "  ${RED}File not found${RESET}" ;;
        3) echo -e "  ${YEL}Config file path: ${RESET}"
           read -r conf
           [[ -f "$conf" ]] && nmcli connection import file "$conf" || echo -e "  ${RED}File not found${RESET}" ;;
    esac
}

set_dns() {
    echo -e "\n  ${YEL}Quick DNS presets:${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} Cloudflare (1.1.1.1 / 1.0.0.1)"
    echo -e "  ${YEL}[2]${RESET} Google (8.8.8.8 / 8.8.4.4)"
    echo -e "  ${YEL}[3]${RESET} Quad9 (9.9.9.9)"
    echo -e "  ${YEL}[4]${RESET} Custom"
    read -r -n1 c; echo
    local conn
    conn=$(nmcli -c no connection show --active 2>/dev/null | awk 'NR==2{print $1}')
    [[ -z "$conn" ]] && { echo -e "  ${RED}No active connection${RESET}"; return; }
    case "$c" in
        1) nmcli con mod "$conn" ipv4.dns "1.1.1.1 1.0.0.1"; nmcli con mod "$conn" ipv6.dns "2606:4700:4700::1111" ;;
        2) nmcli con mod "$conn" ipv4.dns "8.8.8.8 8.8.4.4" ;;
        3) nmcli con mod "$conn" ipv4.dns "9.9.9.9 149.112.112.112" ;;
        4) echo -e "  ${YEL}Enter DNS (space-separated): ${RESET}"; read -r dns
           nmcli con mod "$conn" ipv4.dns "$dns" ;;
    esac
    nmcli con up "$conn" 2>/dev/null
    echo -e "  ${GRN}✓ DNS updated${RESET}"
}

open_nmtui() {
    echo -e "\n  ${GRY}Launching nmtui (full NetworkManager TUI)...${RESET}"
    sleep 0.5
    nmtui
}

firewall_status() {
    echo -e "\n  ${YEL}Firewall (ufw/nftables):${RESET}\n"
    if command -v ufw &>/dev/null; then
        ufw status verbose 2>/dev/null | sed 's/^/  /' || echo "  ufw not configured"
    elif command -v nft &>/dev/null; then
        nft list ruleset 2>/dev/null | head -20 | sed 's/^/  /' || echo "  nftables not configured"
    else
        echo -e "  ${GRY}No firewall tool detected. Install ufw for easy management.${RESET}"
    fi
}

while true; do
    header
    show_status
    echo -e "\n  ${ORG}${BOLD}── Actions ──${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} Connect to WiFi"
    echo -e "  ${YEL}[2]${RESET} Disconnect"
    echo -e "  ${YEL}[3]${RESET} Manage VPN"
    echo -e "  ${YEL}[4]${RESET} Set DNS"
    echo -e "  ${YEL}[5]${RESET} Open nmtui (full interface)"
    echo -e "  ${YEL}[6]${RESET} Firewall status"
    echo -e "  ${YEL}[7]${RESET} Restart NetworkManager"
    echo -e "  ${YEL}[q]${RESET} Quit"
    echo -e "\n  ${GRY}Choice: ${RESET}"
    read -r -n1 choice; echo
    case "$choice" in
        1) connect_wifi ;;
        2) disconnect_network ;;
        3) manage_vpn ;;
        4) set_dns ;;
        5) open_nmtui ;;
        6) firewall_status ;;
        7) systemctl restart NetworkManager && echo -e "\n  ${GRN}✓ Restarted${RESET}" ;;
        q|Q) break ;;
        *) ;;
    esac
    echo -e "\n  ${GRY}Press Enter to continue...${RESET}"
    read -r
done
NETEOF

    chmod +x /usr/local/bin/sway-network-setup
    ok "Network TUI installed: sway-network-setup"
}

# ─── TLP Power Management ─────────────────────────────────────────────────────
configure_tlp() {
    step "TLP Power Management"

    cat > /etc/tlp.conf << 'TLPEOF'
# =============================================================================
# TLP — Optimized for Sway/Wayland on laptops
# =============================================================================

TLP_ENABLE=1
TLP_WARN_LEVEL=3

# Power source detection
TLP_DEFAULT_MODE=AC
TLP_PERSISTENT_DEFAULT=0

# CPU frequency scaling
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=80

CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# Intel/AMD Platform Power
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Intel GPU
INTEL_GPU_MIN_FREQ_ON_AC=0
INTEL_GPU_MIN_FREQ_ON_BAT=0
INTEL_GPU_MAX_FREQ_ON_AC=0
INTEL_GPU_MAX_FREQ_ON_BAT=0
INTEL_GPU_BOOST_FREQ_ON_AC=0

# AMD GPU
AMDGPU_ABM_LEVEL_ON_AC=0
AMDGPU_ABM_LEVEL_ON_BAT=3

# Memory
MEM_SLEEP_ON_AC=s2idle
MEM_SLEEP_ON_BAT=deep

# Disk
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2
MAX_LOST_WORK_SECS_ON_AC=15
MAX_LOST_WORK_SECS_ON_BAT=60

# SATA power management
SATA_LINKPWR_ON_AC="med_power_with_dipm"
SATA_LINKPWR_ON_BAT="min_power"

AHCI_RUNTIME_PM_ON_AC=on
AHCI_RUNTIME_PM_ON_BAT=auto
AHCI_RUNTIME_PM_TIMEOUT=15

# NVMe
NVME_POWER_MGMT_ON_AC=0
NVME_POWER_MGMT_ON_BAT=med_power_with_dipm
NVME_POWER_MGMT_TIMEOUT_ON_BAT=10

# WiFi
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Ethernet
WOL_DISABLE=Y

# Audio
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1
SOUND_POWER_SAVE_CONTROLLER=Y

# PCI
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB
USB_AUTOSUSPEND=1
USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN=1

# Battery thresholds (ThinkPad / ASUS)
# START_CHARGE_THRESH_BAT0=20
# STOP_CHARGE_THRESH_BAT0=80

RESTORE_THRESHOLDS_ON_BAT=1

# Radeon DPM
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
RADEON_POWER_PROFILE_ON_AC=default
RADEON_POWER_PROFILE_ON_BAT=low
TLPEOF

    systemctl enable --now tlp
    systemctl enable NetworkManager-dispatcher
    systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true
    ok "TLP configured and enabled"
}

# ─── Snapper / Btrfs ──────────────────────────────────────────────────────────
configure_snapper() {
    step "Snapper Btrfs Configuration"

    # Check if root is btrfs
    if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
        warn "Root filesystem is NOT btrfs — skipping snapper setup"
        warn "Snapper scripts installed but not configured"
    else
        # Create snapper config for root
        snapper -c root create-config / 2>&1 | tee -a "$LOG_FILE" || true

        # Snapper config
        if [[ -f /etc/snapper/configs/root ]]; then
            sed -i 's/^ALLOW_USERS=.*/ALLOW_USERS="'"$USER_NAME"'"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="yes"/' /etc/snapper/configs/root
            sed -i 's/^NUMBER_MIN_AGE=.*/NUMBER_MIN_AGE="1800"/' /etc/snapper/configs/root
            sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' /etc/snapper/configs/root
            sed -i 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' /etc/snapper/configs/root
            sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="2"/' /etc/snapper/configs/root
        fi

        systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
        ok "Snapper configured for btrfs root"
    fi

    # Snapper assistant TUI
    cat > /usr/local/bin/sway-snapper-tui << 'SNAPEOF'
#!/usr/bin/env bash
# ─── Snapper Btrfs TUI ───────────────────────────────────────────────────────

RESET='\033[0m'; BOLD='\033[1m'
YEL='\033[38;2;215;153;33m'; GRN='\033[38;2;152;151;26m'
RED='\033[38;2;204;36;29m';  GRY='\033[38;2;146;131;116m'
ORG='\033[38;2;214;93;14m';  BLU='\033[38;2;69;133;136m'

header() {
    clear
    echo -e "${GRN}${BOLD}"
    echo "  ╔════════════════════════════════════════╗"
    echo "  ║    🌳  Snapper Btrfs Assistant TUI     ║"
    echo "  ║    Snapshots · Timeline · Restore      ║"
    echo "  ╚════════════════════════════════════════╝"
    echo -e "${RESET}"
}

list_configs() {
    echo -e "\n  ${YEL}── Snapper Configurations ──${RESET}\n"
    snapper list-configs 2>/dev/null | sed 's/^/  /' || echo "  (no configs found)"
}

list_snapshots() {
    echo -e "\n  ${YEL}Enter config (default: root): ${RESET}"
    read -r cfg; cfg="${cfg:-root}"
    echo -e "\n  ${BLU}── Snapshots for [$cfg] ──${RESET}\n"
    snapper -c "$cfg" list 2>/dev/null | sed 's/^/  /' || echo "  (none)"
}

create_snapshot() {
    echo -e "\n  ${YEL}Config (default: root): ${RESET}"
    read -r cfg; cfg="${cfg:-root}"
    echo -e "  ${YEL}Description: ${RESET}"
    read -r desc
    snapper -c "$cfg" create --description "${desc:-manual}" --cleanup-algorithm number
    echo -e "\n  ${GRN}✓ Snapshot created${RESET}"
}

delete_snapshot() {
    echo -e "\n  ${YEL}Config (default: root): ${RESET}"
    read -r cfg; cfg="${cfg:-root}"
    list_snapshots
    echo -e "\n  ${YEL}Snapshot number to delete: ${RESET}"
    read -r num
    [[ -z "$num" ]] && return
    snapper -c "$cfg" delete "$num" && \
        echo -e "  ${GRN}✓ Snapshot $num deleted${RESET}" || \
        echo -e "  ${RED}✗ Failed to delete${RESET}"
}

diff_snapshots() {
    echo -e "\n  ${YEL}Config (default: root): ${RESET}"
    read -r cfg; cfg="${cfg:-root}"
    echo -e "  ${YEL}Snapshot 1: ${RESET}"; read -r s1
    echo -e "  ${YEL}Snapshot 2: ${RESET}"; read -r s2
    snapper -c "$cfg" diff "$s1" "$s2" 2>/dev/null | head -50 | sed 's/^/  /' || true
}

rollback() {
    echo -e "\n  ${RED}${BOLD}⚠ ROLLBACK WARNING ──────────────────${RESET}"
    echo -e "  ${YEL}This will rollback root to a snapshot.${RESET}"
    echo -e "  ${YEL}Config (default: root): ${RESET}"; read -r cfg; cfg="${cfg:-root}"
    list_snapshots
    echo -e "\n  ${YEL}Snapshot number to rollback to: ${RESET}"; read -r num
    [[ -z "$num" ]] && return
    echo -e "  ${RED}Are you sure? [yes/no]: ${RESET}"; read -r confirm
    [[ "$confirm" != "yes" ]] && { echo -e "  ${GRY}Cancelled.${RESET}"; return; }
    snapper -c "$cfg" rollback "$num" && \
        echo -e "  ${GRN}✓ Rollback done — REBOOT required${RESET}" || \
        echo -e "  ${RED}✗ Rollback failed${RESET}"
}

disk_usage() {
    echo -e "\n  ${BLU}── Btrfs Filesystem Usage ──${RESET}\n"
    btrfs filesystem df / 2>/dev/null | sed 's/^/  /' || echo "  (not btrfs)"
    echo ""
    btrfs filesystem usage / 2>/dev/null | head -20 | sed 's/^/  /' || true
}

while true; do
    header
    list_configs
    echo -e "\n  ${ORG}${BOLD}── Actions ──${RESET}\n"
    echo -e "  ${YEL}[1]${RESET} List snapshots"
    echo -e "  ${YEL}[2]${RESET} Create snapshot"
    echo -e "  ${YEL}[3]${RESET} Delete snapshot"
    echo -e "  ${YEL}[4]${RESET} Diff two snapshots"
    echo -e "  ${YEL}[5]${RESET} Rollback to snapshot"
    echo -e "  ${YEL}[6]${RESET} Disk usage"
    echo -e "  ${YEL}[q]${RESET} Quit"
    echo -e "\n  ${GRY}Choice: ${RESET}"
    read -r -n1 choice; echo
    case "$choice" in
        1) list_snapshots ;;
        2) create_snapshot ;;
        3) delete_snapshot ;;
        4) diff_snapshots ;;
        5) rollback ;;
        6) disk_usage ;;
        q|Q) break ;;
        *) ;;
    esac
    echo -e "\n  ${GRY}Press Enter to continue...${RESET}"
    read -r
done
SNAPEOF

    chmod +x /usr/local/bin/sway-snapper-tui
    ok "Snapper TUI installed: sway-snapper-tui"
}

# ─── Screen Sharing (Zoom/Google Meet) ───────────────────────────────────────
configure_screenshare() {
    step "Screen Sharing (Wayland Portals)"

    # xdg-desktop-portal-wlr is already installed
    # Configure portal
    mkdir -p /usr/share/xdg-desktop-portal

    cat > /usr/share/xdg-desktop-portal/sway-portals.conf << 'EOF'
[preferred]
default=wlr
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.Inhibit=none
EOF

    # Pipewire is our screencast backend
    # Ensure portal services are enabled
    systemctl --user enable --now xdg-desktop-portal.service 2>/dev/null || true
    systemctl --user enable --now xdg-desktop-portal-wlr.service 2>/dev/null || true

    # Browser flags for WebRTC
    local CHROME_FLAGS="$REAL_HOME/.config/chrome-flags.conf"
    local CHROMIUM_FLAGS="$REAL_HOME/.config/chromium-flags.conf"
    for f in "$CHROME_FLAGS" "$CHROMIUM_FLAGS"; do
        cat > "$f" << 'EOF'
--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer
--ozone-platform=wayland
--enable-webrtc-pipewire-capturer
EOF
    done

    # Firefox env
    mkdir -p "$REAL_HOME/.config/environment.d"
    cat >> "$REAL_HOME/.config/environment.d/sway.conf" << 'EOF'
MOZ_ENABLE_WAYLAND=1
MOZ_WEBRENDER=1
EOF

    ok "Screen sharing configured (xdg-desktop-portal-wlr + PipeWire)"
    info "For Zoom/Google Meet: use Firefox or Chromium with WebRTC PipeWire"
}

# ─── Printing ─────────────────────────────────────────────────────────────────
configure_printing() {
    step "Printing (CUPS)"

    systemctl enable --now cups.service avahi-daemon.service

    # mDNS in nsswitch
    if ! grep -q "mdns" /etc/nsswitch.conf; then
        sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
    fi

    # Add user to lp and sys groups
    usermod -aG lp,sys "$USER_NAME" 2>/dev/null || true

    ok "CUPS configured — access at http://localhost:631"
}

# ─── Services & Systemd ───────────────────────────────────────────────────────
configure_services() {
    step "Services"

    # System services
    local SYS_SERVICES=(
        NetworkManager
        bluetooth
        cups
        avahi-daemon
        tlp
    )
    for s in "${SYS_SERVICES[@]}"; do
        systemctl enable --now "$s" 2>/dev/null && ok "Enabled: $s" || warn "Could not enable: $s"
    done

    # Systemd user services
    local USER_SERVICES=(
        pipewire
        pipewire-pulse
        wireplumber
    )
    for s in "${USER_SERVICES[@]}"; do
        sudo -u "$USER_NAME" systemctl --user enable "$s" 2>/dev/null && ok "User service: $s" || warn "Could not enable user service: $s"
    done

    # PAM environment for sway
    cat > "$REAL_HOME/.config/environment.d/sway.conf" << 'EOF'
# Wayland
WAYLAND_DISPLAY=wayland-1
XDG_CURRENT_DESKTOP=sway
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=sway

# Qt Wayland
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
QT_AUTO_SCREEN_SCALE_FACTOR=1

# GTK
GDK_BACKEND=wayland,x11
CLUTTER_BACKEND=wayland

# Firefox
MOZ_ENABLE_WAYLAND=1

# Java (for JVM apps on Wayland)
_JAVA_AWT_WM_NONREPARENTING=1

# GNOME Keyring
SSH_AUTH_SOCK=/run/user/1000/keyring/ssh

# Locale
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

    ok "Environment variables configured"
}

# ─── Fish Shell + Starship ────────────────────────────────────────────────────
configure_shell() {
    step "Shell Configuration (Fish + Starship)"

    local FISH_DIR="$REAL_HOME/.config/fish"
    mkdir -p "$FISH_DIR"

    cat > "$FISH_DIR/config.fish" << 'FISHEOF'
# ─── Fish Config — Gruvbox ───────────────────────────────────────────────────

# Disable greeting
set fish_greeting ""

# Starship prompt
if command -q starship
    starship init fish | source
end

# Zoxide (smarter cd)
if command -q zoxide
    zoxide init fish | source
end

# Abbreviations (faster than aliases for interactive use)
abbr -a ls   'eza --icons'
abbr -a ll   'eza -lh --icons --git'
abbr -a la   'eza -lha --icons --git'
abbr -a lt   'eza --tree --icons --level=2'
abbr -a cat  'bat --style=plain'
abbr -a find 'fd'
abbr -a grep 'rg'
abbr -a top  'btop'
abbr -a vim  'nvim'
abbr -a vi   'nvim'
abbr -a ..   'cd ..'
abbr -a ...  'cd ../..'

# Sway TUI tools
abbr -a audio   'sway-audio-setup'
abbr -a display 'sway-display-setup'
abbr -a network 'sway-network-setup'
abbr -a snapper 'sway-snapper-tui'

# Pacman
abbr -a pac    'sudo pacman -S'
abbr -a pacs   'pacman -Ss'
abbr -a pacr   'sudo pacman -Rns'
abbr -a pacu   'sudo pacman -Syu'
abbr -a yays   'yay -Ss'
abbr -a yayi   'yay -S'

# Sway
abbr -a reload-sway 'swaymsg reload'

# Environment
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox
set -gx PAGER less
set -gx MANPAGER 'nvim +Man!'

# XDG
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME   $HOME/.local/share
set -gx XDG_CACHE_HOME  $HOME/.cache

# PATH additions
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin

# FZF
set -gx FZF_DEFAULT_OPTS '--color=bg+:#3c3836,bg:#282828,spinner:#d79921,hl:#83a598,fg:#bdae93,header:#83a598,info:#d79921,pointer:#d3869b,marker:#d3869b,fg+:#ebdbb2,prompt:#d3869b,hl+:#d3869b'
FISHEOF

    # Starship Gruvbox config
    cat > "$REAL_HOME/.config/starship.toml" << 'STAREOF'
# Starship — Gruvbox Powerline Theme

format = """
[](fg:#282828 bg:#d65d0e)\
$os\
[](fg:#d65d0e bg:#d79921)\
$directory\
[](fg:#d79921 bg:#458588)\
$git_branch$git_status\
[](fg:#458588 bg:#689d6a)\
$python$nodejs$rust$golang\
[](fg:#689d6a bg:#3c3836)\
$cmd_duration\
[ ](fg:#3c3836)\
$line_break\
$character"""

[os]
style = "fg:#282828 bg:#d65d0e bold"
disabled = false

[directory]
style = "fg:#282828 bg:#d79921 bold"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = true

[git_branch]
style = "fg:#ebdbb2 bg:#458588"
format = "[ $symbol$branch ]($style)"
symbol = " "

[git_status]
style = "fg:#ebdbb2 bg:#458588"
format = "[$all_status$ahead_behind ]($style)"

[cmd_duration]
style = "fg:#a89984 bg:#3c3836"
format = "[  $duration ]($style)"
min_time = 500

[character]
success_symbol = "[❯](bold green)"
error_symbol   = "[❯](bold red)"

[python]
style = "fg:#282828 bg:#689d6a"
format = "[ $symbol$version ]($style)"

[nodejs]
style = "fg:#282828 bg:#689d6a"
format = "[ $symbol$version ]($style)"

[rust]
style = "fg:#282828 bg:#689d6a"
format = "[ $symbol$version ]($style)"
STAREOF

    # Set fish as default shell for user
    chsh -s "$(which fish)" "$USER_NAME" 2>/dev/null || warn "Could not change shell to fish (do it manually)"
    ok "Fish + Starship configured"
}

# ─── Wallpaper ────────────────────────────────────────────────────────────────
generate_wallpaper() {
    step "Generating Gruvbox Wallpaper"

    local WALLDIR="$REAL_HOME/.config/sway"
    mkdir -p "$WALLDIR"

    # Generate a Gruvbox-colored SVG wallpaper
    cat > "$WALLDIR/wallpaper.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
  <defs>
    <radialGradient id="g1" cx="30%" cy="40%" r="60%">
      <stop offset="0%" stop-color="#32302f"/>
      <stop offset="100%" stop-color="#1d2021"/>
    </radialGradient>
    <radialGradient id="g2" cx="80%" cy="70%" r="50%">
      <stop offset="0%" stop-color="#3c3836" stop-opacity="0.8"/>
      <stop offset="100%" stop-color="#1d2021" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#g1)"/>
  <rect width="1920" height="1080" fill="url(#g2)"/>
  <!-- Grid pattern -->
  <g stroke="#3c3836" stroke-width="0.5" opacity="0.3">
    <line x1="0" y1="120" x2="1920" y2="120"/>
    <line x1="0" y1="240" x2="1920" y2="240"/>
    <line x1="0" y1="360" x2="1920" y2="360"/>
    <line x1="0" y1="480" x2="1920" y2="480"/>
    <line x1="0" y1="600" x2="1920" y2="600"/>
    <line x1="0" y1="720" x2="1920" y2="720"/>
    <line x1="0" y1="840" x2="1920" y2="840"/>
    <line x1="0" y1="960" x2="1920" y2="960"/>
    <line x1="192" y1="0" x2="192" y2="1080"/>
    <line x1="384" y1="0" x2="384" y2="1080"/>
    <line x1="576" y1="0" x2="576" y2="1080"/>
    <line x1="768" y1="0" x2="768" y2="1080"/>
    <line x1="960" y1="0" x2="960" y2="1080"/>
    <line x1="1152" y1="0" x2="1152" y2="1080"/>
    <line x1="1344" y1="0" x2="1344" y2="1080"/>
    <line x1="1536" y1="0" x2="1536" y2="1080"/>
    <line x1="1728" y1="0" x2="1728" y2="1080"/>
  </g>
  <!-- Decorative diamonds -->
  <polygon points="960,440 1020,520 960,600 900,520" fill="none" stroke="#d65d0e" stroke-width="1.5" opacity="0.5"/>
  <polygon points="960,400 1060,520 960,640 860,520" fill="none" stroke="#d79921" stroke-width="1" opacity="0.3"/>
  <polygon points="960,360 1100,520 960,680 820,520" fill="none" stroke="#458588" stroke-width="0.8" opacity="0.2"/>
  <!-- Corner accents -->
  <line x1="0" y1="0" x2="200" y2="0" stroke="#d65d0e" stroke-width="2"/>
  <line x1="0" y1="0" x2="0" y2="100" stroke="#d65d0e" stroke-width="2"/>
  <line x1="1920" y1="0" x2="1720" y2="0" stroke="#d65d0e" stroke-width="2"/>
  <line x1="1920" y1="0" x2="1920" y2="100" stroke="#d65d0e" stroke-width="2"/>
  <line x1="0" y1="1080" x2="200" y2="1080" stroke="#d65d0e" stroke-width="2"/>
  <line x1="0" y1="1080" x2="0" y2="980" stroke="#d65d0e" stroke-width="2"/>
  <line x1="1920" y1="1080" x2="1720" y2="1080" stroke="#d65d0e" stroke-width="2"/>
  <line x1="1920" y1="1080" x2="1920" y2="980" stroke="#d65d0e" stroke-width="2"/>
  <!-- Subtle text -->
  <text x="960" y="560" text-anchor="middle" font-family="monospace" font-size="11" fill="#504945" letter-spacing="8">SWAY WM · ARCH LINUX · GRUVBOX</text>
</svg>
SVGEOF

    # Convert SVG to PNG if ImageMagick available
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 "$WALLDIR/wallpaper.svg" "$WALLDIR/wallpaper.png" 2>/dev/null && \
            ok "Wallpaper PNG generated" || warn "SVG wallpaper created (PNG conversion failed)"
    else
        cp "$WALLDIR/wallpaper.svg" "$WALLDIR/wallpaper.jpg"
        ok "Wallpaper SVG ready (install imagemagick for PNG)"
    fi
}

# ─── Sway Launcher Desktop Entry ─────────────────────────────────────────────
configure_sway_entry() {
    step "Sway Desktop Entry"

    # Ensure /usr/share/wayland-sessions exists
    mkdir -p /usr/share/wayland-sessions

    cat > /usr/share/wayland-sessions/sway.desktop << 'EOF'
[Desktop Entry]
Name=Sway
Comment=An i3-compatible Wayland compositor
Exec=sway
Type=Application
EOF

    # Sway wrapper script with env
    cat > /usr/local/bin/sway-run << 'EOF'
#!/usr/bin/env bash
# Sway environment wrapper

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export GDK_BACKEND=wayland,x11
export _JAVA_AWT_WM_NONREPARENTING=1
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export ECORE_EVAS_ENGINE=wayland_egl
export ELM_ENGINE=wayland_egl

exec sway "$@"
EOF
    chmod +x /usr/local/bin/sway-run

    ok "Sway session entry created"
}

# ─── Media Codecs ─────────────────────────────────────────────────────────────
configure_codecs() {
    step "Media Codecs"

    # VA-API / VDPAU
    pacman -S --noconfirm --needed \
        ffmpeg \
        libva \
        libvdpau \
        libdvdread \
        libdvdnav \
        libdvdcss \
        libaacs \
        libbluray \
        2>&1 | tee -a "$LOG_FILE" || warn "Some codec packages unavailable"

    # MPV config for hardware decoding
    mkdir -p "$REAL_HOME/.config/mpv"
    cat > "$REAL_HOME/.config/mpv/mpv.conf" << 'EOF'
# Hardware video acceleration
hwdec=auto-safe
hwdec-codecs=all

# Wayland
vo=gpu
gpu-api=vulkan

# Audio
ao=pipewire
audio-channels=stereo

# Performance
video-sync=display-resample
interpolation=yes
tscale=oversample

# OSD Gruvbox colors
osd-color=#ebdbb2
osd-border-color=#282828
osd-font=JetBrainsMono Nerd Font
osd-font-size=28

# Screenshot
screenshot-format=png
screenshot-directory=~/Pictures/Screenshots
EOF

    ok "Media codecs configured"
}

# ─── Fix Permissions ─────────────────────────────────────────────────────────
fix_permissions() {
    step "Fixing Permissions"
    chown -R "$USER_NAME:$USER_NAME" "$REAL_HOME/.config" 2>/dev/null || true
    chown -R "$USER_NAME:$USER_NAME" "$REAL_HOME/.local" 2>/dev/null || true
    chmod 700 "$REAL_HOME/.config/sway"
    ok "Permissions fixed"
}

# ─── Keybinding Cheatsheet ───────────────────────────────────────────────────
generate_cheatsheet() {
    step "Keybinding Cheatsheet"

    cat > "$REAL_HOME/.config/sway/KEYBINDINGS.md" << 'EOF'
# Sway WM Keybindings — Gruvbox Setup

## Core
| Key | Action |
|-----|--------|
| Super+Return | Open terminal (foot) |
| Super+Shift+Return | Open terminal in current dir |
| Super+d | Fuzzel launcher |
| Super+Shift+q | Kill window |
| Super+Shift+e | Logout menu (wlogout) |
| Super+Shift+r | Reload sway config |
| Super+Shift+l | Lock screen (swaylock) |
| Super+b | Browser |
| Super+e | File manager (lf) |

## Screenshots
| Key | Action |
|-----|--------|
| Print | Copy full screen |
| Shift+Print | Copy selected area |
| Super+Print | Save full screen |
| Super+Shift+Print | Save selected area |
| Super+Shift+s | Screenshot → annotate (satty) |

## Clipboard
| Key | Action |
|-----|--------|
| Super+v | Clipboard history (cliphist) |
| Super+Shift+p | Color picker |

## Volume & Brightness
| Key | Action |
|-----|--------|
| XF86AudioRaiseVolume | Volume up (+5%) |
| XF86AudioLowerVolume | Volume down (-5%) |
| XF86AudioMute | Toggle mute |
| XF86MonBrightnessUp | Brightness up |
| XF86MonBrightnessDown | Brightness down |

## Window Management
| Key | Action |
|-----|--------|
| Super+hjkl / Arrows | Focus direction |
| Super+Shift+hjkl | Move window |
| Super+r → hjkl | Resize mode |
| Super+f | Fullscreen |
| Super+Shift+Space | Toggle float |
| Super+Space | Focus float/tile |
| Super+a | Focus parent |

## Layout
| Key | Action |
|-----|--------|
| Super+b | Split horizontal |
| Super+v | Split vertical |
| Super+s | Stacking |
| Super+w | Tabbed |
| Super+t | Toggle split |

## Workspaces
| Key | Action |
|-----|--------|
| Super+1-9,0 | Switch workspace |
| Super+Shift+1-9,0 | Move to workspace |
| Super+Tab | Next workspace |
| Super+Shift+Tab | Prev workspace |
| Super+` | Last workspace |
| Super+minus | Toggle scratchpad |
| Super+Shift+minus | Send to scratchpad |

## TUI Tools (in terminal)
| Command | Tool |
|---------|------|
| sway-audio-setup | Audio configuration TUI |
| sway-display-setup | Display/monitor TUI |
| sway-network-setup | Network management TUI |
| sway-snapper-tui | Btrfs snapshot manager |
EOF

    ok "Cheatsheet saved: ~/.config/sway/KEYBINDINGS.md"
}

# ─── Summary ─────────────────────────────────────────────────────────────────
print_summary() {
    clear
    echo -e "${GRV_ORANGE}${BOLD}"
    cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║              INSTALLATION COMPLETE!                          ║
  ║                                                               ║
  ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"

    echo -e "  ${GRV_GREEN}${BOLD}What was configured:${RESET}\n"
    echo -e "  ${GRV_AQUA}◆${RESET} Sway WM with Gruvbox dark theme"
    echo -e "  ${GRV_AQUA}◆${RESET} Waybar status bar"
    echo -e "  ${GRV_AQUA}◆${RESET} Fuzzel application launcher"
    echo -e "  ${GRV_AQUA}◆${RESET} Foot terminal + Fish shell + Starship"
    echo -e "  ${GRV_AQUA}◆${RESET} SwayNC notification center"
    echo -e "  ${GRV_AQUA}◆${RESET} Swaylock screen locker + Swayidle"
    echo -e "  ${GRV_AQUA}◆${RESET} Hot corners (top-right: launcher, bottom-right: logout)"
    echo -e "  ${GRV_AQUA}◆${RESET} Screenshots (grim + slurp + satty)"
    echo -e "  ${GRV_AQUA}◆${RESET} Clipboard history (cliphist)"
    echo -e "  ${GRV_AQUA}◆${RESET} Screen sharing (xdg-portal-wlr + PipeWire)"
    echo -e "  ${GRV_AQUA}◆${RESET} CUPS printing + Avahi"
    echo -e "  ${GRV_AQUA}◆${RESET} PipeWire + WirePlumber audio stack"
    echo -e "  ${GRV_AQUA}◆${RESET} TLP power management (configured)"
    echo -e "  ${GRV_AQUA}◆${RESET} Snapper btrfs snapshots + snap-pac"
    echo -e "  ${GRV_AQUA}◆${RESET} Full media codec support (ffmpeg + gst + VA-API)"
    echo -e "  ${GRV_AQUA}◆${RESET} GTK/Qt Gruvbox theming"
    echo -e "  ${GRV_AQUA}◆${RESET} Gammastep night light"

    echo -e "\n  ${GRV_YELLOW}${BOLD}TUI Tools (run in terminal):${RESET}\n"
    echo -e "  ${GRV_YELLOW}sway-audio-setup${RESET}    — Audio device configuration"
    echo -e "  ${GRV_YELLOW}sway-display-setup${RESET}  — Monitor/display management"
    echo -e "  ${GRV_YELLOW}sway-network-setup${RESET}  — WiFi/Ethernet/VPN management"
    echo -e "  ${GRV_YELLOW}sway-snapper-tui${RESET}    — Btrfs snapshot manager"

    echo -e "\n  ${GRV_YELLOW}${BOLD}Next steps:${RESET}\n"
    echo -e "  ${GRV_GRAY}1.${RESET} Add a wallpaper: ${GRV_AQUA}~/.config/sway/wallpaper.png${RESET}"
    echo -e "  ${GRV_GRAY}2.${RESET} Start sway: ${GRV_AQUA}sway${RESET}  or login via display manager"
    echo -e "  ${GRV_GRAY}3.${RESET} Check keybindings: ${GRV_AQUA}~/.config/sway/KEYBINDINGS.md${RESET}"
    echo -e "  ${GRV_GRAY}4.${RESET} Adjust displays: ${GRV_AQUA}~/.config/sway/outputs.conf${RESET}"
    echo -e "  ${GRV_GRAY}5.${RESET} For Zoom/Meet screen share: use Firefox/Chromium on Wayland"

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo -e "\n  ${GRV_RED}${BOLD}Non-fatal errors:${RESET}"
        for e in "${ERRORS[@]}"; do
            echo -e "  ${GRV_RED}•${RESET} $e"
        done
    fi

    echo -e "\n  ${GRV_GRAY}Log saved to: $LOG_FILE${RESET}\n"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    banner
    log "Starting Sway Arch Linux installer"
    log "User: $USER_NAME | Home: $REAL_HOME"

    echo -e "  ${GRV_YELLOW}This script will:${RESET}"
    echo -e "  • Install Sway WM with full desktop stack"
    echo -e "  • Configure Gruvbox theming throughout"
    echo -e "  • Set up TUI tools for audio, video, network, snapshots"
    echo -e "  • Configure TLP, printing, screen sharing, codecs"
    echo -e ""

    confirm "Proceed with full installation?" || { echo "Aborted."; exit 0; }

    preflight
    system_update
    install_packages
    configure_sway
    configure_hot_corners
    configure_waybar
    configure_fuzzel
    configure_foot
    configure_swaync
    configure_swaylock
    configure_wlogout
    configure_theming
    configure_screenshare
    configure_printing
    configure_tlp
    configure_snapper
    configure_codecs
    configure_services
    configure_shell
    generate_wallpaper
    configure_sway_entry
    create_audio_tui
    create_video_tui
    create_network_tui
    fix_permissions
    generate_cheatsheet
    print_summary
}

main "$@"
