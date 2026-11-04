#!/usr/bin/env python3
"""Rebrand the working CreedUI source export as the independent Arcane project."""
from __future__ import annotations

import re
import shutil
import sys
import tempfile
from pathlib import Path


def renamed_path(relative: Path) -> Path | None:
    parts = list(relative.parts)
    if parts == [".github", "workflows", "package-full-source.yml"]:
        return None

    renamed = []
    for part in parts:
        if part == "CreedUI":
            part = "Arcane"
        elif part == "CreedUI.toc":
            part = "Arcane.toc"
        elif part == "cui":
            part = "arcane"
        elif part == "mock_cui.lua":
            part = "mock_arcane.lua"
        elif part == "render_cui.py":
            part = "render_arcane.py"
        elif part == "package-creedui-zip.yml":
            part = "package-arcane-zip.yml"
        renamed.append(part)
    return Path(*renamed)


def rebrand_bytes(data: bytes) -> bytes:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return data

    # Keep the upstream author's account name intact as provenance.
    owner_token = "__ARCANE_UPSTREAM_OWNER__"
    text = text.replace("CreedASui", owner_token)

    # Product identity, runtime namespace, saved variables, and docs.
    text = re.sub(r"(?i)creed\s*-\s*ui", "Arcane UI", text)
    text = re.sub(r"(?i)creed\s+ui", "Arcane UI", text)
    text = re.sub(r"(?i)creedui_shot", "ARCANE_SHOT", text)
    text = re.sub(r"(?i)creeduidb", "ArcaneDB", text)
    text = re.sub(r"(?i)creedui", "Arcane", text)
    text = re.sub(r"(?i)\bcreed\b", "Arcane", text)

    # The standalone CUI alias and dev harness paths are project-specific too.
    text = re.sub(r"(?i)\bCUI\b", "AUI", text)
    text = re.sub(r"(?i)\bcui(?=/)", "arcane", text)

    # Use Arcane's own slash commands.
    text = re.sub(r"(?i)/creed(?=\b)", "/arcane", text)
    text = re.sub(r"(?i)/cui(?=\b)", "/arc", text)

    # WoW expects uppercase slash-command registration identifiers/table keys.
    text = re.sub(
        r"(?i)SLASH_ARCANE([A-Z0-9_]*)",
        lambda m: "SLASH_ARCANE" + m.group(1).upper(),
        text,
    )
    text = re.sub(
        r'(?i)SlashCmdList\["Arcane([A-Za-z0-9_]*)"\]',
        lambda m: 'SlashCmdList["ARCANE' + m.group(1).upper() + '"]',
        text,
    )

    return text.replace(owner_token, "CreedASui").encode("utf-8")


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: rebrand_arcane.py SOURCE_DIR TARGET_REPO_DIR")

    source = Path(sys.argv[1]).resolve()
    target = Path(sys.argv[2]).resolve()
    if not source.is_dir() or not (source / "CreedUI" / "CreedUI.toc").is_file():
        raise SystemExit("source does not contain the expected CreedUI addon folder")

    stage = Path(tempfile.mkdtemp(prefix="arcane-stage-"))
    copied = 0
    for src in source.rglob("*"):
        if not src.is_file():
            continue
        relative = src.relative_to(source)
        if ".git" in relative.parts:
            continue
        dest_relative = renamed_path(relative)
        if dest_relative is None:
            continue
        dest = stage / dest_relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(rebrand_bytes(src.read_bytes()))
        copied += 1

    # Use an Arcane-native package workflow rather than carrying over the
    # temporary CreedUI/seed-export packaging workflow.
    workflow = stage / ".github" / "workflows" / "package-arcane-zip.yml"
    workflow.parent.mkdir(parents=True, exist_ok=True)
    workflow.write_text("""name: Package Arcane addon ZIP

on:
  push:
    branches:
      - main
    paths:
      - "Arcane/**"
      - ".github/workflows/package-arcane-zip.yml"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  package:
    runs-on: ubuntu-latest
    steps:
      - name: Check out source
        uses: actions/checkout@v4
      - name: Verify addon structure and package
        shell: bash
        run: |
          set -euo pipefail
          test -f Arcane/Arcane.toc
          test -d Arcane/Art
          test -d Arcane/Fonts
          mkdir -p "$RUNNER_TEMP/package"
          zip -qr "$RUNNER_TEMP/package/Arcane.zip" Arcane
          unzip -l "$RUNNER_TEMP/package/Arcane.zip" | grep -q "Arcane/Arcane.toc"
          unzip -t "$RUNNER_TEMP/package/Arcane.zip"
      - name: Upload installable Arcane ZIP
        uses: actions/upload-artifact@v4
        with:
          name: Arcane
          path: \${{ runner.temp }}/package/Arcane.zip
          if-no-files-found: error
          retention-days: 7
""", encoding="utf-8")

    # Replace the temporary bootstrap checkout with the independently renamed project.
    for child in list(target.iterdir()):
        if child.name == ".git":
            continue
        if child.is_dir() and not child.is_symlink():
            shutil.rmtree(child)
        else:
            child.unlink()
    for child in stage.iterdir():
        dest = target / child.name
        if child.is_dir():
            shutil.copytree(child, dest)
        else:
            shutil.copy2(child, dest)

    print(f"Copied and rebranded {copied} source files.")
    print("Addon folder: Arcane/")
    print("TOC: Arcane/Arcane.toc")
    print("Runtime namespace: Arcane")
    print("Saved variables: ArcaneDB")


if __name__ == "__main__":
    main()
