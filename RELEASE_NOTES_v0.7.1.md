# Arcane UI v0.7.1 — movable Nameplates settings

Arcane v0.7.1 is a focused usability patch release.

## Arcane Nameplates settings

- The Arcane Nameplates settings panel can now be dragged with the left mouse button using its open background, just like the Timer and Damage Numbers settings windows.
- The panel is clamped to the screen so it cannot be dragged completely off-screen.
- It remains a child of the main Arcane Options hub, preserving the existing behavior where hiding the hub also hides the Nameplates settings panel.
- The existing controls, color presets, saved settings and native nameplate behavior are unchanged.

## Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- The automated workflow compiles Lua chunks with Lua 5.1 as a syntax check; this does not replace live testing in the game's Lua 5.0 client.
- Existing font files, language support, artwork and license notices remain part of the full CI-generated install package.
