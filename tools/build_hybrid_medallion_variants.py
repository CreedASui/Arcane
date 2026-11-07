#!/usr/bin/env python3
"""Generate class-colored Hybrid medallion variants from canonical Arcane art.

Only the inner green enamel is hue-shifted. Gold dragon scales, metalwork, foliage,
the separately tinted lower gem, and the right-hand class emblem remain untouched.
"""
from __future__ import annotations

import colorsys
import math
import struct
from array import array
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art"
W = H = 512


def decode_tga(path: Path) -> bytearray:
    data = path.read_bytes()
    if len(data) < 18:
        raise ValueError(f"Truncated TGA: {path}")
    h = data[:18]
    if (h[2] != 10 or int.from_bytes(h[12:14], "little") != W
            or int.from_bytes(h[14:16], "little") != H or h[16] != 32
            or (h[17] & 15) != 8 or not (h[17] & 32)):
        raise ValueError(f"Expected top-origin 512x512 RGBA RLE TGA: {path}")
    out = bytearray(W * H * 4)
    pos = 18 + h[0]
    for y in range(H):
        x = 0
        while x < W:
            if pos >= len(data):
                raise ValueError(f"RLE stream ends early: {path}")
            packet = data[pos]
            pos += 1
            count = (packet & 127) + 1
            if x + count > W:
                raise ValueError(f"RLE packet crosses scanline: {path}")
            start = (y * W + x) * 4
            if packet & 128:
                if pos + 4 > len(data):
                    raise ValueError(f"Truncated RLE run: {path}")
                px = data[pos:pos + 4]
                pos += 4
                out[start:start + count * 4] = px * count
            else:
                size = count * 4
                if pos + size > len(data):
                    raise ValueError(f"Truncated raw RLE packet: {path}")
                out[start:start + size] = data[pos:pos + size]
                pos += size
            x += count
    if pos != len(data):
        raise ValueError(f"Unexpected trailing data: {path}")
    return out


def smooth(v: float) -> float:
    v = max(0.0, min(1.0, v))
    return v * v * (3.0 - 2.0 * v)


def nearest_opaque(alpha: bytearray, threshold: int = 245, radius: int = 4):
    distance = bytearray([255]) * (W * H)
    nearest = array("i", [-1]) * (W * H)
    queue = deque()
    for i, a in enumerate(alpha):
        if a >= threshold:
            distance[i] = 0
            nearest[i] = i
            queue.append(i)
    while queue:
        i = queue.popleft()
        d = distance[i]
        if d >= radius:
            continue
        y, x = divmod(i, W)
        source = nearest[i]
        for ny in range(max(0, y - 1), min(H, y + 2)):
            row = ny * W
            for nx in range(max(0, x - 1), min(W, x + 2)):
                j = row + nx
                if distance[j] == 255:
                    distance[j] = d + 1
                    nearest[j] = source
                    queue.append(j)
    return nearest


def clean_edge(pixels: bytearray) -> bytearray:
    """Replace screenshot-background RGB spill only in translucent antialiased pixels."""
    out = bytearray(pixels)
    alpha = bytearray(pixels[i + 3] for i in range(0, len(pixels), 4))
    nearest = nearest_opaque(alpha)
    for i, a in enumerate(alpha):
        src = nearest[i]
        if 0 < a < 235 and src >= 0:
            dst_off, src_off = i * 4, src * 4
            out[dst_off:dst_off + 3] = pixels[src_off:src_off + 3]
    return out


def recolor_enamel(pixels: bytearray, target_rgb: tuple[int, int, int]) -> bytearray:
    """Hue-shift inner green enamel and side accents while preserving gold metalwork."""
    output = bytearray(pixels)
    target_h, target_s, _ = colorsys.rgb_to_hsv(*(v / 255.0 for v in target_rgb))
    gem_x, gem_y, gem_rx, gem_ry = 266.0, 418.0, 31.0, 38.0
    for pixel in range(W * H):
        offset = pixel * 4
        alpha = pixels[offset + 3]
        if not alpha:
            continue
        x, y = pixel % W, pixel // W
        # Central enamel plus two narrow enamel accents beside the dragon crest.
        central = 133 <= x <= 379 and 110 <= y <= 367
        left_accent = 82 <= x <= 154 and 216 <= y <= 344
        right_accent = 358 <= x <= 430 and 216 <= y <= 344
        if not (central or left_accent or right_accent):
            continue
        # Keep the lower gemstone separate so its existing in-game tint layer remains crisp.
        gem_protect = math.exp(-(((x - gem_x) / gem_rx) ** 2
                                 + ((y - gem_y) / gem_ry) ** 2) * 1.3)
        if gem_protect >= 0.98:
            continue
        blue, green, red = pixels[offset], pixels[offset + 1], pixels[offset + 2]
        hue, saturation, value = colorsys.rgb_to_hsv(
            red / 255.0, green / 255.0, blue / 255.0
        )
        hue180 = hue * 180.0
        hue_in = max(0.0, min(1.0, (hue180 - 28.0) / 12.0))
        hue_out = max(0.0, min(1.0, (112.0 - hue180) / 14.0))
        sat_weight = max(0.0, min(1.0, (saturation * 255.0 - 46.0) / 68.0))
        weight = (hue_in * hue_out * sat_weight
                  * (1.0 - min(0.98, gem_protect)) * (alpha / 255.0))
        if weight <= 0.001:
            continue
        delta = ((target_h - hue + 0.5) % 1.0) - 0.5
        new_hue = (hue + delta * weight) % 1.0
        new_saturation = saturation + (target_s - saturation) * weight * 0.86
        new_value = min(1.0, value + (20.0 / 255.0) * weight)
        nr, ng, nb = colorsys.hsv_to_rgb(new_hue, new_saturation, new_value)
        output[offset] = max(0, min(255, int(nb * 255.0 + 0.5)))
        output[offset + 1] = max(0, min(255, int(ng * 255.0 + 0.5)))
        output[offset + 2] = max(0, min(255, int(nr * 255.0 + 0.5)))
    return output

def add_shaman_edge_wrap(pixels: bytearray, radius: int = 4) -> bytearray:
    """Add a slim sapphire wrap outside the medallion silhouette only."""
    alpha = bytearray(pixels[i + 3] for i in range(0, len(pixels), 4))
    distance = bytearray([255]) * (W * H)
    queue = deque()
    for i, a in enumerate(alpha):
        if a > 8:
            distance[i] = 0
            queue.append(i)
    while queue:
        i = queue.popleft()
        d = distance[i]
        if d >= radius:
            continue
        y, x = divmod(i, W)
        for ny in range(max(0, y - 1), min(H, y + 2)):
            row = ny * W
            for nx in range(max(0, x - 1), min(W, x + 2)):
                j = row + nx
                if distance[j] == 255:
                    distance[j] = d + 1
                    queue.append(j)
    out = bytearray(pixels)
    ring_alpha = (88, 66, 44, 24)
    ring = (38, 91, 162)  # RGB: dark sapphire, subtle enough to frame rather than glow
    for i, d in enumerate(distance):
        if not 1 <= d <= radius:
            continue
        off = i * 4
        old_a = out[off + 3]
        add_a = ring_alpha[d - 1] * (255 - old_a) / 255.0
        new_a = old_a + add_a
        if new_a <= 0:
            continue
        out[off] = round((out[off] * old_a + ring[2] * add_a) / new_a)
        out[off + 1] = round((out[off + 1] * old_a + ring[1] * add_a) / new_a)
        out[off + 2] = round((out[off + 2] * old_a + ring[0] * add_a) / new_a)
        out[off + 3] = round(new_a)
    for off in range(0, len(out), 4):
        if out[off + 3] == 0:
            out[off:off + 3] = b"\0\0\0"
    return out


def encode_tga(path: Path, pixels: bytearray) -> None:
    header = bytearray(18)
    header[2] = 10
    header[12:14] = struct.pack("<H", W)
    header[14:16] = struct.pack("<H", H)
    header[16] = 32
    header[17] = 0x28  # 8 alpha bits, top-left origin
    out = bytearray(header)
    for y in range(H):
        row = y * W * 4
        x = 0
        while x < W:
            off = row + x * 4
            run = 1
            while x + run < W and run < 128:
                nxt = off + run * 4
                if pixels[nxt:nxt + 4] != pixels[off:off + 4]:
                    break
                run += 1
            if run >= 2:
                out.append(0x80 | (run - 1))
                out.extend(pixels[off:off + 4])
                x += run
            else:
                start = x
                x += 1
                while x < W and x - start < 128:
                    cur = row + x * 4
                    look = 1
                    while x + look < W and look < 128:
                        nxt = cur + look * 4
                        if pixels[nxt:nxt + 4] != pixels[cur:cur + 4]:
                            break
                        look += 1
                    if look >= 2:
                        break
                    x += 1
                count = x - start
                off = row + start * 4
                out.append(count - 1)
                out.extend(pixels[off:off + count * 4])
    path.write_bytes(out)


def main() -> None:
    source = ART / "PanelHybridArcane.tga"
    if not source.is_file():
        raise SystemExit(f"Missing canonical Hybrid medallion: {source}")
    base = decode_tga(source)
    variants = {
        # Match the dominant Hybrid bar palette; the bottom gemstone stays independent.
        "Warrior": ((178, 56, 36), False),
        "Paladin": ((204, 153, 77), False),
        "Rogue": ((158, 82, 191), False),
        "Priest": ((214, 219, 235), False),
        "Shaman": ((82, 168, 255), True),
        "Mage": ((64, 128, 242), False),
        "Warlock": ((163, 107, 245), False),
    }
    for class_name, (color, add_wrap) in variants.items():
        output = clean_edge(recolor_enamel(base, color))
        if add_wrap:
            output = add_shaman_edge_wrap(output)
        encode_tga(ART / f"PanelHybridArcane{class_name}.tga", output)
    print("Generated Warrior red, Paladin gold, Rogue violet, Priest silver, Shaman blue, Mage blue and Warlock violet medallions. Hunter and Druid retain the original green art.")

if __name__ == "__main__":
    main()
