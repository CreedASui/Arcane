#!/usr/bin/env python3
"""Keep Arcane's current release metadata and single-file release history aligned."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)

core = (ROOT / "Core.lua").read_text(encoding="utf-8")
match = re.search(r'Arcane\.VERSION\s*=\s*"([^"]+)"', core)
if not match:
    fail("could not read Arcane.VERSION from Core.lua")

VERSION = match.group(1)
VERSION_TAG = "v" + VERSION
RELEASE_ASSET = f"ArcaneV{VERSION}.zip"

toc = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
workflow = (ROOT / ".github" / "workflows" / "arcane-audit.yml").read_text(encoding="utf-8")

release_heading = re.search(rf"^## {re.escape(VERSION_TAG)} — .+$", changelog, re.M)
first_release_heading = re.search(r"^## v[0-9]", changelog, re.M)

checks = (
    (f"## Version: {VERSION_TAG}" in toc, "TOC version must match Core.VERSION"),
    (f"**Current release: {VERSION_TAG}**" in readme, "README current release must match Core.VERSION"),
    (RELEASE_ASSET in readme, "README installer filename must match Core.VERSION"),
    ("CHANGELOG.md" in readme, "README must link to the consolidated release history"),
    (not re.search(r"RELEASE_NOTES_v[0-9]", readme), "README must not link to per-version release-note files"),
    (release_heading is not None, "CHANGELOG.md must contain the current dated release section"),
    (release_heading is not None and first_release_heading is not None and
     release_heading.start() == first_release_heading.start(),
     "the current release must be the first versioned section in CHANGELOG.md"),
    (changelog.count("## " + VERSION_TAG + " —") == 1, "the current release must appear exactly once in CHANGELOG.md"),
    ('tags:\n      - "v*"' in workflow, "CI must validate all version tags, not only one release"),
    ("tools/extract_release_notes.py" in workflow, "tag publisher must extract notes from CHANGELOG.md"),
    ("if: startsWith(github.ref, 'refs/tags/v')" in workflow, "release publishing must run for version tags"),
    ("gh release create" in workflow, "validated version tags must publish a GitHub Release"),
    ('gh release upload "$GITHUB_REF_NAME" "release-assets/$asset" --clobber' in workflow,
     "release reruns must replace the existing installer"),
    ('gh release edit "$GITHUB_REF_NAME"' in workflow,
     "release reruns must keep the release title and notes current"),
    ('--notes-file "$RUNNER_TEMP/release-notes.md"' in workflow,
     "GitHub Releases must use the extracted changelog section"),
)
for passed, message in checks:
    if not passed:
        fail(message)

stale_notes = sorted(path.name for path in ROOT.glob("RELEASE_NOTES_v*.md"))
if stale_notes:
    fail("per-version release-note files remain: " + ", ".join(stale_notes))

if not (ROOT / "tools" / "extract_release_notes.py").exists():
    fail("release-note extraction helper is missing")

print(f"PASS: Arcane {VERSION_TAG} runtime, TOC, README, single changelog, dynamic CI packaging and GitHub Release publishing metadata are consistent")
