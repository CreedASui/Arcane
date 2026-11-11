#!/usr/bin/env python3
"""Extract one version's Markdown section from CHANGELOG.md for GitHub Releases."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract_release_notes.py VERSION OUTPUT_PATH", file=sys.stderr)
        return 2

    version = sys.argv[1]
    tag = version if version.startswith("v") else "v" + version
    output = Path(sys.argv[2])
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    lines = changelog.splitlines()

    start = None
    for index, line in enumerate(lines):
        if re.match(rf"^## {re.escape(tag)} — .+$", line):
            start = index
            break

    if start is None:
        print(f"Release section {tag} was not found in CHANGELOG.md.", file=sys.stderr)
        return 1

    end = len(lines)
    for index in range(start + 1, len(lines)):
        if lines[index].startswith("## "):
            end = index
            break

    section = "\n".join(lines[start:end]).strip()
    if not section:
        print(f"Release section {tag} is empty.", file=sys.stderr)
        return 1

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(section + "\n", encoding="utf-8")
    print(f"Extracted {tag} release notes to {output}.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
