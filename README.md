# Arcane UI

**Current release: v0.7.8**

A clean, smooth HUD for **Azeroth Survivors** ([wow.aethus.pl](https://wow.aethus.pl)), the World of Warcraft 1.12 roguelike. Everything is drawn in one look (dark glass, a gold rail, the timer's metal) and steps aside while you pick your cards.

## Preview

![Arcane UI running in Azeroth Survivors](docs/images/ArcaneUI.png)

## What's in it

- **Boss timer:** a themed countdown to each boss, with the run's time.
- **Arcane Nameplates:** Arcane's built-in replacement for the game's enemy plates, with 75%-size regular bars, Arcane's shared FRIZQT typography, one-line health values and a right-side enemy-level badge. Bosses and guardians keep their full-size styling and debuffs below. The game's **V** key controls plate visibility, and Arcane's replacement follows it. Its settings window is draggable like the other Arcane submenus.
- **Boss and mini-boss bars:** red bars with real health numbers and debuffs. Guardians sit in compact pairs below full-width bosses, with the name above each bar and HP/percent on the bar. Very narrow layouts use single full-width guardians instead of squeezing the labels.
- **Skulls and cache markers:** a horned skull with red eyes floats over each boss, a plainer one over each awake guardian, and a glowing gold chest marks every cache waiting on the field. Markers scale with distance and fade when their target is gone; cache markers share the Boss skulls toggle.
- **Party shields:** detected absorbs show as a glass-and-stripe overlay on each party health bar.
- **Downed friends (co-op):** a warning and a sound when a friend goes down, a glowing mark with their class crest where you can revive them, and an arrow at the screen's edge with the distance while they're off it.
- **UI style:** choose Classic Arcane, Hybrid or Full Class in Arcane Options. Classic keeps the bronze Arcane treatment and supplied gold dragon/A artwork; Hybrid adds class treatment to the skill bar only, with the Arcane A medallion on the left and the active class crest on the right; Full Class carries the active class palette across the Arcane UI—including your frame, minimap, Stats, Damage meter, Luck and shared panels—alongside class-specific skill-bar rails and paired emblems. The top and bottom center diamonds are calibrated to the visible gold stripe on each rail, including as the kills/gold/cache dock expands. The level and XP label is optically centered inside its gold progress capsule. Your abilities (with rank-up flashes), jewelry and XP remain in the shared bar renderer.
- **Kills, gold and cache:** in the panel; hover for what each gives.
- **Loot pop-up:** each drop appears with its icon, name and rarity color; earned marks appear as their own notification. Up to three stack, and the game's own pop-up returns when Loot is turned off.
- **Stored level-ups:** Arcane's checkbox controls and mirrors the game's actual Store Level-Ups setting. When enabled, a glowing Level Up! button shows how many choices wait; its default position clears the skill bar and XP display.
- **Damage meter:** Damage Done, Healing Done, Boss Damage, Party DPS (with each member's best skill) and Damage Taken, with icons, per second and shares. Resizable from any edge.
- **Luck medallion:** your luck and the odds of a Rare, Epic or Legendary card.
- **Minimap:** a metal ring, your local time, the caches and the guardians' lairs (with the time until each empty lair fills); cache and lair pins fade when they overlap your arrow. The **A** button on its edge opens Arcane Options; use the **Luck** and **Damage meter** toggles in that menu to show or hide those windows. The unused stock **M** world-map shortcut is suppressed while Arcane is loaded, without overwriting saved or custom keybindings.
- **Character window:** gear slots lit in their rarity color and your run's stats grouped beside it (zeros dimmed, changes flashing); its Talents tab opens Arcane UI's talent window (your trees, points and learned talents with their ranks).
- **Standalone Stats window:** independently track the run's 29 stats in customizable groups; choose which values appear and see changes flash green or red.
- **Chat:** dressed to match, and kept clear of the skill bar's full Arcane medallion.
- **Damage numbers:** calm and readable; a spell hitting a crowd adds up into one number a second, and a number that keeps stacking grows.
- **FPS display:** an Arcane-owned readout inside the standard movable-frame system, with a larger grab target in Move frames mode. Toggle it from Arcane Options; Ctrl+R is disabled while Arcane is loaded.
- **Native game text:** positive buff/cast and healing feedback use Arcane's known-good text colors and font. Zone announcements such as “Tower of Azora” remain completely original; gameplay notices keep their existing Arcane theme.
- **Damage-number customization:** six optional custom typefaces and six selectable critical-hit backdrops (Flame, Frost, Arcane, Holy, Shadow and Storm); existing defaults remain unchanged.
- **Run summary:** when a run ends, your time, level, kills, bosses, damage dealt and taken, gold and caches appear on one panel. In co-op, the summary keeps its initial results while teammates continue fighting; closing it stays effective until a new outcome or run.

Every optional HUD part can be turned on or off, sized and moved. Arcane Nameplates follows the game's native **V** visibility control instead of adding a second toggle.

**Languages:** English, French, German, Spanish, Portuguese, Chinese, Russian, Japanese, Korean, Polish and Turkish, picked from the options or with `/Arcane language`.

## Repository layout and packaging

The addon's load map, `Arcane.toc`, stays at the repository root. Lua modules are grouped by responsibility under `Core/`, `Timer/`, `Numbers/`, `SkillBar/`, `Frames/`, `Minimap/`, `Windows/`, `Nameplates/`, `Loot/` and `Locales/`. `Art/` and `Fonts/` also stay at the addon root so the game's existing asset paths remain unchanged. The repository itself is not the install folder. For a release ZIP, place the root files and all module and asset folders inside a top-level folder named `Arcane/`, then zip that folder. The ZIP must open to `Arcane/Arcane.toc` — never a branch-named folder such as `Arcane-main/`.

The release asset is named `ArcaneV0.7.8.zip`. The complete release history and detailed version notes are embedded below in this README. The tag publisher extracts the matching version section from this document for each GitHub Release. GitHub Actions runs the architecture and regression audits, compiles every Lua chunk with Lua 5.1, and builds an installable test ZIP for pull requests and supported branch pushes. Merging a change into `main` only runs the audits and builds a test installer, without creating a tag or a release page. **Releases require your manual approval after in-game testing:** open GitHub Actions, choose **Arcane QA and Manual Release**, select **Run workflow** on `main`, and click **Run workflow**. That one approval runs the full checks again and, only if they pass, creates the matching version tag, publishes the release notes from this README, and attaches the verified ZIP. A tag already belonging to an older commit cannot be moved; bump the version for the next release. Rerunning the approved workflow can repair a release for the exact same tagged commit. These automated checks do not replace a live test in the client's Lua 5.0 runtime.

## Install

1. Download `ArcaneV0.7.8.zip` from [Releases](../../releases).
2. Unzip it into your game's `Interface/AddOns` folder. You should end up with `Interface/AddOns/Arcane/Arcane.toc`.
3. The folder must stay named `Arcane`: the game loads it by that name, and your settings are kept under it.

## Commands

| Command | What it does |
| --- | --- |
| `/Arcane` | Opens the options (or click the **A** on the minimap's edge) |
| `/Arcane move`, `/Arcane lock` | Frees the frames to drag them, then locks them |
| `/Arcane reset` | Puts every frame back in its place |
| `/Arcane language <code>` | Picks the language (`auto` follows the game) |
| `/Arcane timer ...`, `/Arcane numbers ...` | The boss timer's and damage numbers' own settings |
| `/Arcane <part> on/off` | Turns a part on or off |
| `/Arcane talents` | Opens the talent window |
| `/Arcane probe` | Prints what the game gives addons, for reporting what's missing |

## Project workflow, QA and collaboration

### Product direction and UX consolidation

- Keep the current Classic Arcane UX as the stable default while Hybrid and Full Class are brought to the intended finished state.
- The long-term product goal is **one final, coherent default UX**, not three permanent alternatives. Once the final direction is agreed, complete its feature, visual, palette, accessibility, saved-setting and upgrade behavior; then retire the other two styles.
- Do not remove a style prematurely or assume the exact final composition of Hybrid and Full Class without an explicit design decision. Preserve existing saved settings and provide a safe migration if the style setting changes.
- Do not let minor polish or theoretical edge cases indefinitely displace finishing the UX.

### Bug-priority buckets

Every audit finding, bug report and proposed cleanup should receive a severity and a short reason. Severity is based on real impact, frequency, reproducibility, scope and fix cost—not merely whether a defect is technically possible.

| Priority | Meaning | Typical examples |
| --- | --- | --- |
| **P0 — Critical** | Fix immediately. | Crashes, corrupted saved settings, broken core behavior, serious co-op failures, or an issue that makes the addon/gameplay unusable. |
| **P1 — High** | Fix before the next release. | Common feature failures, major visual/layout breakage, native UI not being restored, or meaningful performance/regression problems. |
| **P2 — Normal** | Schedule and fix as part of normal development. | Less frequent functional bugs, a feature behaving incorrectly in a specific class/zone/state, or recoverable usability problems. |
| **P3 — Edge case / polish** | Backlog unless cheap and safe to resolve. | Extremely rare combinations, harmless cosmetic imperfections, theoretical lifecycle concerns, and low-impact refinements. |

A rare issue is still worth fixing when the correction is cheap, safe and well understood. A speculative issue that requires a multi-day investigation but has negligible impact stays in P3 until evidence justifies the effort. Do not spend days chasing a one-in-a-billion scenario while higher-priority work remains.

### Manual release approval

1. Merge reviewed code to `main` after CI passes. The Actions run produces a **test ZIP artifact**, not a public GitHub Release.
2. Download the `Arcane-vVERSION-test-COMMIT` artifact from the successful **Arcane QA and Manual Release** run and install the `ArcaneVVERSION.zip` inside it. Test the changes in-game before publishing.
3. When you approve the build, open **Actions → Arcane QA and Manual Release → Run workflow**, select the **main** branch, and click **Run workflow**. This is the publish button.
4. The approval run repeats the audits, Lua syntax checks and ZIP verification. Only a successful run can create the new `vVERSION` tag, GitHub Release page and `ArcaneVVERSION.zip` release asset. If the version was already tagged to different code, the job fails instead of replacing the tag.

**Never release automatically on merge or by pushing a tag.** Without an explicit button click, Actions only builds and tests.

### Test proportionally to risk

- Prefer behavioral checks that exercise real outcomes: lifecycle transitions, saved settings, missing APIs, error responses, restoration, repeated runs and edge conditions.
- Static audits are useful for enforcing architecture, compatibility and explicit contracts, but they should not be mistaken for proof that runtime behavior works.
- A narrowly scoped trigger fix does not automatically require retesting every unrelated feature. Use the existing behavior, the code path changed, and visible evidence to decide how much additional testing is warranted.
- When a change rewrites a process, alters shared infrastructure, changes saved data, or affects native ownership, expand the test scope accordingly.
- Ask for an in-game test only when CI, mocks or code-level evidence cannot establish the behavior. Keep manual test requests focused and manageable.
- Code audits and after-action reports are part of normal QA. Record what changed, what was checked, what passed, what remains uncertain, and any follow-up findings.

### Development and review workflow

1. Inspect the current repository state, load order and owning module before changing code.
2. Agree on the behavior being changed and keep the patch scoped to that behavior.
3. Review the complete diff critically. No contributor's code—including AI-generated code—is gospel.
4. Run relevant audits, compilation, packaging and CI. Distinguish static/syntax validation from actual Lua 5.0 runtime testing.
5. Review the results and produce a short after-action report with severity-ranked follow-ups.
6. Work through pull requests. Do not push changes directly to `main`, merge a PR, create a release tag or publish a release unless explicitly asked.
7. Preserve project history and contributor attribution. Do not rewrite or strip authorship metadata without an explicit decision.

### Working together

- The developer may describe intended behavior informally or use approximate technical wording. Focus on the intended result; do not mistake wording or spelling for lack of technical understanding.
- Translate an unclear request into a concrete technical interpretation and state the assumption before making a consequential change. Ask one targeted question only when ambiguity changes the implementation.
- Explain findings plainly and directly. Identify what failed, where it failed, why it matters and what the proposed fix changes.
- Treat AI tools as tools. Judge the resulting code, architecture, review and tests—not the name of the model used to produce it.
- Keep the process sustainable. Prefer one well-scoped task at a time, automated checks that reduce repeated manual work, and clear evidence over large ceremonial test checklists.

### Technical contracts

- `Arcane.toc` is the authoritative load list and load order.
- The addon targets Azeroth Survivors 1.12.1 and the client's Lua 5.0 runtime.
- CI's Lua 5.1 compilation is a syntax/chunk check only; it is not a Lua 5.0 runtime emulator.
- Preserve existing saved-variable keys and user settings. A new default anchor must not overwrite a user's saved position.
- Do not call `SaveBindings` or otherwise persist temporary key-binding changes. Only change the exact stock action the feature intends to suppress; leave custom user bindings alone.
- Keep shared lifecycle behavior in the existing shared helpers and feature-specific behavior with its owning module. Avoid rebuilding a monolith or adding abstractions without a real shared contract.
- Validate both the patch and the resulting install package. Retain artwork, fonts and their original license notices.

### Documentation rule — one Markdown file

**`README.md` is the only Markdown document in this repository and the single source of truth for project documentation.**

- Put product overview, install instructions, architecture, attribution/provenance, release history, roadmap, QA standards and project handoff information in this file.
- For a new release, update the version in `Core.lua`, `Arcane.toc`, and the README's current version and installer name, then add the dated changelog entry at the top of the embedded release-history section. CI builds a test ZIP on the release-ready PR and again when merged to `main`. Test that artifact in-game; **do not create a public release until you manually select Actions → Arcane QA and Manual Release → Run workflow on `main`**. That single approval reruns the checks and publishes the tag, installer ZIP and release page. Do not create another Markdown file.
- Update the architecture and working-agreement sections in place when they change. Keep one current description rather than creating another handoff, audit summary or architecture document.
- Do not add other Markdown files. CI enforces this rule.
- Required third-party license notices remain separate plain-text files where the license requires them. The packaged attribution summary is `ATTRIBUTION.txt`, not another Markdown document.

## Architecture and module ownership

This document describes the source layout and the runtime rules behind it. The addon targets the Azeroth Survivors 1.12.1 client and its Lua 5.0 runtime.

### Runtime entry point

- `Arcane.toc` is the authoritative file list and load order. Do not rely on folder enumeration or alphabetical ordering.
- `Core.lua` creates the global `Arcane` namespace and the stable asset/font paths.
- Files under `Core/` add shared services. `Core/Startup.lua` is deliberately last among Core modules so the card-screen handler and all registered services exist before startup callbacks run.
- Localized dictionaries load after Core localization, before feature modules use them.
- Feature modules register their initialization callbacks while their files load. The client dispatches initialization after the addon files have loaded.

### Folder ownership

| Folder | Responsibility |
| --- | --- |
| `Core/` | Shared math, drawing, language/font handling, saved settings, stock-HUD handoff, bars, sizing, panels, safe calls, movement, options, commands, cards and shared unit-frame helpers. |
| `Locales/` | English source strings and translated dictionaries. |
| `Timer/` | Boss timer data and its renderer/controller. |
| `Numbers/` | Damage-number configuration, combat intake, icons, labels, world anchors, layout, culling, placement, animation, lifecycle, options and commands. |
| `SkillBar/` | Class/style data, visual style controller and the skill-slot/XP renderer. |
| `Frames/` | Bosses, skulls, the player frame, party, downed-player and stored-level-up frames, native FPS readout, stock notifications and native text styling. |
| `Minimap/` | Minimap presentation, edge button, cache pins and lair pins. |
| `Windows/` | Tally, meter, damage/healing, pets, luck, summary, character, stats, talents and chat windows. |
| `Nameplates/` | Arcane Nameplates replacement and its options. |
| `Loot/` | Loot-set data and loot notifications. |

### Shared components

Shared behavior belongs to one owner under `Core/`; feature modules should call it rather than copy it. For example, the player and party frames now use `Core/UnitFrames.lua` for health-number formatting and the mana/rage/focus/energy palettes.

Use a shared helper when the behavior and its contract are genuinely the same. Do not merge controls that only look similar but have different interaction, lifecycle or visual requirements. Keep feature-specific tuning close to the feature that owns it.

### Load-order and compatibility rules

- Keep `Art/` and `Fonts/` at the addon root. `Arcane.ART` and existing game texture paths depend on those locations; this refactor does not move or rename assets.
- Use paths relative to the addon folder in `Arcane.toc`. Add each Lua file explicitly and in dependency order.
- Target Lua 5.0: use `table.getn`, `string.find` captures and `math.mod` where needed. Do not introduce newer syntax or APIs.
- Keep each loaded Lua chunk below the 200 file-scope-local limit.
- Keep game-facing frame names, saved-variable keys, slash commands, asset paths and public `Arcane.*` integration points stable unless a behavior change is intentional.
- When extracting code, preserve the original statements and lexical locals first. Move one responsibility at a time; do not mix a structural move with a visual redesign.
- Run the repository architecture audits and Lua compilation. Those use Lua 5.1 as a syntax check only; test runtime behavior in the actual Lua 5.0 client.

### Next candidates for smaller modules

The largest remaining feature files are candidates for later, isolated extractions: `Timer/Timer.lua`, `Windows/Meter.lua` and `Windows/Character.lua`. Each owns a coherent feature but may still contain internal responsibilities worth separating when the boundaries are clear. Split those by data intake, presentation, interaction and lifecycle only when the boundaries can be kept explicit and the live client can verify the result.

### Arcane Nameplates

Arcane Nameplates is split by responsibility rather than by individual helper:
- `Nameplates/State.lua` owns native plate discovery, child-state snapshots and safe visibility restoration.
- `Nameplates/SpecialTargets.lua` owns boss/guardian identity and debuff presentation.
- `Nameplates/Visuals.lua` owns replacement bars, labels and plate styling.
- `Nameplates/ArcaneNameplates.lua` owns cached pool registration, same-update reuse styling, native-region suppression and addon lifecycle.
- `Nameplates/ArcaneNameplatesOptions.lua` owns the settings UI and saved option access.

The controller delegates to these modules in TOC order. The Nameplates settings window is a movable child of the Arcane Options hub: drag its open background with the left mouse button to reposition it, and it stays clamped to the screen while still following the hub's show/hide lifecycle. This matches the movement behavior of the Timer and Damage Numbers settings subwindows. Arcane Nameplates is Arcane's required enemy-plate renderer and remains active whenever Arcane is loaded. The game's native `V` command owns enemy-plate visibility. Azeroth Survivors creates anonymous `Button` children under `WorldFrame`, hides retired plates, and reuses free pool slots. The Arcane replacement bar is parented to the same button, so it follows the game's show/hide state without binding or overriding `V`. The registry is therefore bounded by the game's high-water plate pool; no guessed cleanup timer is needed. There is no second hide checkbox and no stock-renderer fallback.

Arcane-owned code uses the `C.Nameplates` namespace and `arcaneNameplates*` frame state. The existing `ArcaneDB.nameplates` saved-settings key is intentionally retained so upgrades keep custom colors and display preferences. `AZSUNITS`, `AZS_UNITS` and the other `AZS_*` names belong to Azeroth Survivors and must remain unchanged; they are integration contracts, not Arcane branding.


Arcane Nameplates does not own the `WorldFrame` plate root's dimensions, scale or projected position. Azeroth Survivors updates the root anchor as units move; Arcane Nameplates anchors its overlay to the native health bar and restores only native child visibility/alpha that it changed.

### Native text styling

`Frames/NativeText.lua` styles only the game's existing floating combat-text categories for positive spell/aura messages and healing. It uses the same `C.Pal()` title/accent mapping as the known-good reference build. Blizzard still creates each message, applies its own visibility flags and filters, chooses the message type, moves the text, and runs the original animation/fade. Arcane does not replace `CombatText_AddMessage`, `CombatText_OnEvent` or the client's update function.

**Zone and subzone announcements remain entirely native.** Arcane does not reference or hook `ZoneTextString`, `SubZoneTextString`, `ZoneTextFrame`, `SubZoneTextFrame` or `SetZoneText`. The game owns their original wording, font, exact size, contextual fill color, position and fade. No outline, banner, trim, background or other Arcane decoration is added.

`Frames/StockErrors.lua` retains the known-good treatment for the game's separate `UIErrorsFrame` gameplay-notification feed: Arcane typography and the active `C.Pal().title` color. Lua script errors are separate from this gameplay-notification feed. Live-client testing remains necessary in Azeroth Survivors 1.12.1 / Lua 5.0.


### Nameplate sizing and level badge

Regular Arcane Nameplates replacement bars use 75% of the native health-bar width and height (the previous regular scale was 50%). The health FontString is constrained to the bar's inner width so current/maximum health stays inside the bar rather than spilling past its edges.

The native 1.12 nameplate exposes its level as a numeric root FontString, separate from the name. `Nameplates/State.lua` reads and caches that value before the native labels are hidden, refreshing it as pooled plates are reused. `Nameplates/Visuals.lua` displays it in a compact square glass-and-metal badge attached to the right side of the replacement bar. The badge uses the shared Arcane `rim`, `trough` and `title` palette and is parented to the replacement overlay, so it follows the game's native V visibility and pooled-frame lifecycle. If the native plate has no numeric level, the badge stays hidden.

The WorldFrame plate's root size, scale, projected position and anchor remain game-owned; Arcane only enlarges its child replacement visual.


### Nameplate lifecycle and hover tooltip

The native Azeroth Survivors plate is recognized by its actual 1.12 structure: an anonymous `Button` under `WorldFrame`, six root regions in the game's creation order (border Texture, glow Texture, name FontString, level FontString, skull Texture, raid Texture), and one direct horizontal health `StatusBar`. `Nameplates/State.lua` validates that signature once and caches the native region and StatusBar references. It does not recursively search arbitrary descendants for a name and a wide StatusBar. Frames that do not match the native signature are ignored.

The native pool is dynamic. Arcane registers hidden pool entries before first use, chains their existing `OnShow` and `OnHide` handlers without discarding them, and refreshes cached frame identities during the plate driver. On reuse, it restores the captured child visibility/alpha state, invalidates the old identity, reapplies the new plate style, and hides only the four native decoration regions, native name/level strings and native health bar. The WorldFrame root's size, scale, position and visibility remain game-owned. The controller no longer waits half a second to recognize a new plate.

The replacement bar is centered on the cached native health StatusBar rather than converting a bottom-left anchor into a center offset. Its dimensions are bounded to the native StatusBar's expected range. Health text has no whitespace break around its separator and is measured/fitted against the bar's inner width, preventing current/maximum values from wrapping into two rows. The regular-bar scale and right-side enemy-level badge behavior remain unchanged.

`Frames/WorldTooltip.lua` is a standalone guard for the persistent default-anchored world-hover `GameTooltip`. It chains the existing `OnTooltipSetDefaultAnchor` and `OnShow` scripts, then hides the tooltip only when the native `GameTooltip.default` flag is set. Ordinary control tooltips use their normal non-default anchors and remain available. The guard does not depend on Arcane's startup table and does not run a per-frame polling script.


### Skill-bar center ornaments

The top and bottom center diamonds are anchored to their respective panel rail textures (root.deco.railT and root.deco.railB), with small opposite vertical offsets to compensate for transparent art padding and align the diamond centers to the visible gold stripes. This calibrated placement applies in Classic, Hybrid and Full Class modes. Because the rails span the outer panel, both diamonds remain horizontally centered on the complete visible bar as the kills/gold/cache tally dock expands or contracts.

## Attribution and project provenance

Arcane is an independent continuation and rework initialized from the CreedUI for Azeroth Survivors codebase in JamieeLee's fork:

- Upstream project: https://github.com/CreedASui/CreedUI-for-AS-
- Working source fork used as the starting point: https://github.com/JamieeLee/CreedUI-for-AS-

The repository was copied into a separate project rather than created as another GitHub fork. Existing source code, artwork and assets were retained as the starting foundation and have been rebranded and modified. Original authorship and any applicable terms for upstream material remain with their respective rights holders. This note records provenance; it does not grant or change any license.

The bundled font files are modified versions of Lora and Noto Sans CJK. Their detailed copyright and SIL Open Font License notices are retained in [Fonts/LICENSE.txt](Fonts/LICENSE.txt).

### Nameplate integration

The Arcane Nameplates feature adapts the MIT-licensed nameplate implementation by Valorless from [Valorless/ASTinyPlates](https://github.com/Valorless/ASTinyPlates). Its runtime code, settings, frame identifiers and saved-variable keys have been integrated into Arcane's own namespace and options system. The original MIT notice is retained in [ArcaneNameplates-LICENSE.txt](ArcaneNameplates-LICENSE.txt). This credit records source provenance; it does not imply that the upstream project is part of or endorses Arcane.

### Class skill-bar artwork

The optional nine-class skill-bar treatment reuses the class emblems, crests and rail textures from the synced `JamieeLee/CreedUI-for-AS-` working base. Those assets retain the same project provenance and original rights notices described above; Arcane keeps its own panel branding, slot renderer and settings namespace.

The Hybrid-only Arcane medallion is original generated artwork adapted for Arcane's identity. Its forged-metal base and separately colorized gem layer are new Hybrid assets; the original Classic Arcane sigil is unchanged. The class-specific right-hand emblems remain sourced from the synced Creed reference above.

### Damage-number fonts and critical-hit artwork

The optional damage-number font choices include six bundled fonts adapted from the corresponding open font releases. Their original copyright notices and SIL Open Font License terms are retained in [Fonts/NumberFonts-LICENSE.txt](Fonts/NumberFonts-LICENSE.txt); the font files are not relicensed by Arcane.

The optional critical-hit backdrops reuse six effect textures from the synced Creed working base. They are only used behind critical damage numbers when selected; they do not recolor Arcane's panels, bars, medallions, or overall bronze/gold theme.

## Consolidated release history

Add each new release as a dated section at the top of this embedded history. GitHub Actions extracts the matching versioned section from this README when publishing a tag.

<!-- RELEASE_HISTORY_BEGIN -->
### v0.7.8 — November 12, 2026

The guardian bar layout gets a readability pass based on live in-game testing with four Horsemen and a boss. This build is for in-game QA before the manually approved public release.

#### Improved

- **Guardian names:** give each guardian's name nearly the entire bar width instead of forcing name and HP onto the same line. Four Horsemen names have far more room and no longer compete with damage numbers.
- **Health labels:** show HP and percent together on the guardian's own health bar, where they have a separate line. Full-width boss health text stays in its original location.
- **Spacing:** slightly increase guardian row height and bar thickness to avoid crowding, while retaining two compact guardian columns below full-width bosses.
- **Narrow widths:** automatically switch to one readable guardian per row if the custom boss-bar width is below 340 rather than squeezing two tiny bars together. Debuffs stay bounded by the actual bar width.

#### Preserved behavior

- The selected-target pane stays intentionally removed.
- Existing boss and guardian health data, debuff behavior, animations, saved positions, scales, native HUD restoration, and the manually approved release gate remain unchanged.

#### Validation

- Static guardian geometry checks now cover 240–700 width, paired and single layouts, four guardians, and full-width boss placement.
- Lua compilation, architecture audits, and ZIP integrity checks run before packaging; final text rendering still requires live in-game testing.

### v0.7.7 — November 12, 2026

Arcane v0.7.7 improves co-op meter readability, fixes skill-rank badges, and makes multiple guardian fights less cluttered. The selected-target pane remains intentionally removed.

#### Fixed and improved

- **Party DPS best skill:** a party member's leading skill is named rather than displayed as missing or "nil". Skill damage is read by actor and source, and totals are combined separately for each player.
- **Skill-rank badges:** a badge first uses the rank recorded for that slot and icon; if the icon is missing, it falls back to the slot rank, then the highest matching icon rank. Duplicate or stale ability entries no longer override the appropriate rank.
- **Guardian bars:** guardians appear in two compact columns below full-width boss bars. A single unmatched guardian stays centered. Name and health text use bounded widths, and debuff icons stay within their own bar's space.

#### Preserved behavior

- There is deliberately no click-to-target pane. The game still handles target selection, while nameplates and boss/guardian bars provide health information.
- Existing saved frame positions, addon settings, player frame, and established gameplay behavior are preserved.
- Install ZIPs retain third-party attribution and required font and nameplate license notices.

#### Validation

- Release publishing requires passing the architecture audits, regression checks, Lua compilation, and install-package validation.
- In-game verification remains recommended for multiplayer best-skill attribution, skill-rank updates and crowded guardian encounters. Static CI does not emulate the game's Lua 5.0 runtime.

### v0.7.6 — November 10, 2026

Arcane v0.7.6 brings a multiplayer run-summary fix, clearer cache markers, a properly connected Stored Level-Ups setting, and a little less unused game UI.

#### What's changed

- **Co-op run summary:** when you fall while your teammates continue the run, the game's end-of-run statistics can keep changing. Arcane now keeps the original summary snapshot instead of reopening and replaying its count-up animation on every update. Closing the summary stays effective while the run continues, and a genuinely new outcome or the next run can show a new summary.
- **Gold cache markers:** caches waiting on the field now have a floating gold chest marker with a matching glow. It scales with distance and fades after the cache is collected. The feature is part of **Boss skulls** and follows the same Options toggle.
- **Stored Level-Ups setting:** Arcane's Stored level-ups checkbox now reads and changes the game's actual Store Level-Ups preference. The Arcane menu and the game's native Options page stay synchronized, and the custom Level Up button is used when the game setting is enabled.
- **Stored Level-Ups placement:** raised the default button position so it clears the skill bar and XP display. Existing saved positions are preserved; the new anchor applies to fresh layouts or after resetting positions.
- **Remove unused world-map shortcut:** Arcane suppresses the stock **M** binding only when M is assigned to `TOGGLEWORLDMAP`. Custom M bindings are left alone, and the player's saved key configuration is not overwritten.

#### Preserved behavior

- Existing saved frame positions and per-part settings, except that fresh/reset Stored Level-Ups placement uses the higher default.
- The minimap, its ring, clock, chest and lair pins, and the Arcane A options button. Only the unused stock M world-map shortcut is suppressed.
- The player's saved keybinding file and any custom M binding.
- Existing Store Level-Ups gameplay behavior and native game Options control.
- Boss skulls, guardian markers and the existing minimap chest markers.

#### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation and static audits do not replace a live test in the client's Lua 5.0 runtime. In particular, the co-op summary behavior should be verified in a multiplayer run.

### v0.7.5 — November 10, 2026

Arcane v0.7.5 is a focused usability and reliability update. It brings the FPS readout into Arcane's normal movable-frame system, improves the default placement of the boss bars, and fixes an error at the end of slash-command handling.

#### What's changed

- **FPS display and mover:** the FPS text now lives inside Arcane's own movable frame and moves with its gold grab outline. The larger move target makes it easier to pick up in Move frames mode. Toggle the display from Arcane Options; Ctrl+R is unbound while Arcane is loaded.
- **Boss and mini-boss bar placement:** the default/reset position remains horizontally centered beneath the boss timer, with the mover outline lowered below the timer's drag hint to prevent overlap.
- **Slash command reliability:** fix the command router's final Options refresh to call `C.RefreshHub()` through Arcane's namespace. This removes the Lua error raised after commands such as `/Arcane reset`, while keeping the existing commands and aliases.

#### Preserved behavior

- Existing saved frame positions and per-part settings.
- The FPS display's Options checkbox and Arcane's standard `C.Movable` drag/lock/reset behavior.
- The player's saved keybinding file; Ctrl+R suppression is runtime-only.
- Existing slash commands, aliases, part toggles and language commands.
- Boss-bar health, debuff display, sizing and gameplay behavior.

#### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation is not a substitute for testing in the client's Lua 5.0 runtime.

### v0.7.4 — November 10, 2026

Arcane v0.7.4 is a focused visual-polish update for the skill bar's experience display.

#### What's changed

- **XP level text alignment:** move the level and experience label up by 2 UI pixels so the visible text sits more naturally centered inside the gold progress capsule.
- **Visual consistency:** preserve the existing font, size, color treatment, and horizontal centering.

#### Preserved behavior

- XP tracking and calculations.
- Level progression and level-up animation.
- Progress-bar fill and animation.
- Skill slots, abilities, and jewelry layout.
- Existing saved settings and customization options.

#### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Automated architecture and regression audits passed.
- Lua 5.1 compilation passed as a syntax check.
- The install ZIP is validated for archive integrity, expected folder layout, required artwork, multilingual fonts, and license notices.

Lua 5.1 compilation is not a substitute for a live in-game test with the client's Lua 5.0 runtime.

### v0.7.3 — November 9, 2026

Arcane v0.7.3 packages the current mainline HUD as a consistent, verified install. It carries forward the v0.7.2 skill-bar alignment correction and the existing Arcane feature set; this is a packaging and release-process update, not a new gameplay or UI behavior release.

#### Included

- The current Arcane HUD, including the center-diamond alignment to the visible gold rails.
- Existing Classic Arcane, Hybrid and Full Class styling.
- Arcane Nameplates, damage numbers, boss and party frames, minimap, loot, Stats, Damage meter, Luck, Character and run-summary panels.
- Existing language support, artwork, bundled fonts and their license notices.

#### Install package

- **Download:** `ArcaneV0.7.3.zip`
- **Archive layout:** the ZIP opens directly to `Arcane/Arcane.toc`.
- **Assets:** includes the complete `Art/` and `Fonts/` folders, multilingual font files, and attribution/license notices.
- **Upgrade:** extract into `Interface/AddOns`; keep the installed folder named `Arcane`. Existing `ArcaneDB` saved settings are retained.

#### Validation

The release-tag workflow runs the repository architecture and regression audits, compiles every Lua chunk with Lua 5.1 as a syntax check, creates the install ZIP, verifies archive integrity and required assets, and publishes the GitHub Release only after those steps pass.

The target remains Azeroth Survivors 1.12.1 and its Lua 5.0 runtime. Lua 5.1 compilation does not establish live Lua 5.0 compatibility; an in-game smoke test is still required.

### v0.7.2 — November 9, 2026

Arcane v0.7.2 is a focused visual-alignment patch.

#### Skill bar

- Correct the top and bottom center diamond anchors so each diamond sits on the visible gold stripe of its corresponding rail, compensating for transparent artwork padding.
- Both diamonds remain centered horizontally on the full outer panel as the kills, gold and cache dock expands or contracts.
- Preserve the existing diamond artwork, dimensions, palette behavior and vertical placement.

#### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Existing skill slots, XP display, jewelry, tally dock, saved settings, languages, artwork and fonts are unchanged.
- Automated audits and Lua compilation run in GitHub Actions; the Lua 5.1 compiler is a syntax check only and does not replace live testing in the game's Lua 5.0 client.
- The full CI install package retains all existing Art and Fonts assets and license notices.

### v0.7.1 — November 9, 2026

Arcane v0.7.1 is a focused usability patch release.

#### Arcane Nameplates settings

- The Arcane Nameplates settings panel can now be dragged with the left mouse button using its open background, just like the Timer and Damage Numbers settings windows.
- The panel is clamped to the screen so it cannot be dragged completely off-screen.
- It remains a child of the main Arcane Options hub, preserving the existing behavior where hiding the hub also hides the Nameplates settings panel.
- The existing controls, color presets, saved settings and native nameplate behavior are unchanged.

#### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- The automated workflow compiles Lua chunks with Lua 5.1 as a syntax check; this does not replace live testing in the game's Lua 5.0 client.
- Existing font files, language support, artwork and license notices remain part of the full CI-generated install package.

### v0.7 — November 9, 2026

Arcane v0.7 is a substantial polish and reliability release. It builds on the v0.6 architecture refactor and focuses on the parts of the HUD that matter most during a run: readable enemy plates, correct native-frame lifecycle handling, consistent text and palette behavior, dependable run summaries, and a cleaner layout.

#### Enemy nameplates — bigger, clearer, and more reliable

- **Arcane Nameplates identity and upgrade path.** The former Tiny Plates subsystem is now consistently named and namespaced as Arcane Nameplates. Azeroth Survivors' `AZS_*` integration identifiers remain untouched, and the existing `ArcaneDB.nameplates` settings bucket is retained so saved colors and display preferences survive the upgrade.

- **Regular enemy bars are larger.** The standard replacement bar now uses 75% of the native health-bar dimensions instead of 50%, giving health values more room without changing the game's projected nameplate position.
- **Health values stay on one line.** Current and maximum health are rendered without breakable spacing around the separator. The text measures itself and fits to the usable inner width of the bar, including larger health totals.
- **Enemy level is visible at a glance.** A compact square badge sits on the right side of the health bar, using Arcane's dark glass fill, metallic rim, and active title color.
- **The bar is aligned to the actual health bar.** The replacement is centered directly on the native StatusBar rather than reusing an offset calculated from a different anchor point.
- **Native plate discovery is exact and cached.** Arcane recognizes the Azeroth Survivors 1.12 plate structure instead of recursively searching unrelated UI descendants for something that merely resembles a nameplate.
- **Pooled plates update immediately.** Azeroth Survivors reuses native plate buttons. Arcane tracks those known frames, responds to their show/hide lifecycle, refreshes the enemy identity, and reapplies the correct presentation without the old half-second discovery delay.
- **Native visual leftovers stay hidden.** The game can update its own name, level, border, glow, skull, raid marker, and health-bar regions after a plate is created or reused. Arcane suppresses those specific native layers after the game's update so they do not flash through or stack with the replacement.
- **The game's plate ownership stays intact.** Arcane does not reposition, resize, or rescale the WorldFrame root plate. The native `V` key remains the only visibility control, and the replacement follows the same pooled plate.
- **Bosses and guardians keep their full-size treatment.** The regular-enemy size change does not shrink the special-target presentation or remove its debuff handling.
- **World-hover information can stay out of the way.** The persistent default-anchored world tooltip for hovered units, corpses, and world objects is suppressed. Normal tooltips owned by actual UI controls remain available.

#### Text and notification theming

- **Buff and aura feedback uses Arcane's palette.** Positive spell/aura messages—including gained and fading effects—use the active Arcane title color treatment.
- **Healing feedback follows the healing palette.** Healing and critical/periodic healing messages use the established Arcane healing accent.
- **The native gameplay notification feed is themed.** Stock gameplay messages use Arcane typography and the active UX palette in Arcane, Hybrid, and Full Class modes.
- **The notification feed stays transparent and borderless.** It can be repositioned with Move frames and controlled from Arcane Options without replacing the game's message queue or event routing.
- **Real Lua script errors remain separate.** The gameplay notification feed is not confused with the client's actual script-error window.
- **Zone announcements remain original.** Names such as “Tower of Azora” keep Blizzard's original wording, font, size, contextual color, position, and fade. No Arcane banner, outline, trim, or overlay is applied to zone or subzone text.

#### UI styles and palette consistency

- **Full Class now reaches the wider Arcane UI.** The active class palette is applied across shared panels and consumers, including player and party frames, minimap, Stats, Damage meter, Luck, Character, pet and stored-level-up panels.
- **Classic Arcane remains bronze.** Its established bronze/gold treatment is preserved.
- **Hybrid keeps its intended split.** The skill bar receives its class treatment while the rest of the shared UI retains the bronze Arcane look.
- **The boss timer keeps its own zone palette.** Its contextual treatment is not overwritten by the global Full Class palette.
- **The selector is now named for its real scope.** The Options label describes the overall UI style rather than implying that it only affects the skill bar.

#### Layout, movement, and native UI cleanup

- **Move frames is the deliberate positioning mode.** Ordinary clicks no longer drag Stats, Luck, and Damage meter windows by accident. Use the mover overlay to reposition them; the established saved-position and resize behavior remains.
- **Stats has a cleaner default position.** It resets directly above the Damage meter, aligned to the meter's right edge. Damage meter and Luck retain their right-side defaults.
- **Party frames sit below the player frame.** The default party stack is aligned with the player frame instead of occupying a disconnected position.
- **The redundant target pane is removed.** Arcane keeps its player frame and the enemy/boss presentation without adding a separate selected-target portrait and health window. Native target selection is unchanged.
- **Unused bag access is removed safely.** The B key is cleared only when it is currently assigned to a bag-opening action. Other B bindings and the player's saved key map are not overwritten.
- **The unused Honor tab stays hidden.** This remains true even when Arcane's custom Character panel is disabled.
- **The duplicate Luck stat row is gone.** Luck remains available in its own dedicated window; it no longer appears a second time in the Stats plate.

#### Run summary lifecycle

- **The summary survives the transition screen.** It remains visible during “Move to begin” after a run ends.
- **It dismisses when the next run actually starts.** The summary closes on the transition into active play rather than disappearing too early.
- **Repeated outcomes work correctly.** A second run that ends with the same result as the first still receives its own summary.
- **The summary uses a stable end-of-run snapshot.** It compares the full run result and statistics so stale data from the previous run cannot reopen an old summary during the next run.
- **Close and endless-victory behavior are preserved.** The stored summary remains available after the live API clears its end data, and the close control continues to work.

#### Compatibility and upgrade notes

- Arcane remains targeted at **Azeroth Survivors 1.12.1 and its Lua 5.0 runtime**.
- Azeroth Survivors integration names such as `AZSUNITS`, `AZS_UNITS`, and other `AZS_*` APIs remain game-owned and unchanged.
- Existing saved-variable contracts—including `ArcaneDB.nameplates`—are preserved. This release does not require wiping Arcane settings.
- The native enemy-plate `V` key remains in charge of plate visibility.
- Install by replacing the existing `Arcane/` addon folder with the v0.7 package. Keep the folder named exactly `Arcane`.

#### Validation

- Repository architecture and regression audits passed.
- Lua source chunks compiled and the local-variable limits passed.
- The installable addon ZIP passed archive validation.
- The CI compiler uses Lua 5.1 as a syntax and chunk-limit check; it does not emulate the game's Lua 5.0 client. Live-client checks remain the authority for in-game behavior.

**Thank you for playing with Arcane!**

---

### v0.6 — November 8, 2026

- **Arcane Nameplates identity:** move the integrated enemy-plate renderer into Arcane-owned modules, namespace and frame-state names. Preserve the game's `AZS_*` integration and the existing `ArcaneDB.nameplates` saved settings for upgrades.
- **Arcane Nameplates refactor:** reorganize the built-in enemy-plate replacement into state, special-target, visual and controller modules. Keep its health bars on Arcane's shared bar renderer.
- **Native visibility ownership:** the game's `V` command remains the only enemy-plate visibility control. Arcane's replacement is attached to the same pooled native plate buttons, with no second enable/hide switch or stock-renderer fallback.
- **Safer native restoration:** capture and restore only native child visibility and alpha; leave the game's projected plate position and geometry untouched. Avoid blanket show-all recovery when the original state is unknown.
- **Pooled-frame and update fixes:** identify only the game's native plate buttons, refresh reused pool slots without stale state, retry incomplete styling, cache special-target/debuff lookups, and isolate errors to the affected plate.
- **Regression coverage:** add a dedicated Arcane Nameplates audit to the repository's CI checks.

### v0.5 — November 8, 2026

- **Classic skill bar medallions:** use the supplied high-resolution gold dragon/A artwork on both default endcaps, mirrored on the right and aligned against Hybrid's lower ornamental tails. The bar rails, slots, spacing and other styles remain unchanged.
- **README preview:** replace the older preview image with a current in-game screenshot showing the v0.5 HUD.

### v0.4 — November 8, 2026

- **Standalone Stats window:** a movable, resizable tracker for 29 run stats, grouped by Offense, Survival, Area and DoTs, and Run. Choose the stats to show; increases and decreases briefly flash green and red.
- **Party shields:** party health bars now show detected absorb shields using Arcane's existing animated glass-and-stripe overlay.
- **Target portrait rings:** bosses and final bosses receive the original gold elite dragon ring; guardians receive the silver rare ring. The corrected segmented texture keeps the full ring intact.
- **Damage-number choices:** six optional custom fonts join the four built-in faces; six optional critical-hit backdrops add Flame, Frost, Arcane, Holy, Shadow and Storm treatments. The default backdrop remains None.
- **Minimap readability:** cache and lair markers fade near the player's arrow and return to full strength with distance.
- **Loot rarity correction:** Tier 0.5 set armor is identified as Epic (purple), while exact named Tier 0.5 weapons retain their Legendary rarity.

### v0.3

- **Three selectable skill-bar styles:** Classic Arcane remains the unchanged default for existing installs; Hybrid combines the gold Arcane A medallion on the left with the active class crest on the right; Full Class uses class-specific paired emblems, rails and tinted glass.
- **Nine class palettes:** Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock and Druid receive dedicated skill-bar styling. The selected style persists in `ArcaneDB.bar.style`.
- **Hybrid medallion treatments:** class-colored enamel variants are supplied for Warrior, Paladin, Rogue, Priest, Shaman, Mage and Warlock. Hunter and Druid retain the approved original green Arcane medallion; the gold dragon/A artwork is preserved.
- **Hybrid panel edge:** retain the complete right-hand panel endcap beneath the class crest so the bar does not appear cut off.

### v0.2

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

### Developer reference

This section records the project's runtime constraints and observed Azeroth Survivors addon API. It is a maintainer reference, not a list of release changes. API observations should be checked against the live client before depending on them.

#### Runtime and coding constraints

- Arcane targets the Azeroth Survivors 1.12.1 client and its **Lua 5.0** runtime. Do not assume modern WoW widget methods or newer Lua features are available.
- Keep chunk-level local declarations below Lua 5.0's 200-local limit. Group related state and constants under a table instead of continually adding file-scope locals.
- Use Lua 5.0-compatible idioms: use `table.getn` for arrays, `string.find` with captures instead of `string.match`, and `math.mod` where appropriate. Avoid the length operator, hex literals, `goto`, and Lua 5.1+ vararg patterns.
- Pass game APIs only the arguments they require; avoid stray `nil` arguments. Use the shared protected-call helper where appropriate.
- Remove array entries with `table.remove`. Do not create holes in arrays that are read with `table.getn`.
- Core's memo writers (`C.SetText`, `C.Size`, `C.Width`, `C.Place`, `C.Vis`, `C.Alpha`, `C.Color`, `C.TextColor`, `C.TextWidth`) skip unchanged writes. Do not mix them with direct writes to the same region.
- Route player-facing strings through `C.L`, `C.F` or `C.LText`; keep all 11 addon languages aligned with the English keys.
- Register each UI part through `C.RegisterPart`, expose its enabled state, and restore the game's own UI when Arcane's replacement is disabled. Guard frame-update work against errors.
- Preserve Arcane's existing visual identity and artwork. Comments should explain what the player sees in plain English.

#### Testing

The repository's GitHub workflow performs static architecture checks, compiles Lua chunks with Lua 5.1, and checks the generated ZIP. There is no mock game client or complete in-game API fixture. These checks do **not** prove Lua 5.0 runtime compatibility, widget-method availability, live API return shapes, or correct restoration of the game's UI.

Load changes in the actual client and check the affected behavior, especially frame methods, event data, visibility restoration, saved positions and cross-system interactions. Use `/Arcane probe` to collect live values when an API shape is uncertain. Never report a live test as passed unless it was actually run.

#### Recorded Azeroth Survivors API observations

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
<!-- RELEASE_HISTORY_END -->