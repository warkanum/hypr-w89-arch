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
| `gtk_themes` | Upstream Flat-Remix GTK themes + Bibata cursor (audited, neutral) |

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
- Missing: Star Trek wallpapers. Prompts in `assets/hypr-themes/WALLPAPERS.md`.

## Known gaps

- `auto-install.sh` still clones the upstream repo (LinuxBeginnings/Arch-Hyprland).
- Hyprlock uses the current wallpaper; swaync, ags and quickshell audited, no anime content.
- Remaining wlogout presets: default, silvia (nebula), hadi493, BlueBerries (neon street).
- Install scripts verified with `bash -n` only; full install not yet run.

See `CHANGELOGS.md`.
