"""Builds splash.png from the same geometry as splash.svg.

Run once:
    python assets/_build_splash.py

Kept in the repo as the canonical splash generator — refresh if the shape list
or colour palette in the splash changes. Output is `assets/splash.png`.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

WIDTH = 512
HEIGHT = 512
BG = (10, 31, 20, 255)           # #0a1f14
INNER_BG = (18, 48, 31, 255)     # #12301f
TILES = [
    (96, 336, 176, 416, 14, (42, 106, 68, 255)),    # 2
    (192, 240, 288, 336, 16, (63, 161, 99, 255)),   # 8
    (288, 144, 400, 256, 20, (95, 212, 135, 255)),  # 128
    (320, 64, 456, 152, 20, (184, 255, 196, 255)),  # 2048
]


def rounded_rect(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int, int]) -> None:
    draw.rounded_rectangle(rect, radius=radius, fill=fill)


def build() -> Path:
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (64, 64, 448, 448), 32, INNER_BG)
    for (x0, y0, x1, y1, r, c) in TILES:
        rounded_rect(draw, (x0, y0, x1, y1), r, c)
    out = Path(__file__).resolve().parent / "splash.png"
    img.save(out, "PNG")
    return out


if __name__ == "__main__":
    path = build()
    print(f"wrote {path}")
