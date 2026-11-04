# Desktop backends

Shared wallpapers live in `assets/wallpapers/`; palettes and application colour
converters live in `assets/themes/`. Wallpaper prompts live in `assets/WALLPAPERS.md`.
`lib/assets.sh` provides discovery, name resolution and non-destructive wallpaper
copying. SDDM, boot themes and shell themes remain independent of desktop choice.

Each desktop has its own directory containing:

- `install.sh`: executable installer, accepting `--help`, responsible for its own packages and configuration.
- `theme.sh`: sourced adapter defining `desktop_check SCHEME WALLPAPER`,
  `desktop_scheme JSON_FILE SCHEME_NAME` and `desktop_wallpaper ABSOLUTE_FILE`.

`desktop_check` receives empty strings for operations that were not requested.
It must check dependencies and session requirements before any settings change.
All adapter operations must return a nonzero status on failure. Paths and names
are validated by `desktop.sh` before invoking the adapter.

Add a directory with these two files to support another desktop. `install.sh
--list-desktops` and `desktop.sh --list-desktops` discover backends automatically;
no central case statement or asset copy is needed. Common app theming is available
through `theme.sh`; desktop packages and session settings belong in the backend.

The Hyprland installer retains the existing interactive package/dotfiles flow.
Its theme overlay installs `hypr-theme` into `~/.local/bin`; the installed
`~/.local/share/hypr-themes` location is retained for existing users. Rerun the
overlay after updating the checkout to refresh its installed palettes and helper.
The KDE-apps option in that installer configures KDE applications inside Hyprland;
it is separate from installing a Plasma desktop.

The Plasma installer installs a basic desktop and copies the shared wallpapers.
Outside a Plasma session it configures KDE colours for the next login; inside
Plasma it activates them with `plasma-apply-colorscheme`. An explicitly requested
wallpaper is applied with `plasma-apply-wallpaperimage` in a running Plasma
session. Offline installs print the command to run after login. Wallpaper-only
application requires the corresponding live desktop and a running wallpaper
daemon on Hyprland (`awww` or `swww`). The installer does not choose a display
manager or change its enabled service; use the existing login setup or install
SDDM separately.

Plasma's wallpaper tool ships in
[plasma-workspace](https://archlinux.org/packages/extra/x86_64/plasma-workspace/files/).
See also [KDE's desktop scripting documentation](https://develop.kde.org/docs/plasma/scripting/).

Run the isolated smoke tests with `python3 -m unittest discover -s tests -v`.
They mock desktop commands and never install packages or change the live session.
