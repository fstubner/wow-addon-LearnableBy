# LearnableBy

A World of Warcraft addon that adds **class** and **slot** information directly to item tooltips — so you always know who can equip something without leaving the game or alt-tabbing to Wowhead.

![Interface: 12.0.1](https://img.shields.io/badge/Interface-12.0.1%20%28Midnight%29-C69B3A?style=flat-square)
![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

## What it does

When you hover over any equippable item, LearnableBy appends two lines to the tooltip:

```
Slot:          Two-Hand
Learnable by:  Death Knight, Paladin, Warrior
```

It handles all armour types (cloth, leather, mail, plate), all weapon types (axes, swords, staves, bows, crossbows, daggers, wands, fist weapons, polearms, warglaives, and more), and universal items like rings, trinkets, and cloaks. Tooltips work everywhere — item links in chat, the auction house, character inspect, dungeon journal, and loot frames.

## Installation

1. Download or clone this repository.
2. Copy the `LearnableBy` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/LearnableBy
   ```
3. Launch WoW (or `/reload` if already in-game) and enable the addon in the AddOns menu.

## Slash commands

| Command | Description |
|---|---|
| `/lby` or `/lby help` | Show available commands |
| `/lby about` | Show version info |
| `/learnableby` | Alias for `/lby` |

## Compatibility

- **Interface:** 12.0.1 (The War Within / Midnight)
- Uses the modern `OnTooltipSetItem` hook — no `OnUpdate` polling
- Hooks `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1`, and `ShoppingTooltip2`
- No dependencies; no saved variables

## Contributing

Pull requests welcome. If a class/weapon subclass mapping is wrong or a new weapon type is added in a patch, please open an issue or PR with a fix and the relevant Wowpedia source.

## License

MIT
