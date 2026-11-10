# Arcane UI v0.7.6 — Co-op Summary, Stored Level-Ups and HUD Cleanup

Arcane v0.7.6 brings a multiplayer run-summary fix, clearer cache markers, a properly connected Stored Level-Ups setting, and a little less unused game UI.

## What's changed

- **Co-op run summary:** when you fall while your teammates continue the run, the game's end-of-run statistics can keep changing. Arcane now keeps the original summary snapshot instead of reopening and replaying its count-up animation on every update. Closing the summary stays effective while the run continues, and a genuinely new outcome or the next run can show a new summary.
- **Gold cache markers:** caches waiting on the field now have a floating gold chest marker with a matching glow. It scales with distance and fades after the cache is collected. The feature is part of **Boss skulls** and follows the same Options toggle.
- **Stored Level-Ups setting:** Arcane's Stored level-ups checkbox now reads and changes the game's actual Store Level-Ups preference. The Arcane menu and the game's native Options page stay synchronized, and the custom Level Up button is used when the game setting is enabled.
- **Stored Level-Ups placement:** raised the default button position so it clears the skill bar and XP display. Existing saved positions are preserved; the new anchor applies to fresh layouts or after resetting positions.
- **Remove unused world-map shortcut:** Arcane suppresses the stock **M** binding only when M is assigned to `TOGGLEWORLDMAP`. Custom M bindings are left alone, and the player's saved key configuration is not overwritten.

## Also included from v0.7.5

- **Movable FPS display:** FPS text and its larger gold grab outline move together through Arcane's standard Move frames system. The display remains configurable in Arcane Options; Ctrl+R is suppressed at runtime without saving over the player's keymap.
- **Boss-bar default spacing:** boss and mini-boss bars reset centered beneath the timer, with the mover outline clear of the timer's drag hint. Existing saved positions remain untouched.
- **Slash command fix:** the Options hub refresh uses Arcane's `C.RefreshHub()` function, preventing the Lua error after slash commands while preserving the existing commands and aliases.

## Preserved behavior

- Existing saved frame positions and per-part settings, except that fresh/reset Stored Level-Ups placement uses the higher default.
- The minimap, its ring, clock, chest and lair pins, and the Arcane A options button. Only the unused stock M world-map shortcut is suppressed.
- The player's saved keybinding file and any custom M binding.
- Existing Store Level-Ups gameplay behavior and native game Options control.
- Boss skulls, guardian markers and the existing minimap chest markers.

## Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation and static audits do not replace a live test in the client's Lua 5.0 runtime. In particular, the co-op summary behavior should be verified in a multiplayer run.
