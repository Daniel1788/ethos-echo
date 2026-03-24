#!/bin/bash

echo "========================================================"
echo " Starting Minimal Sway Setup for Acer Aspire 5 (Intel)"
echo "========================================================"

# 1. Update system and install packages
echo ">>> Installing core packages via pacman..."
sudo pacman -Syu --needed --noconfirm \
  sway swaybg swayidle swaylock waybar polkit-gnome \
  mesa vulkan-intel intel-media-driver kanshi brightnessctl \
  pipewire wireplumber pipewire-pulse pipewire-alsa \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  slurp grim network-manager-applet bluez bluez-utils blueman \
  foot wofi thunar mako mpv ttf-jetbrains-mono-nerd inter-font

# 2. Setup Font Configuration (Inter as system font)
echo ">>> Configuring Inter as the default system font..."
mkdir -p ~/.config/fontconfig

cat <<'EOF' >~/.config/fontconfig/fonts.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Inter</family>
    </prefer>
  </alias>
  <alias>
    <family>ui-sans-serif</family>
    <prefer>
      <family>Inter</family>
    </prefer>
  </alias>
</fontconfig>
EOF

# Refresh the font cache
fc-cache -fv

# 3. Setup Sway Configuration
echo ">>> Building base Sway configuration..."
git clone https://github.com/Daniel1788/ethos-echo.git
mkdir -p ~/.config
mkdir -p ~/Pictures/
mv sway ~/.config
mv foot ~/.config
mv waybar ~/.config
mv background.jpg Pictures
