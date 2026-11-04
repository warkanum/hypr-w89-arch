#!/usr/bin/env bash
# Desktop dispatcher. The existing no-argument Hyprland menu remains the default.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/assets.sh"
desktop=hyprland
case "${1:-}" in
  --desktop) [[ $# -ge 2 ]] || { echo '--desktop needs a name' >&2; exit 1; }; desktop="$2"; shift 2 ;;
  --list-desktops) list_desktops; exit ;;
  -h|--help)
    echo "Usage: $0 [--desktop NAME] [desktop installer options]"
    echo "Default: hyprland (existing interactive installer; accepts --preset FILE)."
    echo "Plasma: --desktop plasma [--theme-only] [--scheme NAME] [--wallpaper NAME|FILE] [--dry-run]"
    echo "Use --list-desktops to list available backends."
    exit ;;
esac
require_desktop "$desktop"
exec bash "$REPO_ROOT/desktops/$desktop/install.sh" "$@"
