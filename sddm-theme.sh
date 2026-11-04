#!/usr/bin/env bash
# Named Qt6 SDDM themes, independent of the selected desktop environment.
# Usage: ./sddm-theme.sh <command> [options]
# Commands: themes, set, test, export, remove, status, schemes, backgrounds
#   --theme NAME        bundled theme (default stargate)
#   --scheme NAME       shared accent palette
#   --background FILE   shared wallpaper name or external file
#   --output DIR        new output directory for export
#   --theme-dir DIR     custom self-contained theme source
#   --no-animations     static Destiny, Atlantis or LCARS theme
#   --kitty             also apply --scheme to Kitty (set only)
#   --wallpapers [DIR]  copy shared wallpapers (set only)
set -euo pipefail
here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$here/lib/assets.sh"
collection="$here/assets/sddm-themes"
action="${1:-set}"
[[ $# -eq 0 ]] || shift
name=stargate scheme="" background="" output="" custom="" kitty=0 wallpapers=0 no_animations=0
wall_dir="$HOME/Pictures/wallpapers"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme|--scheme|--background|--output|--theme-dir)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "$1 needs a value" >&2; exit 1; }
      case "$1" in
        --theme) name="$2" ;; --scheme) scheme="$2" ;; --background) background="$2" ;;
        --output) output="$2" ;; --theme-dir) custom="$2" ;;
      esac; shift 2 ;;
    --kitty) kitty=1; shift ;;
    --no-animations) no_animations=1; shift ;;
    --wallpapers) wallpapers=1; if [[ $# -gt 1 && "$2" != --* ]]; then wall_dir="$2"; shift; fi; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
case "$action" in
  themes)
    for directory in "$collection"/*; do [[ ! -f "$directory/metadata.desktop" ]] || basename "$directory"; done
    exit 0 ;;
  -h|--help|help) sed -n '/^# Usage:/,/^set /p' "$0" | sed '$d; s/^# \?//'; exit 0 ;;
  schemes) for file in "$SCHEME_DIR"/*.json; do basename "$file" .json; done; exit 0 ;;
  set|test|export|remove|status|backgrounds) ;;
  *) echo "Unknown command: $action (see --help)." >&2; exit 1 ;;
esac
[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || { echo 'Invalid theme name' >&2; exit 1; }
src="${custom:-$collection/$name}"
[[ -f "$src/metadata.desktop" && -f "$src/Main.qml" && -f "$src/theme.conf" ]] || { echo "Unknown or incomplete theme: $name ($src)" >&2; exit 1; }
dest="/usr/share/sddm/themes/$name"
# A single managed drop-in and backup prevent variants from overriding each other.
dropin=/etc/sddm.conf.d/10-stargate-theme.conf
main_conf=/etc/sddm.conf
backup=/etc/sddm.conf.stargate.bak
current_theme() {
  { cat /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf "$main_conf" 2>/dev/null || true; } |
    awk '/^\[/{s=$0} s=="[Theme]" && /^[ \t]*Current=/{sub(/^[^=]*=/,""); v=$0} END{print v}'
}
if [[ "$action" == status ]]; then
  echo "Active theme: $(current_theme)"
  if [[ -d "$dest" ]]; then echo "Installed: $dest"; else echo "Installed: no ($name)"; fi
  exit 0
fi
if [[ "$action" == backgrounds ]]; then
  find "$src" "$WALLPAPER_DIR" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sed 's/\.png$//' | sort -u
  exit 0
fi
[[ -z "$scheme" ]] || scheme="$(resolve_scheme "$scheme")"
if [[ "$kitty" == 1 && -z "$scheme" ]]; then scheme=stargate-carbon-dark; fi
if [[ -n "$background" ]]; then
  if [[ -f "$src/$background" ]]; then background="$src/$background"
  elif [[ -f "$src/$background.png" ]]; then background="$src/$background.png"
  else background="$(resolve_wallpaper "$background")"; fi
fi
if [[ "$action" == set || "$action" == remove ]]; then
  [[ "$EUID" != 0 ]] || { echo 'Run as your normal user; sudo is used where needed.' >&2; exit 1; }
fi
if [[ "$action" == remove ]]; then
  # Removing an inactive variant must not change the current login theme.
  if [[ "$(current_theme)" == "$name" ]]; then
    sudo rm -f "$dropin"
    if [[ -f "$backup" ]]; then sudo cp "$backup" "$main_conf"; sudo rm -f "$backup"; fi
  fi
  sudo rm -rf "$dest"
  echo "Removed $name. Active theme: $(current_theme)"
  exit 0
fi
command -v python3 >/dev/null || { echo 'python3 is required to assemble themes.' >&2; exit 1; }
args=(--theme "$name")
[[ "$no_animations" == 0 ]] || args+=(--no-animations)
[[ -z "$custom" ]] || args+=(--source "$custom")
[[ -z "$scheme" ]] || args+=(--scheme "$SCHEME_DIR/$scheme.json")
[[ -z "$background" ]] || args+=(--background "$background")
if [[ "$action" == export ]]; then
  [[ -n "$output" ]] || { echo 'export requires --output DIR (must not exist).' >&2; exit 1; }
  python3 -I "$here/lib/sddm_theme.py" "${args[@]}" --output "$output"
  echo "Exported $name to $output"
  exit 0
fi
if [[ "$action" == test ]]; then
  command -v sddm-greeter-qt6 >/dev/null || { echo 'sddm-greeter-qt6 is required (install sddm).' >&2; exit 1; }
fi
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
python3 -I "$here/lib/sddm_theme.py" "${args[@]}" --output "$staging/theme"
if [[ "$action" == test ]]; then
  echo "Previewing $name; close the window to finish. No login settings are changed."
  sddm-greeter-qt6 --test-mode --theme "$staging/theme"
  exit 0
fi
sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
sudo rm -rf "$dest"
sudo cp -r "$staging/theme" "$dest"
if [[ -f "$main_conf" && ! -f "$backup" ]]; then sudo cp "$main_conf" "$backup"; fi
printf '[Theme]\nCurrent=%s\n' "$name" | sudo tee "$dropin" >/dev/null
if [[ -f "$main_conf" ]]; then
  sudo sed -i -E "/^\[Theme\]/,/^\[/ s/^[[:space:]]*Current=.*/Current=$name/" "$main_conf"
fi
if [[ "$kitty" == 1 ]]; then python3 -I "$SCHEME_DIR/apply-targets.py" kitty "$SCHEME_DIR/$scheme.json" "$scheme"; fi
if [[ "$wallpapers" == 1 ]]; then copy_wallpapers "$wall_dir"; fi
echo "Installed $name. Takes effect at the next login screen."
