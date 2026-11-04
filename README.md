# Arcane UI

A clean, smooth HUD for **Azeroth Survivors** ([wow.aethus.pl](https://wow.aethus.pl)), the World of Warcraft 1.12 roguelike. Everything is drawn in one look (dark glass, a gold rail, the timer's metal) and steps aside while you pick your cards.

## What's in it

- **Boss timer:** a themed countdown to each boss, with the run's time.
- **Boss and mini-boss bars:** red bars with real health numbers and the debuffs on them.
- **Skulls:** a horned skull with red eyes floating over each boss, and a plainer one over each guardian, wherever it is on the screen, large when near and small when far.
- **Your frame, your target and your party:** in class colors, portraits in metal rings.
- **Downed friends (co-op):** a warning and a sound when a friend goes down, a glowing mark with their class crest where you can revive them, and an arrow at the screen's edge with the distance while they're off it.
- **Skill bar:** your abilities (each with its rank, flashing when a card ranks it up) and jewelry, your XP a second, on a gold-framed panel with a painted golden dragon on each end.
- **Kills, gold and cache:** in the panel; hover for what each gives.
- **Stored level-ups:** a glowing Level Up! button with how many wait (with the game's Store Level-Ups on).
- **Damage meter:** Damage Done, Healing Done, Boss Damage, Party DPS and Damage Taken, with icons, per second and shares. Resizable from any edge.
- **Luck medallion:** your luck and the odds of a Rare, Epic or Legendary card.
- **Minimap:** a metal ring, your local time, the caches and the guardians' lairs (with the time until each empty lair fills). The **A** button on its edge opens Arcane Options; use the **Luck** and **Damage meter** toggles in that menu to show or hide those windows.
- **Character window:** gear slots lit in their rarity color and your run's stats grouped beside it (zeros dimmed, changes flashing); its Talents tab opens Arcane UI's talent window (your trees, points and learned talents with their ranks).
- **Chat:** dressed to match, and kept clear of the skill bar's dragon.
- **Damage numbers:** calm and readable; a spell hitting a crowd adds up into one number a second, and a number that keeps stacking grows.
- **Run summary:** when a run ends, your time, level, kills, bosses, damage dealt and taken, gold and caches on one panel.

Every part can be turned on or off, sized and moved.

**Languages:** English, French, German, Spanish, Portuguese, Chinese, Russian, Japanese, Korean, Polish and Turkish, picked from the options or with `/Arcane language`.

## Build

Requires Python 3 and FontTools (`python -m pip install fonttools`). From the repository root, run `python3 tools/package.py`. The script validates the addon TOC, required assets, saved-variable name and Arcane branding, updates the bundled fonts' internal family names to Arcane UI in the staged package, then creates `dist/Arcane-<version>.zip`. The ZIP contains only the installable `Arcane/` addon folder, not the development tools.

## Install

1. Download the latest `Arcane-<version>.zip` from [Releases](../../releases).
2. Unzip it into your game's `Interface/AddOns` folder. You should end up with `Interface/AddOns/Arcane/Arcane.toc`.
3. The folder must stay named `Arcane`: the game loads it by that name, and your settings are kept under it.

## Commands

| Command | What it does |
| --- | --- |
| `/Arcane` | Opens the options (or click the C on the minimap's edge) |
| `/Arcane move`, `/Arcane lock` | Frees the frames to drag them, then locks them |
| `/Arcane reset` | Puts every frame back in its place |
| `/Arcane language <code>` | Picks the language (`auto` follows the game) |
| `/Arcane timer ...`, `/Arcane numbers ...` | The boss timer's and damage numbers' own settings |
| `/Arcane <part> on/off` | Turns a part on or off |
| `/Arcane talents` | Opens the talent window |
| `/Arcane probe` | Prints what the game gives addons, for reporting what's missing |

## Credits

Arcane is developed as an independent project. Project history and retained upstream attribution are documented in [ATTRIBUTION.md](ATTRIBUTION.md). The bundled fonts in `Arcane/Fonts` are modified from Lora and Noto Sans CJK; their SIL Open Font License notices are retained in `Arcane/Fonts/LICENSE.txt`.

## Working on it

The tools that build and check Arcane UI (a stand-in game client with its tests, the translation, art and font scripts, a preview renderer) are in [`dev`](dev/README.md).
