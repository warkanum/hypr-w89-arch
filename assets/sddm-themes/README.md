# SDDM themes

Each theme has its own directory. All use Qt6 and work independently of whether
you log into Plasma or Hyprland.

| Name | Design |
|---|---|
| `stargate` | Original animated dialing gate, chevron sequence, success splash and failed-login reset |
| `stargate-universe` | Destiny observation window, slowly drifting starlight, bronze accents and a right-side crew login |
| `atlantis` | Ocean city panorama, faint moving water reflections, teal accents and a left-side expedition login |
| `lcars` | Orange and violet rounded console rails with a scanning segment strip |

See the [screenshot gallery](../../README.md#sddm-theme-previews) for all four layouts.

```bash
./sddm-theme.sh themes
./sddm-theme.sh test --theme stargate-universe
./sddm-theme.sh test --theme atlantis --scheme atlantis-teal-dark
./sddm-theme.sh set --theme lcars
./sddm-theme.sh export --theme atlantis --output /tmp/atlantis-sddm
./sddm-theme.sh test --theme stargate-universe --no-animations
```

`test` opens a preview and leaves system settings unchanged. `set` uses sudo to
install and activate the selected theme for the next login. It does not restart
SDDM or log you out. `export` creates a self-contained directory that must not
already exist. It includes the theme's QML, metadata, configuration, shared login
component if needed, and selected wallpaper. No repository-relative paths remain
in the exported theme.

`--background NAME|FILE` selects any image from `assets/wallpapers/` or an external
file; `--scheme NAME` overrides the accent colours. Exported themes can also be
used with `sddm-greeter-qt6 --test-mode --theme DIR`.

`stargate/` contains the original dialing animation. The other designs use
`shared/LoginPanel.qml` for user/session selection, password entry, direct
authentication, failure recovery and power actions; they do not play the dialing
animation. Both Plasma and Hyprland appear in the session selector when installed.
The three newer themes have a short panel fade-in, subtle hover transitions,
an activity strip during authentication, failed-login feedback and a soft success
wash. These effects never delay authentication or shift the input controls.
Use `--no-animations` with `set`, `test`, or `export` for a static version, or set
`animations=false` in that theme's `theme.conf`. Static mode keeps status messages
and failure/success colours. This toggle applies to the three newer layouts;
the original dialing-gate animation is unchanged.
Wallpaper files and generation prompts are kept outside the theme directories:
`assets/wallpapers/` and `assets/WALLPAPERS.md`. The original theme's background
path resolves against the shared collection before export.

Add a theme directory containing `Main.qml`, `theme.conf` and `metadata.desktop`
to have it listed automatically. New bundled layouts may import `../shared`;
the export builder replaces that import and copies the component locally.

The installer manages one drop-in, `/etc/sddm.conf.d/10-stargate-theme.conf`, so
switching bundled themes does not leave competing theme overrides. It keeps
`/etc/sddm.conf.stargate.bak` when the main config exists. Removing an inactive
variant leaves the active selection alone; removing the active variant restores
the saved main config when available.

Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v`.
Package tests check exports and overrides. With `pyside6` installed, offscreen
rendering tests also load all four themes at two resolutions and check duplicate
submission prevention, password clearing and failed/successful login states
against a mock greeter. The three newer layouts are checked with animations on
and off, including whether their ambient motion advances or stays still.
They never authenticate a real user or change SDDM.

Theme metadata and greeter context follow the
[SDDM theming API](https://github.com/sddm/sddm/blob/develop/docs/THEMING.md).
