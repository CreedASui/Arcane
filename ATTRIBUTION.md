# Attribution and project history

Arcane is an independent continuation and rework initialized from the CreedUI for Azeroth Survivors codebase in JamieeLee's fork:

- Upstream project: https://github.com/CreedASui/CreedUI-for-AS-
- Working source fork used as the starting point: https://github.com/JamieeLee/CreedUI-for-AS-

The repository was copied into a separate project rather than created as another GitHub fork. Existing source code, artwork and assets were retained as the starting foundation and have been rebranded and modified. Original authorship and any applicable terms for upstream material remain with their respective rights holders. This note records provenance; it does not grant or change any license.

The bundled font files are modified versions of Lora and Noto Sans CJK. Their detailed copyright and SIL Open Font License notices are retained in [Fonts/LICENSE.txt](Fonts/LICENSE.txt).

## Nameplate integration

The Tiny Plates feature adapts the MIT-licensed nameplate implementation by Valorless from [Valorless/ASTinyPlates](https://github.com/Valorless/ASTinyPlates). Its runtime code, settings, frame identifiers and saved-variable keys have been integrated into Arcane's own namespace and options system. The original MIT notice is retained in [ArcanePlates-LICENSE.txt](ArcanePlates-LICENSE.txt). This credit records source provenance; it does not imply that the upstream project is part of or endorses Arcane.

## Class skill-bar artwork

The optional nine-class skill-bar treatment reuses the class emblems, crests and rail textures from the synced `JamieeLee/CreedUI-for-AS-` working base. Those assets retain the same project provenance and original rights notices described above; Arcane keeps its own panel branding, slot renderer and settings namespace.

The Hybrid-only Arcane medallion is original generated artwork adapted for Arcane's identity. Its forged-metal base and separately colorized gem layer are new Hybrid assets; the original Classic Arcane sigil is unchanged. The class-specific right-hand emblems remain sourced from the synced Creed reference above.

## Damage-number fonts and critical-hit artwork

The optional damage-number font choices include six bundled fonts adapted from the corresponding open font releases. Their original copyright notices and SIL Open Font License terms are retained in [Fonts/NumberFonts-LICENSE.txt](Fonts/NumberFonts-LICENSE.txt); the font files are not relicensed by Arcane.

The optional critical-hit backdrops reuse six effect textures from the synced Creed working base. They are only used behind critical damage numbers when selected; they do not recolor Arcane's panels, bars, medallions, or overall bronze/gold theme.
