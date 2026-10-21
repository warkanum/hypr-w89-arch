#!/bin/bash
# ==================================================
#  KDE / Qt apps instead of GTK (Stargate / Star Trek fork)
#  Based on KooL's Arch-Hyprland by LinuxBeginnings
#  https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Dolphin + KDE apps, Breeze style, KDE portal. Hyprland stays the compositor.

kde=(
  python
  plasma-integration
  breeze
  breeze-icons
  dolphin
  dolphin-plugins
  ark
  kio-extras
  kio-admin
  kio-fuse
  kde-cli-tools
  kdegraphics-thumbnailers
  ffmpegthumbs
  gwenview
  okular
  kate
  xdg-desktop-portal-kde
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_kde.log"

printf "${INFO} Installing ${SKY_BLUE}KDE apps${RESET}...\n"
for PKG in "${kde[@]}"; do
  install_package "$PKG" "$LOG"
done

# Dolphin as the default file manager
xdg-mime default org.kde.dolphin.desktop inode/directory
echo "${OK} ${MAGENTA}Dolphin${RESET} is now the default file manager." | tee -a "$LOG"

# Portal: KDE file chooser, Hyprland for the rest
portals="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
mkdir -p "$(dirname "$portals")"
cat > "$portals" <<'PORTALS'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=kde
PORTALS
echo "${OK} Portal config written to $portals" | tee -a "$LOG"

echo "${NOTE} Qt env + colours are applied by hypr_theme.sh (runs after the dots)." | tee -a "$LOG"
printf "\n%.0s" {1..2}
