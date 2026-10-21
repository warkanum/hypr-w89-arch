#!/bin/bash
# ==================================================
#  Stargate / Star Trek: choose where a colour scheme is applied
#  Based on KooL's Arch-Hyprland by LinuxBeginnings
#  https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Usage: ./theme.sh                       interactive (pick scheme, then targets)
#        ./theme.sh --scheme NAME [targets]
#   --kitty    kitty terminal theme
#   --gtk      GTK3/GTK4 colours (gtk.css, dark preference)
#   --kde      KDE/Qt colour scheme (kdeglobals)
#   --sddm     SDDM login theme (runs sddm-theme.sh set, asks for sudo)
#   --zsh [THEME]  zsh prompt/highlight colours; THEME = stargate | lcars | stargate-minimal sets ZSH_THEME
#   --hypr     Hyprland/waybar/rofi colours via hypr-theme (needs the dots installed)
#   --wallpapers [DIR]  copy the bundled wallpapers (default ~/Pictures/wallpapers, existing files kept)
#   --all      every target (including wallpapers)
#   --list     list schemes

set -u
here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
themes="$here/assets/hypr-themes"

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user." >&2
  exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }

list() { for f in "$themes"/*.json; do basename "$f" .json; done; }

scheme="" t_kitty=0 t_gtk=0 t_kde=0 t_sddm=0 t_hypr=0 t_wall=0 t_zsh=0 zsh_theme="" wall_dir="$HOME/Pictures/wallpapers"
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme) scheme="${2:?--scheme needs a name}"; shift 2 ;;
    --kitty) t_kitty=1; shift ;;
    --gtk)   t_gtk=1; shift ;;
    --kde)   t_kde=1; shift ;;
    --sddm)  t_sddm=1; shift ;;
    --zsh)   t_zsh=1; if [ $# -gt 1 ] && [[ "$2" != --* ]]; then zsh_theme="$2"; shift; fi; shift ;;
    --hypr)  t_hypr=1; shift ;;
    --wallpapers) t_wall=1; if [ $# -gt 1 ] && [[ "$2" != --* ]]; then wall_dir="$2"; shift; fi; shift ;;
    --all)   t_kitty=1; t_gtk=1; t_kde=1; t_sddm=1; t_hypr=1; t_wall=1; t_zsh=1; shift ;;
    --list)  list; exit 0 ;;
    -h|--help) sed -n '/^# Usage/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Interactive when no scheme or no target was given
if [ -z "$scheme" ] || [ $((t_kitty + t_gtk + t_kde + t_sddm + t_hypr + t_wall + t_zsh)) -eq 0 ]; then
  if command -v whiptail >/dev/null 2>&1; then
    if [ -z "$scheme" ]; then
      args=()
      while read -r n; do args+=("$n" "" "OFF"); done < <(list)
      args[2]="ON"
      scheme="$(whiptail --title "Colour scheme" --radiolist "Choose a scheme" 24 60 15 "${args[@]}" 3>&1 1>&2 2>&3)" || exit 0
    fi
    if [ $((t_kitty + t_gtk + t_kde + t_sddm + t_hypr + t_wall + t_zsh)) -eq 0 ]; then
      picked="$(whiptail --title "Apply $scheme to" --checklist "Choose targets" 17 70 7 \
        kitty "Kitty terminal theme" ON \
        gtk   "GTK3/GTK4 colours" ON \
        kde   "KDE/Qt colour scheme" ON \
        zsh   "zsh prompt + highlight colours" ON \
        sddm  "SDDM login theme (sudo)" OFF \
        hypr  "Hyprland, waybar, rofi (hypr-theme)" OFF \
        wall  "Copy bundled wallpapers to $wall_dir" OFF 3>&1 1>&2 2>&3)" || exit 0
      for t in $(echo "$picked" | tr -d '"'); do printf -v "t_$t" '%s' 1; done
      if [ "$t_zsh" -eq 1 ]; then
        zsh_theme="$(whiptail --title "zsh prompt theme" --radiolist "Prompt theme" 14 60 4 \
          keep "Keep current ZSH_THEME" ON stargate "Gate glyph, two lines" OFF \
          lcars "Rounded LCARS segments" OFF stargate-minimal "Path and chevron" OFF 3>&1 1>&2 2>&3)" || zsh_theme=""
        [ "$zsh_theme" = "keep" ] && zsh_theme=""
      fi
    fi
  else
    echo "whiptail not found; pass --scheme NAME and target flags (see --help)." >&2
    exit 1
  fi
fi

[ -f "$themes/$scheme.json" ] || { [ -f "$themes/$scheme-dark.json" ] && scheme="$scheme-dark"; }
file="$themes/$scheme.json"
[ -f "$file" ] || { echo "Unknown scheme: $scheme (see: $0 --list)" >&2; exit 1; }
[ $((t_kitty + t_gtk + t_kde + t_sddm + t_hypr + t_wall + t_zsh)) -gt 0 ] || { echo "No targets selected."; exit 0; }

apply() { python3 -I "$themes/apply-targets.py" "$1" "$file" "$scheme"; }

[ "$t_kitty" -eq 1 ] && apply kitty
[ "$t_gtk" -eq 1 ]   && apply gtk
[ "$t_zsh" -eq 1 ]   && HW_ZSH_THEME="$zsh_theme" apply zsh
[ "$t_kde" -eq 1 ]   && apply kde
[ "$t_sddm" -eq 1 ]  && "$here/sddm-theme.sh" set --scheme "$scheme"
if [ "$t_hypr" -eq 1 ]; then
  if command -v hypr-theme >/dev/null 2>&1; then
    HYPR_THEME_NO_KDE=1 hypr-theme set "$scheme"
  else
    echo "hypr-theme not found (install the dots option first); skipped --hypr." >&2
  fi
fi
if [ "$t_wall" -eq 1 ]; then
  mkdir -p "$wall_dir"
  cp -n "$themes"/wallpapers/* "$wall_dir/" 2>/dev/null
  echo "wallpapers: $(ls "$themes"/wallpapers | wc -l) bundled, copied to $wall_dir (existing files kept)"
fi
echo "Done: $scheme"
