--[[
  LearnableBy — WoW Addon
  Shows which classes can equip an item and what slot it occupies, directly in the item tooltip.

  Author: fstubner
  Version: 1.0.0
  Interface: 120001 (The War Within / Midnight)
--]]

-- ─── Slot names ──────────────────────────────────────────────────────────────

local SLOT_NAMES = {
  INVTYPE_HEAD          = "Head",
  INVTYPE_NECK          = "Neck",
  INVTYPE_SHOULDER      = "Shoulder",
  INVTYPE_BODY          = "Shirt",
  INVTYPE_CHEST         = "Chest",
  INVTYPE_ROBE          = "Chest",
  INVTYPE_WAIST         = "Waist",
  INVTYPE_LEGS          = "Legs",
  INVTYPE_FEET          = "Feet",
  INVTYPE_WRIST         = "Wrist",
  INVTYPE_HAND          = "Hands",
  INVTYPE_FINGER        = "Finger",
  INVTYPE_TRINKET       = "Trinket",
  INVTYPE_CLOAK         = "Back",
  INVTYPE_WEAPON        = "One-Hand",
  INVTYPE_SHIELD        = "Off-Hand",
  INVTYPE_2HWEAPON      = "Two-Hand",
  INVTYPE_WEAPONMAINHAND = "Main Hand",
  INVTYPE_WEAPONOFFHAND  = "Off Hand",
  INVTYPE_HOLDABLE       = "Held in Off-Hand",
  INVTYPE_RANGED         = "Ranged",
  INVTYPE_RANGEDRIGHT    = "Ranged",
  INVTYPE_THROWN         = "Thrown",
  INVTYPE_RELIC          = "Relic",
  INVTYPE_TABARD         = "Tabard",
  INVTYPE_BAG            = "Bag",
  INVTYPE_QUIVER         = "Quiver",
  INVTYPE_AMMO           = "Ammo",
  INVTYPE_NON_EQUIP      = nil,
  INVTYPE_NON_EQUIP_IGNORE = nil,
}

-- ─── Armor class → class list ─────────────────────────────────────────────────

local ARMOR_CLASSES = {
  [1] = { "Mage", "Priest", "Warlock" },
  [2] = { "Demon Hunter", "Druid", "Monk", "Rogue" },
  [3] = { "Evoker", "Hunter", "Shaman" },
  [4] = { "Death Knight", "Paladin", "Warrior" },
}

-- ─── Weapon subclass → class list ────────────────────────────────────────────

local WEAPON_CLASSES = {
  [0]  = { "Death Knight", "Druid", "Hunter", "Paladin", "Rogue", "Shaman", "Warrior", "Evoker" },
  [1]  = { "Death Knight", "Druid", "Hunter", "Paladin", "Shaman", "Warrior" },
  [2]  = { "Hunter", "Rogue", "Warrior" },
  [3]  = { "Hunter", "Rogue", "Warrior" },
  [4]  = { "Death Knight", "Druid", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warrior" },
  [5]  = { "Death Knight", "Druid", "Paladin", "Shaman", "Warrior" },
  [6]  = { "Death Knight", "Druid", "Hunter", "Monk", "Paladin", "Warrior", "Evoker" },
  [7]  = { "Death Knight", "Demon Hunter", "Mage", "Paladin", "Rogue", "Warlock", "Warrior", "Evoker" },
  [8]  = { "Death Knight", "Paladin", "Warrior" },
  [9]  = { "Demon Hunter", "Rogue", "Warrior" },
  [10] = { "Druid", "Hunter", "Mage", "Monk", "Priest", "Shaman", "Warlock", "Warrior" },
  [13] = { "Death Knight", "Druid", "Hunter", "Monk", "Rogue", "Shaman", "Warrior" },
  [14] = { "Hunter", "Mage", "Priest", "Rogue", "Warlock", "Warrior" },
  [15] = { "Death Knight", "Demon Hunter", "Druid", "Hunter", "Mage", "Monk", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" },
  [16] = { "Rogue", "Warrior" },
  [18] = { "Hunter", "Rogue", "Warrior" },
  [19] = { "Mage", "Priest", "Warlock" },
  [20] = { "Everyone" },
}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function sortedUnique(t)
  local seen = {}
  local out  = {}
  for _, v in ipairs(t) do
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out)
  return out
end

local function join(t, sep)
  return table.concat(t, sep)
end

local function colorText(r, g, b, text)
  return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

local function GOLD(text)  return colorText(1.00, 0.82, 0.00, text) end
local function GREY(text)  return colorText(0.60, 0.60, 0.60, text) end
local function GREEN(text) return colorText(0.10, 0.90, 0.10, text) end

-- ─── Core tooltip logic ───────────────────────────────────────────────────────

local function addLearnableByLines(tooltip, itemLink)
  if not itemLink then return end

  local itemName, _, _, _, _, itemType, itemSubType,
        _, itemEquipLoc, _, _, itemClassID, itemSubClassID =
    GetItemInfo(itemLink)

  if not itemName then return end

  local slotName = SLOT_NAMES[itemEquipLoc]
  if slotName then
    tooltip:AddLine(GREY("Slot: ") .. GOLD(slotName))
  end

  local classList

  if itemClassID == Enum.ItemClass.Armor then
    if itemSubClassID == 0 then
      classList = { "Everyone" }
    else
      classList = ARMOR_CLASSES[itemSubClassID]
    end
  elseif itemClassID == Enum.ItemClass.Weapon then
    classList = WEAPON_CLASSES[itemSubClassID]
  end

  if classList then
    local unique = sortedUnique(classList)
    local label  = (#unique == 1 and unique[1] == "Everyone")
        and GREEN("Everyone")
        or  GREEN(join(unique, ", "))
    tooltip:AddLine(GREY("Learnable by: ") .. label)
  end
end

-- ─── Tooltip hooks ───────────────────────────────────────────────────────────

local function hookTooltip(tooltip)
  tooltip:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    addLearnableByLines(self, link)
  end)
end

hookTooltip(GameTooltip)
hookTooltip(ItemRefTooltip)
hookTooltip(ShoppingTooltip1)
hookTooltip(ShoppingTooltip2)

-- ─── Slash commands ───────────────────────────────────────────────────────────

SLASH_LEARNABLEBY1 = "/learnableby"
SLASH_LEARNABLEBY2 = "/lby"

SlashCmdList["LEARNABLEBY"] = function(msg)
  local cmd = strtrim(msg):lower()
  if cmd == "help" or cmd == "" then
    print(GOLD("LearnableBy") .. " — commands:")
    print("  " .. GOLD("/lby help") .. "  — show this help")
    print("  " .. GOLD("/lby about") .. " — show version info")
  elseif cmd == "about" then
    print(GOLD("LearnableBy") .. " v1.0.0 by fstubner")
    print("Adds class and slot information to item tooltips.")
  else
    print(GOLD("LearnableBy") .. ": unknown command. Type " .. GOLD("/lby help") .. " for options.")
  end
end
