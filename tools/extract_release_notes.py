#!/usr/bin/env python3
"""Extract one version's Markdown release section from the canonical README."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
START_MARKER = "<!-- RELEASE_HISTORY_BEGIN -->"
END_MARKER = "<!-- RELEASE_HISTORY_END -->"


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract_release_notes.py VERSION OUTPUT_PATH", file=sys.stderr)
        return 2

    version = sys.argv[1]
    tag = version if version.startswith("v") else "v" + version
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    if START_MARKER not in readme or END_MARKER not in readme:
        print("README is missing the consolidated release-history block.", file=sys.stderr)
        return 1

    history = readme.split(START_MARKER, 1)[1].split(END_MARKER, 1)[0]
    lines = history.splitlines()
    start = None
    for index, line in enumerate(lines):
        if re.match(rf"^### {re.escape(tag)} — .+$", line):
            start = index
            break

    if start is None:
        print(f"Release section {tag} was not found in README.", file=sys.stderr)
        return 1

    end = len(lines)
    for index in range(start + 1, len(lines)):
        if re.match(r"^### (?:v[0-9]|Developer reference)", lines[index]):
            end = index
            break

    section = "\n".join(lines[start:end]).strip()
    if not section:
        print(f"Release section {tag} is empty.", file=sys.stderr)
        return 1

    # Keep the archive nested in README, but use a conventional h2 title in GitHub Releases.
    section = "## " + section[len("### "):]
    output = Path(sys.argv[2])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(section + "\n", encoding="utf-8")
    print(f"Extracted {tag} release notes from README to {output}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
