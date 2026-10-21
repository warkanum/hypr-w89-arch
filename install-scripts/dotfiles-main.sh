#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Hyprland-Dots to download from main #


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

# Block the Wallpaper-Bank download (not Stargate / Star Trek content)
export WALLPAPER_BANK_REPO="file:///nonexistent"

# Bundled dots (see vendor/SOURCES.txt)
printf "${NOTE} Installing bundled ${SKY_BLUE}KooL's Hyprland Dots${RESET}....\n"

if [ -d vendor/Hyprland-Dots ]; then
  cd vendor/Hyprland-Dots || exit 1
  chmod +x copy.sh
  ./copy.sh
else
  echo -e "$ERROR ${YELLOW}vendor/Hyprland-Dots${RESET} not found. Run from the repo root."
fi

printf "\n%.0s" {1..2}