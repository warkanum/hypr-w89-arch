#!/usr/bin/env bash
# Apply shared assets through one desktop backend.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/assets.sh"
desktop="" scheme="" wallpaper="" copy=0 destination="$HOME/Pictures/wallpapers"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --desktop|--scheme|--wallpaper|--wallpapers-dir)
      [[ $# -ge 2 && "$2" != --* && -n "$2" ]] || { echo "$1 needs a value" >&2; exit 1; }
      case "$1" in
        --desktop) desktop="$2" ;; --scheme) scheme="$2" ;;
        --wallpaper) wallpaper="$2" ;; --wallpapers-dir) destination="$2"; copy=1 ;;
      esac; shift 2 ;;
    --wallpapers) copy=1; shift ;;
    --list-desktops) list_desktops; exit ;;
    -h|--help)
      echo "Usage: $0 --desktop NAME [--scheme NAME] [--wallpaper NAME|FILE] [--wallpapers] [--wallpapers-dir DIR]"
      echo 'Applies only the requested assets. --wallpaper requires a running desktop session.'
      exit ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
require_desktop "$desktop"
[[ -z "$scheme" ]] || scheme="$(resolve_scheme "$scheme")"
[[ -z "$wallpaper" ]] || wallpaper="$(resolve_wallpaper "$wallpaper")"
[[ -n "$scheme$wallpaper" || "$copy" == 1 ]] || { echo 'Choose --scheme, --wallpaper or --wallpapers.' >&2; exit 1; }
# Each backend defines desktop_check, desktop_scheme and desktop_wallpaper.
source "$REPO_ROOT/desktops/$desktop/theme.sh"
desktop_check "$scheme" "$wallpaper"
[[ -z "$scheme" ]] || desktop_scheme "$SCHEME_DIR/$scheme.json" "$scheme"
if [[ "$copy" == 1 ]]; then copy_wallpapers "$destination"; fi
[[ -z "$wallpaper" ]] || desktop_wallpaper "$wallpaper"
