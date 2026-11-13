#!/usr/bin/env python3
"""Create a hot-pink XFCE wallpaper from Zenwolf's existing Avatar still.
Preserves the original image and profile checksum; only recolors a copy.
"""
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFilter
except ImportError:
    print("Pillow unavailable; original wallpaper will be used.", file=sys.stderr)
    raise SystemExit(3)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: zenwolf-recolor-avatar.py INPUT OUTPUT", file=sys.stderr)
        return 2
    source, target = map(Path, sys.argv[1:])
    if not source.is_file():
        print(f"Missing original Avatar artwork: {source}", file=sys.stderr)
        return 1
    image = Image.open(source).convert("RGB")
    h, s, v = image.convert("HSV").split()
    # Shift blue, cyan and violet lighting into neon magenta. Preserve the
    # character's warm skin-tone regions and source artwork details.
    hue_lut = list(range(256))
    for i in range(256):
        if 105 <= i <= 215:
            hue_lut[i] = 229 + (i - 105) // 16
        elif 216 <= i <= 247:
            hue_lut[i] = 232
    shifted = Image.merge("HSV", (h.point(hue_lut), s, v)).convert("RGB")
    image = Image.blend(image, shifted, 0.72)
    image = ImageEnhance.Color(image).enhance(1.14)
    width, height = image.size
    # Soft color atmosphere, not a replacement portrait.
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    pen = ImageDraw.Draw(glow)
    pen.ellipse((-width // 3, height // 5, width // 2, height * 6 // 5),
                fill=(255, 25, 182, 85))
    pen.ellipse((width * 2 // 3, -height // 3, width * 4 // 3, height // 2),
                fill=(145, 41, 217, 68))
    glow = glow.filter(ImageFilter.GaussianBlur(max(12, width // 14)))
    image = Image.alpha_composite(image.convert("RGBA"), glow).convert("RGB")
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, "PNG", optimize=True)
    print(f"Created neon Avatar wallpaper: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
