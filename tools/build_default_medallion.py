#!/usr/bin/env python3
"""Build the single, untinted Classic Arcane medallion texture for WoW."""
from __future__ import annotations

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "assets" / "PanelDefaultMedallion.webp"
OUTPUT = ROOT / "Art" / "PanelDefaultMedallion.tga"
EXPECTED_SIZE = (512, 512)


def encode_tga_rle(image: Image.Image) -> bytes:
    image = image.convert("RGBA")
    width, height = image.size
    if width != height or width not in (128, 256, 512):
        raise ValueError(f"Expected a supported square texture, got {width}x{height}")

    px = image.load()
    header = bytearray(18)
    header[2] = 10  # RLE true-color image
    header[12:14] = width.to_bytes(2, "little")
    header[14:16] = height.to_bytes(2, "little")
    header[16] = 32  # BGRA
    header[17] = 0x28  # top-origin, 8 alpha bits
    body = bytearray()

    def bgra(x: int, y: int) -> bytes:
        r, g, b, a = px[x, y]
        return bytes((b, g, r, a))

    for y in range(height):
        row = [bgra(x, y) for x in range(width)]
        x = 0
        while x < width:
            run = 1
            while x + run < width and run < 128 and row[x + run] == row[x]:
                run += 1
            if run >= 2:
                body.append(0x80 | (run - 1))
                body.extend(row[x])
                x += run
                continue

            raw_start = x
            x += 1
            while x < width and (x - raw_start) < 128:
                next_run = 1
                while x + next_run < width and next_run < 128 and row[x + next_run] == row[x]:
                    next_run += 1
                if next_run >= 2:
                    break
                x += 1
            count = x - raw_start
            body.append(count - 1)
            for pixel in row[raw_start:x]:
                body.extend(pixel)

    return bytes(header) + bytes(body)


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"Missing single-source medallion artwork: {SOURCE.relative_to(ROOT)}")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(SOURCE) as source:
        if source.size != EXPECTED_SIZE:
            raise SystemExit(f"Expected {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]} source image, got {source.size}")
        texture = encode_tga_rle(source)
    OUTPUT.write_bytes(texture)
    print(f"Built one untinted {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]} BGRA RLE medallion texture: {OUTPUT.relative_to(ROOT)} ({len(texture)} bytes)")


if __name__ == "__main__":
    main()
