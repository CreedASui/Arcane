#!/usr/bin/env python3
"""Keep Arcane's active release metadata and publishing workflow aligned."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.7.5"
VERSION_TAG = "v" + VERSION
RELEASE_ASSET = f"ArcaneV{VERSION}.zip"
ARTIFACT_PREFIX = f"Arcane-v{VERSION}-test-"
INSTALL_ZIP = RELEASE_ASSET
RELEASE_DATE = "November 10, 2026"

checks = (
    (ROOT / "Core.lua", f'Arcane.VERSION = "{VERSION}"', "Core.VERSION must match the release version"),
    (ROOT / "Arcane.toc", f"## Version: {VERSION_TAG}", "TOC version must match the release version"),
    (ROOT / "README.md", f"**Current release: {VERSION_TAG}**", "README current release must match"),
    (ROOT / "README.md", RELEASE_ASSET, "README installer filename must match"),
    (ROOT / "README.md", f"RELEASE_NOTES_{VERSION_TAG}.md", "README must link to the current release notes"),
    (ROOT / "CHANGELOG.md", f"## {VERSION_TAG} — {RELEASE_DATE}", "changelog must include the dated release section"),
    (ROOT / f"RELEASE_NOTES_{VERSION_TAG}.md", f"# Arcane UI {VERSION_TAG}", "current release notes must exist"),
    (ROOT / ".github/workflows/arcane-audit.yml", ARTIFACT_PREFIX, "CI artifact prefix must match the release version"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'archive="$RUNNER_TEMP/{INSTALL_ZIP}"', "CI installer filename must match the release asset"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'- "{VERSION_TAG}"', "CI must run for the release tag"),
    (ROOT / ".github/workflows/arcane-audit.yml", f"Audit {VERSION_TAG} release metadata consistency", "CI must run the matching metadata audit"),
    (ROOT / ".github/workflows/arcane-audit.yml", f"if: github.ref == 'refs/tags/{VERSION_TAG}'", "release job must be restricted to the matching tag"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'test "$GITHUB_REF_NAME" = "{VERSION_TAG}"', "release job must verify the tag name"),
    (ROOT / ".github/workflows/arcane-audit.yml", "gh release create", "the validated tag build must publish a GitHub Release"),
    (ROOT / ".github/workflows/arcane-audit.yml", "GH_TOKEN: ${{ github.token }}", "release publishing must authenticate with the Actions token"),
    (ROOT / ".github/workflows/arcane-audit.yml", "gh run download", "release job must download the package from this workflow run"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'--title "Arcane UI {VERSION_TAG}"', "GitHub release title must match the tag"),
    (ROOT / ".github/workflows/arcane-audit.yml", f'--notes-file "RELEASE_NOTES_{VERSION_TAG}.md"', "GitHub release notes must match the tag"),
)
for path, expected, message in checks:
    if not path.exists() or expected not in path.read_text(encoding="utf-8"):
        print("FAIL:", message, file=sys.stderr)
        raise SystemExit(1)

readme = (ROOT / "README.md").read_text(encoding="utf-8")
workflow = (ROOT / ".github" / "workflows" / "arcane-audit.yml").read_text(encoding="utf-8")
if "ArcaneV0.7.4.zip" in readme or "ArcaneV0.7.3.zip" in readme:
    print("FAIL: README still points at an older installer", file=sys.stderr)
    raise SystemExit(1)
if "Arcane-v0.7.4-test-" in workflow or "Arcane-v0.7.3-test-" in workflow:
    print("FAIL: CI still labels test packages with an older release version", file=sys.stderr)
    raise SystemExit(1)

print(f"PASS: Arcane {VERSION_TAG} runtime, TOC, README, changelog, release notes, CI package and tag publishing metadata are consistent")
