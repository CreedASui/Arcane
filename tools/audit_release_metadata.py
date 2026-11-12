#!/usr/bin/env python3
"""Keep Arcane release metadata and the single-README documentation policy aligned."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

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
workflow = (ROOT / ".github" / "workflows" / "arcane-audit.yml").read_text(encoding="utf-8")

if "<!-- RELEASE_HISTORY_BEGIN -->" not in readme or "<!-- RELEASE_HISTORY_END -->" not in readme:
    fail("README is missing the marked release-history section")
history = readme.split("<!-- RELEASE_HISTORY_BEGIN -->", 1)[1].split("<!-- RELEASE_HISTORY_END -->", 1)[0]
release_heading = re.search(rf"^### {re.escape(VERSION_TAG)} — .+$", history, re.M)
first_release_heading = re.search(r"^### v[0-9]", history, re.M)

checks = (
    (f"## Version: {VERSION_TAG}" in toc, "TOC version must match Core.VERSION"),
    (f"**Current release: {VERSION_TAG}**" in readme, "README current release must match Core.VERSION"),
    (RELEASE_ASSET in readme, "README installer filename must match Core.VERSION"),
    ("## Consolidated release history" in readme, "README must include the consolidated release history"),
    (release_heading is not None, "README release history must contain the current dated release section"),
    (release_heading is not None and first_release_heading is not None and
     release_heading.start() == first_release_heading.start(),
     "the current release must be the first versioned section in README"),
    (history.count("### " + VERSION_TAG + " —") == 1, "the current release must appear exactly once in README"),
    ("## Architecture and module ownership" in readme, "README must include the architecture guide"),
    ("## Attribution and project provenance" in readme, "README must include the attribution record"),
    ("### Documentation rule — one Markdown file" in readme, "README must state the one-file documentation policy"),
    ('tags:\n      - "v*"' in workflow, "CI must validate all version tags"),
    ("tools/extract_release_notes.py" in workflow, "tag publisher must extract notes from README"),
    ("if: startsWith(github.ref, 'refs/tags/v')" in workflow, "release publishing must run for version tags"),
    ("gh release create" in workflow, "validated version tags must publish a GitHub Release"),
    ('gh release upload "$GITHUB_REF_NAME" "release-assets/$asset" --clobber' in workflow,
     "release reruns must replace the existing installer"),
    ('gh release edit "$GITHUB_REF_NAME"' in workflow,
     "release reruns must keep the release title and notes current"),
    ('--notes-file "$RUNNER_TEMP/release-notes.md"' in workflow,
     "GitHub Releases must use the extracted README section"),
    ('python tools/extract_release_notes.py "$version" "$RUNNER_TEMP/release-notes.md"' in workflow,
     "the release job must extract its matching release section"),
    ('cp ATTRIBUTION.txt ArcaneNameplates-LICENSE.txt "$addon/"' in workflow,
     "the install ZIP must retain its plain-text attribution notice"),
    ('"Arcane/ATTRIBUTION.txt"' in workflow, "the install ZIP must verify the plain-text attribution notice"),
)
for passed, message in checks:
    if not passed:
        fail(message)

stale_notes = sorted(path.name for path in ROOT.glob("RELEASE_NOTES_v*.md"))
if stale_notes:
    fail("per-version release-note files remain: " + ", ".join(stale_notes))

markdown_files = sorted(
    path.relative_to(ROOT).as_posix()
    for path in ROOT.rglob("*.md")
    if ".git" not in path.parts
)
if markdown_files != ["README.md"]:
    fail("README.md must be the only Markdown file; found: " + ", ".join(markdown_files))

# Exercise the exact extractor used by the tag publisher.
with tempfile.TemporaryDirectory(prefix="arcane-release-notes-") as temp_dir:
    output = Path(temp_dir) / "release-notes.md"
    result = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "extract_release_notes.py"), VERSION, str(output)],
        cwd=ROOT, text=True, capture_output=True
    )
    if result.returncode != 0:
        fail("release-note extraction failed: " + result.stderr.strip())
    extracted = output.read_text(encoding="utf-8")
    if not extracted.startswith(f"## {VERSION_TAG} —") or "Gold cache markers" not in extracted:
        fail("extracted current release notes are incomplete or mismatched")

print(f"PASS: Arcane {VERSION_TAG} metadata, one-Markdown policy, architecture, attribution, package and tag publisher are consistent")
