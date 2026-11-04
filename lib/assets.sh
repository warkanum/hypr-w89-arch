#!/usr/bin/env bash
# Shared asset paths and non-destructive wallpaper installation.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME_DIR="$REPO_ROOT/assets/themes"
WALLPAPER_DIR="$REPO_ROOT/assets/wallpapers"

resolve_scheme() {
  local name="$1"
  [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid scheme: $name" >&2; return 1; }
  if [[ ! -f "$SCHEME_DIR/$name.json" && -f "$SCHEME_DIR/$name-dark.json" ]]; then
    name="$name-dark"
  fi
  [[ -f "$SCHEME_DIR/$name.json" ]] || { echo "Unknown scheme: $name" >&2; return 1; }
  printf '%s\n' "$name"
}

resolve_wallpaper() {
  local value="$1" candidate
  for candidate in "$value" "$WALLPAPER_DIR/$value" "$WALLPAPER_DIR/$value.png"; do
    if [[ -f "$candidate" ]]; then realpath -- "$candidate"; return; fi
  done
  echo "Wallpaper not found: $value" >&2
  return 1
}

copy_wallpapers() {
  local destination="$1" file
  mkdir -p -- "$destination" || return
  for file in "$WALLPAPER_DIR"/*; do
    [[ -f "$file" ]] || continue
    # Keep user files, including dangling symlinks, on repeated installs.
    [[ -e "$destination/${file##*/}" || -L "$destination/${file##*/}" ]] && continue
    cp -- "$file" "$destination/" || return
  done
  printf 'Wallpapers installed in %s (existing files kept).\n' "$destination"
}

list_desktops() {
  local directory
  for directory in "$REPO_ROOT"/desktops/*; do
    [[ -f "$directory/install.sh" && -f "$directory/theme.sh" ]] && basename "$directory"
  done
  return 0
}

require_desktop() {
  [[ "$1" =~ ^[a-zA-Z0-9_-]+$ && -f "$REPO_ROOT/desktops/$1/install.sh" && -f "$REPO_ROOT/desktops/$1/theme.sh" ]] || {
    echo "Unknown desktop: $1 (see --list-desktops)." >&2; return 1;
  }
}
