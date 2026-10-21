#!/bin/bash
# ==================================================
#  Stargate boot chain: Plymouth splash + GRUB theme
#  Based on KooL's Arch-Hyprland by LinuxBeginnings
#  https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Changes the initramfs hooks and kernel command line, so every edited file is backed up first.
# Usage: boot_theme.sh            install
#        boot_theme.sh --revert   restore the newest backup

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_boot_theme.log"
src="assets/boot-stargate"
backup_root="$HOME/.cache/hypr-w89-boot-backup"
mkinit=/etc/mkinitcpio.conf
grub_default=/etc/default/grub

# Newest backup directory, or empty
latest_backup() { ls -1d "$backup_root"/*/ 2>/dev/null | sort | tail -n1; }

if [ "$1" = "--revert" ]; then
  b="$(latest_backup)"
  [ -n "$b" ] || { echo "${ERROR} No backup found in $backup_root" | tee -a "$LOG"; exit 1; }
  echo "${NOTE} Restoring from $b" | tee -a "$LOG"
  [ -f "$b/mkinitcpio.conf" ] && sudo cp -f "$b/mkinitcpio.conf" "$mkinit"
  [ -f "$b/grub" ] && sudo cp -f "$b/grub" "$grub_default"
  if [ -d "$b/entries" ]; then
    sudo cp -f "$b"/entries/*.conf /boot/loader/entries/
  fi
  [ -f "$b/cmdline" ] && sudo cp -f "$b/cmdline" /etc/kernel/cmdline
  sudo mkinitcpio -P 2>&1 | tee -a "$LOG"
  [ -f /boot/grub/grub.cfg ] && sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tee -a "$LOG"
  echo "${OK} Reverted. Reboot to apply." | tee -a "$LOG"
  exit 0
fi

for d in plymouth grub; do
  [ -d "$src/$d" ] || { echo "${ERROR} $src/$d not found. Run from the repo root." | tee -a "$LOG"; exit 1; }
done

# Detect bootloader
bootloader=""
if [ -f "$grub_default" ] && sudo test -d /boot/grub; then
  bootloader="grub"
elif sudo test -d /boot/loader || sudo test -d /efi/loader || sudo bootctl is-installed >/dev/null 2>&1; then
  bootloader="systemd-boot"
fi
echo "${INFO} Bootloader: ${SKY_BLUE}${bootloader:-unknown}${RESET}" | tee -a "$LOG"

cat <<MSG
${NOTE} This will:
  - install plymouth, add the 'plymouth' hook to $mkinit, rebuild the initramfs
  - add 'quiet splash' to the kernel command line
  - GRUB only: install the GRUB theme and regenerate grub.cfg
  Backups: $backup_root
  Undo:    $0 --revert
MSG
read -r -p "Continue? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "${NOTE} Cancelled."; exit 0; }

ts="$(date +%Y%m%d-%H%M%S)"
bdir="$backup_root/$ts"
mkdir -p "$bdir"
[ -f "$mkinit" ] && cp "$mkinit" "$bdir/mkinitcpio.conf"
[ -f "$grub_default" ] && cp "$grub_default" "$bdir/grub"
[ -f /etc/kernel/cmdline ] && cp /etc/kernel/cmdline "$bdir/cmdline"

if [ "$(bootctl status 2>/dev/null | awk -F': ' '/Secure Boot/ {print $2; exit}' | cut -d' ' -f1)" = "enabled" ]; then
  echo "${WARN} Secure Boot is enabled. If you sign your initramfs or use unified kernel images, re-sign after the rebuild." | tee -a "$LOG"
fi

# --- Plymouth ---------------------------------------------------------------
install_package plymouth "$LOG"
sudo mkdir -p /usr/share/plymouth/themes/stargate
sudo cp -f "$src"/plymouth/* /usr/share/plymouth/themes/stargate/

# Hook order: after systemd (systemd initramfs) or after udev/base (busybox initramfs)
if ! grep -Eq '^HOOKS=.*\bplymouth\b' "$mkinit"; then
  if grep -Eq '^HOOKS=.*\bsystemd\b' "$mkinit"; then
    sudo sed -i -E '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' "$mkinit"
  elif grep -Eq '^HOOKS=.*\budev\b' "$mkinit"; then
    sudo sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' "$mkinit"
  else
    sudo sed -i -E '/^HOOKS=/ s/\bbase\b/base plymouth/' "$mkinit"
  fi
  echo "${OK} Added plymouth hook." | tee -a "$LOG"
fi
grep '^HOOKS=' "$mkinit" | tee -a "$LOG"

# Kernel command line
add_params() { # $1 = string, echoes it with quiet/splash added once
  local out="$1"
  [[ " $out " == *" quiet "* ]] || out="$out quiet"
  [[ " $out " == *" splash "* ]] || out="$out splash"
  echo "$out"
}

case "$bootloader" in
  grub)
    cur="$(sed -n -E 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"/\1/p' "$grub_default")"
    new="$(add_params "$cur")"
    sudo sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new\"|" "$grub_default"
    ;;
  systemd-boot)
    if [ -f /etc/kernel/cmdline ]; then
      new="$(add_params "$(cat /etc/kernel/cmdline)")"
      echo "$new" | sudo tee /etc/kernel/cmdline >/dev/null
    fi
    # /boot is root-only on systemd-boot installs, so list and glob through sudo
    if sudo test -d /boot/loader/entries; then
      mkdir -p "$bdir/entries"
      while IFS= read -r e; do
        sudo cp "$e" "$bdir/entries/"
        sudo grep -q '^options' "$e" || continue
        sudo grep -Eq '^options.*\bsplash\b' "$e" || sudo sed -i -E '/^options/ s/$/ quiet splash/' "$e"
      done < <(sudo find /boot/loader/entries -name '*.conf')
    fi
    ;;
  *)
    echo "${WARN} Unknown bootloader. Add 'quiet splash' to your kernel command line yourself." | tee -a "$LOG"
    ;;
esac

# --- GRUB theme -------------------------------------------------------------
if [ "$bootloader" = "grub" ]; then
  theme_dir=/boot/grub/themes/stargate
  sudo mkdir -p "$theme_dir"
  sudo cp -f "$src"/grub/* "$theme_dir/"
  # Font used by theme.txt ("Unifont Regular 16")
  if [ -f /usr/share/grub/unicode.pf2 ]; then
    sudo cp -f /usr/share/grub/unicode.pf2 "$theme_dir/unicode.pf2"
  fi
  if grep -q '^#\?GRUB_THEME=' "$grub_default"; then
    sudo sed -i -E "s|^#?GRUB_THEME=.*|GRUB_THEME=\"$theme_dir/theme.txt\"|" "$grub_default"
  else
    echo "GRUB_THEME=\"$theme_dir/theme.txt\"" | sudo tee -a "$grub_default" >/dev/null
  fi
  if grep -q '^#\?GRUB_GFXMODE=' "$grub_default"; then
    sudo sed -i -E 's|^#?GRUB_GFXMODE=.*|GRUB_GFXMODE=auto|' "$grub_default"
  else
    echo 'GRUB_GFXMODE=auto' | sudo tee -a "$grub_default" >/dev/null
  fi
  sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tee -a "$LOG"
  echo "${OK} GRUB theme installed." | tee -a "$LOG"
fi

# Set the Plymouth theme and rebuild the initramfs
sudo plymouth-set-default-theme -R stargate 2>&1 | tee -a "$LOG"
echo "${OK} Plymouth theme set. Reboot to see it. Backups: $bdir" | tee -a "$LOG"
printf "\n%.0s" {1..2}
