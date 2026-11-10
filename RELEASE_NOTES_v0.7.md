# Arcane UI v0.7 — Nameplates, readability & reliability

Arcane v0.7 is a substantial polish and reliability release. It builds on the v0.6 architecture refactor and focuses on the parts of the HUD that matter most during a run: readable enemy plates, correct native-frame lifecycle handling, consistent text and palette behavior, dependable run summaries, and a cleaner layout.

## Enemy nameplates — bigger, clearer, and more reliable

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

## Text and notification theming

- **Buff and aura feedback uses Arcane's palette.** Positive spell/aura messages—including gained and fading effects—use the active Arcane title color treatment.
- **Healing feedback follows the healing palette.** Healing and critical/periodic healing messages use the established Arcane healing accent.
- **The native gameplay notification feed is themed.** Stock gameplay messages use Arcane typography and the active UX palette in Arcane, Hybrid, and Full Class modes.
- **The notification feed stays transparent and borderless.** It can be repositioned with Move frames and controlled from Arcane Options without replacing the game's message queue or event routing.
- **Real Lua script errors remain separate.** The gameplay notification feed is not confused with the client's actual script-error window.
- **Zone announcements remain original.** Names such as “Tower of Azora” keep Blizzard's original wording, font, size, contextual color, position, and fade. No Arcane banner, outline, trim, or overlay is applied to zone or subzone text.

## UI styles and palette consistency

- **Full Class now reaches the wider Arcane UI.** The active class palette is applied across shared panels and consumers, including player and party frames, minimap, Stats, Damage meter, Luck, Character, pet and stored-level-up panels.
- **Classic Arcane remains bronze.** Its established bronze/gold treatment is preserved.
- **Hybrid keeps its intended split.** The skill bar receives its class treatment while the rest of the shared UI retains the bronze Arcane look.
- **The boss timer keeps its own zone palette.** Its contextual treatment is not overwritten by the global Full Class palette.
- **The selector is now named for its real scope.** The Options label describes the overall UI style rather than implying that it only affects the skill bar.

## Layout, movement, and native UI cleanup

- **Move frames is the deliberate positioning mode.** Ordinary clicks no longer drag Stats, Luck, and Damage meter windows by accident. Use the mover overlay to reposition them; the established saved-position and resize behavior remains.
- **Stats has a cleaner default position.** It resets directly above the Damage meter, aligned to the meter's right edge. Damage meter and Luck retain their right-side defaults.
- **Party frames sit below the player frame.** The default party stack is aligned with the player frame instead of occupying a disconnected position.
- **The redundant target pane is removed.** Arcane keeps its player frame and the enemy/boss presentation without adding a separate selected-target portrait and health window. Native target selection is unchanged.
- **Unused bag access is removed safely.** The B key is cleared only when it is currently assigned to a bag-opening action. Other B bindings and the player's saved key map are not overwritten.
- **The unused Honor tab stays hidden.** This remains true even when Arcane's custom Character panel is disabled.
- **The duplicate Luck stat row is gone.** Luck remains available in its own dedicated window; it no longer appears a second time in the Stats plate.

## Run summary lifecycle

- **The summary survives the transition screen.** It remains visible during “Move to begin” after a run ends.
- **It dismisses when the next run actually starts.** The summary closes on the transition into active play rather than disappearing too early.
- **Repeated outcomes work correctly.** A second run that ends with the same result as the first still receives its own summary.
- **The summary uses a stable end-of-run snapshot.** It compares the full run result and statistics so stale data from the previous run cannot reopen an old summary during the next run.
- **Close and endless-victory behavior are preserved.** The stored summary remains available after the live API clears its end data, and the close control continues to work.

## Compatibility and upgrade notes

- Arcane remains targeted at **Azeroth Survivors 1.12.1 and its Lua 5.0 runtime**.
- Azeroth Survivors integration names such as `AZSUNITS`, `AZS_UNITS`, and other `AZS_*` APIs remain game-owned and unchanged.
- Existing saved-variable contracts—including `ArcaneDB.nameplates`—are preserved. This release does not require wiping Arcane settings.
- The native enemy-plate `V` key remains in charge of plate visibility.
- Install by replacing the existing `Arcane/` addon folder with the v0.7 package. Keep the folder named exactly `Arcane`.

## Validation

- Repository architecture and regression audits passed.
- Lua source chunks compiled and the local-variable limits passed.
- The installable addon ZIP passed archive validation.
- The CI compiler uses Lua 5.1 as a syntax and chunk-limit check; it does not emulate the game's Lua 5.0 client. Live-client checks remain the authority for in-game behavior.

**Thank you for playing with Arcane!**
