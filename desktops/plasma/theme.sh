#!/usr/bin/env bash
# Sourced by desktop.sh. Use Plasma's own tools to notify running applications.
desktop_check() {
  if [[ -n "$1" ]]; then
    command -v python3 >/dev/null || { echo 'python3 is required.' >&2; return 1; }
    command -v plasma-apply-colorscheme >/dev/null || { echo 'plasma-apply-colorscheme is required.' >&2; return 1; }
  fi
  if [[ -n "$2" ]]; then
    [[ ":${XDG_CURRENT_DESKTOP:-}:" == *:KDE:* && -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || {
      echo 'Apply the wallpaper from a running Plasma session.' >&2; return 1;
    }
    command -v plasma-apply-wallpaperimage >/dev/null || { echo 'plasma-apply-wallpaperimage is required.' >&2; return 1; }
  fi
}
desktop_scheme() {
  # Generate only; Plasma activates and merges the palette itself.
  python3 -I "$SCHEME_DIR/kde-colors.py" "$1" "$2" --generate-only
  plasma-apply-colorscheme "$2"
}
desktop_wallpaper() {
  plasma-apply-wallpaperimage "$1"
}
