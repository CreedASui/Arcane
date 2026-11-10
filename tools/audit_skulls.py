#!/usr/bin/env python3
"""Static regression checks for the world markers: skulls over bosses and guardians, and a gold
chest over each cache waiting on the field."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Frames/Skulls.lua").read_text(encoding="utf-8")

def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)

required = (
    ('kinds = { "boss", "finalBoss", "guardian", "cache" }', "the world-anchor query must ask for caches too"),
    ('e.kind == "cache"', "cache anchors must be kept in the marker list"),
    ('cache = e.kind == "cache"', "each marker must know whether it is a cache"),
    ('r.attachment, r.offset.z = "position", CACHE.lift', "a cache's mark must float over its position (caches have no head)"),
    ('(cache and "Chest")', "a cache must wear the chest art"),
    ("collected = true", "a taken cache's mark must go"),
)
for fragment, message in required:
    if fragment not in source:
        fail(message)
if not (ROOT / "Art/Chest.blp").exists():
    fail("the chest art must ship in Art/")

print("PASS: every cache on the field wears a gold chest mark, which goes once it is taken")
