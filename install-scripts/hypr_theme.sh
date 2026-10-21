#!/bin/bash
# ==================================================
#  Stargate / Star Trek Hyprland theme overlay
#  Based on KooL's Arch-Hyprland by LinuxBeginnings
#  https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Runs after dotfiles-main.sh. Adds the colour schemes and the hypr-theme
# switcher, and removes the stock (anime) wallpapers shipped with the dots.

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hypr_theme.log"
src="assets/hypr-themes"
share="$HOME/.local/share/hypr-themes"
default_theme="stargate-carbon-dark"

if [ ! -d "$src" ]; then
  echo "${ERROR} $src not found. Run this script from the repo root." 2>&1 | tee -a "$LOG"
  exit 1
fi

# Schemes + switcher
mkdir -p "$share" "$HOME/.local/bin" "$HOME/.config/wallust/colorschemes" "$HOME/.local/state/hypr"
cp -f "$src"/*.json "$src/kde-colors.py" "$share/"
cp -f "$src"/*.json "$HOME/.config/wallust/colorschemes/"
install -m 755 "$src/hypr-theme" "$HOME/.local/bin/hypr-theme"
echo "${OK} Installed colour schemes and hypr-theme." 2>&1 | tee -a "$LOG"

# Remove the stock wallpapers shipped with Hyprland-Dots (names taken from the cloned dots)
if [ -d Hyprland-Dots/wallpapers ]; then
  while IFS= read -r -d '' f; do
    rm -f "$HOME/Pictures/wallpapers/${f#Hyprland-Dots/wallpapers/}"
  done < <(find Hyprland-Dots/wallpapers -type f -print0)
  find "$HOME/Pictures/wallpapers" -type d -empty -delete 2>/dev/null
  echo "${OK} Removed stock wallpapers." 2>&1 | tee -a "$LOG"
fi

# Wallpapers supplied by this repo
if compgen -G "assets/hypr-themes/wallpapers/*" >/dev/null; then
  mkdir -p "$HOME/Pictures/wallpapers"
  cp -f assets/hypr-themes/wallpapers/* "$HOME/Pictures/wallpapers/"
fi

# Dots call `wallust theme` for the saved global theme; ours are colorschemes, so use `wallust cs`
ws="$HOME/.config/hypr/scripts/WallustSwww.sh"
if [ -f "$ws" ]; then
  sed -i 's/ theme -- "\$global_theme"/ cs -- "$global_theme"/' "$ws"
fi

# Remove the Japanese-themed wlogout presets (sekiro, kurenai, fuji) and their menu entries
rm -rf "$HOME/.config/wlogout/themes"/{sekiro,kurenai,fuji}
wl="$HOME/.config/hypr/scripts/RofiWlogoutTheme.sh"
if [ -f "$wl" ]; then
  sed -i -e '/Sekiro (Sumi-e/d' -e '/Kurenai (Crimson/d' -e '/Fuji (Mount/d' \
         -e 's/Silvia (Sakura Pink)/Silvia (Nebula)/' "$wl"
fi

# KDE mode: when Dolphin is installed, make Qt use the KDE platform theme and Dolphin the default
if command -v dolphin >/dev/null 2>&1; then
  envlua="$HOME/.config/hypr/lua/env.lua"
  if [ -f "$envlua" ]; then
    sed -i -e 's/hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")/hl.env("QT_QPA_PLATFORMTHEME", "kde")/' \
           -e '/hl.env("QT_STYLE_OVERRIDE", "Fusion")/d' "$envlua"
  fi
  ud="$HOME/.config/hypr/UserConfigs/user_defaults.lua"
  if [ -f "$ud" ] && ! grep -q '^KOOLDOTS_DEFAULTS.files' "$ud"; then
    echo 'KOOLDOTS_DEFAULTS.files = "dolphin"' >> "$ud"
  fi
  # ssh passphrases via KWallet
  if [ -f "$envlua" ] && command -v ksshaskpass >/dev/null 2>&1 && ! grep -q SSH_ASKPASS "$envlua"; then
    printf '%s\n' 'hl.env("SSH_ASKPASS", "/usr/bin/ksshaskpass")' 'hl.env("SSH_ASKPASS_REQUIRE", "prefer")' >> "$envlua"
  fi
  # Env that survives dots updates, and session startup for KDE apps/portals
  uenv="$HOME/.config/hypr/UserConfigs/user_env.lua"
  if [ -f "$uenv" ] && ! grep -q 'hypr-w89 kde' "$uenv"; then
    cat >> "$uenv" <<'LUA'

-- hypr-w89 kde
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("KDE_SESSION_VERSION", "6")
hl.env("GTK_USE_PORTAL", "1")
LUA
  fi
  us="$HOME/.config/hypr/UserConfigs/user_startup.lua"
  if [ -f "$us" ] && ! grep -q 'hypr-w89 kde' "$us"; then
    sed -i '/^local startup_commands = {/a\
  -- hypr-w89 kde\
  "dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME XDG_MENU_PREFIX KDE_SESSION_VERSION GTK_USE_PORTAL",\
  "kded6",\
  "kbuildsycoca6",' "$us"
  fi
  echo "${OK} KDE mode: Qt platform theme = kde, file manager = dolphin." 2>&1 | tee -a "$LOG"
fi

# Saved theme from an older install used names without -dark: map it, or wallust cs fails
saved="$HOME/.local/state/hypr/global_theme"
if [ -f "$saved" ]; then
  cur="$(tr -d '\r\n' < "$saved")"
  if [ -n "$cur" ] && [ ! -f "$share/$cur.json" ] && [ -f "$share/$cur-dark.json" ]; then
    printf '%s\n' "$cur-dark" > "$saved"
    printf '%s\n' "$cur-dark" > "$HOME/.cache/.global_theme"
  fi
fi

# Apply the default scheme
if "$HOME/.local/bin/hypr-theme" set "$default_theme" 2>&1 | tee -a "$LOG"; then
  echo "${OK} Applied ${SKY_BLUE}$default_theme${RESET}. Switch with: hypr-theme set <name>" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
