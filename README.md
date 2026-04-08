# LearnableBy

A World of Warcraft addon that enriches item tooltips with **per-alt** information — showing which of your alts already know a recipe, which could learn it, and which can equip a piece of gear.

![Interface: 12.0.1](https://img.shields.io/badge/Interface-12.0.1%20%28Midnight%29-C69B3A?style=flat-square)
![Version: 3.0.0](https://img.shields.io/badge/Version-3.0.0-informational?style=flat-square)

## What it does

**For recipes, patterns, schematics, and formulae:**
```
── LearnableBy ──
Already knows:    Bjorn ✦ (425/425), Vaelithar (410/425)
Can learn:        Zylara (310/425)
No profession:    Prismfang
```

**For equippable gear** (filtered by class restrictions):
```
Slot:         Two-Hand
Can equip:    Bjorn ✦, Vaelithar
Can't equip:  Zylara, Prismfang
```

**For account-wide collectibles:**
```
Toy:          ✓ Already collected
Appearance:   ✗ Not collected
Mount:        ✓ Already collected
```

(✦ marks the character you're currently logged in on)

### How the alt roster works

Every time you log in on a character, LearnableBy silently records that character's name, realm, class, professions, and known recipe spells into an account-wide `SavedVariables` database. After logging in on each of your alts once, tooltips everywhere will show exactly which characters benefit from an item — no configuration required.

Whenever you learn a new recipe, the addon automatically refreshes that character's known spells via the `TRADE_SKILL_UPDATE` event.

## Installation

1. Download or clone this repository.
2. Copy the `LearnableBy` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/LearnableBy
   ```
3. Launch WoW (or `/reload`) and enable the addon.
4. Log in on each of your alts at least once to build the roster.

## Slash commands

| Command | Description |
|---|---|
| `/lby` or `/lby help` | Show available commands |
| `/lby alts` | List all registered alts, classes, professions, and recipe counts |
| `/lby refresh` | Re-scan the current character's recipes and professions |
| `/lby clear` | Clear the roster and start fresh |
| `/lby about` | Show version info |
| `/learnableby` | Alias for `/lby` |

## What's tracked

**Per-alt (updated each login or `/lby refresh`):**
- Character name, realm, class
- Primary and secondary professions with current skill rank
- All known profession recipe spell IDs (scanned from the spellbook)

**Per recipe / learnable item:**
- Whether each alt already knows the recipe
- Whether each alt has the profession (with rank shown) but hasn't learned it yet
- Whether each alt is missing the profession entirely

**Account-wide (no per-alt data needed):**
- Toys (`PlayerHasToy`)
- Mounts (`C_MountJournal`)
- Transmog appearances (`C_TransmogCollection`)

**Equippable gear:**
- Class restriction filtering for all armor types (cloth, leather, mail, plate) and weapon types
- Universal items (rings, necks, trinkets, cloaks) show all alts

## Compatibility

- **Interface:** 12.0.1 (The War Within / Midnight)
- Uses `OnTooltipSetItem` hook — no `OnUpdate` polling
- Hooks `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1`, `ShoppingTooltip2`
- Listens to `TRADE_SKILL_UPDATE` to keep recipe data current automatically
- SavedVariables: `LearnableByDB` (account-wide)

## Contributing

Pull requests welcome. If a class/weapon mapping is outdated, a new item type should be tracked, or profession subtype names have changed in a patch, please open an issue with a Wowpedia source.

## License

MIT
