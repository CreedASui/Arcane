# Arcane UI — developer handoff

Current release: **v0.2**  
Repository: <https://github.com/JamieeLee/Arcane>

Arcane is a HUD addon for **Azeroth Survivors**, a World of Warcraft 1.12.1 roguelike running on the benilla client. The addon uses **Lua 5.0** and the 1.12 widget API. JamieeLee owns product direction and tests changes in the game.

## Repository layout

The repository root is the **source workspace**, not the install folder. All addon source files are at the root:

- `Arcane.toc` — addon manifest, load order, title, notes and version.
- `Core.lua` — shared helpers, saved settings, language system, options hub, `/Arcane`, shared panel and frame utilities.
- `Timer.lua`, `Numbers.lua`, `Bosses.lua`, `Skulls.lua`, `Units.lua`, `Party.lua`, `Downed.lua` — timer, combat numbers, boss/guardian display, unit/party frames and revive indicators.
- `Bar.lua`, `Tally.lua`, `LevelUps.lua`, `Minimap.lua`, `MinimapButton.lua`, `Chests.lua` — skill bar, run counters, stored level-ups, minimap and map pins.
- `ArcanePlates.lua`, `ArcanePlatesOptions.lua` — Tiny Plates nameplates and their options.
- `Meter.lua`, `Hurt.lua`, `Pets.lua`, `Luck.lua`, `Summary.lua`, `Character.lua`, `Talents.lua`, `Chat.lua`, `LootSets.lua`, `Loot.lua` — meter, damage taken/healing numbers, pet bar, luck, run summary, character/talents, chat and loot.
- `Locale.lua` — English source strings plus French, German, Spanish and Portuguese translations.
- `Locale_zh.lua`, `Locale_ru.lua`, `Locale_ja.lua`, `Locale_ko.lua`, `Locale_pl.lua`, `Locale_tr.lua` — Chinese, Russian, Japanese, Korean, Polish and Turkish translations.
- `Art/` — committed BLP textures used by the UI.
- `Fonts/` — `Letters.ttf`, `LettersCJK.ttf` and `LICENSE.txt`.
- `ArcanePlates-LICENSE.txt` — retained MIT notice for Tiny Plates.
- `docs/images/arcane-ui-v0.2.png` — README preview image.
- `README.md`, `CHANGELOG.md`, `ATTRIBUTION.md`, `CLAUDE.md` — project documentation.

There are currently no packaging or development-tool directories in this repository. No packaging scripts, mock client or automated test harness are checked in. Do not document or instruct contributors to run scripts under removed paths.

## Version and release packaging

The current version is **v0.2** in all current-version fields:

- `Arcane.toc`: `## Version: v0.2`
- `Core.lua`: `C.VERSION = "0.2"` (the options hub adds the leading `v` when displaying it)
- Release tag/title and release asset: `v0.2`, **Arcane UI v0.2**, `Arcane-v0.2.zip`
- Current changelog heading: `## v0.2`

The install folder name is always **Arcane**. Textures, fonts and saved variables depend on that name. When preparing a release ZIP, create a top-level `Arcane/` folder and place the root-level addon files and folders inside it. The ZIP must contain `Arcane/Arcane.toc` at its top level. Never ship a branch-named directory such as `Arcane-main/`.

To make the install package, include `Arcane.toc`, all listed Lua modules, `Art/`, `Fonts/` and the applicable license notices. The repository documentation and `docs/images/` preview do not need to be inside the install folder.

## Runtime and coding rules

- Keep code compatible with **Lua 5.0**. Do not use the length operator `#`, `string.match`, hex literals, `goto`, or Lua 5.1+ vararg idioms. Use `table.getn`, `string.find` with captures, `math.mod` and the Lua 5.0 `arg` table.
- Keep file-scope local counts below Lua 5.0's 200-local limit. `Numbers.lua` is especially close to that limit; group new state and constants under a table rather than adding more top-level locals.
- Use only methods supported by the 1.12 widget type being accessed. Verify methods against the actual client/API; do not assume modern WoW APIs exist.
- Avoid passing stray `nil` arguments to game APIs. Use `C.Call(fn, ...)` where appropriate and pass the exact argument count.
- Remove list entries with `table.remove`; do not leave holes by assigning `nil` into an array that relies on `table.getn`.
- Shared memo writers in `Core.lua` (`C.SetText`, `C.Size`, `C.Width`, `C.Place`, `C.Vis`, `C.Alpha`, `C.Color`, `C.TextColor`, `C.TextWidth`) skip unchanged writes. Do not mix them with direct writes on the same region.
- Every player-facing string should go through `C.L`, `C.F` or `C.LText`. Keep all 11 languages aligned with the English keys in `Locale.lua` and the six `Locale_*.lua` files. Translation-generation and validation scripts are not in this repository; make edits directly and check key coverage when adding strings.
- Preserve Arcane's visual identity and existing artwork. Do not replace its art with assets from other addons.
- Every UI part should be registered through `C.RegisterPart`, expose its show/hide setting and restore the game's own UI when disabled. Guard frame update handlers against errors in the same style as the surrounding modules.
- Comments should describe what the player sees in plain English.

## Live testing

Static source review is useful but does not replace loading the addon in Azeroth Survivors. Test changes in the actual client, especially UI frame methods, game API return shapes, combat event data, visibility restoration and saved positions. Do not report tests as passing unless they were actually run. Use `/Arcane probe` to collect game-provided values when investigating an API.

## 6. The game's addon API (AZS)

No mock client or automated API fixture is checked into this repository. Treat these as recorded API observations, and use `/Arcane probe` plus live client behaviour to confirm details before depending on them. Known:

- **Run state:** `AZS_RUN` (`lvl`, `xp`, `xpn`, `gold`, `kills`, `chest`, `rr`, `rrc`, `px`, `py`, ...),
  `AZS_STATS` (`luck`, `gluck`, ...; the full field list isn't known yet). `AZS_GetPhase`,
  `AZS_GetRunTime` (stops during cards and pause), `AZS_GetRunLength`, `AZS_GetLocalTime`.
- **Minimap data:** `AZS_LAIRS` + `AZS_LAIRS_UPDATED` (state asleep/awake/empty, `left`, `x`, `y`,
  `flag`), `AZS_CHESTS`.
- **The game's HUD pieces:** `AZS_SetHudShown` / `AZS_IsHudShown` (parts like `flag` and `localClock`),
  `AZS_SetOnTopOfScreens`.
- **Combat text:** `AZS_GetCombatTextCapabilities`, `AZS_GetCombatTextEvents(cursor, max)`,
  `AZS_ProjectCombatTextAnchors`, `AZS_RegisterCombatTextFrameHandler`. Events carry `meterSource` and
  `meterSourceKey` (the meter line a hit counts toward) and now a distance from the hero.
- **Meter API v1:** `AZS_GetMeterContext`, `AZS_GetMeterSnapshot(query)` (strict query keys;
  `sources` carry names and icons), checkpoints. Also summons, totems, bosses and guardians getters.
  `AZS_GetMeterLoadout({ apiVersion = 1, runId [, ownerId] })` (those keys only): `abilities` (`sourceKey`,
  `rank`, `slotId`, `learned`, `passive`), `equipment`, `talents`, `runJewelry`, and `sources[key].icon`.
  The skill bar's rank boxes match each slot to its ability by icon (by `slotId` if there are none).
- **Spells:** `AZS_SPELLS` (+ `AZS_SPELLS_UPDATED`): `{ key, spell, rank, cd, cdmax }` each, no slot.
- **The run's end:** `AZS_GetRunSummary()` is nil while the run goes on, else `AZS_END`: `result`
  (`victory`, `defeat`, `left`), `t` (seconds), `lvl`, `kills`, `elites`, `guardians`, `bosses`, `dmg`,
  `taken`, `gold`, `chests`, `magnets`, `endl`, `hero`.
- **Damage taken:** `AZS_TAKEN` (+ `_UPDATED`): `{ source, dmg }` each. The meter API itself has only
  `damage` and `healing` metrics.
- **Stored level-ups:** `AZS_GetStoredLevels()` (`AZS_RUN.sl`), `AZS_IsStoringLevels()`,
  `AZS_OpenStoredLevels()` (as the game's Level Up! button), `AZS_SetStoringLevels(on)`. The game's
  button is the `levels` HUD part.
- **Downed and revive lines:** `AZS_DOWNED` raw `{ id, name, x, y, z, ep, state }`; `AZS_GetRevive()`
  `{ down, share, by, reviving, rshare }`. `PlaySound(kit)` plays the game's sounds ("RaidWarning").
- **The game's own words** in its 14 languages (`"end.victory": "..."` and so on) are JSON inside the
  client file too: read them as UTF-8 from the bytes (`strings` drops non-ASCII letters).
- **World anchors (API 0.139.2):** read from the game's own code (below), verified against the live client.
  - `AZS_GetWorldAnchorCapabilities()`: kinds `enemy`, `elite`, `guardian`, `boss`, `finalBoss`,
    `cache`, `guardianLair`, `downedPartyMember`; attachments `position`, `overhead`; 256 a call.
  - `AZS_GetWorldAnchors(query, cursor, limit)`: query nil or `{ kinds = {...}, states = {...} }` (no
    other keys), cursor nil or a string, limit 1 to 256. Answers `{ apiVersion, catalogId, entries,
    hasMore, nextCursor, overflowed }`; each entry has `anchorId`, `kind`, a state (`alive`, `dead`,
    `downed`, `asleep`, `awake`, `empty`...), `attachments`, `positionAvailable`, `x/y/z`, ids
    (`unitId`, `cacheId`, `lairIndex`, `memberId`). Errors `NOT_READY`, `CATALOG_CHANGED` (read again
    from the start), `INVALID_ARGUMENT`.
  - `AZS_ProjectWorldAnchors(requests)`: each `{ anchorId, attachment = "position"|"overhead", offset =
    { x, y, z } }` in yards. Answers `{ cameraSampleId, frameCurrent, entries }`; each entry `state`
    (`onScreen`, `offscreen`, `behindCamera`, `clipped`, `notReady`, `expired`, `unknownAnchor`,
    `worldChanged`, `unsupportedAttachment`), `targetState`, `x`, `y` (WorldFrame's bottom left, as
    combat text), `cameraDepth`, `uiUnitsPerYard`, `playerDistance`.
  - `AZS_RegisterWorldAnchorFrameHandler(fn)`: called each frame after the camera, as combat text's.
  - `AZS_GetDownedPartyMembers()`: no arguments; a list of `{ id, name, positionAvailable, anchorStatus,
    anchorId, x, y, z, mapId, runId, spaceId }` (nil and an error before the run's lines come).
    `AZS_GetRevive()` / `AZS_REVIVE`: `{ down, share, by, reviving, rshare }` (your own revive and
    the friend you stand over). `AZS_DOWNED` + `AZS_DOWNED_UPDATED` are the raw list.
  - The exact nesting of the answers is the one thing not seen live: `/Arcane probe` prints them.
- **Where the API is written down:** the game's Lua for every `AZS_*` function, with comments, is
  inside its client, `https://wow.aethus.pl/wenilla_bg.wasm` (about 90 MB): `strings -n 3` it and
  search for `function AZS_`. The native side's field names and error messages are there too.
- `/Arcane probe` prints `AZS_STATS`, `AZS_RUN` and the stats the character panel found. Ask the user
  for its output when you need field names.

