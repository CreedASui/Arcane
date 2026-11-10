#!/usr/bin/env python3
"""Keep active release metadata, package naming and published notes aligned."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.7.2"
VERSION_TAG = "v" + VERSION
RELEASE_ASSET = "ArcaneV0.7.2.zip"
ARTIFACT_PREFIX = "Arcane-v0.7.2-test-"
INSTALL_ZIP = "ArcaneV0.7.2.zip"

checks = (
    (ROOT / "Core.lua", f'Arcane.VERSION = "{VERSION}"', "Core.VERSION must be 0.7.2"),
    (ROOT / "Arcane.toc", f"## Version: {VERSION_TAG}", "TOC version must be v0.7.1"),
    (ROOT / "README.md", f"**Current release: {VERSION_TAG}**", "README release must be v0.7.1"),
    (ROOT / "README.md", RELEASE_ASSET, "README release package name must match v0.7.1"),
    (ROOT / "CHANGELOG.md", "## v0.7.2 — November 9, 2026", "changelog must include the dated v0.7.1 section"),
    (ROOT / "RELEASE_NOTES_v0.7.2.md", "# Arcane UI v0.7.2", "the full v0.7.2 release notes must exist"),
    (ROOT / ".github/workflows/arcane-audit.yml", ARTIFACT_PREFIX, "CI test artifact name must use v0.7.1"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'archive="$RUNNER_TEMP/{INSTALL_ZIP}"', "CI inner installer must use the fixed ArcaneV0.7.2.zip filename"),
)
for path, expected, message in checks:
    if expected not in path.read_text(encoding="utf-8"):
        print("FAIL:", message, file=sys.stderr)
        raise SystemExit(1)

# Previous changelog entries may mention older releases, but the active install/package metadata must match v0.7.1.
readme = (ROOT / "README.md").read_text(encoding="utf-8")
workflow = (ROOT / ".github" / "workflows" / "arcane-audit.yml").read_text(encoding="utf-8")
if "ArcaneV0.7.1.zip" in readme:
    print("FAIL: README still points at the v0.7.1 release asset", file=sys.stderr)
    raise SystemExit(1)
if "Arcane-v0.7.1-test-" in workflow:
    print("FAIL: CI still labels test packages as v0.7.1", file=sys.stderr)
    raise SystemExit(1)

print("PASS: Arcane v0.7.2 runtime, TOC, README, changelog, release notes and CI package metadata are consistent")
