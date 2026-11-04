#!/usr/bin/env python3
"""Assemble a self-contained SDDM theme from the shared asset collection."""
import argparse
import configparser
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
COLLECTION = ROOT / "assets/sddm-themes"


def assemble(name, output, source=None, scheme=None, background=None, animations=None):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError("Invalid theme name")
    source = Path(source).resolve() if source else COLLECTION / name
    for required in ("Main.qml", "theme.conf", "metadata.desktop"):
        if not (source / required).is_file():
            raise ValueError(f"Theme is missing {required}: {source}")
    conf = configparser.ConfigParser(interpolation=None)
    conf.optionxform = str
    conf.read(source / "theme.conf")
    general = conf["General"]
    if animations is not None:
        if name == "stargate" and not animations:
            raise ValueError("The original dialing-gate theme does not support --no-animations")
        general["animations"] = "true" if animations else "false"
    if scheme:
        import json
        palette = json.loads(Path(scheme).read_text())
        general["accent"] = palette["special"]["cursor"]
        general["horizon"] = palette["colors"]["color6"]
    background = background or general.get("background", "stargate-space.png")
    candidates = [Path(background), source / background, ROOT / "assets/wallpapers" / background]
    image = next((p.resolve() for p in candidates if p.is_file()), None)
    if image is None:
        raise ValueError(f"Wallpaper not found: {background}")
    output = Path(output)
    if output.exists():
        raise ValueError(f"Output already exists: {output}; choose a new directory")
    output.mkdir(parents=True)
    # Custom sources retain their supporting components and assets.
    if source.parent != COLLECTION:
        shutil.copytree(source, output, dirs_exist_ok=True)
    else:
        for file in source.iterdir():
            if file.suffix in (".qml", ".desktop"):
                shutil.copy2(file, output / file.name)
    shared = COLLECTION / "shared/LoginPanel.qml"
    if name != "stargate" and source.parent == COLLECTION:
        shutil.copy2(shared, output / shared.name)
        main = output / "Main.qml"
        main.write_text(main.read_text().replace('import "../shared"', 'import "."'))
    shutil.copy2(image, output / ("background" + image.suffix))
    general["background"] = "background" + image.suffix
    with (output / "theme.conf").open("w") as stream:
        conf.write(stream, space_around_delimiters=False)
    metadata = configparser.ConfigParser(interpolation=None)
    metadata.optionxform = str
    metadata.read(output / "metadata.desktop")
    metadata["SddmGreeterTheme"]["Theme-Id"] = name
    with (output / "metadata.desktop").open("w") as stream:
        metadata.write(stream, space_around_delimiters=False)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--theme", default="stargate")
    parser.add_argument("--output", required=True)
    parser.add_argument("--source")
    parser.add_argument("--scheme")
    parser.add_argument("--background")
    parser.add_argument("--no-animations", action="store_true")
    args = parser.parse_args()
    try:
        assemble(args.theme, args.output, args.source, args.scheme, args.background,
                 False if args.no_animations else None)
    except (ValueError, OSError, KeyError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
