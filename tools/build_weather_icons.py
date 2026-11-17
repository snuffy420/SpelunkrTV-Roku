"""Draws the header's weather icons into images/weather/ (64 x 64, drawn 4x and
shrunk for smooth edges): sun, moon, partly cloudy (day and night), cloud, fog,
drizzle, rain, snow and thunder. A dark outline keeps them readable on every theme.
Run:  python tools/build_weather_icons.py
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "images", "weather")
S = 4
N = 64 * S

SUN = (255, 196, 46, 255)
SUN_CORE = (255, 226, 110, 255)
MOON = (236, 232, 200, 255)
CLOUD = (232, 238, 250, 255)
CLOUD_DARK = (168, 182, 210, 255)
RAIN = (90, 170, 255, 255)
SNOW = (245, 250, 255, 255)
BOLT = (255, 214, 40, 255)
EDGE = (16, 18, 40, 255)


def canvas():
    return Image.new("RGBA", (N, N), (0, 0, 0, 0))


def outlined(draw_fn, img, width=3):
    """Draws a shape twice: a dark, slightly larger silhouette, then the colour."""
    draw_fn(ImageDraw.Draw(img), True, width * S)
    draw_fn(ImageDraw.Draw(img), False, 0)


def sun(img, cx, cy, r):
    def shape(d, edge, grow):
        for k in range(8):
            a = k * math.pi / 4
            x1, y1 = cx + math.cos(a) * r * 1.35, cy + math.sin(a) * r * 1.35
            x2, y2 = cx + math.cos(a) * r * 1.85, cy + math.sin(a) * r * 1.85
            d.line([(x1, y1), (x2, y2)], fill=EDGE if edge else SUN, width=int(r * 0.32) + grow)
        rr = r + grow / 2
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=EDGE if edge else SUN)
    outlined(shape, img)
    d = ImageDraw.Draw(img)
    d.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55], fill=SUN_CORE)


def moon(img, cx, cy, r):
    mask = Image.new("L", (N, N), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    md.ellipse([cx - r * 0.35, cy - r * 1.15, cx + r * 1.45, cy + r * 0.65], fill=0)
    edge = Image.new("L", (N, N), 0)
    ed = ImageDraw.Draw(edge)
    g = 3 * S
    ed.ellipse([cx - r - g, cy - r - g, cx + r + g, cy + r + g], fill=255)
    ed.ellipse([cx - r * 0.35 + g, cy - r * 1.15 - g, cx + r * 1.45 - g, cy + r * 0.65 - g], fill=0)
    img.paste(EDGE, (0, 0), edge)
    img.paste(MOON, (0, 0), mask)


def cloud(img, cx, cy, w, color=CLOUD):
    """A rounded cloud: three bumps on a flat base, centre (cx, cy), width w."""
    h = w * 0.55

    def shape(d, edge, grow):
        c = EDGE if edge else color
        g = grow
        d.rounded_rectangle([cx - w / 2 - g, cy - h * 0.05 - g, cx + w / 2 + g, cy + h * 0.5 + g], radius=h * 0.28 + g, fill=c)
        d.ellipse([cx - w * 0.38 - g, cy - h * 0.38 - g, cx - w * 0.02 + g, cy + h * 0.3 + g], fill=c)
        d.ellipse([cx - w * 0.14 - g, cy - h * 0.72 - g, cx + w * 0.3 + g, cy + h * 0.2 + g], fill=c)
        d.ellipse([cx + w * 0.08 - g, cy - h * 0.4 - g, cx + w * 0.44 + g, cy + h * 0.3 + g], fill=c)
    outlined(shape, img)


def drops(img, xs, y, length, color, width):
    d = ImageDraw.Draw(img)
    for x in xs:
        d.line([(x + length * 0.3, y), (x, y + length)], fill=EDGE, width=width + 3 * S)
    for x in xs:
        d.line([(x + length * 0.3, y), (x, y + length)], fill=color, width=width)


def flakes(img, xs, y):
    d = ImageDraw.Draw(img)
    for i, x in enumerate(xs):
        yy = y + (i % 2) * 7 * S
        r = 5 * S
        for k in range(3):
            a = k * math.pi / 3
            p1 = (x + math.cos(a) * r, yy + math.sin(a) * r)
            p2 = (x - math.cos(a) * r, yy - math.sin(a) * r)
            d.line([p1, p2], fill=EDGE, width=5 * S)
        for k in range(3):
            a = k * math.pi / 3
            p1 = (x + math.cos(a) * r, yy + math.sin(a) * r)
            p2 = (x - math.cos(a) * r, yy - math.sin(a) * r)
            d.line([p1, p2], fill=SNOW, width=2 * S)


def bolt(img, x, y):
    pts = [(x, y), (x - 9 * S, y + 15 * S), (x - 1 * S, y + 15 * S), (x - 6 * S, y + 28 * S), (x + 9 * S, y + 9 * S), (x + 1 * S, y + 9 * S), (x + 5 * S, y)]
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=BOLT, outline=EDGE, width=2 * S)


def save(img, name):
    img.resize((64, 64), Image.LANCZOS).save(os.path.join(OUT, name + ".png"), optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    c = N / 2

    img = canvas(); sun(img, c, c, 14 * S); save(img, "clear-day")
    img = canvas(); moon(img, c, c, 20 * S); save(img, "clear-night")

    img = canvas(); sun(img, c - 10 * S, c - 10 * S, 10 * S); cloud(img, c + 4 * S, c + 6 * S, 40 * S); save(img, "partly-day")
    img = canvas(); moon(img, c - 9 * S, c - 9 * S, 13 * S); cloud(img, c + 4 * S, c + 6 * S, 40 * S); save(img, "partly-night")

    img = canvas(); cloud(img, c - 8 * S, c - 6 * S, 34 * S, CLOUD_DARK); cloud(img, c + 4 * S, c + 4 * S, 44 * S); save(img, "cloudy")

    img = canvas(); cloud(img, c, c - 8 * S, 42 * S)
    d = ImageDraw.Draw(img)
    for i, y in enumerate([c + 12 * S, c + 20 * S, c + 28 * S]):
        x0 = c - 22 * S + (i % 2) * 6 * S
        d.line([(x0, y), (x0 + 38 * S, y)], fill=EDGE, width=7 * S)
        d.line([(x0, y), (x0 + 38 * S, y)], fill=CLOUD_DARK, width=3 * S)
    save(img, "fog")

    img = canvas(); cloud(img, c, c - 8 * S, 44 * S)
    drops(img, [c - 12 * S, c + 2 * S, c + 16 * S], c + 12 * S, 8 * S, RAIN, 3 * S); save(img, "drizzle")

    img = canvas(); cloud(img, c, c - 8 * S, 44 * S)
    drops(img, [c - 14 * S, c - 3 * S, c + 8 * S, c + 19 * S], c + 10 * S, 16 * S, RAIN, 4 * S); save(img, "rain")

    img = canvas(); cloud(img, c, c - 8 * S, 44 * S)
    flakes(img, [c - 14 * S, c, c + 14 * S], c + 16 * S); save(img, "snow")

    img = canvas(); cloud(img, c, c - 10 * S, 44 * S, CLOUD_DARK)
    bolt(img, c + 2 * S, c + 2 * S)
    drops(img, [c - 16 * S, c + 16 * S], c + 8 * S, 10 * S, RAIN, 3 * S); save(img, "thunder")

    for name in sorted(os.listdir(OUT)):
        print(os.path.join(OUT, name))


if __name__ == "__main__":
    main()
