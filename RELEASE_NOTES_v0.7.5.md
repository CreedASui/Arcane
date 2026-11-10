# Arcane UI v0.7.5 — FPS, Movers and Slash Command Fixes

Arcane v0.7.5 is a focused usability and reliability update. It brings the FPS readout into Arcane's normal movable-frame system, improves the default placement of the boss bars, and fixes an error at the end of slash-command handling.

## What's changed

- **FPS display and mover:** the FPS text now lives inside Arcane's own movable frame and moves with its gold grab outline. The larger move target makes it easier to pick up in Move frames mode. Toggle the display from Arcane Options; Ctrl+R is unbound while Arcane is loaded.
- **Boss and mini-boss bar placement:** the default/reset position remains horizontally centered beneath the boss timer, with the mover outline lowered below the timer's drag hint to prevent overlap.
- **Slash command reliability:** fix the command router's final Options refresh to call `C.RefreshHub()` through Arcane's namespace. This removes the Lua error raised after commands such as `/Arcane reset`, while keeping the existing commands and aliases.

## Preserved behavior

- Existing saved frame positions and per-part settings.
- The FPS display's Options checkbox and Arcane's standard `C.Movable` drag/lock/reset behavior.
- The player's saved keybinding file; Ctrl+R suppression is runtime-only.
- Existing slash commands, aliases, part toggles and language commands.
- Boss-bar health, debuff display, sizing and gameplay behavior.

## Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Repository architecture and regression audits passed.
- All Lua chunks compiled with Lua 5.1 as a syntax check.
- The install ZIP was validated for archive integrity, the `Arcane/` folder layout, required artwork, multilingual fonts and license notices.

Lua 5.1 compilation is not a substitute for testing in the client's Lua 5.0 runtime.
