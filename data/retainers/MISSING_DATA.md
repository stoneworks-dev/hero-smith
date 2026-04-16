# Retainer Data — Status

## Overview
107 abilities across 21 retainers. All retainer-specific advancement abilities are at levels 7 and 10 (NOT level 4). Only Angulotl Hopper and Radenwight Sidekick have level 4 retainer-specific abilities. At level 4, other retainers use role advancement abilities instead.

## Resolved Issues

### Round 1 (`fix_retainer_levels.py`)
- **15 abilities** had wrong `advancement_level` values. All corrected.
- **2 duplicate abilities** deleted, **1 renamed**.
- **19 retainer advancement maps** updated.

### Round 2 (`fix_retainer_levels_round2.py`)
- **Spew Death** (The Nameless): advancement_level 7 → 10.
- **4 new level 7 advancement abilities** added from book images (Looming Wings, Unholy Attraction, Hangry Frenzy, Blood Surge).
- **2 new base abilities** added (Magic Arrows, Flurry of Fangs).
- **4 retainer advancement maps** updated.

### Round 3 (`fix_retainer_levels_round3.py`)
- **12 abilities** moved from level 4 to correct levels (9 to level 7, 3 to level 10).
- **11 retainer advancement maps** updated — removed all incorrect level 4 entries.

## Current State — All Complete
All 21 retainers now have their expected advancement ability slots filled:

| Retainer | Start | Slots |
|----------|-------|-------|
| Angulotl Hopper | 1 | 4/7/10 |
| Radenwight Sidekick | 1 | 4/7/10 |
| High Elf Weatherwise | 1 | 7/10 |
| Wode Elf Arrowswift | 1 | 7/10 |
| Goblin Guide | 1 | 7/10 |
| Human Warrior | 1 | 7/10 |
| Kobold Shieldbearer | 1 | 7/10 |
| Orc Charger | 1 | 7/10 |
| Undead Servitor | 1 | 7/10 |
| Unquiet Spirit | 1 | 7/10 |
| Dwarf Mortar | 1 | 7/10 |
| Gnoll Gnasher | 2 | 7/10 |
| Bugbear Commando | 2 | 7/10 |
| Minotaur Gorer | 3 | 7/10 |
| Time Raider Mind Healer | 3 | 7/10 |
| Shadow Elf Shade | 4 | 7/10 |
| Hobgoblin Flameslinger | 4 | 7/10 |
| Vampire Rebel | 4 | 7/10 |
| Devil Defector | 5 | 7/10 |
| Troll Mercenary | 5 | 7/10 |
| The Nameless | 6 | 7/10 |

## Parser Root Cause Analysis
The parser consistently misassigned advancement levels because of how the PDF text extraction works:

1. **Two-column interleaving**: The PDF has a two-column layout. The extraction tool reads left-to-right across the page, interleaving lines from both columns. A "Level 7 Retainer Advancement Ability" header from the right column may appear next to ability text from the left column.

2. **Garbled level numbers**: The `ADV_MARKER_RE` regex picks up "Level X Retainer Advancement Ability" markers, but the level number `X` in the extracted text is often wrong — a "Level 4" marker in the extracted text was actually "Level 7" or "Level 10" in the original PDF because the digits got swapped across columns.

3. **Proximity-based assignment**: The `assign_advancement_abilities()` function trusts the level number from the marker and assigns abilities to whichever retainer is nearest in the text. Since both the level AND the position are unreliable, abilities end up at wrong levels AND sometimes assigned to wrong retainers.

4. **No level 4 retainer abilities (for most retainers)**: The parser assumed level 4 was a valid retainer advancement level, but most retainers only have abilities at levels 7 and 10. At level 4, players pick from role advancement abilities instead.

**Conclusion**: The PDF extraction approach cannot reliably determine advancement levels from the text alone. Manual verification against the book is required for levels.
