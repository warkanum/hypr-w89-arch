#!/bin/bash
# ==================================================
#  Based on KoolDots (2026) by LinuxBeginnings
#  Original: https://github.com/LinuxBeginnings/Arch-Hyprland
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# fastfetch-star-lore (Stargate / Star Trek) terminal art

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh_star_lore.log"
STAR_LORE_URL="https://github.com/warkanum/fastfetch-star-lore.git"
STAR_LORE_DIR="$HOME/.cache/fastfetch-star-lore-src"
MARKER='# fastfetch-star-lore'

printf "${NOTE} Installing ${SKY_BLUE}fastfetch-star-lore${RESET}\n"

for pkg in git fastfetch; do
  install_package "$pkg" "$LOG"
done

# Fresh checkout every run; the installer must run from a separate checkout
rm -rf "$STAR_LORE_DIR"
if ! git clone --depth=1 "$STAR_LORE_URL" "$STAR_LORE_DIR" >>"$LOG" 2>&1; then
  echo "${ERROR} Failed to clone ${YELLOW}fastfetch-star-lore${RESET}. Check your internet connection." | tee -a "$LOG"
  exit 1
fi

# Shell hook is added below (upstream --shell uses 'all', which includes other franchises)
if ! "$STAR_LORE_DIR/install.sh" --renderer sprite >>"$LOG" 2>&1; then
  echo "${ERROR} fastfetch-star-lore install failed. See $LOG" | tee -a "$LOG"
  exit 1
fi
rm -rf "$STAR_LORE_DIR"

if [ -f "$HOME/.zshrc" ]; then
  # Replace the default fastfetch call
  sed -i "s|^fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|#fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|" "$HOME/.zshrc" >>"$LOG" 2>&1
  if ! grep -Fqx "$MARKER" "$HOME/.zshrc"; then
    printf '\n%s\nfastfetch-star-lore $(shuf -n1 -e stargate star-trek)\n' "$MARKER" >>"$HOME/.zshrc"
  fi
else
  echo "$HOME/.zshrc not found. Cant enable ${YELLOW}fastfetch-star-lore${RESET} on shell start" | tee -a "$LOG"
fi

printf "${OK} fastfetch-star-lore installed. Ensure ~/.local/bin is on PATH. Sprites need the kitty terminal.\n"
printf "\n%.0s" {1..2}
