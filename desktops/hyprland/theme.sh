#!/usr/bin/env bash
# Sourced by desktop.sh; the installed dots own Hyprland's wallust templates.
desktop_check() {
  if [[ -n "$1" ]]; then
    command -v hypr-theme >/dev/null || { echo 'Install the Hyprland dots and theme overlay first (hypr-theme is required).' >&2; return 1; }
  fi
  if [[ -n "$2" ]]; then
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || { echo 'Apply the wallpaper from a running Hyprland session.' >&2; return 1; }
    command -v awww >/dev/null || command -v swww >/dev/null || { echo 'awww or swww is required.' >&2; return 1; }
  fi
}
desktop_scheme() {
  HYPR_THEME_NO_KDE=1 hypr-theme set "$2"
}
desktop_wallpaper() {
  local engine=swww
  command -v awww >/dev/null && engine=awww
  "$engine" img "$1"
}
