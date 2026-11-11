"""Regenerates the images the app bundles instead of drawing at runtime.

  images/logos/<channel>.png  every channel's pixel logo, from the live lineup
  images/tv-static-sheet.png  all frames of the channel-change static

Run it when channels or logos change upstream, then run tools/package.py.
Requires Pillow.
"""
import colorsys
import json
import os
import re
import sys
import urllib.request

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINEUP_URL = "https://data.spelunkr.tv/lineup.json"
# A 32px logo is shown 48 physical pixels wide on a 1080p Roku. Exactly double
# that keeps the pixel art crisp when the TV scales it.
LOGO_SCALE = 3
STATIC_FRAME = (187, 105)
STATIC_COLUMNS = 4
FIXED_COLORS = {
    "k": "0B0F26",
    "n": "2A3580",
    "s": "8899CC",
    "p": "E8EAF0",
    "g": "FFD740",
    "o": "D2500C",
}


def rgb(hex_color):
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))


def hsl_rgb(hue, saturation, lightness):
    red, green, blue = colorsys.hls_to_rgb(hue, lightness, saturation)
    return tuple(max(0, min(255, int(value * 255))) for value in (red, green, blue))


def channel_colors(channel):
    hex_color = (channel.get("color") or "#FFFFFF").lstrip("#")
    if len(hex_color) != 6:
        hex_color = "FFFFFF"
    red, green, blue = (value / 255 for value in rgb(hex_color))
    high, low = max(red, green, blue), min(red, green, blue)
    hue = colorsys.rgb_to_hls(red, green, blue)[0]
    saturation = (high - low) / high if high > 0 else 0
    lightness = (high + low) / 2
    if channel.get("logomarkSaturation") is not None:
        saturation = min(1, max(0, channel["logomarkSaturation"] / 100))
    if channel.get("logomarkLightness") is not None:
        lightness = min(0.94, max(0.06, channel["logomarkLightness"] / 100))
    return {
        "c": hsl_rgb(hue, saturation, lightness),
        "d": hsl_rgb(hue, saturation, max(0.06, lightness * 0.58)),
        "l": hsl_rgb(hue, saturation, min(0.94, lightness + (1 - lightness) * 0.46)),
    }


def render_logo(channel, path):
    rows = channel["logomark"]["rows"]
    palette = {key: rgb(value) for key, value in FIXED_COLORS.items()}
    palette.update(channel_colors(channel))
    image = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key in palette:
                image.putpixel((x, y), palette[key] + (255,))
    size = (image.width * LOGO_SCALE, image.height * LOGO_SCALE)
    image.resize(size, Image.NEAREST).save(path, optimize=True)


def main():
    request = urllib.request.Request(LINEUP_URL, headers={"User-Agent": "SpelunkrRoku/1.0"})
    lineup = json.load(urllib.request.urlopen(request, timeout=30))
    logo_dir = os.path.join(ROOT, "images", "logos")
    os.makedirs(logo_dir, exist_ok=True)
    # The channel list lives in the app; only the channels it shows get a logo.
    task_source = open(os.path.join(ROOT, "components", "GuideTask.brs"), encoding="utf-8").read()
    directory = re.search(r"directoryIds = \[(.*?)\]", task_source).group(1)
    listed = set(re.findall(r'"([^"]+)"', directory))
    count = 0
    for channel in lineup["channels"]:
        if channel["id"] in listed and (channel.get("logomark") or {}).get("rows"):
            render_logo(channel, os.path.join(logo_dir, channel["id"] + ".png"))
            count += 1
    print(f"wrote {count} logos")

    # Poster nodes draw only a GIF's first frame, so every frame goes on one sheet
    # that MainScene.xml steps through. Half size keeps its texture near 1 MB.
    gif = Image.open(os.path.join(ROOT, "images", "tv-static.gif"))
    sheet = Image.new("RGB", (STATIC_FRAME[0] * STATIC_COLUMNS, STATIC_FRAME[1] * STATIC_COLUMNS))
    for index in range(gif.n_frames):
        gif.seek(index)
        frame = gif.convert("RGB").resize(STATIC_FRAME, Image.NEAREST)
        sheet.paste(frame, ((index % STATIC_COLUMNS) * STATIC_FRAME[0], (index // STATIC_COLUMNS) * STATIC_FRAME[1]))
    sheet.quantize(32).save(os.path.join(ROOT, "images", "tv-static-sheet.png"), optimize=True)
    print(f"wrote tv-static-sheet.png with {gif.n_frames} frames")


if __name__ == "__main__":
    sys.exit(main())
