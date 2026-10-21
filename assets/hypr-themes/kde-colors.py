#!/usr/bin/env python3
"""Turn a wallust colorscheme (pywal json) into a KDE colour scheme and merge it into kdeglobals.

Usage: kde-colors.py <scheme.json> <scheme-name>
"""
import configparser
import json
import os
import sys

src, name = sys.argv[1], sys.argv[2]
d = json.load(open(src))
c = d["colors"]
sp = d["special"]


def rgb(h):
    h = h.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


bg, fg, accent = sp["background"], sp["foreground"], sp["cursor"]
alt = c["color0"]
def mix(a, b, t):
    a, b = a.lstrip("#"), b.lstrip("#")
    return "#" + "".join("%02x" % round(int(a[i:i + 2], 16) * (1 - t) + int(b[i:i + 2], 16) * t) for i in (0, 2, 4))


dim = mix(fg, bg, 0.45)
raised = c["color8"]

view = {
    "BackgroundNormal": bg, "BackgroundAlternate": alt,
    "ForegroundNormal": fg, "ForegroundInactive": dim, "ForegroundActive": accent,
    "ForegroundLink": c["color6"], "ForegroundVisited": c["color5"],
    "ForegroundNegative": "#da4453", "ForegroundNeutral": "#f67400", "ForegroundPositive": "#27ae60",
    "DecorationFocus": accent, "DecorationHover": accent,
}
window = dict(view, BackgroundNormal=alt, BackgroundAlternate=bg)
button = dict(view, BackgroundNormal=raised, BackgroundAlternate=alt)
selection = dict(view, BackgroundNormal=accent, BackgroundAlternate=accent,
                 ForegroundNormal=bg, ForegroundInactive=bg, ForegroundActive=bg,
                 ForegroundLink=bg, ForegroundVisited=bg)
sections = {
    "Colors:View": view, "Colors:Window": window, "Colors:Button": button,
    "Colors:Selection": selection, "Colors:Tooltip": window,
    "Colors:Complementary": window, "Colors:Header": window,
}

cp = configparser.ConfigParser(interpolation=None)
cp.optionxform = str
for sec, vals in sections.items():
    cp[sec] = {k: rgb(v) for k, v in vals.items()}
cp["General"] = {"ColorScheme": name, "Name": name}
cp["WM"] = {
    "activeBackground": rgb(alt), "activeForeground": rgb(fg),
    "inactiveBackground": rgb(bg), "inactiveForeground": rgb(dim),
}

home = os.path.expanduser("~")
data = os.environ.get("XDG_DATA_HOME", f"{home}/.local/share")
conf = os.environ.get("XDG_CONFIG_HOME", f"{home}/.config")

os.makedirs(f"{data}/color-schemes", exist_ok=True)
with open(f"{data}/color-schemes/{name}.colors", "w") as f:
    cp.write(f, space_around_delimiters=False)

# Merge into kdeglobals so Qt/KDE apps (Dolphin etc.) pick it up
kg = configparser.ConfigParser(interpolation=None)
kg.optionxform = str
path = f"{conf}/kdeglobals"
kg.read(path)
for sec in cp.sections():
    if sec == "General":
        kg["General"] = dict(kg["General"]) if kg.has_section("General") else {}
        kg["General"]["ColorScheme"] = name
        continue
    kg[sec] = dict(cp[sec])
for sec, key, val in (("KDE", "widgetStyle", "Breeze"), ("Icons", "Theme", "breeze-dark")):
    if not kg.has_section(sec):
        kg.add_section(sec)
    kg[sec][key] = val
with open(path, "w") as f:
    kg.write(f, space_around_delimiters=False)
