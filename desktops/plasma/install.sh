#!/usr/bin/env bash
# Standalone Arch Plasma setup. No Hyprland dotfiles or portal overrides.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../lib/assets.sh"
scheme=stargate-carbon-dark wallpaper="" destination="$HOME/Pictures/wallpapers"
theme_only=0 dry_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scheme|--wallpaper|--wallpapers-dir)
      [[ $# -ge 2 && "$2" != --* && -n "$2" ]] || { echo "$1 needs a value" >&2; exit 1; }
      case "$1" in --scheme) scheme="$2" ;; --wallpaper) wallpaper="$2" ;; --wallpapers-dir) destination="$2" ;; esac
      shift 2 ;;
    --theme-only) theme_only=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--theme-only] [--scheme NAME] [--wallpaper NAME|FILE] [--wallpapers-dir DIR] [--dry-run]"
      echo 'Installs Plasma packages, shared wallpapers and KDE colours. --theme-only skips packages.'
      exit ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
scheme="$(resolve_scheme "$scheme")"
[[ -z "$wallpaper" ]] || wallpaper="$(resolve_wallpaper "$wallpaper")"
packages=(plasma-desktop plasma-workspace systemsettings breeze breeze-icons plasma-integration
  dolphin konsole xdg-desktop-portal-kde qt6-wayland python)
if [[ "$dry_run" == 1 ]]; then
  [[ "$theme_only" == 1 ]] || printf 'Packages: %s\n' "${packages[*]}"
  printf 'Desktop: plasma\nScheme: %s\nWallpapers: %s\n' "$scheme" "$destination"
  [[ -z "$wallpaper" ]] || printf 'Apply wallpaper: %s\n' "$wallpaper"
  exit 0
fi
[[ "$EUID" != 0 ]] || { echo 'Run as your normal user; sudo is used for packages.' >&2; exit 1; }
if [[ "$theme_only" == 0 ]]; then
  command -v pacman >/dev/null || { echo 'The Plasma package installer requires Arch Linux.' >&2; exit 1; }
  sudo pacman -S --needed --noconfirm "${packages[@]}"
fi
command -v python3 >/dev/null || { echo 'python3 is required.' >&2; exit 1; }
copy_wallpapers "$destination"
if [[ ":${XDG_CURRENT_DESKTOP:-}:" == *:KDE:* && -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  args=(--desktop plasma --scheme "$scheme")
  [[ -z "$wallpaper" ]] || args+=(--wallpaper "$wallpaper")
  bash "$REPO_ROOT/desktop.sh" "${args[@]}"
else
  python3 -I "$SCHEME_DIR/kde-colors.py" "$SCHEME_DIR/$scheme.json" "$scheme"
  echo 'Plasma colours configured. Select the Plasma session in your login manager.'
  if [[ -n "$wallpaper" ]]; then
    echo 'After logging into Plasma, apply the wallpaper with:'
    printf '  %q --desktop plasma --wallpaper %q\n' "$REPO_ROOT/desktop.sh" "$wallpaper"
  fi
fi
echo 'Plasma setup complete. SDDM and boot themes can be installed separately.'
