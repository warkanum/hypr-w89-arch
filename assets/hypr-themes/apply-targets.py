#!/usr/bin/env python3
"""Apply a colour scheme (assets/hypr-themes/<name>.json) to one target.

Usage: apply-targets.py <kitty|gtk|kde|zsh> <scheme.json> <name>
"""
import json
import os
import re
import subprocess
import sys

target, path, name = sys.argv[1:4]
d = json.load(open(path))
c, s = d["colors"], d["special"]
home = os.path.expanduser("~")
here = os.path.dirname(os.path.abspath(__file__))


def kitty():
    # Update every kitty.conf that may be in use: $KITTY_CONFIG_DIRECTORY, the default
    # ~/.config/kitty, and the dots' UserConfigs copy.
    candidates = []
    env_dir = os.environ.get("KITTY_CONFIG_DIRECTORY")
    if env_dir:
        candidates.append(f"{env_dir}/kitty.conf")
    candidates += [f"{home}/.config/kitty/kitty.conf", f"{home}/.config/hypr/UserConfigs/kitty.conf"]
    confs = [f for f in dict.fromkeys(candidates) if os.path.isfile(f)]
    if not confs:
        confs = [f"{home}/.config/kitty/kitty.conf"]
    lines = [
        f"foreground {s['foreground']}", f"background {s['background']}", f"cursor {s['cursor']}",
        f"selection_foreground {s['background']}", f"selection_background {s['foreground']}",
        f"active_tab_foreground {s['background']}", f"active_tab_background {s['cursor']}",
        f"inactive_tab_foreground {s['foreground']}", f"inactive_tab_background {c['color0']}",
        f"active_border_color {s['cursor']}", f"inactive_border_color {c['color8']}",
    ] + [f"color{i} {c['color%d' % i]}" for i in range(16)]
    pat = re.compile(r"^include .*themes/[^/\n]*\.conf$", re.M)
    for kconf in confs:
        out_dir = os.path.join(os.path.dirname(kconf), "kitty-themes")
        os.makedirs(out_dir, exist_ok=True)
        theme = f"{out_dir}/{name}.conf"
        open(theme, "w").write("\n".join(lines) + "\n")
        text = open(kconf).read() if os.path.isfile(kconf) else ""
        if pat.search(text):
            text = pat.sub(lambda m: f"include {theme}", text, count=1)
        else:
            text += f"\ninclude {theme}\n"
        open(kconf, "w").write(text)
        print(f"kitty: {theme} selected in {kconf}")
    # kitty reloads its config on SIGUSR1
    subprocess.run(["pkill", "-USR1", "-x", "kitty"], check=False, stderr=subprocess.DEVNULL)


def gtk():
    bg, fg, accent, alt = s["background"], s["foreground"], s["cursor"], c["color0"]
    names = {
        "accent_color": accent, "accent_bg_color": accent, "accent_fg_color": bg,
        "window_bg_color": bg, "window_fg_color": fg,
        "view_bg_color": bg, "view_fg_color": fg,
        "headerbar_bg_color": alt, "headerbar_fg_color": fg,
        "card_bg_color": alt, "card_fg_color": fg,
        "popover_bg_color": alt, "popover_fg_color": fg,
        "sidebar_bg_color": alt, "sidebar_fg_color": fg,
        "dialog_bg_color": alt, "dialog_fg_color": fg,
        "destructive_bg_color": "#da4453", "destructive_fg_color": "#ffffff",
        "success_bg_color": "#27ae60", "warning_bg_color": "#f67400", "error_bg_color": "#da4453",
        # GTK3 legacy names
        "theme_bg_color": bg, "theme_fg_color": fg, "theme_base_color": bg, "theme_text_color": fg,
        "theme_selected_bg_color": accent, "theme_selected_fg_color": bg,
    }
    block = ("/* hypr-w89 theme begin */\n"
             f"/* scheme: {name} */\n"
             + "".join(f"@define-color {k} {v};\n" for k, v in names.items())
             + "/* hypr-w89 theme end */\n")
    pat = re.compile(r"/\* hypr-w89 theme begin \*/.*?/\* hypr-w89 theme end \*/\n?", re.S)
    for ver in ("gtk-3.0", "gtk-4.0"):
        f = f"{home}/.config/{ver}/gtk.css"
        os.makedirs(os.path.dirname(f), exist_ok=True)
        text = open(f).read() if os.path.isfile(f) else ""
        text = pat.sub("", text).rstrip("\n")
        open(f, "w").write((text + "\n\n" if text else "") + block)
        print(f"gtk: {f}")
    try:
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark"],
                       check=False, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        pass


def zsh():
    def mix(a, b, t):
        a, b = a.lstrip("#"), b.lstrip("#")
        return "#" + "".join("%02x" % round(int(a[i:i + 2], 16) * (1 - t) + int(b[i:i + 2], 16) * t) for i in (0, 2, 4))

    bg, fg, accent = s["background"], s["foreground"], s["cursor"]
    v = {
        "HW_BG": bg, "HW_FG": fg, "HW_ACCENT": accent, "HW_DIM": mix(fg, bg, 0.5),
        "HW_PATH": c["color4"], "HW_ERR": "#da4453",
        "HW_SEG1": accent, "HW_SEG2": c["color5"], "HW_SEG3": c["color4"],
    }
    lines = [f"# zsh colours from scheme {name} (theme.sh --zsh)"]
    lines += [f"export {k}='{val}'" for k, val in v.items()]
    lines += [
        f"export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={v['HW_DIM']}'",
        "typeset -gA ZSH_HIGHLIGHT_STYLES",
        f"ZSH_HIGHLIGHT_STYLES[command]='fg={c['color6']}'",
        f"ZSH_HIGHLIGHT_STYLES[builtin]='fg={c['color6']}'",
        f"ZSH_HIGHLIGHT_STYLES[alias]='fg={c['color6']}'",
        f"ZSH_HIGHLIGHT_STYLES[function]='fg={c['color6']}'",
        f"ZSH_HIGHLIGHT_STYLES[path]='fg={fg},underline'",
        f"ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={c['color3']}'",
        f"ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={c['color3']}'",
        f"ZSH_HIGHLIGHT_STYLES[comment]='fg={v['HW_DIM']}'",
        "ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#da4453'",
    ]
    out = f"{home}/.config/hypr-w89/zsh-colors.zsh"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write("\n".join(lines) + "\n")
    print(f"zsh: {out}")
    # Install the prompt themes where Oh-My-Zsh looks first, so ZSH_THEME resolves
    import glob
    import shutil
    custom = os.environ.get("ZSH_CUSTOM") or f"{home}/.oh-my-zsh/custom"
    if os.path.isdir(f"{home}/.oh-my-zsh"):
        os.makedirs(f"{custom}/themes", exist_ok=True)
        for f in glob.glob(f"{here}/../add_zsh_theme/*.zsh-theme"):
            if os.path.basename(f) in ("stargate.zsh-theme", "lcars.zsh-theme", "stargate-minimal.zsh-theme"):
                shutil.copy(f, f"{custom}/themes/")
        print(f"zsh: prompt themes installed in {custom}/themes")
    else:
        print("zsh: ~/.oh-my-zsh not found; install the zsh option first, then re-run")
    theme = os.environ.get("HW_ZSH_THEME")
    zrc = f"{home}/.zshrc"
    if theme and os.path.isfile(zrc):
        text = open(zrc).read()
        new, n = re.subn(r'^ZSH_THEME=.*$', f'ZSH_THEME="{theme}"', text, count=1, flags=re.M)
        if n:
            open(zrc, "w").write(new)
            print(f"zsh: ZSH_THEME={theme} in {zrc}")
    print("zsh: open a new shell (or `exec zsh`) to see it")


def kde():
    subprocess.run([sys.executable, "-I", f"{here}/kde-colors.py", path, name], check=True)
    print(f"kde: color scheme {name} written to kdeglobals")


{"kitty": kitty, "gtk": gtk, "kde": kde, "zsh": zsh}[target]()
