#!/usr/bin/env python3
"""Static safeguards for Arcane's modular damage-number refactor."""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_NUMBERS_ORDER = [
    "Numbers/Numbers.lua", "Numbers/Widgets.lua", "Numbers/Combat.lua",
    "Numbers/Icons.lua", "Numbers/Labels.lua", "Numbers/CombatAPI.lua",
    "Numbers/Preview.lua", "Numbers/Anchors.lua", "Numbers/Layout.lua",
    "Numbers/Culling.lua", "Numbers/Placement.lua", "Numbers/Animation.lua",
    "Numbers/Lifecycle.lua", "Numbers/Options.lua", "Numbers/Commands.lua",
]
CORE_ORDER = [
    "Core/Math.lua", "Core/Rendering.lua", "Core/Localization.lua",
    "Core/Theme.lua", "Core/Storage.lua", "Core/HUD.lua",
    "Core/Bars.lua", "Core/Sizing.lua", "Core/Panels.lua",
    "Core/SafeCalls.lua", "Core/Movement.lua", "Core/Options.lua",
    "Core/Commands.lua", "Core/Cards.lua", "Core/UnitFrames.lua",
    "Core/Startup.lua",
]

MODULES = {
    "Numbers/Numbers.lua": ("Config", "C"),
    "Numbers/Widgets.lua": ("Widgets", "S"),
    "Numbers/Combat.lua": ("Combat", "S"),
    "Numbers/Icons.lua": ("Icons", "I"),
    "Numbers/Labels.lua": ("Combat", "S"),
    "Numbers/CombatAPI.lua": ("CombatAPI", "S"),
    "Numbers/Preview.lua": ("Preview", "S"),
    "Numbers/Anchors.lua": ("Anchors", "S"),
    "Numbers/Layout.lua": ("Layout", "S"),
    "Numbers/Culling.lua": ("Culling", "S"),
    "Numbers/Placement.lua": ("Placement", "S"),
    "Numbers/Animation.lua": ("Animation", "S"),
    "Numbers/Lifecycle.lua": ("Lifecycle", "S"),
    "Numbers/Options.lua": ("Options", "S"),
    "Numbers/Commands.lua": ("Commands", "S"),
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
    if entries.index("Core.lua") > entries.index("Numbers/Numbers.lua"):
        fail("Core.lua must load before Numbers.lua")
    if entries.index("Timer/Timer.lua") > entries.index("Numbers/Numbers.lua"):
        fail("Timer.lua must load before Numbers.lua")
    print(f"PASS: TOC contains {len(entries)} existing, unique entries")
    print("PASS: Numbers module load order is preserved")
    return entries

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
    culling = sources["Numbers/Culling.lua"]
    if len(re.findall(r"\bS\s*\.\s*CullLabel\s*=\s*function\b", culling)) != 1:
        fail("Numbers_Culling.lua must own exactly one S.CullLabel implementation")
    for caller in ("Numbers/Placement.lua", "Numbers/Animation.lua"):
        code = sources[caller]
        if "N.Culling.CullLabel(" not in code:
            fail(f"{caller} must call the shared N.Culling.CullLabel implementation")
        if "N.Layout.CullLabel" in code:
            fail(f"{caller} still references obsolete N.Layout.CullLabel")
    numbers_code = sources["Numbers/Numbers.lua"]
    if re.search(r"\blocal\s+function\s+(Clamp|Smooth)\b", numbers_code):
        fail("Numbers.lua must reuse Core's Clamp/Smooth helpers, not duplicate them")
    if "AUI.Clamp(" not in numbers_code or "AUI.Smooth(" not in sources["Numbers/Layout.lua"]:
        fail("Numbers must reuse Core's shared Clamp/Smooth helpers")
    print(f"PASS: {len(references)} namespace references resolve to one owner")
    print("PASS: shared culling helper has one implementation and correct callers")
    print("PASS: Core math helpers are reused instead of duplicated")


def check_core_structure(entries: list[str]) -> None:
    if "Core.lua" not in entries:
        fail("Core.lua bootstrap is missing")
    positions = []
    for name in CORE_ORDER:
        if name not in entries or not (ROOT / name).is_file():
            fail(f"Core module is missing from the TOC or repository: {name}")
        positions.append(entries.index(name))
    if positions != sorted(positions):
        fail("Core modules are not in their required dependency/load order")
    if entries.index("Core.lua") > positions[0]:
        fail("Core.lua must create Arcane before Core services load")
    if entries.index("Core/Startup.lua") < entries.index("Core/Cards.lua"):
        fail("Core/Startup.lua must load after the card-screen handler")
    print(f"PASS: {len(CORE_ORDER)} Core modules load in dependency order")

def check_shared_unit_frame_helpers() -> None:
    shared = (ROOT / "Core/UnitFrames.lua").read_text(encoding="utf-8")
    if len(re.findall(r"function C\.UnitFrames\.HealthText", shared)) != 1:
        fail("Core/UnitFrames.lua must own the shared health-text formatter exactly once")
    for name in ("Frames/Units.lua", "Frames/Party.lua"):
        code = (ROOT / name).read_text(encoding="utf-8")
        if "local Unit = C.UnitFrames" not in code:
            fail(f"{name} must use the shared unit-frame helpers")
        if "Unit.HealthText(" not in code or "Unit.POWER_COLORS[" not in code:
            fail(f"{name} must use the shared health formatter and power palette")
        if re.search(r"local\s+function\s+HPText\b|local\s+POWER_COLORS\s*=", code):
            fail(f"{name} still duplicates the shared unit-frame helpers")
    print("PASS: player/target and party frames share health formatting and power colors")


def count_chunk_level_locals(source: str) -> int:
    """Count names declared at file scope, excluding locals nested in functions/blocks."""
    code = mask_comments_and_strings(source)
    count = 0
    for line in code.splitlines():
        if not line.startswith("local "):
            continue
        declaration = line[len("local "):].strip()
        if declaration.startswith("function "):
            count += 1
            continue
        names = declaration.split("=", 1)[0].strip()
        count += len([name for name in names.split(",") if name.strip()])
    return count

def check_timer_structure(entries: list[str]) -> None:
    data_path = ROOT / "Timer/Data.lua"
    timer_path = ROOT / "Timer/Timer.lua"
    if not data_path.is_file():
        fail("Timer_Data.lua is missing")
    if entries.index("Core.lua") > entries.index("Timer/Data.lua"):
        fail("Core.lua must load before Timer_Data.lua")
    if entries.index("Timer/Data.lua") > entries.index("Timer/Timer.lua"):
        fail("Timer_Data.lua must load before Timer.lua")

    data = mask_comments_and_strings(data_path.read_text(encoding="utf-8"))
    timer = mask_comments_and_strings(timer_path.read_text(encoding="utf-8"))
    if len(re.findall(r"\bAUI\s*\.\s*TimerData\s*=", data)) != 1:
        fail("Timer_Data.lua must own exactly one AUI.TimerData definition")
    if len(re.findall(r"\bAUI\s*\.\s*TimerData\s*=", timer)):
        fail("Timer.lua must consume, not redefine, AUI.TimerData")
    if len(re.findall(r"\blocal\s+DATA\s*=\s*AUI\s*\.\s*TimerData\b", timer)) != 1:
        fail("Timer.lua must consume the shared Timer_Data module exactly once")

    fields = (
        "THEMES", "ZONE_ORDER", "PAL_KEYS", "FALLBACK", "MOTIFS",
        "HEROIC_COLORS", "ROMAN", "AFFIX_NAMES", "NAME_TO_ZONE", "ZNAME_TO_ZONE",
    )
    for field in fields:
        if not re.search(rf"\b{field}\s*=\s*{field}\b", data):
            fail(f"Timer_Data.lua does not export {field}")
        if not re.search(rf"\bDATA\s*\.\s*{field}\b", timer):
            fail(f"Timer.lua does not consume Timer_Data.{field}")

    # The behavior is shared in Core. Keep Timer's Toward easing local: its snap
    # threshold intentionally differs from Core.Toward.
    aliases = {
        "Clamp": r"local\s+Clamp\s*,\s*Smooth\s*=\s*AUI\s*\.\s*Clamp\s*,\s*AUI\s*\.\s*Smooth",
        "Spring": r"local\s+Spring\s*,\s*Ease\s*=\s*AUI\s*\.\s*Spring\s*,\s*AUI\s*\.\s*Ease",
        "Clock": r"local\s+Clock\s*,\s*Call\s*=\s*AUI\s*\.\s*Clock\s*,\s*AUI\s*\.\s*Call",
        "Tex": r"local\s+Tex\s*,\s*Text\s*=\s*AUI\s*\.\s*Tex\s*,\s*AUI\s*\.\s*Text",
        "Size": r"local\s+Size\s*,\s*Color\s*,\s*Vis\s*,\s*Alpha\s*=\s*AUI\s*\.\s*Size\s*,\s*AUI\s*\.\s*Color\s*,\s*AUI\s*\.\s*Vis\s*,\s*AUI\s*\.\s*Alpha",
    }
    for helper, pattern in aliases.items():
        if not re.search(pattern, timer):
            fail(f"Timer must reuse Core's shared {helper} helper group")
    duplicated = ("Clamp", "Smooth", "Spring", "Ease", "Clock", "Call",
                  "Tex", "Text", "Size", "Color", "Vis", "Alpha")
    for helper in duplicated:
        if re.search(rf"^\s*local\s+function\s+{helper}\b", timer, re.M):
            fail(f"Timer.lua must not duplicate Core helper {helper}")
    if not re.search(r"^\s*local\s+function\s+Toward\b", timer, re.M):
        fail("Timer must retain its intentionally distinct Toward implementation")

    # These are public cross-system contracts: Core controls the timer, Bosses
    # anchors to its root, and other parts use its live shared palette.
    for contract in ("AUI.pal = p", "AUI.palStamp = AUI.palStamp + 1",
                     "AUI.THEMES = THEMES", "AUI.timerRoot = W.root",
                     "AUI.timerLock = function", "AUI.timerReset = function",
                     "AUI.timerOptions = function", "AUI.timerSlash = Slash"):
        if contract not in timer:
            fail(f"Timer public integration contract is missing: {contract}")

    local_count = count_chunk_level_locals(timer_path.read_text(encoding="utf-8"))
    if local_count >= 200:
        fail(f"Timer.lua has {local_count} file-scope locals; Lua 5.0 limit is 200")
    print("PASS: Timer data is isolated and loads before Timer.lua")
    print("PASS: Timer reuses Core helpers and keeps distinct easing local")
    print("PASS: Timer's shared palette and Core/Bosses integration contracts remain")
    print(f"PASS: Timer has {local_count} file-scope locals (under Lua 5.0 limit)")

def main() -> None:
    entries = read_toc()
    check_core_structure(entries)
    check_shared_unit_frame_helpers()
    check_module_ownership()
    check_timer_structure(entries)
    print("PASS: Arcane static architecture audit complete")

if __name__ == "__main__":
    main()
