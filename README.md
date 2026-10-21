# hypr-w89-arch

Stargate / Star Trek themed Arch Linux Hyprland installer.

**Credit:** fork of [LinuxBeginnings/Arch-Hyprland](https://github.com/LinuxBeginnings/Arch-Hyprland) (KooL's Arch-Hyprland). Licence GPL-3.0 (`LICENSE.md`).

## Scripts

| Script | Use |
|---|---|
| `./install.sh` | Full installer (menu) |
| `./theme.sh` | Apply one scheme to chosen targets; whiptail menu without arguments, else `--scheme NAME [targets]`. Targets are documented under each section below |
| `./sddm-theme.sh` | SDDM theme only, no `install.sh` |

`./theme.sh` flags: `--scheme`, `--kitty`, `--gtk`, `--kde`, `--zsh [THEME]`, `--sddm`, `--hypr`, `--wallpapers [DIR]`, `--all`, `--list`.

## SDDM theme only: `./sddm-theme.sh` (no `install.sh`)

`./sddm-theme.sh <command> [options]`

| Command | Does |
|---|---|
| `set` | Install + activate (default) |
| `test` | Preview window, installs nothing |
| `remove` | Delete theme, restore config |
| `status` / `schemes` / `backgrounds` | Show active theme / list schemes / list backgrounds |

| Option | Does |
|---|---|
| `--scheme NAME` | SDDM accent + gate colour from a palette |
| `--background NAME\|FILE` | Background image (bundled or path) |
| `--kitty` | Write + select a kitty theme from `--scheme` (default `stargate-carbon-dark`) |
| `--wallpapers [DIR]` | Copy bundled wallpapers (default `~/Pictures/wallpapers`, existing files kept) |
| `--theme-dir DIR` | Theme source |

`./theme.sh --sddm` runs `sddm-theme.sh set --scheme` (sudo).

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
| `dots` | Installs the bundled `vendor/Hyprland-Dots`, then applies the theme overlay |
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
installs schemes + `hypr-theme`, removes stock wallpapers and Japanese wlogout presets (sekiro, kurenai, fuji), blocks the Wallpaper-Bank download, pins `stargate-carbon-dark`.

| Scheme | Look |
|---|---|
| `stargate-carbon-dark` | Carbon black + Stargate blue (default) |
| `stargate-blue-dark` | Event-horizon blue on deep navy |
| `stargate-dark` | Dark grey stone, steel-blue accent |
| `atlantis-teal-dark` | Pegasus ocean teal |
| `ancient-aurora-dark` | Ancient outpost green / violet aurora |
| `goauld-gold-dark` | Gold on black |
| `wraith-hive-dark` | Toxic green, amber |
| `replicator-silver-dark` | Cold silver-grey |
| `star-trek-lcars-dark` | Orange / peach / violet on black |
| `starfleet-blue-dark` | Command gold, science blue, ops red |
| `vulcan-amber-dark` | Desert amber |
| `klingon-red-dark` | Blood red on black |
| `romulan-green-dark` | Dark green |
| `borg-collective-dark` | Terminal green on black |
| `section-31-dark` | Near-black, muted steel |
| `stargate-oled-dark` | Pure black `#000`, Stargate blue accent |
| `stargate-gunmetal-dark` | Gunmetal surfaces, ice-blue accent |
| `stargate-midnight-dark` | Very dark navy, event-horizon blue |
| `atlantis-abyss-dark` | Near-black, deep ocean teal |

All schemes are dark; names end in `-dark`. Old names (e.g. `stargate-blue`) still resolve to the `-dark` file.

| Command | Does |
|---|---|
| `hypr-theme list` | List schemes |
| `hypr-theme current` | Show active |
| `hypr-theme set <name>` | Apply to waybar, rofi, kitty, hyprland, etc. |

| `theme.sh` flag | Does |
|---|---|
| `--hypr` | `hypr-theme set` for Hyprland, waybar, rofi (needs the dots; KDE colours skipped, use `--kde`) |
| `--wallpapers [DIR]` | Copy bundled wallpapers (default `~/Pictures/wallpapers`, existing files kept) |
| `--list` | List schemes |
| `--all` | Every target |

- Wallpapers: `assets/hypr-themes/wallpapers/` -> `~/Pictures/wallpapers`.
- Includes Stargate, Atlantis, dark-grey, and LCARS wallpapers. The two Starfleet wallpapers remain missing; prompts and generation status are in `assets/hypr-themes/WALLPAPERS.md`.

## Kitty (`theme.sh --kitty`)

- Writes the scheme as a kitty theme next to every existing `kitty.conf` (`$KITTY_CONFIG_DIRECTORY`, `~/.config/kitty`, hypr `UserConfigs`), repoints the include line, reloads running kitty (SIGUSR1).

## GTK (`theme.sh --gtk`)

- Writes `@define-color` blocks into `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css`, sets dark preference.
- Full effect on GTK4/libadwaita; GTK3 only for themes using the named colours.
- Only the block between `hypr-w89 theme begin/end` is rewritten; other content is kept.

## Zsh themes (`assets/add_zsh_theme`, `theme.sh --zsh [THEME]`)

- Prompts: `stargate` (default), `lcars`, `stargate-minimal`; upstream themes stay installed.
- Installed to `~/.oh-my-zsh/custom/themes` (by `zsh.sh` and `--zsh`).
- `--zsh` writes `~/.config/hypr-w89/zsh-colors.zsh` (prompt, autosuggestion, syntax-highlight colours, sourced by `.zshrc`); `THEME` also sets `ZSH_THEME` in `~/.zshrc`.
- Truecolor hex; without the colours file the built-in Stargate colours are used.

## Boot chain (`assets/boot-stargate`, `install-scripts/boot_theme.sh`)

- Plymouth `stargate`: 9 chevrons lock as boot progresses, event horizon opens at the end, passphrase prompt styled.
- GRUB theme (GRUB only): space background, right-hand "Stargate Command" menu, "Dialling in N..." timeout.
- systemd-boot: Plymouth only (no bootloader theme).
- Edits `/etc/mkinitcpio.conf`, kernel cmdline (`quiet splash`), `/etc/default/grub`; backups in `~/.cache/hypr-w89-boot-backup`.
- Undo: `./install-scripts/boot_theme.sh --revert` (from repo root).
- Regenerate images: `python3 assets/boot-stargate/tools/generate.py` (needs python-pillow).
- Secure Boot: re-sign the initramfs/UKI if you sign them.

## KDE mode (`install-scripts/kde.sh` + `hypr_theme.sh`)

- Also: kwallet + kwallet-pam (auto-unlock via SDDM PAM, needs wallet password = login password), kwalletmanager, ksshaskpass (`SSH_ASKPASS`), kdeconnect, kcalc, kdialog, kfind, filelight, partitionmanager.
- Warns if gnome-keyring is installed (both claim `org.freedesktop.secrets`); it is never removed.
- Installs dolphin, ark, kio-extras, gwenview, okular, kate, breeze, plasma-integration, xdg-desktop-portal-kde.
- Dolphin = default file manager. Default apps: Ark (archives), Gwenview (images), Okular (pdf/epub), Kate (text).
- Dialogs: `~/.config/xdg-desktop-portal/hyprland-portals.conf` sends FileChooser, AppChooser, Print and Settings to the KDE portal; `GTK_USE_PORTAL=1` makes GTK apps use it. Screen sharing stays on the Hyprland portal.
- Browsers: Firefox gets `widget.use-xdg-desktop-portal.*` prefs (system default + existing profiles' `user.js`); Chromium-based browsers follow `GTK_USE_PORTAL=1`.
- Thumbnails: kio-extras, kdegraphics-thumbnailers (pdf/ps/raw), ffmpegthumbs (video), kimageformats + qt6-imageformats (avif/heif/jxl/webp/exr...), taglib (audio covers). Thunar option: tumbler, ffmpegthumbnailer, poppler-glib, libgsf, libopenraw, webp/heif/jxl loaders, epub.
- Integration: `qt6-wayland`, `udisks2` (Dolphin devices), `archlinux-xdg-menu` + `XDG_MENU_PREFIX=arch-` + `kbuildsycoca6` ("Open with" menu), D-Bus activation env set at session start.
- Services: `kded6` (started with the session), `kglobalacceld` (global shortcuts, D-Bus activated). KDE app notifications go to the running daemon (swaync); KDE's own notification daemon is part of plasma-workspace and is not installed.
- Env lives in `UserConfigs/user_env.lua` and startup in `UserConfigs/user_startup.lua` (marker `hypr-w89 kde`).
- After the dots: `QT_QPA_PLATFORMTHEME=kde`, Fusion override removed, `files = dolphin`.
- `theme.sh --kde` writes the scheme to `~/.local/share/color-schemes` and merges it into `kdeglobals`.
- `hypr-theme set` also writes `~/.local/share/color-schemes/<name>.colors` and merges it into `~/.config/kdeglobals` (Breeze style, breeze-dark icons).
- Select `kde` before `dots` (menu order does this).

See `CHANGELOGS.md`.
