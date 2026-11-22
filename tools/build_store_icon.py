"""Builds Spelunkr's home-screen / store icons: the yellow S mark and SPELUNKR over a
greyed-out collage of the channel logos.

Everything is drawn at each final size (no upscaling of finished images), so the mark
and the text stay sharp:
  assets/store/spelunkr-icon-2160x1620.png   master (store listings, previews)
  assets/store/spelunkr-icon-540x405.png      same as images/icon_fhd.png
  assets/store/spelunkr-icon-290x218.png      same as images/icon_hd.png
Run:  python tools/build_store_icon.py
"""
import math
import os
import re

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGOS = os.path.join(ROOT, "images", "logos")
OUT = os.path.join(ROOT, "assets", "store")
FONT = "C:/Windows/Fonts/arialbd.ttf"

NAVY = (11, 15, 38)
YELLOW = (255, 215, 64)
BORDER = (44, 58, 140)


def mark(scale):
    """The S mark from its 32x32 pixel SVG, each pixel scale x scale (crisp)."""
    svg = open(os.path.join(ROOT, "images", "spelunkr-mark.svg"), encoding="utf-8").read()
    img = Image.new("RGBA", (32 * scale, 32 * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for group in re.finditer(r'<g fill="(#[0-9a-fA-F]{6})">(.*?)</g>', svg):
        color = tuple(int(group.group(1)[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
        for r in re.finditer(r'x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)"', group.group(2)):
            x, y, w, h = (int(v) for v in r.groups())
            d.rectangle([x * scale, y * scale, (x + w) * scale - 1, (y + h) * scale - 1], fill=color)
    return img


def collage(w, h, tile=288, gap=56):
    """Every channel logo, greyed and dimmed, in an offset grid tilted a little.
    tile: a whole multiple of the 96 px pixel-art logos, so nearest-neighbour stays sharp."""
    names = sorted(f for f in os.listdir(LOGOS) if f.endswith(".png"))
    step = tile + gap
    size = int(math.hypot(w, h)) + step * 2
    layer = Image.new("RGBA", (size, size), NAVY + (255,))
    k = 0
    for row in range(size // step + 1):
        offset = (step // 2) * (row % 2)
        for col in range(size // step + 1):
            logo = Image.open(os.path.join(LOGOS, names[k % len(names)])).convert("RGBA")
            k += 7  # spread neighbours apart
            logo = logo.resize((tile, tile), Image.NEAREST)
            grey = logo.convert("LA")
            l, a = grey.split()
            # Grey at about a third of its brightness, tinted towards the navy.
            l = l.point(lambda v: int(26 + v * 0.30))
            tinted = Image.merge("RGBA", (l, l, l.point(lambda v: min(255, v + 18)), a))
            layer.alpha_composite(tinted, (col * step - offset, row * step))
    layer = layer.rotate(-12, resample=Image.BICUBIC)
    left = (size - w) // 2
    top = (size - h) // 2
    return layer.crop((left, top, left + w, top + h))


def icon(w, h, master_collage):
    img = master_collage.resize((w, h), Image.LANCZOS).convert("RGBA")
    # Darken the middle so the mark stands out (soft radial shade).
    shade = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shade).ellipse([w * 0.12, h * 0.02, w * 0.88, h * 1.02], fill=200)
    shade = shade.filter(ImageFilter.GaussianBlur(radius=max(4, w // 12)))
    img = Image.composite(Image.new("RGBA", (w, h), NAVY + (255,)), img, shade)

    # The mark: the largest whole-pixel scale that fits ~52% of the height.
    scale = max(1, int(h * 0.52 / 32))
    m = mark(scale)
    mx = (w - m.width) // 2
    my = int(h * 0.09)
    # Soft yellow glow behind it.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow.alpha_composite(m, (mx, my))
    alpha = glow.split()[3].filter(ImageFilter.GaussianBlur(radius=max(3, scale * 3)))
    glow = Image.new("RGBA", (w, h), YELLOW + (0,))
    glow.putalpha(alpha.point(lambda v: int(v * 0.55)))
    img.alpha_composite(glow)
    img.alpha_composite(m, (mx, my))

    d = ImageDraw.Draw(img)
    # The yellow line and the name, as on the original icon.
    line_y = my + m.height + int(h * 0.075)
    thick = max(2, round(h * 0.011))
    d.rectangle([w * 0.205, line_y, w * 0.795, line_y + thick - 1], fill=YELLOW)
    font = ImageFont.truetype(FONT, max(10, round(h * 0.115)))
    text = "SPELUNKR"
    box = d.textbbox((0, 0), text, font=font)
    tx = (w - (box[2] - box[0])) // 2 - box[0]
    ty = line_y + thick + int(h * 0.035) - box[1]
    d.text((tx, ty), text, font=font, fill=YELLOW)

    # Thin blue border, inset like the original.
    inset = max(2, round(h * 0.012))
    width = max(2, round(h * 0.009))
    d.rectangle([inset, inset, w - 1 - inset, h - 1 - inset], outline=BORDER, width=width)
    return img.convert("RGB")


def manifest_version():
    text = open(os.path.join(ROOT, "manifest"), encoding="utf-8").read()
    part = lambda key: re.search(key + r"=(\d+)", text).group(1)
    return "%s.%s.%s" % (part("major_version"), part("minor_version"), part("build_version"))


def splash(w, h, version, master_collage):
    """The launch splash: the icon's look across the whole screen."""
    img = master_collage.resize((w, h), Image.LANCZOS).convert("RGBA")
    # A dark pool in the middle for the mark and the name, darker edges all round.
    shade = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shade).ellipse([w * 0.27, h * 0.06, w * 0.73, h * 0.96], fill=238)
    shade = shade.filter(ImageFilter.GaussianBlur(radius=w // 16))
    img = Image.composite(Image.new("RGBA", (w, h), NAVY + (255,)), img, shade)
    edge = Image.new("L", (w, h), 255)
    ImageDraw.Draw(edge).rectangle([w * 0.06, h * 0.08, w * 0.94, h * 0.92], fill=0)
    edge = edge.filter(ImageFilter.GaussianBlur(radius=w // 18)).point(lambda v: int(v * 0.6))
    img = Image.composite(Image.new("RGBA", (w, h), (4, 6, 18, 255)), img, edge)

    scale = max(1, int(h * 0.36 / 32))
    m = mark(scale)
    mx = (w - m.width) // 2
    my = int(h * 0.13)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow.alpha_composite(m, (mx, my))
    alpha = glow.split()[3].filter(ImageFilter.GaussianBlur(radius=scale * 4))
    glow = Image.new("RGBA", (w, h), YELLOW + (0,))
    glow.putalpha(alpha.point(lambda v: int(v * 0.6)))
    img.alpha_composite(glow)
    img.alpha_composite(m, (mx, my))

    d = ImageDraw.Draw(img)

    def centered(text, size, y, fill, spacing=0):
        font = ImageFont.truetype(FONT, size)
        widths = [d.textbbox((0, 0), c, font=font)[2] for c in text]
        total = sum(widths) + spacing * (len(text) - 1)
        x = (w - total) // 2
        top = d.textbbox((0, 0), text, font=font)[1]
        for c, cw in zip(text, widths):
            d.text((x, y - top), c, font=font, fill=fill)
            x += cw + spacing
        return y + d.textbbox((0, 0), text, font=font)[3] - top

    line_y = my + m.height + int(h * 0.05)
    thick = max(2, round(h * 0.006))
    d.rectangle([w * 0.33, line_y, w * 0.67, line_y + thick - 1], fill=YELLOW)
    y = centered("SPELUNKR", round(h * 0.105), line_y + thick + int(h * 0.03), YELLOW, round(h * 0.006))
    y = centered("TV GUIDE", round(h * 0.036), y + int(h * 0.028), (255, 236, 160), round(h * 0.014))
    centered("UNOFFICIAL  ·  v" + version, round(h * 0.024), y + int(h * 0.03), (170, 180, 215), round(h * 0.003))
    return img.convert("RGB")


def main():
    import sys
    # Splash screens: --splash [VERSION] writes only images/splash_fhd.png and
    # splash_hd.png (version defaults to the manifest's). The icons are left alone:
    # their collage changes whenever a channel is added, and the store icon must
    # keep matching the approved images/icon_fhd.png and icon_hd.png.
    if "--splash" in sys.argv:
        at = sys.argv.index("--splash")
        version = sys.argv[at + 1] if len(sys.argv) > at + 1 else manifest_version()
        wide = collage(1920, 1080, tile=192, gap=40)
        for w, h, name in [(1920, 1080, "splash_fhd.png"), (1280, 720, "splash_hd.png")]:
            path = os.path.join(ROOT, "images", name)
            splash(w, h, version, wide).save(path, optimize=True)
            print(path)
        return
    os.makedirs(OUT, exist_ok=True)
    base = collage(2160, 1620)
    for w, h in [(2160, 1620), (540, 405), (290, 218)]:
        path = os.path.join(OUT, "spelunkr-icon-%dx%d.png" % (w, h))
        icon(w, h, base).save(path, optimize=True)
        print(path)
    # The README shows the same tile as the Roku home screen; the contact page
    # header needs a square one.
    icon(540, 405, base).save(os.path.join(ROOT, "assets", "icon.png"), optimize=True)
    icon(512, 512, collage(1024, 1024)).save(os.path.join(ROOT, "docs", "icon.png"), optimize=True)
    print(os.path.join(ROOT, "assets", "icon.png"))
    print(os.path.join(ROOT, "docs", "icon.png"))


if __name__ == "__main__":
    main()
