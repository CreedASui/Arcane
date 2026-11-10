# Arcane UI v0.7.2 — centered skill-bar ornaments

Arcane v0.7.2 is a focused visual-alignment patch.

## Skill bar

- Correct the top and bottom center diamond anchors so each diamond sits on the visible gold stripe of its corresponding rail, compensating for transparent artwork padding.
- Both diamonds remain centered horizontally on the full outer panel as the kills, gold and cache dock expands or contracts.
- Preserve the existing diamond artwork, dimensions, palette behavior and vertical placement.

## Compatibility and validation

- Targets Azeroth Survivors 1.12.1 and its Lua 5.0 runtime.
- Existing skill slots, XP display, jewelry, tally dock, saved settings, languages, artwork and fonts are unchanged.
- Automated audits and Lua compilation run in GitHub Actions; the Lua 5.1 compiler is a syntax check only and does not replace live testing in the game's Lua 5.0 client.
- The full CI install package retains all existing Art and Fonts assets and license notices.
