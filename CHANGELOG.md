## Unreleased

- **Run summary lifecycle:** keep the end-of-run summary visible during “Move to begin,” dismiss it when the next run starts, and show the next end summary even when consecutive runs have the same outcome. Compare the full end snapshot so stale data cannot reopen the old summary during the new run.

- **Stats default position:** Stats now resets directly above the Damage meter on the right side, aligned to the meter's right edge. The Damage meter and Luck keep their original right-side default positions.

- **Stock gameplay notification text:** keep the native message feed transparent and borderless; its text uses the active Arcane UX palette in Arcane, Hybrid and Full Class modes. The feed remains movable through Arcane's Move frames system, while genuine Lua script errors stay in their separate error window.

- **Stock error-frame controls:** the original `UIErrorsFrame` can now be shown or hidden from Arcane Options and repositioned with Arcane's Move frames mode. Hiding it is visual only; its original error, info and system-message event handling stays intact for A/B testing.

- **Full Class palette propagation:** Full Class now applies the active class palette across Arcane's shared UI, including player and party frames, the minimap, Stats, Damage meter, Luck, Character window, pet and stored-level-up panels. Arcane and Hybrid keep their existing bronze UI outside the skill-bar treatment; the boss timer keeps its own zone palette.
- **UI style selector:** the Options hub now labels the selector by its full scope rather than implying it only changes the skill bar.

- **Remove the redundant target pane:** keep the player frame, Arcane Nameplates, and boss/guardian bars without a separate selected-target portrait and health window. Native target selection is unchanged; the stock target pane and its combo-point overlay stay hidden.
- **Party layout:** move the default party-frame stack directly below the player frame.
- **Remove unused legacy access:** B no longer opens the backpack or bags while Arcane is active; other B bindings and the saved key map are left alone. Keep the game's Honor tab hidden whether Arcane's Character panel is enabled or disabled.

## v0.6 — November 8, 2026

- **Arcane Nameplates identity:** move the integrated enemy-plate renderer into Arcane-owned modules, namespace and frame-state names. Preserve the game's `AZS_*` integration and the existing `ArcaneDB.nameplates` saved settings for upgrades.
- **Arcane Nameplates refactor:** reorganize the built-in enemy-plate replacement into state, special-target, visual and controller modules. Keep its health bars on Arcane's shared bar renderer.
- **Native visibility ownership:** the game's `V` command remains the only enemy-plate visibility control. Arcane's replacement is attached to the same pooled native plate buttons, with no second enable/hide switch or stock-renderer fallback.
- **Safer native restoration:** capture and restore only native child visibility and alpha; leave the game's projected plate position and geometry untouched. Avoid blanket show-all recovery when the original state is unknown.
- **Pooled-frame and update fixes:** identify only the game's native plate buttons, refresh reused pool slots without stale state, retry incomplete styling, cache special-target/debuff lookups, and isolate errors to the affected plate.
- **Regression coverage:** add a dedicated Arcane Nameplates audit to the repository's CI checks.

## v0.5 — November 8, 2026

- **Classic skill bar medallions:** use the supplied high-resolution gold dragon/A artwork on both default endcaps, mirrored on the right and aligned against Hybrid's lower ornamental tails. The bar rails, slots, spacing and other styles remain unchanged.
- **README preview:** replace the older preview image with a current in-game screenshot showing the v0.5 HUD.

## v0.4 — November 8, 2026

- **Standalone Stats window:** a movable, resizable tracker for 29 run stats, grouped by Offense, Survival, Area and DoTs, and Run. Choose the stats to show; increases and decreases briefly flash green and red.
- **Party shields:** party health bars now show detected absorb shields using Arcane's existing animated glass-and-stripe overlay.
- **Target portrait rings:** bosses and final bosses receive the original gold elite dragon ring; guardians receive the silver rare ring. The corrected segmented texture keeps the full ring intact.
- **Damage-number choices:** six optional custom fonts join the four built-in faces; six optional critical-hit backdrops add Flame, Frost, Arcane, Holy, Shadow and Storm treatments. The default backdrop remains None.
- **Minimap readability:** cache and lair markers fade near the player's arrow and return to full strength with distance.
- **Loot rarity correction:** Tier 0.5 set armor is identified as Epic (purple), while exact named Tier 0.5 weapons retain their Legendary rarity.

## v0.3

- **Three selectable skill-bar styles:** Classic Arcane remains the unchanged default for existing installs; Hybrid combines the gold Arcane A medallion on the left with the active class crest on the right; Full Class uses class-specific paired emblems, rails and tinted glass.
- **Nine class palettes:** Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock and Druid receive dedicated skill-bar styling. The selected style persists in `ArcaneDB.bar.style`.
- **Hybrid medallion treatments:** class-colored enamel variants are supplied for Warrior, Paladin, Rogue, Priest, Shaman, Mage and Warlock. Hunter and Druid retain the approved original green Arcane medallion; the gold dragon/A artwork is preserved.
- **Hybrid panel edge:** retain the complete right-hand panel endcap beneath the class crest so the bar does not appear cut off.

## v0.2

This release consolidates the current Arcane UI feature set and the previously recorded improvements below. Earlier internal development version labels are intentionally grouped into this release.

- **Skill bar branding:** replace both dragon endcaps with transparent gold-and-black Arcane A medallions; preserve the existing panel rails, slots, and spacing, and keep chat glass clear of the full medallion.
- **Loot pop-up:** Arcane shows item drops with their icon, name and rarity color, plus collection status; marks appear as separate notifications. Up to three stack and fade away. The game's own loot pop-up is restored when the Loot part is turned off.
- **Boss bars:** boss and mini-boss bars are 20% larger; the existing size setting still scales them on top.
- **Boss skulls:** boss skulls are 20% larger, with increased minimum and maximum sizes. Guardian skulls retain their previous apparent size.

- **Lua 5.0 compatibility:** the addon source targets the client's Lua 5.0 runtime.
- **Repository layout:** addon source modules and assets live at the repository root; release packages place them inside the required `Arcane/` install folder.
- **Arcane Nameplates:** regular nameplates now use Arcane's shared FRIZQT face, hostile-name color and layered enemy-red bars; bosses and guardians use the same bar style at full size. The health numbers inside the bars have their own Show health numbers toggle, independent of bar visibility. The game's health values, V visibility toggle and captured native child visibility and alpha are restored during pooled-frame reuse and logout.
- **Bronze gold everywhere:** every frame's metal (your frame, your target and party, the boss bars, the minimap ring, the meter, the luck window and the rest) is the skill bar's bronze gold in every zone, instead of taking the zone's colors. The boss timer keeps its own.
- **Dragons:** both face out now, perched on the bar's ends with the end rail behind them.
- **The skill bar keeps one size:** it no longer grows when a run starts and the kills, gold and cache show up, or as their numbers get longer.

- **New skill bar look**, from your own bar picture: a painted golden dragon sits on each end of the bar, facing in, wings raised, with room so it never covers a slot; gold diamonds mark the middle of the top and bottom rails.
- **One gold everywhere:** the panels' metal, the titles and tooltip headings, the borders and the rank boxes all take the same golds as that picture.

- **Dragons:** the body is one smooth piece now (neck, chest, haunch and thigh flow into each other instead of reading as separate shapes), with a band of domed belly plates down its front. The second wing is folded over the neck instead of sticking up behind it, and the front legs are a pair.

- **Dragons:** the skill bar's dragons are redrawn rearing up: jaws open, forelegs raised with claws curled, crouched on a hind leg, wings spread high, and the tail sweeping along the ground to a tip of flame. Their scales are now raised plates with depth: each one domed, overlapping the next with a step of shadow.

- **Talent window:** the Talents tab (or `/Arcane talents`) opens Arcane UI's own talent window: your trees side by side with their names and points, every talent you learned as its icon with its rank (point at one for its name), and the total. Tree names are in your language, by the game's own words.
- **Damage numbers:** a number that keeps adding hits (a DoT ticking on, a spell's crowd total) grows as it stacks, up to about a third bigger after a second and a half. Every number is a touch smaller to make room.
- **Dragons:** the skill bar dragons' front legs bend naturally at the elbow and grip the ground with clawed hands, the hind feet have toes and claws, and the tail ends in a barb instead of an anchor.
- **Downed friends:** the mark and its class crest are more solid (still see-through).

- **Damage numbers and the level-up cards:** picking a card no longer sends black icons flashing across the screen. The numbers step aside while the cards are up, the ones from before are dropped as the cards close, and new hits show as the fight resumes.

Fixes from playtesting:
- **Talents:** the Talents tab opens the game's own Talents window, with Azeroth Survivors' real trees, milestones and points (Arcane UI's page showed the wrong talents).
- **Level-up cards:** behind the cards, the character window now goes as dark as the rest of the game instead of showing through half lit.
- **Addon list:** Arcane UI's description in Options → AddOns is one short line instead of a wall of text.
- **Party frames:** the health bars' class colors are richer and brighter, so every class reads at a glance.
- **Run summary:** the numbers stay still once it opens (in co-op the run goes on after you fall, and they kept flickering).
- **Guardian bars:** narrower, thinner and closer together, so several guardians don't crowd the screen; bosses keep their full bars.
- **Skulls:** guardians get a skull too (in an amber glow), and bosses a fiercer horned skull with smouldering red eyes. Also fixes the skulls switching themselves off with an error after a few bosses had come and gone.
- **Downed friends:** their class crest shows inside the revive mark, as see-through as the mark.
- `/Arcane probe` also lists the game's AZS tables.

- **Downed friends (co-op):** when a friend goes down, a banner says so with the raid warning sound. A glowing mark shows where they lie (stand on it to bring them back), with their name in their class color and the distance; while you revive them it turns green and counts up. While they're off the screen, a gold arrow at its edge points the way, with the distance.
- **Stored level-ups:** with the game's Store Level-Ups on, a glowing Level Up! button over the skill bar shows how many wait; click it to pick their cards. It pulses when one more comes.
- **Run summary:** when a run ends, a panel shows your time, level, kills, elites, guardians and bosses slain, damage dealt (and a second) and taken, gold earned and caches opened, counting up. Close it with its x; it moves with Move frames.
- **Damage Taken:** a new view in the damage meter: what hit you, the most first, per second.
- The options window has room for the three new parts.

- Each ability on the skill bar shows its rank in a little gold-rimmed box on its bottom right corner. When a card ranks one up, the box and the ability flash gold as you come back from the cards.
- `/Arcane probe` also shows the game's spells, their ranks and the rank each slot found.

- A skull floats over each boss, wherever it is on the screen, without a target or a nameplate: large when the boss is near, small when it's far, glowing gold over the final boss. It fades away when the boss falls. Mini-bosses have none. Turn it off or size it in the options (Boss skulls).
- The options window has two columns now, so it fits on any screen.
- `/Arcane probe` also shows what the game says about the bosses' places and downed friends.

- The Talents page now looks like the game's talent window: each tree in its own framed panel with its background painting, the full grid of talents, and branches with arrows from each talent to the ones it opens. Talents with points are lit with their rank, ones you could take are in color, locked ones are greyed.

- The Skills tab becomes a Talents page with your three talent trees side by side.
- The Honor tab is gone (no PvP).

- The talents strip under the model is removed for now.

- Character window in Arcane UI's look: gear slots lit in their rarity color, the run's stats grouped in a panel beside it (zeros dimmed, changes flashing), the portrait in a ring.
- `/Arcane probe` prints what the game gives addons.

- New heavier dragons on the skill bar, wrapped in their wings and sitting flush against the frame.
- Over an edge that sizes a window, the cursor becomes the resize arrow.

- The meter's and luck window's gems become crossed swords and a clover on the minimap's edge, draggable around it, dimmed while their window is hidden.

- The A button on the minimap's edge opens the options; right-click frees or locks the frames.
- Tooltips show Chinese, Japanese, Korean, Russian, Polish and Turkish letters.
- Damage numbers keep a proc's hits (like Shadow Weaving) apart from the spell it borrows, with its own icon.

- Bundled fonts so every language shows its letters.

---

## Developer reference

This section records the project's runtime constraints and observed Azeroth Survivors addon API. It is a maintainer reference, not a list of release changes. API observations should be checked against the live client before depending on them.

### Runtime and coding constraints

- Arcane targets the Azeroth Survivors 1.12.1 client and its **Lua 5.0** runtime. Do not assume modern WoW widget methods or newer Lua features are available.
- Keep chunk-level local declarations below Lua 5.0's 200-local limit. Group related state and constants under a table instead of continually adding file-scope locals.
- Use Lua 5.0-compatible idioms: use `table.getn` for arrays, `string.find` with captures instead of `string.match`, and `math.mod` where appropriate. Avoid the length operator, hex literals, `goto`, and Lua 5.1+ vararg patterns.
- Pass game APIs only the arguments they require; avoid stray `nil` arguments. Use the shared protected-call helper where appropriate.
- Remove array entries with `table.remove`. Do not create holes in arrays that are read with `table.getn`.
- Core's memo writers (`C.SetText`, `C.Size`, `C.Width`, `C.Place`, `C.Vis`, `C.Alpha`, `C.Color`, `C.TextColor`, `C.TextWidth`) skip unchanged writes. Do not mix them with direct writes to the same region.
- Route player-facing strings through `C.L`, `C.F` or `C.LText`; keep all 11 addon languages aligned with the English keys.
- Register each UI part through `C.RegisterPart`, expose its enabled state, and restore the game's own UI when Arcane's replacement is disabled. Guard frame-update work against errors.
- Preserve Arcane's existing visual identity and artwork. Comments should explain what the player sees in plain English.

### Testing

The repository's GitHub workflow performs static architecture checks, compiles Lua chunks with Lua 5.1, and checks the generated ZIP. There is no mock game client or complete in-game API fixture. These checks do **not** prove Lua 5.0 runtime compatibility, widget-method availability, live API return shapes, or correct restoration of the game's UI.

Load changes in the actual client and check the affected behavior, especially frame methods, event data, visibility restoration, saved positions and cross-system interactions. Use `/Arcane probe` to collect live values when an API shape is uncertain. Never report a live test as passed unless it was actually run.

### Recorded Azeroth Survivors API observations

These are recorded observations, not a substitute for checking the current client. Some tables are only partially mapped.

- **Run state:** `AZS_RUN` includes fields such as `lvl`, `xp`, `xpn`, `gold`, `kills`, `chest`, `rr`, `rrc`, `px` and `py`. `AZS_STATS` includes `luck` and `gluck`; its complete field list is not known. Related functions include `AZS_GetPhase`, `AZS_GetRunTime` (stops during cards and pause), `AZS_GetRunLength` and `AZS_GetLocalTime`.
- **Minimap data:** `AZS_LAIRS` and `AZS_LAIRS_UPDATED` expose lair state (including asleep, awake and empty), `left`, `x`, `y` and `flag`. Chests are exposed through `AZS_CHESTS`.
- **Game HUD:** `AZS_SetHudShown` and `AZS_IsHudShown` control or report HUD pieces such as `flag` and `localClock`. `AZS_SetOnTopOfScreens` manages frames that must remain above game screens.
- **Combat text:** `AZS_GetCombatTextCapabilities`, `AZS_GetCombatTextEvents(cursor, max)`, `AZS_ProjectCombatTextAnchors` and `AZS_RegisterCombatTextFrameHandler`. Events include `meterSource`, `meterSourceKey` and distance from the hero.
- **Meter API v1:** `AZS_GetMeterContext`, `AZS_GetMeterSnapshot(query)` and checkpoints. Snapshot sources carry names and icons. Related getters cover summons, totems, bosses and guardians. `AZS_GetMeterLoadout({ apiVersion = 1, runId [, ownerId] })` accepts only those query keys and returns abilities (`sourceKey`, `rank`, `slotId`, `learned`, `passive`), equipment, talents, run jewelry, and source icons. Skill-bar rank boxes match abilities to slots by icon, falling back to `slotId` when needed.
- **Spells:** `AZS_SPELLS` and `AZS_SPELLS_UPDATED`; entries have `key`, `spell`, `rank`, `cd` and `cdmax`, with no slot field.
- **Run summary:** `AZS_GetRunSummary()` is nil while a run is ongoing; at its end, `AZS_END` has been observed with `result` (victory, defeat or left), `t`, `lvl`, `kills`, `elites`, `guardians`, `bosses`, `dmg`, `taken`, `gold`, `chests`, `magnets`, `endl` and `hero`.
- **Damage taken:** `AZS_TAKEN` and `AZS_TAKEN_UPDATED` expose entries with `source` and `dmg`. The meter API itself has only damage and healing metrics.
- **Stored level-ups:** `AZS_GetStoredLevels()` (also reflected by `AZS_RUN.sl`), `AZS_IsStoringLevels()`, `AZS_OpenStoredLevels()` and `AZS_SetStoringLevels(on)`. The game's button is the `levels` HUD part.
- **Downed players and revives:** `AZS_DOWNED` entries have been observed with `id`, `name`, `x`, `y`, `z`, `ep` and `state`. `AZS_GetRevive()` / `AZS_REVIVE` expose `down`, `share`, `by`, `reviving` and `rshare`. `PlaySound(kit)` can play game sounds such as `RaidWarning`.
- **World anchors (API 0.139.2 observation):**
  - `AZS_GetWorldAnchorCapabilities()` reports kinds `enemy`, `elite`, `guardian`, `boss`, `finalBoss`, `cache`, `guardianLair` and `downedPartyMember`; attachments are `position` and `overhead`, with up to 256 results per call.
  - `AZS_GetWorldAnchors(query, cursor, limit)` accepts nil or a query containing only `kinds` and `states`; cursor is nil or a string, and limit is 1–256. The response includes `apiVersion`, `catalogId`, `entries`, `hasMore`, `nextCursor` and `overflowed`. Entries include `anchorId`, `kind`, `state`, `attachments`, `positionAvailable`, coordinates and relevant ids. Observed errors include `NOT_READY`, `CATALOG_CHANGED` (restart the read from the beginning) and `INVALID_ARGUMENT`.
  - `AZS_ProjectWorldAnchors(requests)` accepts requests containing `anchorId`, `attachment` (`position` or `overhead`) and an optional yard-based `offset` with `x`, `y` and `z`. The response includes `cameraSampleId`, `frameCurrent` and entries with projection states such as `onScreen`, `offscreen`, `behindCamera`, `clipped`, `notReady`, `expired`, `unknownAnchor`, `worldChanged` and `unsupportedAttachment`, plus coordinates, camera depth, UI units per yard and player distance.
  - `AZS_RegisterWorldAnchorFrameHandler(fn)` runs each frame after the camera, like the combat-text frame handler.
  - `AZS_GetDownedPartyMembers()` has been observed to return entries with `id`, `name`, `positionAvailable`, `anchorStatus`, `anchorId`, coordinates, `mapId`, `runId` and `spaceId`. Before the run's lines exist, it may return nil and an error.
  - The exact nesting of some API responses has not been confirmed; use `/Arcane probe` in the live client before depending on it.
- The game's own localized words (for example, `end.victory`) are JSON embedded in the client and have been observed in 14 languages. When extracting non-ASCII text, read the client bytes as UTF-8; ordinary `strings` output drops those characters.
- The game's Lua API definitions and comments have been located in the client at `https://wow.aethus.pl/wenilla_bg.wasm`. Searching its extracted strings for `function AZS_` can help investigate API behavior; native-side field names and errors are also present there.

