# Arcane UI: development tools

Everything used to build and check Arcane UI outside the game. Run the commands below from this
`dev` folder; the addon itself is in `../Arcane`.

## What you need

- **Lua 5.0** (the game's own Lua): build it from [lua-5.0.3](https://www.lua.org/ftp/lua-5.0.3.tar.gz)
  (`make` in its folder; the interpreter lands in `bin/lua`). Below it's called `lua50`.
- **Python 3** with `numpy`, `Pillow`, `scipy`, `fontTools` and, for the renderer, `opencv-python`.

## The stand-in game client and its tests

`arcane/mock_arcane.lua` is a stand-in for the game: its widgets (only the calls the 1.12 client really
has: a missing one is an error, see `engine_methods.lua`), the Azeroth Survivors API as the game
answers it, and Azeroth Survivors' character window (`arcane/mock_char.lua`). `bt/sim.lua` plays runs
on it: bosses, guardians, cards, deaths, victory.

| Command | What it checks |
| --- | --- |
| `lua50 arcane/tests.lua . ../Arcane` | Every part, end to end (500+ checks) |
| `lua50 arcane/loot_tests.lua . ../Arcane` | Loot and mark notifications, duplicate chat lines, and restoring the game's own pop-up |
| `lua50 arcane/timer_tests.lua . ../Arcane` | The boss timer |
| `lua50 arcane/numbers_harness.lua . ../Arcane/Numbers.lua` | The damage numbers (`CROWD=1` for crowds) |
| `lua50 arcane/smoke.lua . ../Arcane <out folder>` | A long run with everything on, no errors |
| `lua50 arcane/globals.lua . ../Arcane` | No stray globals (`this`, `event` and `arg1` are the game's) |
| `lua50 arcane/overflow.lua . ../Arcane` | No text spilling out of its place, in all 11 languages |
| `python3 arcane/locale_check.py ../Arcane` | Every phrase translated, its `{1}` slots kept |
| `python3 ../tools/package.py --output /tmp/Arcane-test.zip` | TOC/assets, no duplicate root sources, Lua 5.0 varargs, Arcane namespace, ColorSelect API and ZIP integrity |

## Pictures of it

The `arcane/*prev.lua` scripts set a scene and write a dump; `arcane/render_arcane.py` draws it:

```
lua50 arcane/charprev.lua . ../Arcane out
python3 arcane/render_arcane.py out/char.txt out/char.png 2 0 150 590 720
```

`arcane/classprev.lua` writes the party in all nine class colors (`out/class1..3.txt`); `arcane/guardprev.lua`
one boss and four guardians (`out/guards.txt`); `arcane/cardsprev.lua` the character window behind the
level-up cards (`out/cards.txt`). `arcane/talprev.lua` opens the talent window (`out/talents.txt`); `arcane/numprev.lua` a single hit beside a
stacked DoT (`out/numbers.txt`). `arcane/partyprev.lua` sets friends down (a revive mark and an edge arrow), the Level Up! button and the
meter on Damage Taken (`out/party.txt`), then the run's summary (`out/summary.txt`); `arcane/rankprev.lua`
the skill bar's rank boxes. `arcane/skullprev.lua` sets a boss fight with the skulls over two bosses and writes `out/skulls.txt`, and
the options window in `out/hub.txt`.

A 1920x1080 game screenshot at `arcane/shot.png` (or named in `ARCANE_SHOT`) is drawn behind it,
with its action bar icons standing in for the game's; without one, a plain backdrop. The game's
fonts are stood in for by system ones (`bt/render_bt.py`).

## Translations

- French, German, Spanish and Portuguese are rows in `../Arcane/Locale.lua`: English first.
- Chinese, Russian, Japanese, Korean, Polish and Turkish are numbered lists in `tr/<code>.py`, one
  per line of `en_keys.txt` (the English, in order). `python3 tr/gen.py ../Arcane` writes
  `../Arcane/Locale_<code>.lua` from them.
- A new phrase: add its row to `Locale.lua`, add its English to the end of `en_keys.txt`, its
  number to each `tr/<code>.py`, then `gen.py` and `locale_check.py`. The `tr/add_*.py` scripts
  are past examples that do all of that at once.
- New letters (Chinese, Japanese, Korean, Cyrillic, Polish, Turkish) must be in the bundled fonts:
  rebuild them with the scripts in `font/` if a check finds one missing.

## Art

All of Arcane UI's art is original and drawn by these scripts (numpy and Pillow), written as BLP2
(uncompressed) with PNG copies: `python3 art/make_artN.py <blp folder> <png folder>`. Each script's
first lines say what it draws; later ones replace earlier ones where they share a name.
`art/make_dragon.py` paints the skill bar's dragons. Copy the BLPs into `../Arcane/Art`.

## Fonts

`font/build_font.py` (Chinese, Japanese, Korean, from Noto Sans CJK) and `font/build_latin.py`
(Latin and Cyrillic, from Lora) make `../Arcane/Fonts`. They read the source fonts from the
system, or from `NOTO_CJK` and `LORA_VARIABLE`. Both sources are under the SIL Open Font License
(`font/*-src`).
