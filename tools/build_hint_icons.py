"""Draw the remote-button icons used in the on-screen hints (needs Pillow).

Each icon is a dark rounded button with a white glyph, drawn at 1080p size
(36 px tall) and shown 24 px tall in the 720p layout.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "images" / "hints"
SCALE = 4          # draw large, then shrink for smooth edges
HEIGHT = 36        # final height in pixels (1080p)
# Styled after a Roku remote: a purple direction pad and OK button, and round
# dark buttons for back, *, rewind, play/pause and fast forward.
PURPLE = (108, 45, 145, 255)
PURPLE_EDGE = (176, 128, 214, 255)
DARK = (28, 28, 36, 255)
DARK_EDGE = (120, 120, 132, 255)
GLYPH = (255, 255, 255, 255)


def tri(d, cx, cy, size, direction):
    """A solid triangle pointing up, down, left or right, centred on cx, cy."""
    h = size / 2
    points = {
        "up": [(cx - h, cy + h * 0.8), (cx + h, cy + h * 0.8), (cx, cy - h * 0.8)],
        "down": [(cx - h, cy - h * 0.8), (cx + h, cy - h * 0.8), (cx, cy + h * 0.8)],
        "left": [(cx + h * 0.8, cy - h), (cx + h * 0.8, cy + h), (cx - h * 0.8, cy)],
        "right": [(cx - h * 0.8, cy - h), (cx - h * 0.8, cy + h), (cx + h * 0.8, cy)],
    }[direction]
    d.polygon(points, fill=GLYPH)


def button(width_units, draw_glyph, name, fill=DARK, edge=DARK_EDGE):
    """A round (or pill-shaped, when wider than tall) remote button."""
    w, h = int(width_units * SCALE), HEIGHT * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([SCALE, SCALE, w - SCALE - 1, h - SCALE - 1], radius=h // 2 - SCALE,
                        fill=fill, outline=edge, width=int(1.5 * SCALE))
    draw_glyph(d, w, h)
    img = img.resize((int(width_units), HEIGHT), Image.LANCZOS)
    img.save(OUT / f"{name}.png", optimize=True)


def font(size):
    for candidate in ("C:/Windows/Fonts/arialbd.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    g = 12 * SCALE  # glyph size

    # Direction pad (purple), as pairs of its arrows.
    button(52, lambda d, w, h: (tri(d, w * 0.33, h / 2, g, "up"), tri(d, w * 0.67, h / 2, g, "down")),
           "dpad-updown", PURPLE, PURPLE_EDGE)
    button(52, lambda d, w, h: (tri(d, w * 0.33, h / 2, g, "left"), tri(d, w * 0.67, h / 2, g, "right")),
           "dpad-leftright", PURPLE, PURPLE_EDGE)

    def arrows(d, w, h):
        s = g * 0.7
        tri(d, w * 0.5, h * 0.25, s, "up")
        tri(d, w * 0.5, h * 0.75, s, "down")
        tri(d, w * 0.25, h / 2, s, "left")
        tri(d, w * 0.75, h / 2, s, "right")
    button(36, arrows, "dpad-all", PURPLE, PURPLE_EDGE)

    def ok(d, w, h):
        d.text((w / 2, h / 2), "OK", font=font(int(15 * SCALE)), fill=GLYPH, anchor="mm")
    button(44, ok, "ok", PURPLE, PURPLE_EDGE)

    # Round dark buttons.
    def rewind(d, w, h):
        tri(d, w * 0.38, h / 2, g * 0.85, "left")
        tri(d, w * 0.62, h / 2, g * 0.85, "left")
    button(36, rewind, "rewind")

    def forward(d, w, h):
        tri(d, w * 0.38, h / 2, g * 0.85, "right")
        tri(d, w * 0.62, h / 2, g * 0.85, "right")
    button(36, forward, "forward")

    def playpause(d, w, h):
        tri(d, w * 0.36, h / 2, g * 0.9, "right")
        bar_w, bar_h = 2.5 * SCALE, g * 0.85
        for x in (0.60, 0.72):
            cx = w * x
            d.rectangle([cx - bar_w / 2, h / 2 - bar_h / 2, cx + bar_w / 2, h / 2 + bar_h / 2], fill=GLYPH)
    button(36, playpause, "playpause")

    def back(d, w, h):
        # A left arrow, like the Back button on a Roku remote.
        lw = int(3 * SCALE)
        d.line([(w * 0.34, h / 2), (w * 0.70, h / 2)], fill=GLYPH, width=lw)
        tri(d, w * 0.32, h / 2, g * 0.85, "left")
    button(36, back, "back")

    def star(d, w, h):
        d.text((w / 2, h * 0.64), "*", font=font(int(26 * SCALE)), fill=GLYPH, anchor="mm")
    button(36, star, "star")
    print("icons written to", OUT)


if __name__ == "__main__":
    main()
