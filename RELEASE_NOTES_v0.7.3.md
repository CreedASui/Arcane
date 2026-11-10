# Arcane UI v0.7.3 — release stabilization

Arcane v0.7.3 packages the current mainline HUD as a consistent, verified install. It carries forward the v0.7.2 skill-bar alignment correction and the existing Arcane feature set; this is a packaging and release-process update, not a new gameplay or UI behavior release.

## Included

- The current Arcane HUD, including the center-diamond alignment to the visible gold rails.
- Existing Classic Arcane, Hybrid and Full Class styling.
- Arcane Nameplates, damage numbers, boss and party frames, minimap, loot, Stats, Damage meter, Luck, Character and run-summary panels.
- Existing language support, artwork, bundled fonts and their license notices.

## Install package

- **Download:** `ArcaneV0.7.3.zip`
- **Archive layout:** the ZIP opens directly to `Arcane/Arcane.toc`.
- **Assets:** includes the complete `Art/` and `Fonts/` folders, multilingual font files, and attribution/license notices.
- **Upgrade:** extract into `Interface/AddOns`; keep the installed folder named `Arcane`. Existing `ArcaneDB` saved settings are retained.

## Validation

The release-tag workflow runs the repository architecture and regression audits, compiles every Lua chunk with Lua 5.1 as a syntax check, creates the install ZIP, verifies archive integrity and required assets, and publishes the GitHub Release only after those steps pass.

The target remains Azeroth Survivors 1.12.1 and its Lua 5.0 runtime. Lua 5.1 compilation does not establish live Lua 5.0 compatibility; an in-game smoke test is still required.
