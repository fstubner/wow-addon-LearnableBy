--[[
  LearnableBy — WoW Addon
  Enriches item tooltips with per-alt information:
    • Which of your alts can equip gear (filtered by class restrictions)
    • Which alts already know a recipe / pattern / schematic
    • Which alts have the profession and skill to learn a recipe
    • Account-wide collectible status (toys, mounts, transmog appearances)

  Author: fstubner
  Version: 3.0.0
  Interface: 120001 (The War Within / Midnight)

  SavedVariables layout (account-wide):
    LearnableByDB = {
      alts = {
        ["CharName-RealmName"] = {
          name        = "CharName",
          realm       = "RealmName",
          classFile   = "WARRIOR",   -- uppercase WoW classFile
          level       = 80,
          professions = {
            ["Blacksmithing"] = { rank = 425, maxRank = 425 },
            ...
          },
          knownSpells = {
            [spellID] = true,        -- profession recipe spell IDs this alt knows
            ...
          },
        },
        ...
      }
    }
--]]

local ADDON_NAME = "LearnableBy"
local VERSION    = "3.0.0"

-- ─── Class data ───────────────────────────────────────────────────────────────

local CLASS_DISPLAY = {
  DEATHKNIGHT = "Death Knight",
  DEMONHUNTER = "Demon Hunter",
  DRUID       = "Druid",
  EVOKER      = "Evoker",
  HUNTER      = "Hunter",
  MAGE        = "Mage",
  MONK        = "Monk",
  PALADIN     = "Paladin",
  PRIEST      = "Priest",
  ROGUE       = "Rogue",
  SHAMAN      = "Shaman",
  WARLOCK     = "Warlock",
  WARRIOR     = "Warrior",
}

-- LE_ITEM_CLASS_ARMOR subclass IDs → which display-name classes can equip them
local ARMOR_CLASSES = {
  [1] = { "Mage", "Priest", "Warlock" },
  [2] = { "Demon Hunter", "Druid", "Monk", "Rogue" },
  [3] = { "Evoker", "Hunter", "Shaman" },
  [4] = { "Death Knight", "Paladin", "Warrior" },
}

-- LE_ITEM_CLASS_WEAPON subclass IDs → which display-name classes can equip them
local WEAPON_CLASSES = {
  [0]  = { "Death Knight", "Druid", "Evoker", "Hunter", "Paladin", "Rogue", "Shaman", "Warrior" },
  [1]  = { "Death Knight", "Druid", "Hunter", "Paladin", "Shaman", "Warrior" },
  [2]  = { "Hunter", "Rogue", "Warrior" },
  [3]  = { "Hunter", "Rogue", "Warrior" },
  [4]  = { "Death Knight", "Druid", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warrior" },
  [5]  = { "Death Knight", "Druid", "Paladin", "Shaman", "Warrior" },
  [6]  = { "Death Knight", "Druid", "Evoker", "Hunter", "Monk", "Paladin", "Warrior" },
  [7]  = { "Death Knight", "Demon Hunter", "Evoker", "Mage", "Paladin", "Rogue", "Warlock", "Warrior" },
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

local SLOT_NAMES = {
  INVTYPE_HEAD           = "Head",
  INVTYPE_NECK           = "Neck",
  INVTYPE_SHOULDER       = "Shoulder",
  INVTYPE_BODY           = "Shirt",
  INVTYPE_CHEST          = "Chest",
  INVTYPE_ROBE           = "Chest",
  INVTYPE_WAIST          = "Waist",
  INVTYPE_LEGS           = "Legs",
  INVTYPE_FEET           = "Feet",
  INVTYPE_WRIST          = "Wrist",
  INVTYPE_HAND           = "Hands",
  INVTYPE_FINGER         = "Finger",
  INVTYPE_TRINKET        = "Trinket",
  INVTYPE_CLOAK          = "Back",
  INVTYPE_WEAPON         = "One-Hand",
  INVTYPE_SHIELD         = "Off-Hand",
  INVTYPE_2HWEAPON       = "Two-Hand",
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
}

-- ─── Saved variables / alt roster ────────────────────────────────────────────

LearnableByDB = nil

local function initDB()
  if not LearnableByDB then LearnableByDB = {} end
  if not LearnableByDB.alts then LearnableByDB.alts = {} end
end

-- Scan the current character's profession spellbook tabs and collect all known
-- recipe spell IDs.  We walk every profession spellbook tab (anything that is
-- not a combat tab) and record each SPELL entry's spell ID.
local function scanKnownProfessionSpells()
  local known = {}
  local numTabs = GetNumSpellTabs()
  for t = 1, numTabs do
    local tabName, _, offset, numSpells, isGuild = GetSpellTabInfo(t)
    if isGuild then break end  -- guild-bank tab, stop

    -- Profession tabs don't have a flag but their names match profession names.
    -- We record every non-flyout, non-passive spell ID to stay future-proof.
    for i = offset + 1, offset + numSpells do
      local spellType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
      if spellType == "SPELL" and spellID and spellID > 0 then
        known[spellID] = true
      end
    end
  end
  return known
end

-- Collect primary and secondary profession info for the current character.
local function scanProfessions()
  local profs = {}
  -- GetProfessions returns up to 2 primary + 4 secondary slot indices
  local slots = { GetProfessions() }
  for _, idx in ipairs(slots) do
    if idx then
      local name, _, rank, maxRank = GetProfessionInfo(idx)
      if name and name ~= "" then
        profs[name] = { rank = rank, maxRank = maxRank }
      end
    end
  end
  return profs
end

local function registerSelf()
  initDB()
  local name      = UnitName("player")
  local realm     = GetRealmName()
  local classFile = select(2, UnitClass("player"))
  local level     = UnitLevel("player")
  local key       = name .. "-" .. realm

  LearnableByDB.alts[key] = {
    name        = name,
    realm       = realm,
    classFile   = classFile,
    level       = level,
    professions = scanProfessions(),
    knownSpells = scanKnownProfessionSpells(),
  }
end

local function getAltRoster()
  if not LearnableByDB or not LearnableByDB.alts then return {} end
  local roster = {}
  for _, alt in pairs(LearnableByDB.alts) do
    roster[#roster + 1] = alt
  end
  table.sort(roster, function(a, b) return a.name < b.name end)
  return roster
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function join(t, sep)
  return table.concat(t, sep)
end

local function colorText(r, g, b, text)
  return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

local function GOLD(text)   return colorText(1.00, 0.82, 0.00, text) end
local function GREY(text)   return colorText(0.60, 0.60, 0.60, text) end
local function GREEN(text)  return colorText(0.10, 0.90, 0.10, text) end
local function YELLOW(text) return colorText(1.00, 1.00, 0.20, text) end
local function RED(text)    return colorText(0.90, 0.20, 0.20, text) end
local function BLUE(text)   return colorText(0.40, 0.80, 1.00, text) end

-- Return the current character's roster label (includes realm suffix + ✦)
local function altLabel(alt, currentRealm)
  local label = alt.name
  if alt.realm ~= currentRealm then
    label = alt.name .. " (" .. alt.realm .. ")"
  end
  return label
end

local function isCurrentChar(alt)
  return alt.name == UnitName("player") and alt.realm == GetRealmName()
end

-- ─── Recipe / learnable item logic ───────────────────────────────────────────

-- Returns the spell ID that an item teaches, or nil if it doesn't teach one.
-- GetItemSpell(link) → spellName, spellID  (available in modern WoW)
local function getTeachSpellID(itemLink)
  if not itemLink then return nil end
  local _, spellID = GetItemSpell(itemLink)
  return spellID  -- may be nil
end

-- Build tooltip lines for a recipe / learnable item.
-- Shows per-alt: ✓ Already knows it / ✓ Can learn it / ✗ Missing profession
local function addRecipeLines(tooltip, itemLink, professionName, teachSpellID)
  local roster = getAltRoster()
  local currentRealm = GetRealmName()

  if #roster == 0 then
    tooltip:AddLine(GREY("Log in on each alt to see per-alt recipe status."))
    return
  end

  local alreadyKnow = {}
  local canLearn    = {}
  local missing     = {}

  for _, alt in ipairs(roster) do
    local label = altLabel(alt, currentRealm)
    if isCurrentChar(alt) then label = label .. " ✦" end

    -- Check if alt already knows the recipe
    local knows = teachSpellID and alt.knownSpells and alt.knownSpells[teachSpellID]

    if knows then
      alreadyKnow[#alreadyKnow + 1] = label
    elseif professionName and alt.professions and alt.professions[professionName] then
      -- Alt has the profession but doesn't know this recipe yet
      local pd = alt.professions[professionName]
      canLearn[#canLearn + 1] = label .. " (" .. pd.rank .. "/" .. pd.maxRank .. ")"
    else
      -- Alt is missing the profession entirely
      missing[#missing + 1] = label
    end
  end

  if #alreadyKnow > 0 then
    tooltip:AddLine(GREY("Already knows: ") .. GREEN(join(alreadyKnow, ", ")))
  end
  if #canLearn > 0 then
    tooltip:AddLine(GREY("Can learn: ")     .. YELLOW(join(canLearn, ", ")))
  end
  if #missing > 0 then
    tooltip:AddLine(GREY("No profession: ") .. RED(join(missing, ", ")))
  end
end

-- ─── Equippable item logic ────────────────────────────────────────────────────

local function addEquipLines(tooltip, itemEquipLoc, itemClassID, itemSubClassID)
  local equippableClasses

  if itemClassID == Enum.ItemClass.Armor then
    if itemSubClassID == 0 then
      equippableClasses = nil  -- rings, necks, cloaks, trinkets: anyone
    else
      local classList = ARMOR_CLASSES[itemSubClassID]
      if classList then
        equippableClasses = {}
        for _, c in ipairs(classList) do equippableClasses[c] = true end
      end
    end
  elseif itemClassID == Enum.ItemClass.Weapon then
    local classList = WEAPON_CLASSES[itemSubClassID]
    if classList then
      if classList[1] == "Everyone" then
        equippableClasses = nil
      else
        equippableClasses = {}
        for _, c in ipairs(classList) do equippableClasses[c] = true end
      end
    end
  end

  local roster = getAltRoster()
  local currentRealm = GetRealmName()

  if #roster == 0 then
    -- No roster yet — fall back to raw class list
    if equippableClasses then
      local classList = {}
      for c in pairs(equippableClasses) do classList[#classList + 1] = c end
      table.sort(classList)
      tooltip:AddLine(GREY("Equippable by: ") .. YELLOW(join(classList, ", ")))
      tooltip:AddLine(GREY("(Log in on each alt to see your roster)"))
    end
    return
  end

  local canUse  = {}
  local cantUse = {}

  for _, alt in ipairs(roster) do
    local display  = CLASS_DISPLAY[alt.classFile]
    local eligible = (equippableClasses == nil) or (display and equippableClasses[display])
    local label    = altLabel(alt, currentRealm)
    if isCurrentChar(alt) then label = label .. " ✦" end

    if eligible then
      canUse[#canUse + 1] = label
    else
      cantUse[#cantUse + 1] = label
    end
  end

  if #canUse > 0 then
    tooltip:AddLine(GREY("Can equip: ")    .. GREEN(join(canUse, ", ")))
  end
  if #cantUse > 0 then
    tooltip:AddLine(GREY("Can't equip: ") .. RED(join(cantUse, ", ")))
  end
end

-- ─── Main tooltip handler ─────────────────────────────────────────────────────

local function addLearnableByLines(tooltip, itemLink)
  if not itemLink then return end

  local itemName, _, _, _, _, itemTypeName, itemSubTypeName,
        _, itemEquipLoc, _, itemID, itemClassID, itemSubClassID =
    GetItemInfo(itemLink)

  if not itemName then return end

  -- ── Slot (equippable items) ────────────────────────────────────────────────
  local slotName = SLOT_NAMES[itemEquipLoc]
  if slotName then
    tooltip:AddLine(GREY("Slot: ") .. GOLD(slotName))
  end

  -- ── Account-wide collectibles ─────────────────────────────────────────────
  if itemID then
    -- Toy
    if PlayerHasToy and PlayerHasToy(itemID) then
      tooltip:AddLine(GREY("Toy: ") .. GREEN("✓ Already collected"))
      return
    end

    -- Mount (item class 15 = Miscellaneous, subclass 5 = Mount)
    if itemClassID == 15 and itemSubClassID == 5 then
      if C_MountJournal then
        local mountID = C_MountJournal.GetMountFromItem and C_MountJournal.GetMountFromItem(itemID)
        if mountID then
          local _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
          if isCollected then
            tooltip:AddLine(GREY("Mount: ") .. GREEN("✓ Already collected"))
          else
            tooltip:AddLine(GREY("Mount: ") .. RED("✗ Not collected"))
          end
          return
        end
      end
    end

    -- Transmog appearance
    if C_TransmogCollection and C_TransmogCollection.GetItemInfo then
      local sourceID = select(2, C_TransmogCollection.GetItemInfo(itemID))
      if sourceID then
        if C_TransmogCollection.PlayerKnowsSource(sourceID) then
          tooltip:AddLine(GREY("Appearance: ") .. GREEN("✓ Already collected"))
        else
          tooltip:AddLine(GREY("Appearance: ") .. RED("✗ Not collected"))
        end
      end
    end
  end

  -- ── Recipe / pattern / schematic / formula ────────────────────────────────
  -- Enum.ItemClass.Recipe == 9 in modern WoW
  if itemClassID == Enum.ItemClass.Recipe then
    local professionName = itemSubTypeName  -- e.g. "Alchemy", "Blacksmithing"
    local teachSpellID   = getTeachSpellID(itemLink)
    tooltip:AddLine(BLUE("── LearnableBy ──"))
    addRecipeLines(tooltip, itemLink, professionName, teachSpellID)
    return
  end

  -- ── Equippable gear ───────────────────────────────────────────────────────
  if itemClassID == Enum.ItemClass.Armor or itemClassID == Enum.ItemClass.Weapon then
    addEquipLines(tooltip, itemEquipLoc, itemClassID, itemSubClassID)
  end
end

-- ─── Tooltip hooks ────────────────────────────────────────────────────────────

local function hookTooltip(tt)
  tt:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    addLearnableByLines(self, link)
  end)
end

hookTooltip(GameTooltip)
hookTooltip(ItemRefTooltip)
hookTooltip(ShoppingTooltip1)
hookTooltip(ShoppingTooltip2)

-- ─── Events ───────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")  -- re-scan when a recipe is learned

eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    initDB()

  elseif event == "PLAYER_LOGIN" then
    -- registerSelf fires after all SavedVariables have been loaded
    registerSelf()

  elseif event == "TRADE_SKILL_UPDATE" then
    -- A profession recipe was just learned — refresh this alt's known spells
    local key = UnitName("player") .. "-" .. GetRealmName()
    if LearnableByDB and LearnableByDB.alts and LearnableByDB.alts[key] then
      LearnableByDB.alts[key].knownSpells = scanKnownProfessionSpells()
      LearnableByDB.alts[key].professions = scanProfessions()
    end
  end
end)

-- ─── Slash commands ───────────────────────────────────────────────────────────

SLASH_LEARNABLEBY1 = "/learnableby"
SLASH_LEARNABLEBY2 = "/lby"

SlashCmdList["LEARNABLEBY"] = function(msg)
  local cmd = strtrim(msg):lower()

  if cmd == "" or cmd == "help" then
    print(GOLD("LearnableBy") .. " v" .. VERSION .. " — commands:")
    print("  " .. GOLD("/lby alts") .. "     — list registered alts + professions")
    print("  " .. GOLD("/lby refresh") .. "  — re-scan this character's recipes & professions")
    print("  " .. GOLD("/lby clear") .. "    — clear the alt roster")
    print("  " .. GOLD("/lby about") .. "    — version info")

  elseif cmd == "alts" then
    local roster = getAltRoster()
    if #roster == 0 then
      print(GOLD("LearnableBy") .. ": no alts registered yet. Log in on each character to add them.")
    else
      print(GOLD("LearnableBy") .. " — registered alts (" .. #roster .. "):")
      for _, alt in ipairs(roster) do
        local display = CLASS_DISPLAY[alt.classFile] or alt.classFile
        local profList = {}
        if alt.professions then
          for pName, pData in pairs(alt.professions) do
            profList[#profList + 1] = pName .. " " .. pData.rank .. "/" .. pData.maxRank
          end
          table.sort(profList)
        end
        local knownCount = 0
        if alt.knownSpells then
          for _ in pairs(alt.knownSpells) do knownCount = knownCount + 1 end
        end
        local profStr = #profList > 0 and (" | " .. join(profList, ", ")) or ""
        local spellStr = " | " .. knownCount .. " known recipes"
        print("  " .. YELLOW(alt.name) .. " [" .. display .. "] — " .. alt.realm .. profStr .. spellStr)
      end
    end

  elseif cmd == "refresh" then
    registerSelf()
    local knownCount = 0
    local key = UnitName("player") .. "-" .. GetRealmName()
    if LearnableByDB.alts[key] and LearnableByDB.alts[key].knownSpells then
      for _ in pairs(LearnableByDB.alts[key].knownSpells) do knownCount = knownCount + 1 end
    end
    print(GOLD("LearnableBy") .. ": refreshed. " .. knownCount .. " profession spells indexed.")

  elseif cmd == "clear" then
    LearnableByDB.alts = {}
    registerSelf()  -- immediately re-register the current character
    print(GOLD("LearnableBy") .. ": alt roster cleared. Current character re-registered.")

  elseif cmd == "about" then
    print(GOLD("LearnableBy") .. " v" .. VERSION .. " by fstubner")
    print("Per-alt recipe knowledge and equip eligibility in item tooltips.")

  else
    print(GOLD("LearnableBy") .. ": unknown command. Type " .. GOLD("/lby help") .. " for options.")
  end
end
