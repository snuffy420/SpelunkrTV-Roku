"""Builds the artwork for the guide themes in images/themes/:

  glass-background.png / glass-header.png / glass-panel.9.png
      Glass: frosted, rounded panels over a deep Spelunkr navy and purple, with an
      orange glow (Spelunkr's own colours, not the mock-up's violet).
  neon-background.png / neon-header.png / neon-panel.9.png
      Neon: glowing cyan outlines on black, a pink glow under the header.

The Classic theme uses the original images/guide-background.png and
images/header-gradient.png. Colours for each theme live in components/Themes.brs.
Run:  python tools/build_themes.py
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "images", "themes")
W, H = 1280, 720


def radial(size, center, radius, color, strength):
    """A soft round glow: color at the centre fading to nothing at radius."""
    layer = Image.new("RGBA", size, color + (0,))
    mask = Image.new("L", size, 0)
    x, y = center
    ImageDraw.Draw(mask).ellipse([x - radius, y - radius, x + radius, y + radius], fill=int(255 * strength))
    mask = mask.filter(ImageFilter.GaussianBlur(radius * 0.45))
    layer.putalpha(mask)
    return layer


def vertical(size, top, bottom):
    w, h = size
    img = Image.new("RGBA", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def nine_patch(img, stretch_x, stretch_y):
    """Adds the 1 px 9-patch border: black marks on the top and left edges say
    which middle part stretches. stretch_x/y are (start, end) in the image."""
    w, h = img.size
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    out.paste(img, (1, 1))
    d = ImageDraw.Draw(out)
    d.line([(1 + stretch_x[0], 0), (stretch_x[1], 0)], fill=(0, 0, 0, 255))
    d.line([(0, 1 + stretch_y[0]), (0, stretch_y[1])], fill=(0, 0, 0, 255))
    return out


def glass():
    bg = vertical((W, H), (11, 14, 34, 255), (30, 14, 44, 255))
    bg.alpha_composite(radial((W, H), (1100, -40), 620, (210, 100, 15), 0.55))   # Spelunkr orange
    bg.alpha_composite(radial((W, H), (120, 760), 560, (87, 34, 59), 0.85))      # Spelunkr plum
    bg.alpha_composite(radial((W, H), (640, 380), 520, (27, 40, 104), 0.55))     # Spelunkr navy
    bg.convert("RGB").save(os.path.join(OUT, "glass-background.png"), optimize=True)

    header = Image.new("RGBA", (W, 78), (0, 0, 0, 0))
    d = ImageDraw.Draw(header)
    for y in range(78):
        d.line([(0, y), (W, y)], fill=(255, 255, 255, int(34 * (1 - y / 78))))
    header.alpha_composite(radial((W, 78), (160, 10), 260, (210, 100, 15), 0.45))
    header.save(os.path.join(OUT, "glass-header.png"), optimize=True)

    # Frosted panel: 22 px corners, a faint white fill fading down, a thin bright
    # rim, a highlight along the top edge and a soft drop shadow underneath.
    s, r, pad = 96, 22, 10
    panel = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    shadow = Image.new("L", (s, s), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([pad, pad + 4, s - pad, s - pad + 4], r, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    panel.paste((0, 0, 0, 255), (0, 0), shadow)
    fill = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, fill=255)
    grad = vertical((s, s), (255, 255, 255, 40), (255, 255, 255, 12))
    fill.paste(grad, (0, 0), mask)
    panel.alpha_composite(fill)
    d = ImageDraw.Draw(panel)
    d.rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, outline=(255, 255, 255, 58), width=1)
    d.line([(pad + r, pad + 1), (s - pad - r, pad + 1)], fill=(255, 255, 255, 90))
    nine_patch(panel, (pad + r + 2, s - pad - r - 2), (pad + r + 2, s - pad - r - 2)).save(
        os.path.join(OUT, "glass-panel.9.png"), optimize=True)


def neon():
    # Plain and dark so the glowing text reads cleanly: deep black-purple with
    # two very faint corner glows (pink top left, cyan bottom right). No pattern.
    bg = vertical((W, H), (6, 4, 14, 255), (3, 3, 8, 255))
    bg.alpha_composite(radial((W, H), (-60, -80), 560, (255, 63, 208), 0.10))
    bg.alpha_composite(radial((W, H), (1340, 800), 600, (51, 240, 255), 0.08))
    bg.convert("RGB").save(os.path.join(OUT, "neon-background.png"), optimize=True)

    header = Image.new("RGBA", (W, 78), (5, 4, 11, 255))
    glow = Image.new("RGBA", (W, 78), (255, 63, 208, 0))
    mask = Image.new("L", (W, 78), 0)
    ImageDraw.Draw(mask).rectangle([0, 70, W, 78], fill=200)
    glow.putalpha(mask.filter(ImageFilter.GaussianBlur(8)))
    header.alpha_composite(glow)
    header.save(os.path.join(OUT, "neon-header.png"), optimize=True)

    # A glowing cyan tube: an 18 px rounded outline with a blurred halo inside and out.
    s, r, pad = 96, 18, 12
    halo = Image.new("L", (s, s), 0)
    ImageDraw.Draw(halo).rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, outline=255, width=4)
    halo = halo.filter(ImageFilter.GaussianBlur(5)).point(lambda v: int(v * 0.8))
    panel = Image.new("RGBA", (s, s), (51, 240, 255, 0))
    panel.putalpha(halo)
    tube = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(tube).rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, outline=(170, 250, 255, 255), width=2)
    panel.alpha_composite(tube)
    nine_patch(panel, (pad + r + 2, s - pad - r - 2), (pad + r + 2, s - pad - r - 2)).save(
        os.path.join(OUT, "neon-panel.9.png"), optimize=True)


def afterglow():
    """Spelunkr Neon: very dark, with Spelunkr's orange and blue as glowing light."""
    bg = vertical((W, H), (5, 5, 16, 255), (2, 2, 8, 255))
    bg.alpha_composite(radial((W, H), (-40, -60), 600, (255, 122, 26), 0.14))   # orange glow
    bg.alpha_composite(radial((W, H), (1320, 780), 640, (61, 107, 255), 0.13))  # blue glow
    bg.convert("RGB").save(os.path.join(OUT, "afterglow-background.png"), optimize=True)

    header = Image.new("RGBA", (W, 78), (4, 4, 12, 255))
    glow = Image.new("RGBA", (W, 78), (255, 122, 26, 0))
    mask = Image.new("L", (W, 78), 0)
    ImageDraw.Draw(mask).rectangle([0, 70, W, 78], fill=210)
    glow.putalpha(mask.filter(ImageFilter.GaussianBlur(8)))
    header.alpha_composite(glow)
    header.save(os.path.join(OUT, "afterglow-header.png"), optimize=True)

    # An electric-blue tube with a blue halo, like Neon's but in Spelunkr blue.
    s, r, pad = 96, 18, 12
    halo = Image.new("L", (s, s), 0)
    ImageDraw.Draw(halo).rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, outline=255, width=4)
    halo = halo.filter(ImageFilter.GaussianBlur(5)).point(lambda v: int(v * 0.85))
    panel = Image.new("RGBA", (s, s), (61, 107, 255, 0))
    panel.putalpha(halo)
    tube = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(tube).rounded_rectangle([pad, pad, s - pad - 1, s - pad - 1], r, outline=(150, 180, 255, 255), width=2)
    panel.alpha_composite(tube)
    nine_patch(panel, (pad + r + 2, s - pad - r - 2), (pad + r + 2, s - pad - r - 2)).save(
        os.path.join(OUT, "afterglow-panel.9.png"), optimize=True)


def channel():
    """Channel Color: grey art the Roku tints with each channel's colour
    (blendColor multiplies, so grey 70 under orange gives a deep dark orange)."""
    bg = vertical((W, H), (78, 78, 78, 255), (34, 34, 34, 255))
    bg.alpha_composite(radial((W, H), (1100, -40), 640, (170, 170, 170), 0.55))
    bg.alpha_composite(radial((W, H), (100, 760), 520, (14, 14, 14), 0.6))
    bg.convert("RGB").save(os.path.join(OUT, "channel-background.png"), optimize=True)

    header = Image.new("RGBA", (W, 78))
    d = ImageDraw.Draw(header)
    for x in range(W):
        v = int(215 - 150 * min(1.0, x / (W * 0.55)))
        d.line([(x, 0), (x, 78)], fill=(v, v, v, 255))
    header.save(os.path.join(OUT, "channel-header.png"), optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    glass()
    neon()
    afterglow()
    channel()
    for name in sorted(os.listdir(OUT)):
        print(os.path.join(OUT, name))


if __name__ == "__main__":
    main()
