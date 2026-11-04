#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/assets.sh"
case "${1:---help}" in
  --list) for file in "$WALLPAPER_DIR"/*; do [[ -f "$file" ]] && basename "$file"; done ;;
  --install) [[ $# -le 2 ]] || exit 1; copy_wallpapers "${2:-$HOME/Pictures/wallpapers}" ;;
  -h|--help) echo "Usage: $0 --list | --install [DIR]" ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac
