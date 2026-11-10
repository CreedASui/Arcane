# Arcane UI

**Current release: v0.6**

A clean, smooth HUD for **Azeroth Survivors** ([wow.aethus.pl](https://wow.aethus.pl)), the World of Warcraft 1.12 roguelike. Everything is drawn in one look (dark glass, a gold rail, the timer's metal) and steps aside while you pick your cards.

## Preview

![Arcane UI running in Azeroth Survivors](docs/images/ArcaneUI.png)

## What's in it

- **Boss timer:** a themed countdown to each boss, with the run's time.
- **Arcane Nameplates:** Arcane's built-in replacement for the game's enemy plates, with half-size regular enemies, Arcane's shared FRIZQT typography and layered health bars; bosses and guardians keep their full size with the same styling and their debuffs below. The game's **V** key controls plate visibility, and Arcane's replacement follows it. Health numbers can be shown or hidden independently in Arcane Nameplates options.
- **Boss and mini-boss bars:** red bars with real health numbers and the debuffs on them.
- **Skulls:** a horned skull with red eyes floating over each boss, and a plainer one over each guardian, wherever it is on the screen, large when near and small when far.
- **Party shields:** detected absorbs show as a glass-and-stripe overlay on each party health bar.
- **Downed friends (co-op):** a warning and a sound when a friend goes down, a glowing mark with their class crest where you can revive them, and an arrow at the screen's edge with the distance while they're off it.
- **UI style:** choose Classic Arcane, Hybrid or Full Class in Arcane Options. Classic keeps the bronze Arcane treatment and supplied gold dragon/A artwork; Hybrid adds class treatment to the skill bar only, with the Arcane A medallion on the left and the active class crest on the right; Full Class carries the active class palette across the Arcane UI—including your frame, minimap, Stats, Damage meter, Luck and shared panels—alongside class-specific skill-bar rails and paired emblems. Your abilities (with rank-up flashes), jewelry and XP remain in the shared bar renderer.
- **Kills, gold and cache:** in the panel; hover for what each gives.
- **Loot pop-up:** each drop appears with its icon, name and rarity color; earned marks appear as their own notification. Up to three stack, and the game's own pop-up returns when Loot is turned off.
- **Stored level-ups:** a glowing Level Up! button with how many wait (with the game's Store Level-Ups on).
- **Damage meter:** Damage Done, Healing Done, Boss Damage, Party DPS and Damage Taken, with icons, per second and shares. Resizable from any edge.
- **Luck medallion:** your luck and the odds of a Rare, Epic or Legendary card.
- **Minimap:** a metal ring, your local time, the caches and the guardians' lairs (with the time until each empty lair fills); cache and lair pins fade when they overlap your arrow. The **A** button on its edge opens Arcane Options; use the **Luck** and **Damage meter** toggles in that menu to show or hide those windows.
- **Character window:** gear slots lit in their rarity color and your run's stats grouped beside it (zeros dimmed, changes flashing); its Talents tab opens Arcane UI's talent window (your trees, points and learned talents with their ranks).
- **Standalone Stats window:** independently track the run's 29 stats in customizable groups; choose which values appear and see changes flash green or red.
- **Chat:** dressed to match, and kept clear of the skill bar's full Arcane medallion.
- **Damage numbers:** calm and readable; a spell hitting a crowd adds up into one number a second, and a number that keeps stacking grows.
- **Native game text:** positive buff/cast and healing feedback use Arcane's known-good text colors and font. Zone announcements such as “Tower of Azora” remain completely original; gameplay notices keep their existing Arcane theme.
- **Damage-number customization:** six optional custom typefaces and six selectable critical-hit backdrops (Flame, Frost, Arcane, Holy, Shadow and Storm); existing defaults remain unchanged.
- **Run summary:** when a run ends, your time, level, kills, bosses, damage dealt and taken, gold and caches on one panel.

Every optional HUD part can be turned on or off, sized and moved. Arcane Nameplates follows the game's native **V** visibility control instead of adding a second toggle.

**Languages:** English, French, German, Spanish, Portuguese, Chinese, Russian, Japanese, Korean, Polish and Turkish, picked from the options or with `/Arcane language`.

## Repository layout and packaging

The addon's load map, `Arcane.toc`, stays at the repository root. Lua modules are grouped by responsibility under `Core/`, `Timer/`, `Numbers/`, `SkillBar/`, `Frames/`, `Minimap/`, `Windows/`, `Nameplates/`, `Loot/` and `Locales/`. `Art/` and `Fonts/` also stay at the addon root so the game's existing asset paths remain unchanged. The repository itself is not the install folder. For a release ZIP, place the root files and all module and asset folders inside a top-level folder named `Arcane/`, then zip that folder. The ZIP must open to `Arcane/Arcane.toc` — never a branch-named folder such as `Arcane-main/`.

The release asset is named `ArcaneV0.6.zip`. GitHub Actions runs the Core, Numbers, timer and skill-bar architecture audits, compiles every Lua chunk with Lua 5.1, and recursively creates a test ZIP for pull requests to `main`. Those checks do not replace a live test in the client's Lua 5.0 runtime.

## Install

1. Download `ArcaneV0.6.zip` from [Releases](../../releases).
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

## Credits

Arcane is developed as an independent project. Project history and retained upstream attribution are documented in [ATTRIBUTION.md](ATTRIBUTION.md). The bundled fonts in `Fonts/` are modified from Lora and Noto Sans CJK; their SIL Open Font License notices are retained in [`Fonts/LICENSE.txt`](Fonts/LICENSE.txt).

## Project files

The source modules are grouped by subsystem; see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the module map and load-order rules. Artwork is in [`Art/`](Art/), bundled fonts and their license are in [`Fonts/`](Fonts/), and the repository preview is in [`docs/images/`](docs/images/).
