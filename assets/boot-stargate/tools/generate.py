#!/usr/bin/env python3
"""Generate the Plymouth and GRUB theme images from the SDDM background.

Usage: generate.py   (run from the repo root; needs python-pillow)
"""
import math
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = "assets/boot-stargate"
BG_SRC = "assets/sddm-stargate/stargate-space.png"
S = 4  # supersampling
N = 600  # gate sprite size
C = N / 2
BLUE = (127, 212, 255)
DIM = (46, 58, 72)

os.makedirs(f"{ROOT}/plymouth", exist_ok=True)
os.makedirs(f"{ROOT}/grub", exist_ok=True)


def canvas():
    return Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))


def pol(r, a):
    return (C * S + r * S * math.cos(a), C * S + r * S * math.sin(a))


def chevron_poly(r_out, r_in, a, half):
    """Trapezoid chevron block pointing inwards at angle a."""
    return [pol(r_out, a - half), pol(r_out, a + half),
            pol(r_in, a + half * 0.55), pol(r_in, a - half * 0.55)]


def ring_image():
    im = canvas()
    d = ImageDraw.Draw(im)
    # outer ring and bezels
    d.ellipse([pol(285, -math.pi)[0], pol(285, -math.pi / 2)[1], pol(285, 0)[0], pol(285, math.pi / 2)[1]], fill=(34, 40, 48, 255))
    d.ellipse([pol(262, -math.pi)[0], pol(262, -math.pi / 2)[1], pol(262, 0)[0], pol(262, math.pi / 2)[1]], fill=(24, 29, 35, 255))
    # 36 glyph plates
    for i in range(36):
        a = i * math.tau / 36
        half = math.tau / 36 * 0.36
        poly = [pol(258, a - half), pol(258, a + half), pol(214, a + half), pol(214, a - half)]
        d.polygon(poly, fill=(52, 64, 80, 255))
    d.ellipse([pol(212, -math.pi)[0], pol(212, -math.pi / 2)[1], pol(212, 0)[0], pol(212, math.pi / 2)[1]], fill=(20, 24, 30, 255))
    # 9 chevron slots
    for k in range(9):
        a = -math.pi / 2 + k * math.tau / 9
        d.polygon(chevron_poly(292, 258, a, 0.085), fill=(*DIM, 255))
    # inner hole (transparent) so the horizon shows through
    hole = Image.new("L", im.size, 0)
    ImageDraw.Draw(hole).ellipse([pol(196, -math.pi)[0], pol(196, -math.pi / 2)[1], pol(196, 0)[0], pol(196, math.pi / 2)[1]], fill=255)
    alpha = im.getchannel("A")
    alpha = Image.composite(Image.new("L", im.size, 0), alpha, hole)
    im.putalpha(alpha)
    return im.resize((N, N), Image.LANCZOS)


def chevron_lit(k):
    a = -math.pi / 2 + k * math.tau / 9
    glow = canvas()
    ImageDraw.Draw(glow).polygon(chevron_poly(292, 258, a, 0.085), fill=(*BLUE, 255))
    halo = glow.filter(ImageFilter.GaussianBlur(14 * S))
    halo.putalpha(halo.getchannel("A").point(lambda v: min(255, v * 2)))
    core = canvas()
    ImageDraw.Draw(core).polygon(chevron_poly(292, 258, a, 0.085), fill=(215, 240, 255, 255))
    out = Image.alpha_composite(halo, core)
    return out.resize((N, N), Image.LANCZOS)


def horizon():
    im = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
    px = im.load()
    rmax = 196 * S
    cx = cy = N * S / 2
    for y in range(0, N * S, 2):
        for x in range(0, N * S, 2):
            r = math.hypot(x - cx, y - cy)
            if r > rmax:
                continue
            t = r / rmax
            ripple = 0.5 + 0.5 * math.cos(t * 26)
            v = (0.55 + 0.45 * (1 - t)) * (0.82 + 0.18 * ripple)
            col = (int(60 + 120 * v * (1 - t)), int(150 + 80 * v), 255, 255)
            for dy in (0, 1):
                for dx in (0, 1):
                    px[x + dx, y + dy] = col
    return im.resize((N, N), Image.LANCZOS)


def background(w, h, level):
    bg = Image.open(BG_SRC).convert("RGB")
    s = max(w / bg.width, h / bg.height)
    bg = bg.resize((round(bg.width * s), round(bg.height * s)), Image.LANCZOS)
    l, t = (bg.width - w) // 2, (bg.height - h) // 2
    bg = bg.crop((l, t, l + w, t + h))
    return ImageEnhance.Brightness(bg).enhance(level)


# Plymouth
ring_image().save(f"{ROOT}/plymouth/ring.png", optimize=True)
for k in range(9):
    chevron_lit(k).save(f"{ROOT}/plymouth/chevron-{k}.png", optimize=True)
horizon().save(f"{ROOT}/plymouth/horizon.png", optimize=True)
background(1280, 720, 0.32).quantize(96, dither=Image.FLOYDSTEINBERG).save(f"{ROOT}/plymouth/bg.png", optimize=True)

# GRUB
background(1920, 1080, 0.6).save(f"{ROOT}/grub/background.png", optimize=True)


def tile(name, w, h, fn):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fn(ImageDraw.Draw(im), w, h)
    im.save(f"{ROOT}/grub/{name}.png")


fill = (60, 140, 230, 150)
edge = (127, 212, 255, 255)
tile("select_c", 8, 36, lambda d, w, h: (d.rectangle([0, 0, w, h], fill=fill), d.line([0, 0, w, 0], fill=edge), d.line([0, h - 1, w, h - 1], fill=edge)))
tile("select_w", 8, 36, lambda d, w, h: (d.rectangle([0, 0, w, h], fill=fill), d.line([0, 0, w, 0], fill=edge), d.line([0, h - 1, w, h - 1], fill=edge), d.line([0, 0, 0, h], fill=edge, width=3)))
tile("select_e", 8, 36, lambda d, w, h: (d.rectangle([0, 0, w, h], fill=fill), d.line([0, 0, w, 0], fill=edge), d.line([0, h - 1, w, h - 1], fill=edge)))
tile("panel_c", 8, 8, lambda d, w, h: d.rectangle([0, 0, w, h], fill=(10, 15, 22, 200)))
print("done")
