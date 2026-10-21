#!/usr/bin/env python3
"""Apply a colour scheme (assets/hypr-themes/<name>.json) to one target.

Usage: apply-targets.py <kitty|gtk|kde> <scheme.json> <name>
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
    out_dir = f"{home}/.config/hypr/UserConfigs/kitty-themes"
    kconf = f"{home}/.config/hypr/UserConfigs/kitty.conf"
    if not os.path.isfile(kconf):
        out_dir, kconf = f"{home}/.config/kitty/themes", f"{home}/.config/kitty/kitty.conf"
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(os.path.dirname(kconf), exist_ok=True)
    theme = f"{out_dir}/{name}.conf"
    lines = [
        f"foreground {s['foreground']}", f"background {s['background']}", f"cursor {s['cursor']}",
        f"selection_foreground {s['background']}", f"selection_background {s['foreground']}",
        f"active_tab_foreground {s['background']}", f"active_tab_background {s['cursor']}",
        f"inactive_tab_foreground {s['foreground']}", f"inactive_tab_background {c['color0']}",
        f"active_border_color {s['cursor']}", f"inactive_border_color {c['color8']}",
    ] + [f"color{i} {c['color%d' % i]}" for i in range(16)]
    open(theme, "w").write("\n".join(lines) + "\n")
    text = open(kconf).read() if os.path.isfile(kconf) else ""
    pat = re.compile(r"^include .*themes/[^/\n]*\.conf$", re.M)
    if pat.search(text):
        text = pat.sub(f"include {theme}", text, count=1)
    else:
        text += f"\ninclude {theme}\n"
    open(kconf, "w").write(text)
    print(f"kitty: {theme} selected in {kconf} (ctrl+shift+f5 reloads open windows)")


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


def kde():
    subprocess.run([sys.executable, "-I", f"{here}/kde-colors.py", path, name], check=True)
    print(f"kde: color scheme {name} written to kdeglobals")


{"kitty": kitty, "gtk": gtk, "kde": kde}[target]()
