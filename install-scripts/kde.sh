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
  qt6-wayland
  archlinux-xdg-menu
  udisks2
  kwallet
  kwallet-pam
  kwalletmanager
  ksshaskpass
  kdeconnect
  kcalc
  kdialog
  kfind
  filelight
  partitionmanager
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

# Default apps (KDE apps open their own file types)
set_default() { # $1 = desktop file, rest = mime types
  local app="$1"; shift
  for m in "$@"; do xdg-mime default "$app" "$m"; done
}
set_default org.kde.ark.desktop application/zip application/x-tar application/x-7z-compressed \
  application/vnd.rar application/gzip application/x-xz application/x-bzip2 application/zstd
set_default org.kde.gwenview.desktop image/png image/jpeg image/gif image/webp image/bmp image/avif image/svg+xml
set_default org.kde.okular.desktop application/pdf application/epub+zip
set_default org.kde.kate.desktop text/plain text/markdown application/json text/x-shellscript text/x-python
echo "${OK} Default apps set (Dolphin, Ark, Gwenview, Okular, Kate)." | tee -a "$LOG"

# Portals: KDE dialogs (file chooser, app chooser, print, settings), Hyprland for screen sharing
portals="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
mkdir -p "$(dirname "$portals")"
cat > "$portals" <<'PORTALS'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=kde
org.freedesktop.impl.portal.AppChooser=kde
org.freedesktop.impl.portal.Print=kde
org.freedesktop.impl.portal.Settings=kde;gtk
PORTALS
echo "${OK} Portal config written to $portals" | tee -a "$LOG"

# Browsers: send their file/open dialogs to the KDE portal
firefox_prefs='pref("widget.use-xdg-desktop-portal.file-picker", 1);
pref("widget.use-xdg-desktop-portal.mime-handler", 1);
pref("widget.use-xdg-desktop-portal.open-uri", 1);
pref("widget.use-xdg-desktop-portal.settings", 1);'
if [ -d /usr/lib/firefox/browser/defaults/preferences ]; then
  echo "$firefox_prefs" | sudo tee /usr/lib/firefox/browser/defaults/preferences/hypr-w89-kde-portal.js >/dev/null
  echo "${OK} Firefox default prefs set (portal dialogs)." | tee -a "$LOG"
fi
# Existing Firefox profiles: user.js wins over defaults
for prof in "$HOME"/.mozilla/firefox/*.default*/; do
  [ -d "$prof" ] || continue
  if ! grep -q 'widget.use-xdg-desktop-portal.file-picker' "$prof/user.js" 2>/dev/null; then
    echo "${firefox_prefs//pref(/user_pref(}" >> "$prof/user.js"
    echo "${OK} Firefox profile updated: $prof" | tee -a "$LOG"
  fi
done
# Chromium-based browsers use the portal through GTK_USE_PORTAL=1 (set in user_env.lua by hypr_theme.sh).

# Application menu cache so "Open with" lists apps outside Plasma
XDG_MENU_PREFIX=arch- kbuildsycoca6 >/dev/null 2>&1 && echo "${OK} KDE service cache built." | tee -a "$LOG"

# KWallet auto-unlock at SDDM login (pam_kwallet5.so is the module for KWallet 6 as well)
if [ -f /etc/pam.d/sddm ] && grep -q 'pam_kwallet5.so' /etc/pam.d/sddm; then
  echo "${OK} SDDM PAM already has pam_kwallet5. Wallet unlocks at login if it uses your login password." | tee -a "$LOG"
else
  echo "${WARN} /etc/pam.d/sddm has no pam_kwallet5 lines; KWallet will not auto-unlock at login." | tee -a "$LOG"
fi

# Both wallets provide org.freedesktop.secrets; only one can own it. gnome-keyring is left untouched.
if pacman -Qq gnome-keyring >/dev/null 2>&1; then
  echo "${WARN} gnome-keyring is installed and competes with KWallet for org.freedesktop.secrets. Not removed." | tee -a "$LOG"
fi

echo "${NOTE} Qt env + colours are applied by hypr_theme.sh (runs after the dots)." | tee -a "$LOG"
printf "\n%.0s" {1..2}
