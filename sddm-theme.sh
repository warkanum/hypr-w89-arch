#!/bin/bash
# ==================================================
#  Stargate SDDM theme: standalone installer (no install.sh needed)
#  Based on KooL's Arch-Hyprland by LinuxBeginnings
#  https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Usage: ./sddm-theme.sh <command> [options]
#
# Commands
#   set        install the theme and make it the active SDDM theme (default)
#   test       preview in a window (sddm-greeter-qt6 --test-mode); installs nothing
#   remove     delete the theme and restore the previous SDDM config
#   status     show the active theme
#   schemes    list colour schemes
#   backgrounds list bundled backgrounds
#
# Options (set and test)
#   --scheme NAME        colour scheme from assets/hypr-themes (sets SDDM accent + gate colour)
#   --background FILE    bundled image name (see 'backgrounds') or a path to an image; copied into the theme
#   --kitty              also write a kitty theme from --scheme and select it (set only)
#   --wallpapers [DIR]   also copy the bundled wallpapers to DIR (default ~/Pictures/wallpapers) (set only)
#   --theme-dir DIR      theme source (default assets/sddm-stargate next to this script)

set -u
here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
themes="$here/assets/hypr-themes"
name="stargate"
dest="/usr/share/sddm/themes/$name"
dropin="/etc/sddm.conf.d/10-$name-theme.conf"
main_conf="/etc/sddm.conf"
backup="/etc/sddm.conf.$name.bak"

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; sudo is used where needed." >&2
  exit 1
fi

action="${1:-set}"
[ $# -gt 0 ] && shift

src="$here/assets/sddm-stargate"
scheme="" background="" kitty=0 wallpapers=0 wall_dir="$HOME/Pictures/wallpapers"
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme)      scheme="${2:?--scheme needs a name}"; shift 2 ;;
    --background)  background="${2:?--background needs a file}"; shift 2 ;;
    --kitty)       kitty=1; shift ;;
    --wallpapers)  wallpapers=1; if [ $# -gt 1 ] && [[ "$2" != --* ]]; then wall_dir="$2"; shift; fi; shift ;;
    --theme-dir)   src="${2:?--theme-dir needs a path}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

current_theme() {
  { cat /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf "$main_conf" 2>/dev/null; } |
    awk '/^\[/{s=$0} s=="[Theme]" && /^[ \t]*Current=/{sub(/^[^=]*=/,""); v=$0} END{print v}'
}

scheme_file() { echo "$themes/$1.json"; }

# Resolve --scheme and --background up front so mistakes fail before anything is changed
if [ "$kitty" -eq 1 ] && [ -z "$scheme" ]; then scheme="stargate-carbon"; fi
if [ -n "$scheme" ] && [ ! -f "$(scheme_file "$scheme")" ]; then
  echo "Unknown scheme: $scheme (see: $0 schemes)" >&2; exit 1
fi
bg_path=""
if [ -n "$background" ]; then
  if [ -f "$background" ]; then bg_path="$background"
  elif [ -f "$src/$background" ]; then bg_path="$src/$background"
  elif [ -f "$src/$background.png" ]; then bg_path="$src/$background.png"
  elif [ -f "$themes/wallpapers/$background" ]; then bg_path="$themes/wallpapers/$background"
  elif [ -f "$themes/wallpapers/$background.png" ]; then bg_path="$themes/wallpapers/$background.png"
  else echo "Background not found: $background (see: $0 backgrounds)" >&2; exit 1; fi
fi
if { [ -n "$scheme" ] || [ "$kitty" -eq 1 ]; } && ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for --scheme/--kitty." >&2; exit 1
fi

# Write theme.conf for the chosen options into directory $1 (using $2 as the command prefix)
write_theme_conf() { # $1 = theme dir, $2 = "sudo" or ""
  local dir="$1" run="$2" accent horizon bg conf
  conf="$(cat "$src/theme.conf")"
  if [ -n "$scheme" ]; then
    read -r accent horizon < <(python3 -I - "$(scheme_file "$scheme")" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(d["special"]["cursor"], d["colors"]["color6"])
PY
)
    conf="$(printf '%s\n' "$conf" | sed -E "s/^accent=.*/accent=$accent/; s/^horizon=.*/horizon=$horizon/")"
  fi
  if [ -n "$bg_path" ]; then
    bg="$(basename "$bg_path")"
    [ -f "$dir/$bg" ] || $run cp "$bg_path" "$dir/$bg"
    conf="$(printf '%s\n' "$conf" | grep -v '^background=')"
    conf="$conf"$'\n'"background=$bg"
  fi
  printf '%s\n' "$conf" | $run tee "$dir/theme.conf" >/dev/null
}

# Write a kitty theme from the scheme and select it
apply_kitty() {
  local out_dir="$HOME/.config/hypr/UserConfigs/kitty-themes" kconf="$HOME/.config/hypr/UserConfigs/kitty.conf" file
  if [ ! -f "$kconf" ]; then
    out_dir="$HOME/.config/kitty/themes"; kconf="$HOME/.config/kitty/kitty.conf"
  fi
  mkdir -p "$out_dir" "$(dirname "$kconf")"
  file="$out_dir/$scheme.conf"
  python3 -I - "$(scheme_file "$scheme")" > "$file" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
c, s = d["colors"], d["special"]
print(f"foreground {s['foreground']}\nbackground {s['background']}\ncursor {s['cursor']}")
print(f"selection_foreground {s['background']}\nselection_background {s['foreground']}")
print(f"active_tab_foreground {s['background']}\nactive_tab_background {s['cursor']}")
print(f"inactive_tab_foreground {s['foreground']}\ninactive_tab_background {c['color0']}")
print(f"active_border_color {s['cursor']}\ninactive_border_color {c['color8']}")
for i in range(16):
    print(f"color{i} {c['color%d' % i]}")
PY
  touch "$kconf"
  if grep -Eq '^include .*kitty-themes/.*\.conf|^include .*themes/.*\.conf' "$kconf"; then
    sed -i -E "s|^(include ).*themes/[^/]*\.conf|\1$out_dir/$scheme.conf|" "$kconf"
  else
    printf '\ninclude %s\n' "$out_dir/$scheme.conf" >> "$kconf"
  fi
  echo "Kitty theme: $file (selected in $kconf). Open kitty windows reload with ctrl+shift+f5."
  # Wallust rewrites 01-Wallust.conf only; this file is not touched by it.
}

copy_wallpapers() {
  mkdir -p "$wall_dir"
  cp -n "$themes"/wallpapers/* "$wall_dir/" 2>/dev/null
  echo "Wallpapers copied to $wall_dir ($(ls "$themes"/wallpapers | wc -l) bundled; existing files kept)."
}

case "$action" in
  set)
    [ -f "$src/Main.qml" ] || { echo "Theme source not found: $src" >&2; exit 1; }
    command -v sddm >/dev/null 2>&1 || echo "Warning: sddm is not installed (pacman -S sddm); the theme is installed anyway."
    sudo rm -rf "$dest"
    sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
    sudo cp -r "$src" "$dest"
    write_theme_conf "$dest" sudo
    if [ -f "$main_conf" ] && [ ! -f "$backup" ]; then sudo cp "$main_conf" "$backup"; fi
    printf '[Theme]\nCurrent=%s\n' "$name" | sudo tee "$dropin" >/dev/null
    # /etc/sddm.conf wins over conf.d, so update a Current= there too
    if [ -f "$main_conf" ] && grep -Eq '^[[:space:]]*Current=' "$main_conf"; then
      sudo sed -i -E "/^\[Theme\]/,/^\[/ s/^[[:space:]]*Current=.*/Current=$name/" "$main_conf"
    fi
    echo "Installed $dest, active theme: $(current_theme)${scheme:+, scheme: $scheme}${bg_path:+, background: $(basename "$bg_path")}"
    [ "$kitty" -eq 1 ] && apply_kitty
    [ "$wallpapers" -eq 1 ] && copy_wallpapers
    echo "Takes effect at the next login screen (log out or restart sddm)."
    ;;
  test)
    command -v sddm-greeter-qt6 >/dev/null 2>&1 || { echo "sddm-greeter-qt6 not found (install sddm)." >&2; exit 1; }
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    cp -r "$src/." "$tmp/"
    write_theme_conf "$tmp" ""
    echo "Keys in the window: Ctrl+Shift+O open gate, Ctrl+Shift+F failed dial"
    sddm-greeter-qt6 --test-mode --theme "$tmp"
    ;;
  remove)
    sudo rm -rf "$dest" "$dropin"
    if [ -f "$backup" ]; then sudo cp "$backup" "$main_conf" && sudo rm -f "$backup"; fi
    echo "Removed $name theme. Active theme now: $(current_theme)"
    ;;
  status)
    echo "Active theme: $(current_theme)"
    [ -d "$dest" ] && echo "Installed:    $dest" || echo "Installed:    no"
    ;;
  schemes)
    for f in "$themes"/*.json; do basename "$f" .json; done
    ;;
  backgrounds)
    for f in "$src"/*.png "$themes"/wallpapers/*.png; do basename "$f" .png; done | sort -u
    ;;
  *)
    sed -n '/^# Usage/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
    exit 1
    ;;
esac
