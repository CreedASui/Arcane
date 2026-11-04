#!/usr/bin/env python3
"""Validate and package the installable Arcane UI addon."""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON_DIR = ROOT / "Arcane"
TOC = ADDON_DIR / "Arcane.toc"
OLD_BRANDING = re.compile(
    r"Creed\s*UI|CreedUIDB|SLASH_CREED|creedDocked|creedSetW|creedW|cuiSkill",
    re.IGNORECASE,
)


def fail(message: str) -> None:
    print(f"Arcane package: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_version() -> str:
    if not TOC.is_file():
        fail(f"missing addon TOC: {TOC.relative_to(ROOT)}")
    text = TOC.read_text(encoding="utf-8")
    match = re.search(r"^##\s*Version:\s*(\S+)\s*$", text, re.MULTILINE)
    if not match:
        fail("Arcane.toc is missing a ## Version field")
    return match.group(1)


def validate_addon() -> tuple[str, list[Path]]:
    version = read_version()

    if not (ADDON_DIR / "Art").is_dir():
        fail("missing Arcane/Art assets folder")
    if not (ADDON_DIR / "Fonts").is_dir():
        fail("missing Arcane/Fonts assets folder")

    toc_text = TOC.read_text(encoding="utf-8")
    listed_files = [
        line.strip()
        for line in toc_text.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    missing = [name for name in listed_files if not (ADDON_DIR / name).is_file()]
    if missing:
        fail("TOC references missing files: " + ", ".join(missing))

    files = sorted(path for path in ADDON_DIR.rglob("*") if path.is_file())
    if not files:
        fail("Arcane addon folder is empty")

    branded = []
    for path in files:
        if path.suffix.lower() not in {".lua", ".toc", ".xml", ".txt"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if OLD_BRANDING.search(text):
            branded.append(str(path.relative_to(ROOT)))
    if branded:
        fail("old CreedUI identifiers remain in addon files: " + ", ".join(branded))

    if "## Title: Arcane UI" not in toc_text:
        fail("TOC title is not 'Arcane UI'")
    if "## SavedVariables: ArcaneDB" not in toc_text:
        fail("TOC saved-variable key is not ArcaneDB")

    return version, files


def rebrand_font_metadata(font_path: Path) -> None:
    """Rename this project's font-family metadata without touching font licensing."""
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        fail("fontTools is required to rebrand bundled fonts (run: python -m pip install fonttools)")

    font = TTFont(font_path)
    changed = False
    for record in font["name"].names:
        try:
            original = record.toUnicode()
        except Exception:
            continue
        renamed = original.replace("Creed UI Letters", "Arcane UI Letters")
        renamed = renamed.replace("CreedUILetters", "ArcaneUILetters")
        if renamed != original:
            record.string = renamed.encode(record.getEncoding())
            changed = True

    if not changed:
        # The fonts may already have been rebranded in a future source revision.
        font.close()
        return

    font.save(font_path)
    font.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="output ZIP path (default: dist/Arcane-VERSION.zip)",
    )
    args = parser.parse_args()

    version, _ = validate_addon()
    output = args.output or (ROOT / "dist" / f"Arcane-{version}.zip")
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)

    try:
        with tempfile.TemporaryDirectory(prefix="arcane-package-") as temporary:
            staging_parent = Path(temporary)
            staging_addon = staging_parent / "Arcane"
            shutil.copytree(ADDON_DIR, staging_addon)

            for font_name in ("Letters.ttf", "LettersCJK.ttf"):
                font_path = staging_addon / "Fonts" / font_name
                if not font_path.is_file():
                    fail(f"missing bundled font: Arcane/Fonts/{font_name}")
                rebrand_font_metadata(font_path)

            with zipfile.ZipFile(
                output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
            ) as archive:
                archive.writestr("Arcane/", b"")
                for path in sorted(p for p in staging_addon.rglob("*") if p.is_file()):
                    archive_name = path.relative_to(staging_parent).as_posix()
                    archive.write(path, archive_name)

        with zipfile.ZipFile(output, "r") as archive:
            bad_member = archive.testzip()
            if bad_member:
                fail(f"ZIP integrity check failed at {bad_member}")
            names = set(archive.namelist())
            if "Arcane/Arcane.toc" not in names:
                fail("ZIP does not contain Arcane/Arcane.toc")
    except (OSError, zipfile.BadZipFile) as exc:
        fail(str(exc))

    print("Arcane package: OK")
    print(f"Version: {version}")
    print("Font family metadata: Arcane UI")
    print("Output: " + str(output))
    print("Install: extract the ZIP into Interface/AddOns")


if __name__ == "__main__":
    main()
