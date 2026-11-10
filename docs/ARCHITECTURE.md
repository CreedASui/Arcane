# Arcane UI module map

This document describes the source layout and the runtime rules behind it. The addon targets the Azeroth Survivors 1.12.1 client and its Lua 5.0 runtime.

## Runtime entry point

- `Arcane.toc` is the authoritative file list and load order. Do not rely on folder enumeration or alphabetical ordering.
- `Core.lua` creates the global `Arcane` namespace and the stable asset/font paths.
- Files under `Core/` add shared services. `Core/Startup.lua` is deliberately last among Core modules so the card-screen handler and all registered services exist before startup callbacks run.
- Localized dictionaries load after Core localization, before feature modules use them.
- Feature modules register their initialization callbacks while their files load. The client dispatches initialization after the addon files have loaded.

## Folder ownership

| Folder | Responsibility |
| --- | --- |
| `Core/` | Shared math, drawing, language/font handling, saved settings, stock-HUD handoff, bars, sizing, panels, safe calls, movement, options, commands, cards and shared unit-frame helpers. |
| `Locales/` | English source strings and translated dictionaries. |
| `Timer/` | Boss timer data and its renderer/controller. |
| `Numbers/` | Damage-number configuration, combat intake, icons, labels, world anchors, layout, culling, placement, animation, lifecycle, options and commands. |
| `SkillBar/` | Class/style data, visual style controller and the skill-slot/XP renderer. |
| `Frames/` | Bosses, skulls, the player frame, party, downed-player and stored-level-up frames, stock notifications and native text styling. |
| `Minimap/` | Minimap presentation, edge button, cache pins and lair pins. |
| `Windows/` | Tally, meter, damage/healing, pets, luck, summary, character, stats, talents and chat windows. |
| `Nameplates/` | Arcane Nameplates replacement and its options. |
| `Loot/` | Loot-set data and loot notifications. |

## Shared components

Shared behavior belongs to one owner under `Core/`; feature modules should call it rather than copy it. For example, the player and party frames now use `Core/UnitFrames.lua` for health-number formatting and the mana/rage/focus/energy palettes.

Use a shared helper when the behavior and its contract are genuinely the same. Do not merge controls that only look similar but have different interaction, lifecycle or visual requirements. Keep feature-specific tuning close to the feature that owns it.

## Load-order and compatibility rules

- Keep `Art/` and `Fonts/` at the addon root. `Arcane.ART` and existing game texture paths depend on those locations; this refactor does not move or rename assets.
- Use paths relative to the addon folder in `Arcane.toc`. Add each Lua file explicitly and in dependency order.
- Target Lua 5.0: use `table.getn`, `string.find` captures and `math.mod` where needed. Do not introduce newer syntax or APIs.
- Keep each loaded Lua chunk below the 200 file-scope-local limit.
- Keep game-facing frame names, saved-variable keys, slash commands, asset paths and public `Arcane.*` integration points stable unless a behavior change is intentional.
- When extracting code, preserve the original statements and lexical locals first. Move one responsibility at a time; do not mix a structural move with a visual redesign.
- Run the repository architecture audits and Lua compilation. Those use Lua 5.1 as a syntax check only; test runtime behavior in the actual Lua 5.0 client.

## Next candidates for smaller modules

The largest remaining feature files are candidates for later, isolated extractions: `Timer/Timer.lua`, `Windows/Meter.lua` and `Windows/Character.lua`. Each owns a coherent feature but may still contain internal responsibilities worth separating when the boundaries are clear. Split those by data intake, presentation, interaction and lifecycle only when the boundaries can be kept explicit and the live client can verify the result.

## Arcane Nameplates

Arcane Nameplates is split by responsibility rather than by individual helper:
- `Nameplates/State.lua` owns native plate discovery, child-state snapshots and safe visibility restoration.
- `Nameplates/SpecialTargets.lua` owns boss/guardian identity and debuff presentation.
- `Nameplates/Visuals.lua` owns replacement bars, labels and plate styling.
- `Nameplates/ArcaneNameplates.lua` owns cached pool registration, same-update reuse styling, native-region suppression and addon lifecycle.
- `Nameplates/ArcaneNameplatesOptions.lua` owns the settings UI and saved option access.

The controller delegates to these modules in TOC order. Arcane Nameplates is Arcane's required enemy-plate renderer and remains active whenever Arcane is loaded. The game's native `V` command owns enemy-plate visibility. Azeroth Survivors creates anonymous `Button` children under `WorldFrame`, hides retired plates, and reuses free pool slots. The Arcane replacement bar is parented to the same button, so it follows the game's show/hide state without binding or overriding `V`. The registry is therefore bounded by the game's high-water plate pool; no guessed cleanup timer is needed. There is no second hide checkbox and no stock-renderer fallback.

Arcane-owned code uses the `C.Nameplates` namespace and `arcaneNameplates*` frame state. The existing `ArcaneDB.nameplates` saved-settings key is intentionally retained so upgrades keep custom colors and display preferences. `AZSUNITS`, `AZS_UNITS` and the other `AZS_*` names belong to Azeroth Survivors and must remain unchanged; they are integration contracts, not Arcane branding.


Arcane Nameplates does not own the `WorldFrame` plate root's dimensions, scale or projected position. Azeroth Survivors updates the root anchor as units move; Arcane Nameplates anchors its overlay to the native health bar and restores only native child visibility/alpha that it changed.

## Native text styling

`Frames/NativeText.lua` styles only the game's existing floating combat-text categories for positive spell/aura messages and healing. It uses the same `C.Pal()` title/accent mapping as the known-good reference build. Blizzard still creates each message, applies its own visibility flags and filters, chooses the message type, moves the text, and runs the original animation/fade. Arcane does not replace `CombatText_AddMessage`, `CombatText_OnEvent` or the client's update function.

**Zone and subzone announcements remain entirely native.** Arcane does not reference or hook `ZoneTextString`, `SubZoneTextString`, `ZoneTextFrame`, `SubZoneTextFrame` or `SetZoneText`. The game owns their original wording, font, exact size, contextual fill color, position and fade. No outline, banner, trim, background or other Arcane decoration is added.

`Frames/StockErrors.lua` retains the known-good treatment for the game's separate `UIErrorsFrame` gameplay-notification feed: Arcane typography and the active `C.Pal().title` color. Lua script errors are separate from this gameplay-notification feed. Live-client testing remains necessary in Azeroth Survivors 1.12.1 / Lua 5.0.


## Nameplate sizing and level badge

Regular Arcane Nameplates replacement bars use 75% of the native health-bar width and height (the previous regular scale was 50%). The health FontString is constrained to the bar's inner width so current/maximum health stays inside the bar rather than spilling past its edges.

The native 1.12 nameplate exposes its level as a numeric root FontString, separate from the name. `Nameplates/State.lua` reads and caches that value before the native labels are hidden, refreshing it as pooled plates are reused. `Nameplates/Visuals.lua` displays it in a compact square glass-and-metal badge attached to the right side of the replacement bar. The badge uses the shared Arcane `rim`, `trough` and `title` palette and is parented to the replacement overlay, so it follows the game's native V visibility and pooled-frame lifecycle. If the native plate has no numeric level, the badge stays hidden.

The WorldFrame plate's root size, scale, projected position and anchor remain game-owned; Arcane only enlarges its child replacement visual.



## Nameplate lifecycle and hover tooltip

The native Azeroth Survivors plate is recognized by its actual 1.12 structure: an anonymous `Button` under `WorldFrame`, six root regions in the game's creation order (border Texture, glow Texture, name FontString, level FontString, skull Texture, raid Texture), and one direct horizontal health `StatusBar`. `Nameplates/State.lua` validates that signature once and caches the native region and StatusBar references. It does not recursively search arbitrary descendants for a name and a wide StatusBar. Frames that do not match the native signature are ignored.

The native pool is dynamic. Arcane registers hidden pool entries before first use, chains their existing `OnShow` and `OnHide` handlers without discarding them, and refreshes cached frame identities during the plate driver. On reuse, it restores the captured child visibility/alpha state, invalidates the old identity, reapplies the new plate style, and hides only the four native decoration regions, native name/level strings and native health bar. The WorldFrame root's size, scale, position and visibility remain game-owned. The controller no longer waits half a second to recognize a new plate.

The replacement bar is centered on the cached native health StatusBar rather than converting a bottom-left anchor into a center offset. Its dimensions are bounded to the native StatusBar's expected range. Health text has no whitespace break around its separator and is measured/fitted against the bar's inner width, preventing current/maximum values from wrapping into two rows. The regular-bar scale and right-side enemy-level badge behavior remain unchanged.

`Frames/WorldTooltip.lua` is a standalone guard for the persistent default-anchored world-hover `GameTooltip`. It chains the existing `OnTooltipSetDefaultAnchor` and `OnShow` scripts, then hides the tooltip only when the native `GameTooltip.default` flag is set. Ordinary control tooltips use their normal non-default anchors and remain available. The guard does not depend on Arcane's startup table and does not run a per-frame polling script.
