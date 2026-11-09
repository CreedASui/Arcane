#!/usr/bin/env python3
"""Keep the displayed, TOC and internal release versions aligned."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
checks = (
    (ROOT / "Core.lua", 'Arcane.VERSION = "0.6"', "Core.VERSION must be 0.6"),
    (ROOT / "Arcane.toc", "## Version: v0.6", "TOC version must be v0.6"),
    (ROOT / "README.md", "**Current release: v0.6**", "README release must be v0.6"),
    (ROOT / "README.md", "ArcaneV0.6.zip", "README package name must match v0.6"),
    (ROOT / "CHANGELOG.md", "## v0.6 —", "changelog must include the v0.6 section"),
)
for path, expected, message in checks:
    if expected not in path.read_text(encoding="utf-8"):
        print("FAIL:", message, file=sys.stderr)
        raise SystemExit(1)
print("PASS: Arcane v0.6 release metadata is consistent")
