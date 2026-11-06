#!/usr/bin/env python3
"""Static safeguards for Arcane's modular damage-number refactor."""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_NUMBERS_ORDER = [
    "Numbers.lua", "Numbers_Widgets.lua", "Numbers_Combat.lua",
    "Numbers_Icons.lua", "Numbers_Labels.lua", "Numbers_CombatAPI.lua",
    "Numbers_Preview.lua", "Numbers_Anchors.lua", "Numbers_Layout.lua",
    "Numbers_Culling.lua", "Numbers_Placement.lua", "Numbers_Animation.lua",
    "Numbers_Lifecycle.lua", "Numbers_Options.lua", "Numbers_Commands.lua",
]
MODULES = {
    "Numbers.lua": ("Config", "C"),
    "Numbers_Widgets.lua": ("Widgets", "S"),
    "Numbers_Combat.lua": ("Combat", "S"),
    "Numbers_Icons.lua": ("Icons", "I"),
    "Numbers_Labels.lua": ("Combat", "S"),
    "Numbers_CombatAPI.lua": ("CombatAPI", "S"),
    "Numbers_Preview.lua": ("Preview", "S"),
    "Numbers_Anchors.lua": ("Anchors", "S"),
    "Numbers_Layout.lua": ("Layout", "S"),
    "Numbers_Culling.lua": ("Culling", "S"),
    "Numbers_Placement.lua": ("Placement", "S"),
    "Numbers_Animation.lua": ("Animation", "S"),
    "Numbers_Lifecycle.lua": ("Lifecycle", "S"),
    "Numbers_Options.lua": ("Options", "S"),
    "Numbers_Commands.lua": ("Commands", "S"),
}
# Multi-variable assignments such as S.labels, S.nLabels = {}, 0.
TUPLE_INITIALIZED = {
    "Combat.labels", "Combat.nLabels", "Combat.byKey", "Combat.missByKey",
    "Combat.nextLabelId", "Combat.pending", "Combat.nPending",
    "Combat.bossNames", "Combat.frameNow",
    "CombatAPI.apiReady", "CombatAPI.active", "CombatAPI.registered",
    "CombatAPI.warnedNoApi", "CombatAPI.cursor",
    "Lifecycle.lastNow", "Lifecycle.nextBossRefresh", "Lifecycle.nextSweep",
    "Lifecycle.errors", "Lifecycle.lastErrorAt", "Lifecycle.errorShown",
    "Lifecycle.giveUp", "Lifecycle.blocked", "Lifecycle.handlerAt",
}

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)

def mask_comments_and_strings(source: str) -> str:
    """Blank comments and quoted/long strings while preserving offsets/newlines."""
    out = list(source)
    i, n = 0, len(source)
    def blank(start: int, end: int) -> None:
        for pos in range(start, min(end, n)):
            if out[pos] != "\n":
                out[pos] = " "
    while i < n:
        if source.startswith("--", i):
            start = i
            i += 2
            long = re.match(r"\[(=*)\[", source[i:])
            if long:
                opener = long.group(0)
                closer = "]" + long.group(1) + "]"
                i += len(opener)
                end = source.find(closer, i)
                i = n if end < 0 else end + len(closer)
            else:
                end = source.find("\n", i)
                i = n if end < 0 else end
            blank(start, i)
            continue
        if source[i] in ("'", '"'):
            quote, start = source[i], i
            i += 1
            while i < n:
                if source[i] == "\\":
                    i += 2
                elif source[i] == quote:
                    i += 1
                    break
                else:
                    i += 1
            blank(start, i)
            continue
        if source[i] == "[":
            long = re.match(r"\[(=*)\[", source[i:])
            if long:
                start = i
                opener = long.group(0)
                closer = "]" + long.group(1) + "]"
                i += len(opener)
                end = source.find(closer, i)
                i = n if end < 0 else end + len(closer)
                blank(start, i)
                continue
        i += 1
    return "".join(out)

def read_toc() -> list[str]:
    toc_path = ROOT / "Arcane.toc"
    if not toc_path.is_file():
        fail("Arcane.toc is missing")
    entries: list[str] = []
    for raw in toc_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        entries.append(line)
        if not (ROOT / line).is_file():
            fail(f"TOC entry does not exist: {line}")
    if len(entries) != len(set(entries)):
        fail("Arcane.toc contains duplicate load entries")
    positions = []
    for name in EXPECTED_NUMBERS_ORDER:
        if name not in entries:
            fail(f"Arcane.toc is missing required module: {name}")
        positions.append(entries.index(name))
    if positions != sorted(positions):
        fail("Numbers modules are not in their required dependency/load order")
    if entries.index("Core.lua") > entries.index("Numbers.lua"):
        fail("Core.lua must load before Numbers.lua")
    if entries.index("Timer.lua") > entries.index("Numbers.lua"):
        fail("Timer.lua must load before Numbers.lua")
    print(f"PASS: TOC contains {len(entries)} existing, unique entries")
    print("PASS: Numbers module load order is preserved")

def check_module_ownership() -> None:
    sources: dict[str, str] = {}
    definitions: set[str] = set()
    references: set[str] = set()
    for filename, (namespace, alias) in MODULES.items():
        path = ROOT / filename
        if not path.is_file():
            fail(f"Required Numbers module is missing: {filename}")
        code = mask_comments_and_strings(path.read_text(encoding="utf-8"))
        sources[filename] = code
        for match in re.finditer(rf"\b{re.escape(alias)}\s*\.\s*([A-Za-z_]\w*)\s*=", code):
            definitions.add(f"{namespace}.{match.group(1)}")
        for match in re.finditer(rf"\b{re.escape(alias)}\s*\.\s*([A-Za-z_]\w*)\b", code):
            references.add(f"{namespace}.{match.group(1)}")
        for match in re.finditer(r"\bN\s*\.\s*([A-Za-z_]\w*)\s*\.\s*([A-Za-z_]\w*)\b", code):
            references.add(f"{match.group(1)}.{match.group(2)}")
        # Config is shared by every Numbers module through local C = N.Config.
        for match in re.finditer(r"\bC\s*\.\s*([A-Za-z_]\w*)\b", code):
            references.add(f"Config.{match.group(1)}")
    unresolved = sorted(references - definitions - TUPLE_INITIALIZED)
    if unresolved:
        fail("Unresolved Numbers namespace references: " + ", ".join(unresolved))
    culling = sources["Numbers_Culling.lua"]
    if len(re.findall(r"\bS\s*\.\s*CullLabel\s*=\s*function\b", culling)) != 1:
        fail("Numbers_Culling.lua must own exactly one S.CullLabel implementation")
    for caller in ("Numbers_Placement.lua", "Numbers_Animation.lua"):
        code = sources[caller]
        if "N.Culling.CullLabel(" not in code:
            fail(f"{caller} must call the shared N.Culling.CullLabel implementation")
        if "N.Layout.CullLabel" in code:
            fail(f"{caller} still references obsolete N.Layout.CullLabel")
    numbers_code = sources["Numbers.lua"]
    if re.search(r"\blocal\s+function\s+(Clamp|Smooth)\b", numbers_code):
        fail("Numbers.lua must reuse Core's Clamp/Smooth helpers, not duplicate them")
    if "AUI.Clamp(" not in numbers_code or "AUI.Smooth(" not in sources["Numbers_Layout.lua"]:
        fail("Numbers must reuse Core's shared Clamp/Smooth helpers")
    print(f"PASS: {len(references)} namespace references resolve to one owner")
    print("PASS: shared culling helper has one implementation and correct callers")
    print("PASS: Core math helpers are reused instead of duplicated")

def main() -> None:
    read_toc()
    check_module_ownership()
    print("PASS: Arcane Numbers static architecture audit complete")

if __name__ == "__main__":
    main()
