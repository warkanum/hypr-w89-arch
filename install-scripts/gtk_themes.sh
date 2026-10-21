#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# GTK Themes & ICONS and  Sourcing from a different Repo #

engine=(
    unzip
)

# gtk-engine-murrine pulls gtk2 from the AUR (long source build), so it is opt-in
if [ "${GTK_MURRINE:-OFF}" = "ON" ]; then
    engine+=(gtk-engine-murrine)
fi

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


# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_themes.log"


# installing engine needed for gtk themes
for PKG1 in "${engine[@]}"; do
    install_package "$PKG1" "$LOG"
done

echo "$NOTE Installing bundled ${SKY_BLUE}GTK themes and Icons${RESET} (vendor/GTK-themes-icons)..." 2>&1 | tee -a "$LOG"
if [ -d vendor/GTK-themes-icons ]; then
    cd vendor/GTK-themes-icons
    chmod +x auto-extract.sh
    ./auto-extract.sh
    cd ../..
    echo "$OK Extracted GTK Themes & Icons to ~/.icons & ~/.themes directories" 2>&1 | tee -a "$LOG"
else
    echo "$ERROR vendor/GTK-themes-icons not found. Run from the repo root." 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}