#!/usr/bin/env python3
"""Draw the crit backdrops made for the damage-number looks: original art, nothing traced.

Each is a wide burst drawn behind a critical hit's number, 256x128, in the manner of the six
that came with the Creed working base (Flame, Frost, Arcane, Holy, Shadow, Storm):

  NumSteel   crossing blade slashes with sparks: a physical crit (the Elemental look)
  NumBurst   a comic-book starburst: the Comic look
  NumGilded  a dark glass plaque in a gold rim with diamond tips: the Royal look

They are written to Art/ as BLP2 (uncompressed BGRA, one mip), the format the game reads.
The .blp files are kept in the repository; this script is here so they can be drawn again.
It needs numpy and Pillow, and takes an optional folder for PNG copies to look at:

    python tools/build_crit_backdrops.py [png folder]
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art"
PNG = Path(sys.argv[1]) if len(sys.argv) > 1 else None
W, H, SS = 256, 128, 3  # drawn three times as large, then averaged down for clean edges


def write_blp(name: str, rgba: np.ndarray) -> None:
    h, w, _ = rgba.shape
    a8 = np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8)
    head = b"BLP2" + struct.pack("<I", 1) + bytes([3, 8, 8, 0]) + struct.pack("<II", w, h)
    head += struct.pack("<16I", *([1172] + [0] * 15)) + struct.pack("<16I", *([w * h * 4] + [0] * 15))
    head += b"\x00" * 1024
    (ART / f"{name}.blp").write_bytes(head + a8[:, :, [2, 1, 0, 3]].tobytes())
    if PNG:
        PNG.mkdir(parents=True, exist_ok=True)
        Image.fromarray(a8, "RGBA").save(PNG / f"{name}.png")


# The picture's own units: x from -2 to 2, y from -1 to 1 (up is positive), so a unit is square.
xs = (np.arange(W * SS) + 0.5) / (W * SS) * 4 - 2
ys = 1 - (np.arange(H * SS) + 0.5) / (H * SS) * 2
x, y = np.meshgrid(xs, ys)
px = 4.0 / (W * SS)


def blur(m: np.ndarray, radius: float) -> np.ndarray:
    """A soft (Gaussian) blur, `radius` in final pixels: across, then down."""
    sigma = radius * SS
    reach = int(sigma * 3) + 1
    t = np.arange(-reach, reach + 1)
    kernel = np.exp(-t * t / (2 * sigma * sigma))
    kernel /= kernel.sum()
    out = np.apply_along_axis(lambda row: np.convolve(row, kernel, mode="same"), 1, m)
    return np.apply_along_axis(lambda column: np.convolve(column, kernel, mode="same"), 0, out)


def cover(sdf: np.ndarray, soft: float = 1.0) -> np.ndarray:
    """How much of a pixel a shape covers, from its signed distance (negative inside)."""
    return np.clip(0.5 - sdf / (px * soft), 0, 1)


def mix(a, b, t) -> np.ndarray:
    t = np.clip(t, 0, 1)[..., None]
    return np.array(a) * (1 - t) + np.array(b) * t


def over(col: np.ndarray, alpha: np.ndarray, top, top_alpha: np.ndarray):
    """Paint `top` over a picture kept as straight color and alpha."""
    top_alpha = np.clip(top_alpha, 0, 1)
    out_a = top_alpha + alpha * (1 - top_alpha)
    top = np.broadcast_to(np.array(top, dtype=np.float64), col.shape)
    with np.errstate(invalid="ignore", divide="ignore"):
        out_c = np.where(out_a[..., None] > 1e-6,
                         (top * top_alpha[..., None] + col * (alpha * (1 - top_alpha))[..., None]) / out_a[..., None], 0)
    return out_c, out_a


def finish(name: str, col: np.ndarray, alpha: np.ndarray) -> None:
    """Down to size with premultiplied averaging, so no dark fringe creeps into the edges."""
    alpha = np.clip(alpha, 0, 1)
    pc = np.clip(col, 0, 1) * alpha[..., None]
    pc = pc.reshape(H, SS, W, SS, 3).mean(axis=(1, 3))
    a = alpha.reshape(H, SS, W, SS).mean(axis=(1, 3))
    with np.errstate(invalid="ignore", divide="ignore"):
        c = np.where(a[..., None] > 1e-5, pc / a[..., None], 0)
    write_blp(name, np.dstack([np.clip(c, 0, 1), a]))


def segment_distance(x0, y0, x1, y1):
    dx, dy = x1 - x0, y1 - y0
    ln2 = dx * dx + dy * dy + 1e-12
    u = np.clip(((x - x0) * dx + (y - y0) * dy) / ln2, 0, 1)
    return np.hypot(x - (x0 + u * dx), y - (y0 + u * dy)), u


def sparks(n, seed, spots, size):
    """Small bright points; `spots` gives each one's place from the random source."""
    g = np.random.default_rng(seed)
    m = np.zeros_like(x)
    for _ in range(n):
        cx, cy = spots(g)
        s = g.uniform(size * 0.5, size)
        m = np.maximum(m, np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (s * s)))
    return m


# ---------------------------------------------------------------------------------------- Steel
def steel() -> None:
    """Three blade slashes crossing behind the number: white-hot edges in a cold steel glow,
    with sparks struck off where they meet."""
    slashes = [
        # from, to, bend (how far its middle bows), width
        ((-1.72, 0.50), (1.70, -0.46), 0.10, 0.060),
        ((-1.50, -0.56), (1.56, 0.52), -0.08, 0.052),
        ((-0.62, 0.86), (0.70, -0.84), 0.05, 0.040),
    ]
    core = np.zeros_like(x)
    glow = np.zeros_like(x)
    for (x0, y0), (x1, y1), bend, width in slashes:
        # a bowed stroke as a chain of short pieces, thin at both ends and full in the middle
        steps = 28
        nx, ny = -(y1 - y0), (x1 - x0)
        ln = np.hypot(nx, ny)
        nx, ny = nx / ln, ny / ln
        prev = None
        for i in range(steps + 1):
            t = i / steps
            bow = bend * np.sin(np.pi * t)
            p = (x0 + (x1 - x0) * t + nx * bow, y0 + (y1 - y0) * t + ny * bow)
            if prev is not None:
                tm = (i - 0.5) / steps
                w = width * np.sin(np.pi * tm) ** 0.75
                d, _ = segment_distance(prev[0], prev[1], p[0], p[1])
                core = np.maximum(core, np.clip(1 - d / max(w, 1e-4), 0, 1) ** 1.6)
                glow = np.maximum(glow, np.exp(-(d / (w * 3.2 + 0.03)) ** 2) * np.sin(np.pi * tm) ** 0.5)
            prev = p
    heart = np.exp(-((x / 0.55) ** 2 + (y / 0.30) ** 2))
    struck = sparks(34, 61, lambda g: (g.normal(0, 0.62), g.normal(0, 0.30)), 0.030)
    flung = sparks(16, 62, lambda g: (g.uniform(-1.7, 1.7), g.uniform(-0.8, 0.8)), 0.022)
    alpha = np.clip(glow * 0.62 + core + heart * 0.55 + struck * 0.95 + flung * 0.8, 0, 1)
    col = mix([0.36, 0.47, 0.70], [0.74, 0.83, 0.95], np.clip(glow * 0.9 + heart * 0.5, 0, 1))
    col = mix(col, [1.0, 1.0, 1.0], np.clip(core * 1.25 + heart * 0.35, 0, 1))
    col = mix(col, [1.0, 0.86, 0.56], np.clip(struck + flung, 0, 1) * (1 - np.clip(core, 0, 1)))
    finish("NumSteel", col, alpha * 0.95)


# ---------------------------------------------------------------------------------------- Burst
def star(tips, seed, valley, jitter, size, turn, sx, sy):
    """A spiky star with straight edges, as a comic burst is inked: its coverage of each pixel.
    `tips` points of uneven length round an oval `sx` by `sy`, valleys at `valley` of a point."""
    g = np.random.default_rng(seed)
    points = []
    for i in range(tips * 2):
        angle = turn + (i + g.uniform(-0.16, 0.16)) * np.pi / tips
        if i % 2 == 0:
            radius = 1.0 + g.uniform(-jitter, jitter)
            if (i // 2) % 2 == 1:
                radius *= 0.84  # every other point shorter
        else:
            radius = valley * (1.0 + g.uniform(-jitter, jitter))
        points.append((np.cos(angle) * radius * size * sx, np.sin(angle) * radius * size * sy))
    # drawn twice as large again and averaged, for smooth edges
    more = 2
    wide, high = W * SS * more, H * SS * more
    mask = Image.new("L", (wide, high), 0)
    ImageDraw.Draw(mask).polygon([((px_ + 2) / 4 * wide, (1 - py_) / 2 * high) for px_, py_ in points], fill=255)
    m = np.asarray(mask, dtype=np.float64) / 255.0
    return m.reshape(H * SS, more, W * SS, more).mean(axis=(1, 3))


def burst() -> None:
    """A comic-book burst: a yellow star of uneven points inked in a dark outline, a red star
    inside it for the number to sit on, and a print's halftone dots toward the points."""
    sx, sy = 1.90, 0.94
    rr = np.hypot(x / sx, y / sy)
    outer = star(13, 71, 0.60, 0.07, 1.0, 0.12, sx, sy)
    inner = star(13, 72, 0.66, 0.05, 0.66, 0.36, sx, sy)
    ink = [0.11, 0.04, 0.02]
    line = np.clip(blur(outer, 1.6) * 2.6, 0, 1)            # the ink round the yellow star
    inner_line = np.clip(blur(inner, 1.2) * 2.6, 0, 1)      # and round the red one

    col = np.zeros(x.shape + (3,))
    alpha = np.zeros_like(x)
    col, alpha = over(col, alpha, ink, line * 0.94)
    # the yellow star, deepening to orange toward its points
    yellow = mix([1.00, 0.94, 0.32], [1.00, 0.70, 0.07], np.clip((rr - 0.42) / 0.5, 0, 1))
    # halftone: rows of small orange dots, each row shifted half a step, growing toward the points
    cell = 0.094
    row = np.floor(y / cell)
    gx = (x + (row % 2) * cell / 2) / cell
    gy = y / cell
    dot = np.hypot(gx - np.floor(gx) - 0.5, gy - np.floor(gy) - 0.5)
    dots = np.clip((np.clip((rr - 0.50) / 0.42, 0, 1) * 0.40 - dot) / 0.07, 0, 1)
    yellow = yellow * (1 - dots[..., None] * 0.7) + np.array([0.95, 0.36, 0.04]) * dots[..., None] * 0.7
    col, alpha = over(col, alpha, yellow, outer)
    col, alpha = over(col, alpha, ink, inner_line * outer * 0.92)
    # the red star: bright at its points, deep in the middle where the number sits
    red = mix([0.96, 0.20, 0.07], [0.50, 0.04, 0.04], np.clip(1 - rr / 0.52, 0, 1) ** 1.1)
    col, alpha = over(col, alpha, red, inner)
    finish("NumBurst", col, alpha * 0.97)


# ---------------------------------------------------------------------------------------- Gilded
def lozenge(cx, cy, w, h):
    return (np.abs(x - cx) / w + np.abs(y - cy) / h - 1) * min(w, h)


def gilded() -> None:
    """A plaque for a crit: dark glass in a gold rim, cut to a point at each end, with a gold
    diamond on each point, small ones over and under the middle, and a fine line inside the rim."""
    a, b, cut = 1.50, 0.50, 0.50  # half width, half height, how far in the points start

    def plaque(grow):
        aa, bb = a + grow, b + grow
        # a box with its ends cut to points: inside when under the flat edge and both slants
        slant = (np.abs(x) - aa) * (bb / cut) + np.abs(y)
        return np.maximum(np.abs(y) - bb, slant / np.hypot(1, bb / cut))

    body = plaque(0)
    glass = cover(body)
    rim = cover(np.abs(body + 0.030) - 0.030)               # a gold band just inside the edge
    hair = cover(np.abs(body + 0.105) - 0.007) * 0.75       # a fine line inside it
    glow = np.exp(-(np.clip(body, 0, None) / 0.16) ** 2) * (1 - glass) * 0.42

    col = np.zeros(x.shape + (3,))
    alpha = np.zeros_like(x)
    col, alpha = over(col, alpha, [0.95, 0.72, 0.26], glow)
    # dark glass: near black, a breath of blue, lighter along the top as glass under a light
    sheen = np.clip((y + b) / (2 * b), 0, 1) ** 2.2
    glass_col = mix([0.035, 0.035, 0.060], [0.13, 0.13, 0.19], sheen * 0.8)
    col, alpha = over(col, alpha, glass_col, glass * 0.80)
    # gold with a soft light from above: bright on the upper rim, deep under
    lit = np.clip(0.55 + y * 0.9 + 0.25 * np.cos(x * 2.2), 0, 1)
    gold = mix([0.62, 0.40, 0.10], [1.00, 0.86, 0.46], lit)
    col, alpha = over(col, alpha, gold, rim)
    col, alpha = over(col, alpha, mix([0.70, 0.50, 0.16], [0.98, 0.82, 0.42], lit), hair)
    # diamonds: one on each point, small ones on the middle of the top and bottom rims
    for cx, cy, w, h in ((-a, 0, 0.17, 0.17), (a, 0, 0.17, 0.17), (0, b - 0.01, 0.085, 0.085), (0, -b + 0.01, 0.085, 0.085)):
        d = lozenge(cx, cy, w, h)
        col, alpha = over(col, alpha, [0.20, 0.12, 0.03], cover(d - 0.022))            # a dark seat
        face = mix([0.70, 0.46, 0.12], [1.00, 0.90, 0.55], np.clip(0.5 + (y - cy) / h * 0.7 - (x - cx) / w * 0.25, 0, 1))
        col, alpha = over(col, alpha, face, cover(d))
        col, alpha = over(col, alpha, [1.0, 0.97, 0.80], cover(lozenge(cx, cy + h * 0.18, w * 0.30, h * 0.30)) * 0.85)
    # a few motes of gold light off the points
    motes = sparks(14, 81, lambda g: (g.choice([-1, 1]) * g.uniform(1.52, 1.95), g.normal(0, 0.22)), 0.022)
    col, alpha = over(col, alpha, [1.0, 0.90, 0.55], motes * 0.9)
    finish("NumGilded", col, alpha * 0.97)


steel()
burst()
gilded()
print("wrote NumSteel, NumBurst and NumGilded to", ART)
