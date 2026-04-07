# LearnableBy

A World of Warcraft addon that enriches item tooltips with information specific to **your account** — showing which of your alts can equip an item and whether you’ve already collected a toy, mount, or transmog appearance.

![Interface: 12.0.1](https://img.shields.io/badge/Interface-12.0.1%20%28Midnight%29-C69B3A?style=flat-square)
![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-informational?style=flat-square)

## What it does

**For equippable gear:**
```
Slot:         Two-Hand
Can equip:    Bjorn ❆, Vaelithar
Can't equip:  Zylara, Prismfang
```
(❆ marks the character you're currently playing)

**For collectibles (toys, transmog appearances):**
```
Toy:          ✓ Already collected
Appearance:   ✗ Not collected
```

### How the alt roster works

Every time you log in on a character, LearnableBy silently registers that character (name, realm, class) into an account-wide SavedVariables database. After logging in on all your alts once, tooltips everywhere will show exactly which of your characters benefit from an item — no configuration required.

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
| `/lby alts` | List all registered alts and their classes |
| `/lby clear` | Clear the roster and start fresh |
| `/lby about` | Show version info |
| `/learnableby` | Alias for `/lby` |

## What’s tracked

- **Equippable items** (armor, weapons): filtered by class restrictions — cloth, leather, mail, plate, and all weapon types
- **Toys**: uses `PlayerHasToy()` — account-wide
- **Transmog appearances**: uses `C_TransmogCollection.PlayerKnowsSource()` — account-wide
- **Universal items** (rings, necks, trinkets, cloaks): skips class filtering, shows all alts

## Compatibility

- **Interface:** 12.0.1 (The War Within / Midnight)
- Uses `OnTooltipSetItem` hook — no `OnUpdate` polling
- Hooks `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1`, `ShoppingTooltip2`
- SavedVariables: `LearnableByDB` (account-wide)

## Contributing

Pull requests welcome. If a class/weapon mapping is outdated or a new item type should be tracked, please open an issue with a Wowpedia source.

## License

MIT
