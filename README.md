# hypr-w89-arch

Stargate / Star Trek themed Arch Linux Hyprland installer.

**Credit:** fork of [LinuxBeginnings/Arch-Hyprland](https://github.com/LinuxBeginnings/Arch-Hyprland) (KooL's Arch-Hyprland). Licence GPL-3.0 (`LICENSE.md`).

## Install

| Step | Command |
|---|---|
| Run from repo root | `chmod +x install.sh && ./install.sh` |
| Preset | `./install.sh --preset <file>` |
| Single script | `cd` repo root, then `./install-scripts/<name>.sh` |
| Remove configs | `./uninstall.sh` |

- Scripts `cd` to the repo root; never run them from inside `install-scripts/`.
- Needs Arch Linux, a normal user with sudo, an internet connection.
- Logs: `Install-Logs/`.

## Menu options (themed)

| Option | What it does |
|---|---|
| `sddm_theme` | Bundled Qt6 Stargate login theme -> `/usr/share/sddm/themes/stargate` |
| `dots` | Clones LinuxBeginnings/Hyprland-Dots, then applies the theme overlay |
| `star_lore` | [fastfetch-star-lore](https://github.com/warkanum/fastfetch-star-lore), Stargate + Star Trek only |
| `kde` | Dolphin + KDE apps, Breeze, KDE portal; Qt themed with KDE (replaces Thunar/Fusion) |
| `gtk_themes` | Minimal GTK: Flat-Remix + Bibata cursor, for GTK apps only (audited, neutral) |

Other options (sddm, zsh, bluetooth, thunar, nvidia, rog, ags, quickshell) are unchanged from upstream.

## SDDM theme (`assets/sddm-stargate`)

- Pegasus-style gate: 7 glyphs dialled, chevrons lock, kawoosh on success, red flash on failure.
- Background: `stargate-space.png`. Colours: `theme.conf` (`accent`, `horizon`).
- Test: `sddm-greeter-qt6 --test-mode --theme assets/sddm-stargate`

| Key (test window) | Effect |
|---|---|
| `Ctrl+Shift+O` | Toggle open gate + blue splash |
| `Ctrl+Shift+F` | Play failed dial |

Keys are visual only; they never log in.

## Hyprland theme (`assets/hypr-themes`)

Runs after the dots (`install-scripts/hypr_theme.sh`):
installs schemes + `hypr-theme`, removes stock wallpapers and Japanese wlogout presets (sekiro, kurenai, fuji), blocks the Wallpaper-Bank download, pins `stargate-carbon`.

| Scheme | Look |
|---|---|
| `stargate-carbon` | Carbon black + Stargate blue (default) |
| `stargate-blue` | Event-horizon blue on deep navy |
| `stargate-dark` | Dark grey stone, steel-blue accent |
| `atlantis-teal` | Pegasus ocean teal |
| `ancient-aurora` | Ancient outpost green / violet aurora |
| `goauld-gold` | Gold on black |
| `wraith-hive` | Toxic green, amber |
| `replicator-silver` | Cold silver-grey |
| `star-trek-lcars` | Orange / peach / violet on black |
| `starfleet-blue` | Command gold, science blue, ops red |
| `vulcan-amber` | Desert amber |
| `klingon-red` | Blood red on black |
| `romulan-green` | Dark green |
| `borg-collective` | Terminal green on black |
| `section-31` | Near-black, muted steel |

| Command | Does |
|---|---|
| `hypr-theme list` | List schemes |
| `hypr-theme current` | Show active |
| `hypr-theme set <name>` | Apply to waybar, rofi, kitty, hyprland, etc. |

- Wallpapers: `assets/hypr-themes/wallpapers/` -> `~/Pictures/wallpapers`.
- Includes Stargate, Atlantis, dark-grey, and LCARS wallpapers. The two Starfleet wallpapers remain missing; prompts and generation status are in `assets/hypr-themes/WALLPAPERS.md`.

## KDE mode (`install-scripts/kde.sh` + `hypr_theme.sh`)

- Also: kwallet + kwallet-pam (auto-unlock via SDDM PAM, needs wallet password = login password), kwalletmanager, ksshaskpass (`SSH_ASKPASS`), kdeconnect, kcalc, kdialog, kfind, filelight, partitionmanager.
- Warns if gnome-keyring is installed (both claim `org.freedesktop.secrets`); it is never removed.
- Installs dolphin, ark, kio-extras, gwenview, okular, kate, breeze, plasma-integration, xdg-desktop-portal-kde.
- Dolphin = default file manager; KDE file chooser portal.
- After the dots: `QT_QPA_PLATFORMTHEME=kde`, Fusion override removed, `files = dolphin`.
- `hypr-theme set` also writes `~/.local/share/color-schemes/<name>.colors` and merges it into `~/.config/kdeglobals` (Breeze style, breeze-dark icons).
- Select `kde` before `dots` (menu order does this).

## Known gaps

- `auto-install.sh` still clones the upstream repo (LinuxBeginnings/Arch-Hyprland).
- Hyprlock uses the current wallpaper; swaync, ags and quickshell audited, no anime content.
- Remaining wlogout presets: default, silvia (nebula), hadi493, BlueBerries (neon street).
- GTK apps (browsers etc.) are not KDE-themed; GTK pack is kept minimal.
- Install scripts verified with `bash -n` only; full install not yet run.

See `CHANGELOGS.md`.
