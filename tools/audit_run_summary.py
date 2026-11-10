#!/usr/bin/env python3
"""Static regression checks for repeated run-summary lifecycles."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Windows/Summary.lua").read_text(encoding="utf-8")

def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)

required = (
    ('summaryKey = nil', "the summary must store a unique end snapshot"),
    ('local function SummaryKey(e)', "the end snapshot must be identified independently of its result label"),
    ('tostring(e.result), tostring(e.t), tostring(e.lvl), tostring(e.kills)', "the key must include the outcome and run statistics"),
    ('phase == "playing" and S.lastPhase == "ready"', "the new run must be detected when it starts"),
    ('S.runActive = true', "starting a new run must arm the next summary"),
    ('key ~= S.summaryKey and (phase == nil or phase == "dead" or phase == "victory")', "the next end must have a new snapshot and an end-of-run phase"),
    ('S.runActive = false', "the new end summary must finish the active-run wait"),
    ('S.result = tostring(e.result)', "the outcome must be tracked separately for endless-victory handling"),
    ('local want = (S.summaryKey and not S.closed) and 1 or 0', "the saved summary must remain visible independently of the live getter"),
)
for fragment, message in required:
    if fragment not in source:
        fail(message)

start = source.find('if phase == "playing" and S.lastPhase == "ready" then')
arm = source.find("S.runActive = true", start)
run_wait = source.find("if S.runActive then", arm)
fresh_end = source.find("key ~= S.summaryKey and (phase == nil or phase == \"dead\" or phase == \"victory\")", run_wait)
show = source.find("Show(e, now)", fresh_end)
if min(start, arm, run_wait, fresh_end, show) < 0 or not (start < arm < run_wait < fresh_end < show):
    fail("a new run must re-arm summary display and wait for its own changed end snapshot")

if '(e and not S.closed)' in source:
    fail("the summary's visibility must not depend on a possibly stale or cleared getter result")

# Co-op: after you fall the run goes on and the game's end line keeps counting, so its snapshot
# changes every update. Outside a new run, only a first summary or a new outcome may (re)open it;
# reopening on every changed snapshot made the numbers flicker and undid the close button.
if "elseif e and key ~= S.summaryKey then" in source:
    fail("a co-op summary must not reopen each time the still-counting end line changes")
if 'elseif e and (S.summaryKey == nil or tostring(e.result) ~= S.result) then' not in source:
    fail("outside a new run, only a first summary or a new outcome may open the summary")

print("PASS: starting a new run dismisses the previous summary")
print("PASS: the next run's summary reopens even when its result label repeats")
print("PASS: stale previous-run summary data cannot reopen before a new snapshot arrives")
print("PASS: the stored summary remains visible after the live API clears its data")
print("PASS: in co-op the summary keeps its numbers and stays closed while friends fight on")
