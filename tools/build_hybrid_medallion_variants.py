#!/usr/bin/env python3
"""Generate Shaman and Warlock Hybrid medallion variants from canonical Arcane art.

Only the inner green enamel is hue-shifted. Gold dragon scales, metalwork, foliage,
the separately tinted lower gem, and the right-hand class emblem remain untouched.
"""
from __future__ import annotations

import colorsys
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
    """Hue shift the central green enamel, with a soft spatial falloff into its edge."""
    out = bytearray(pixels)
    th, ts, _ = colorsys.rgb_to_hsv(*(v / 255.0 for v in target_rgb))
    # Coordinates are scaled from the 400px transparent source art to the 512px canvas.
    x0, x1 = 104 * W // 400, 296 * W // 400
    y0, y1 = 86 * H // 400, 287 * H // 400
    feather = 3.0
    for y in range(y0, y1):
        fy = smooth(min((y - y0 + 1) / feather, (y1 - y) / feather))
        for x in range(x0, x1):
            fx = smooth(min((x - x0 + 1) / feather, (x1 - x) / feather))
            spatial = fx * fy
            if spatial <= 0:
                continue
            off = (y * W + x) * 4
            b, g, r, a = pixels[off:off + 4]
            if a == 0:
                continue
            hue, sat, val = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            deg = hue * 180.0
            green_band = max(0.0, min(1.0, (deg - 28.0) / 12.0))
            green_band *= max(0.0, min(1.0, (112.0 - deg) / 14.0))
            saturation = max(0.0, min(1.0, (sat * 255.0 - 46.0) / 68.0))
            weight = green_band * saturation * spatial * (a / 255.0)
            if weight <= 0.001:
                continue
            delta = ((th - hue + 0.5) % 1.0) - 0.5
            nh = (hue + delta * weight) % 1.0
            ns = sat + (ts - sat) * weight * 0.86
            nv = min(1.0, val + (20.0 / 255.0) * weight)
            nr, ng, nb = colorsys.hsv_to_rgb(nh, ns, nv)
            out[off:off + 4] = bytes((
                round(nb * 255), round(ng * 255), round(nr * 255), a
            ))
    return out


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
    shaman = clean_edge(recolor_enamel(base, (82, 168, 255)))
    shaman = add_shaman_edge_wrap(shaman)
    warlock = clean_edge(recolor_enamel(base, (163, 107, 245)))
    encode_tga(ART / "PanelHybridArcaneShaman.tga", shaman)
    encode_tga(ART / "PanelHybridArcaneWarlock.tga", warlock)
    print("Generated Shaman blue edge-wrap and Warlock violet enamel medallion variants.")


if __name__ == "__main__":
    main()
