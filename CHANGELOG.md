# Arcane UI — Release History

This is the single source of truth for versioned release notes. Add each new release as a dated section at the top of this file. GitHub Actions extracts the matching section when publishing a version tag; separate per-version release-note files are not used.

## Unreleased

### Fixed

- **Target frame is back:** clicking a monster shows its frame again, with its name and real health (and the gold elite dragon on a boss, the silver one on a guardian). v0.7.6 removed Arcane's target frame but still hid the game's own, so a clicked monster showed nothing. It's a part again in Arcane Options (**Target frame**): turning it off gives back the game's own target frame.
- **Party DPS best skills:** each friend's best skill on Party DPS shows its name instead of "nil". The lines by player carry no skill, so the best skills are read from the same party's damage grouped by skill.
- **Skill ranks:** a skill's rank box no longer sticks at an old rank (it stayed at 2) when the game lists that skill more than once with the same icon. The entry in that very slot wins, else the highest rank.

## v0.7.6 — November 10, 2026

Arcane v0.7.6 brings a multiplayer run-summary fix, clearer cache markers, a properly connected Stored Level-Ups setting, and a little less unused game UI.

### What's changed

- **Co-op run summary:** when you fall while your teammates continue the run, the game's end-of-run statistics can keep changing. Arcane now keeps the original summary snapshot instead of reopening and replaying its count-up animation on every update. Closing the summary stays effective while the run continues, and a genuinely new outcome or the next run can show a new summary.
- **Gold cache markers:** caches waiting on the field now have a floating gold chest marker with a matching glow. It scales with distance and fades after the cache is collected. The feature is part of **Boss skulls** and follows the same Options toggle.
- **Stored Level-Ups setting:** Arcane's Stored level-ups checkbox now reads and changes the game's actual Store Level-Ups preference. The Arcane menu and the game's native Options page stay synchronized, and the custom Level Up button is used when the game setting is enabled.
- **Stored Level-Ups placement:** raised the default button position so it clears the skill bar and XP display. Existing saved positions are preserved; the new anchor applies to fresh layouts or after resetting positions.
- **Remove unused world-map shortcut:** Arcane suppresses the stock **M** binding only when M is assigned to `TOGGLEWORLDMAP`. Custom M bindings are left alone, and the player's saved key configuration is not overwritten.

### Preserved behavior

- Existing saved frame positions and per-part settings, except that fresh/reset Stored Level-Ups placement uses the higher default.
- The minimap, its ring, clock, chest and lair pins, and the Arcane A options button. Only the unused stock M world-map shortcut is suppressed.
- The player's saved keybinding file and any custom M binding.
- Existing Store Level-Ups gameplay behavior and native game Options control.
- Boss skulls, guardian markers and the existing minimap chest markers.

### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation and static audits do not replace a live test in the client's Lua 5.0 runtime. In particular, the co-op summary behavior should be verified in a multiplayer run.

## v0.7.5 — November 10, 2026

Arcane v0.7.5 is a focused usability and reliability update. It brings the FPS readout into Arcane's normal movable-frame system, improves the default placement of the boss bars, and fixes an error at the end of slash-command handling.

### What's changed

- **FPS display and mover:** the FPS text now lives inside Arcane's own movable frame and moves with its gold grab outline. The larger move target makes it easier to pick up in Move frames mode. Toggle the display from Arcane Options; Ctrl+R is unbound while Arcane is loaded.
- **Boss and mini-boss bar placement:** the default/reset position remains horizontally centered beneath the boss timer, with the mover outline lowered below the timer's drag hint to prevent overlap.
- **Slash command reliability:** fix the command router's final Options refresh to call `C.RefreshHub()` through Arcane's namespace. This removes the Lua error raised after commands such as `/Arcane reset`, while keeping the existing commands and aliases.

### Preserved behavior

- Existing saved frame positions and per-part settings.
- The FPS display's Options checkbox and Arcane's standard `C.Movable` drag/lock/reset behavior.
- The player's saved keybinding file; Ctrl+R suppression is runtime-only.
- Existing slash commands, aliases, part toggles and language commands.
- Boss-bar health, debuff display, sizing and gameplay behavior.

### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation is not a substitute for testing in the client's Lua 5.0 runtime.

## v0.7.4 — November 10, 2026

Arcane v0.7.4 is a focused visual-polish update for the skill bar's experience display.

### What's changed

- **XP level text alignment:** move the level and experience label up by 2 UI pixels so the visible text sits more naturally centered inside the gold progress capsule.
- **Visual consistency:** preserve the existing font, size, color treatment, and horizontal centering.

### Preserved behavior

- XP tracking and calculations.
- Level progression and level-up animation.
- Progress-bar fill and animation.
- Skill slots, abilities, and jewelry layout.
- Existing saved settings and customization options.

### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Automated architecture and regression audits passed.
- Lua 5.1 compilation passed as a syntax check.
- The install ZIP is validated for archive integrity, expected folder layout, required artwork, multilingual fonts, and license notices.

Lua 5.1 compilation is not a substitute for a live in-game test with the client's Lua 5.0 runtime.

## v0.7.3 — November 9, 2026

Arcane v0.7.3 packages the current mainline HUD as a consistent, verified install. It carries forward the v0.7.2 skill-bar alignment correction and the existing Arcane feature set; this is a packaging and release-process update, not a new gameplay or UI behavior release.

### Included

- The current Arcane HUD, including the center-diamond alignment to the visible gold rails.
- Existing Classic Arcane, Hybrid and Full Class styling.
- Arcane Nameplates, damage numbers, boss and party frames, minimap, loot, Stats, Damage meter, Luck, Character and run-summary panels.
- Existing language support, artwork, bundled fonts and their license notices.

### Install package

- **Download:** `ArcaneV0.7.3.zip`
- **Archive layout:** the ZIP opens directly to `Arcane/Arcane.toc`.
- **Assets:** includes the complete `Art/` and `Fonts/` folders, multilingual font files, and attribution/license notices.
- **Upgrade:** extract into `Interface/AddOns`; keep the installed folder named `Arcane`. Existing `ArcaneDB` saved settings are retained.

### Validation

The release-tag workflow runs the repository architecture and regression audits, compiles every Lua chunk with Lua 5.1 as a syntax check, creates the install ZIP, verifies archive integrity and required assets, and publishes the GitHub Release only after those steps pass.

The target remains Azeroth Survivors 1.12.1 and its Lua 5.0 runtime. Lua 5.1 compilation does not establish live Lua 5.0 compatibility; an in-game smoke test is still required.

## v0.7.2 — November 9, 2026

Arcane v0.7.2 is a focused visual-alignment patch.

### Skill bar

- Correct the top and bottom center diamond anchors so each diamond sits on the visible gold stripe of its corresponding rail, compensating for transparent artwork padding.
- Both diamonds remain centered horizontally on the full outer panel as the kills, gold and cache dock expands or contracts.
- Preserve the existing diamond artwork, dimensions, palette behavior and vertical placement.

### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Existing skill slots, XP display, jewelry, tally dock, saved settings, languages, artwork and fonts are unchanged.
- Automated audits and Lua compilation run in GitHub Actions; the Lua 5.1 compiler is a syntax check only and does not replace live testing in the game's Lua 5.0 client.
- The full CI install package retains all existing Art and Fonts assets and license notices.

## v0.7.1 — November 9, 2026

Arcane v0.7.1 is a focused usability patch release.

### Arcane Nameplates settings

- The Arcane Nameplates settings panel can now be dragged with the left mouse button using its open background, just like the Timer and Damage Numbers settings windows.
- The panel is clamped to the screen so it cannot be dragged completely off-screen.
- It remains a child of the main Arcane Options hub, preserving the existing behavior where hiding the hub also hides the Nameplates settings panel.
- The existing controls, color presets, saved settings and native nameplate behavior are unchanged.

### Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- The automated workflow compiles Lua chunks with Lua 5.1 as a syntax check; this does not replace live testing in the game's Lua 5.0 client.
- Existing font files, language support, artwork and license notices remain part of the full CI-generated install package.

## v0.7 — November 9, 2026

Arcane v0.7 is a substantial polish and reliability release. It builds on the v0.6 architecture refactor and focuses on the parts of the HUD that matter most during a run: readable enemy plates, correct native-frame lifecycle handling, consistent text and palette behavior, dependable run summaries, and a cleaner layout.

### Enemy nameplates — bigger, clearer, and more reliable

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

### Text and notification theming

- **Buff and aura feedback uses Arcane's palette.** Positive spell/aura messages—including gained and fading effects—use the active Arcane title color treatment.
- **Healing feedback follows the healing palette.** Healing and critical/periodic healing messages use the established Arcane healing accent.
- **The native gameplay notification feed is themed.** Stock gameplay messages use Arcane typography and the active UX palette in Arcane, Hybrid, and Full Class modes.
- **The notification feed stays transparent and borderless.** It can be repositioned with Move frames and controlled from Arcane Options without replacing the game's message queue or event routing.
- **Real Lua script errors remain separate.** The gameplay notification feed is not confused with the client's actual script-error window.
- **Zone announcements remain original.** Names such as “Tower of Azora” keep Blizzard's original wording, font, size, contextual color, position, and fade. No Arcane banner, outline, trim, or overlay is applied to zone or subzone text.

### UI styles and palette consistency

- **Full Class now reaches the wider Arcane UI.** The active class palette is applied across shared panels and consumers, including player and party frames, minimap, Stats, Damage meter, Luck, Character, pet and stored-level-up panels.
- **Classic Arcane remains bronze.** Its established bronze/gold treatment is preserved.
- **Hybrid keeps its intended split.** The skill bar receives its class treatment while the rest of the shared UI retains the bronze Arcane look.
- **The boss timer keeps its own zone palette.** Its contextual treatment is not overwritten by the global Full Class palette.
- **The selector is now named for its real scope.** The Options label describes the overall UI style rather than implying that it only affects the skill bar.

### Layout, movement, and native UI cleanup

- **Move frames is the deliberate positioning mode.** Ordinary clicks no longer drag Stats, Luck, and Damage meter windows by accident. Use the mover overlay to reposition them; the established saved-position and resize behavior remains.
- **Stats has a cleaner default position.** It resets directly above the Damage meter, aligned to the meter's right edge. Damage meter and Luck retain their right-side defaults.
- **Party frames sit below the player frame.** The default party stack is aligned with the player frame instead of occupying a disconnected position.
- **The redundant target pane is removed.** Arcane keeps its player frame and the enemy/boss presentation without adding a separate selected-target portrait and health window. Native target selection is unchanged.
- **Unused bag access is removed safely.** The B key is cleared only when it is currently assigned to a bag-opening action. Other B bindings and the player's saved key map are not overwritten.
- **The unused Honor tab stays hidden.** This remains true even when Arcane's custom Character panel is disabled.
- **The duplicate Luck stat row is gone.** Luck remains available in its own dedicated window; it no longer appears a second time in the Stats plate.

### Run summary lifecycle

- **The summary survives the transition screen.** It remains visible during “Move to begin” after a run ends.
- **It dismisses when the next run actually starts.** The summary closes on the transition into active play rather than disappearing too early.
- **Repeated outcomes work correctly.** A second run that ends with the same result as the first still receives its own summary.
- **The summary uses a stable end-of-run snapshot.** It compares the full run result and statistics so stale data from the previous run cannot reopen an old summary during the next run.
- **Close and endless-victory behavior are preserved.** The stored summary remains available after the live API clears its end data, and the close control continues to work.

### Compatibility and upgrade notes

- Arcane remains targeted at **Azeroth Survivors 1.12.1 and its Lua 5.0 runtime**.
- Azeroth Survivors integration names such as `AZSUNITS`, `AZS_UNITS`, and other `AZS_*` APIs remain game-owned and unchanged.
- Existing saved-variable contracts—including `ArcaneDB.nameplates`—are preserved. This release does not require wiping Arcane settings.
- The native enemy-plate `V` key remains in charge of plate visibility.
- Install by replacing the existing `Arcane/` addon folder with the v0.7 package. Keep the folder named exactly `Arcane`.

### Validation

- Repository architecture and regression audits passed.
- Lua source chunks compiled and the local-variable limits passed.
- The installable addon ZIP passed archive validation.
- The CI compiler uses Lua 5.1 as a syntax and chunk-limit check; it does not emulate the game's Lua 5.0 client. Live-client checks remain the authority for in-game behavior.

**Thank you for playing with Arcane!**

---

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

