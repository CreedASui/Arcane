#!/usr/bin/env python3
"""Keep active release metadata, package naming and published notes aligned."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.7"
VERSION_TAG = "v" + VERSION
RELEASE_ASSET = "ArcaneV0.7.zip"
ARTIFACT_PREFIX = "Arcane-v0.7-test-"

checks = (
    (ROOT / "Core.lua", f'Arcane.VERSION = "{VERSION}"', "Core.VERSION must be 0.7"),
    (ROOT / "Arcane.toc", f"## Version: {VERSION_TAG}", "TOC version must be v0.7"),
    (ROOT / "README.md", f"**Current release: {VERSION_TAG}**", "README release must be v0.7"),
    (ROOT / "README.md", RELEASE_ASSET, "README release package name must match v0.7"),
    (ROOT / "CHANGELOG.md", "## v0.7 — November 9, 2026", "changelog must include the dated v0.7 section"),
    (ROOT / "RELEASE_NOTES_v0.7.md", "# Arcane UI v0.7", "the full v0.7 release notes must exist"),
    (ROOT / ".github/workflows/arcane-audit.yml", ARTIFACT_PREFIX, "CI test artifact name must use v0.7"),
)
for path, expected, message in checks:
    if expected not in path.read_text(encoding="utf-8"):
        print("FAIL:", message, file=sys.stderr)
        raise SystemExit(1)

# Historical changelog entries may mention v0.6, but the active install/package metadata may not.
readme = (ROOT / "README.md").read_text(encoding="utf-8")
workflow = (ROOT / ".github" / "workflows" / "arcane-audit.yml").read_text(encoding="utf-8")
if "ArcaneV0.6.zip" in readme:
    print("FAIL: README still points at the v0.6 release asset", file=sys.stderr)
    raise SystemExit(1)
if "Arcane-v0.6-test-" in workflow:
    print("FAIL: CI still labels test packages as v0.6", file=sys.stderr)
    raise SystemExit(1)

print("PASS: Arcane v0.7 runtime, TOC, README, changelog, release notes and CI package metadata are consistent")
