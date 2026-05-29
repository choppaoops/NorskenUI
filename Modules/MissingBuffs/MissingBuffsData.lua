---@class NRSKNUI
local NRSKNUI = select(2, ...)

NRSKNUI.MissingBuffsData = {}
local Data = NRSKNUI.MissingBuffsData

Data.SAFE_BUFFS = {
    { spellId = 1126,   class = "DRUID",   buffType = "raid", key = "MarkOfTheWild" },
    { spellId = 1459,   class = "MAGE",    buffType = "raid", key = "ArcaneIntellect" },
    { spellId = 6673,   class = "WARRIOR", buffType = "raid", key = "BattleShout",       ignoreRangeCheck = true },
    { spellId = 21562,  class = "PRIEST",  buffType = "raid", key = "PowerWordFortitude" },
    { spellId = 462854, class = "SHAMAN",  buffType = "raid", key = "Skyfury" },
    {
        spellId = 381748,
        castSpellId = 364342,
        class = "EVOKER",
        buffType = "raid",
        key = "BlessingOfTheBronze",
        ignoreRangeCheck = true,
        extraBuffSpellIds = { 381732, 381741, 381746, 381749, 381750, 381751, 381752, 381753, 381754, 381755, 381756, 381757, 381758 }
    },
    { spellId = 2823,             class = "ROGUE", buffType = "poison", poisonType = "lethal" },
    { spellId = 8679,             class = "ROGUE", buffType = "poison", poisonType = "lethal" },
    { spellId = 315584,           class = "ROGUE", buffType = "poison", poisonType = "lethal" },
    { spellId = 381664,           class = "ROGUE", buffType = "poison", poisonType = "lethal" },
    { spellId = 3408,             class = "ROGUE", buffType = "poison", poisonType = "nonlethal" },
    { spellId = 5761,             class = "ROGUE", buffType = "poison", poisonType = "nonlethal" },
    { spellId = 381637,           class = "ROGUE", buffType = "poison", poisonType = "nonlethal" },
    { buffType = "weaponEnchant", slot = "main",   text = "MH",         dbKey = "MHEnchant" },
    { buffType = "weaponEnchant", slot = "off",    text = "OH",         dbKey = "OHEnchant" },
}

Data.WELL_FED_NAME = C_Spell.GetSpellName(19705)
Data.HEARTY_WELL_FED_NAME = C_Spell.GetSpellName(462187)

Data.RESTRICTED_BUFFS = {
    { spellId = 1235111, category = "Flask" },
    { spellId = 1235110, category = "Flask" },
    { spellId = 1235057, category = "Flask" },
    { spellId = 1235108, category = "Flask" },
    { spellId = 432021,  category = "Flask" },
    { spellId = 431971,  category = "Flask" },
    { spellId = 431972,  category = "Flask" },
    { spellId = 431974,  category = "Flask" },
    { spellId = 431973,  category = "Flask" },
    { spellId = 1264426, category = "Rune", itemId = 259085 },
}

Data.TARGETED_BUFFS = {
    { spellId = 53563,  class = "PALADIN", specId = 65,   targetType = "any",    maxTargets = 1, key = "BeaconOfLight",         secret = false, excludeIfTalent = 200025 },
    { spellId = 156910, class = "PALADIN", specId = 65,   targetType = "any",    maxTargets = 1, key = "BeaconOfFaith",         secret = false, talentId = 156910 },

    { spellId = 360827, class = "EVOKER",  specId = 1473, targetType = "any",    maxTargets = 1, key = "BlisteringScales",      secret = false, includeSelf = true,      talentId = 360827 },
    { spellId = 412710, class = "EVOKER",  specId = 1473, targetType = "any",    maxTargets = 1, key = "Timelessness",          secret = true,  talentId = 412710 },
    { spellId = 369459, class = "EVOKER",  specId = 1473, targetType = "healer", maxTargets = 1, key = "SourceOfMagic",         secret = false },

    { spellId = 974,    class = "SHAMAN",  specId = 264,  targetType = "any",    maxTargets = 1, key = "EarthShieldOthers",     secret = false, excludeSelf = true },

    { spellId = 474750, class = "DRUID",   targetType = "any",    maxTargets = 1, key = "SymbioticRelationship", secret = false, talentId = 474750, selfBuffSpellId = 474754 },

    { spellId = 434763, class = "MONK",    specId = 270,  targetType = "any",    maxTargets = 1, key = "LinkedSpirits",         secret = true,  talentId = 434774 },
}

Data.ELEMENTAL_ORBIT_TALENT = 383010
Data.EARTH_SHIELD_SELF_BUFF = 383648

Data.SELF_BUFFS = {
    { spellId = 210126, class = "MAGE",    key = "ArcaneFamiliar",    secret = true,  talentId = 205022,        specId = 62 },
    { spellId = 196099, class = "WARLOCK", key = "GrimoireSacrifice", secret = true,  talentId = 108503,        castSpellId = 108503 },
    { spellId = 319778, class = "SHAMAN",  key = "FlametongueWeapon", secret = false, enchantId = 5400 },
    { spellId = 319773, class = "SHAMAN",  key = "WindfuryWeapon",    secret = false, enchantId = 5401 },
    { spellId = 382021, class = "SHAMAN",  key = "EarthlivingWeapon", secret = false, enchantId = 6498 },
    { spellId = 974,    class = "SHAMAN",  key = "EarthShieldSelf",   secret = false, groupId = "ShamanShield" },
    { spellId = 192106, class = "SHAMAN",  key = "LightningShield",   secret = true,  groupId = "ShamanShield" },
    { spellId = 52127,  class = "SHAMAN",  key = "WaterShield",       secret = true,  groupId = "ShamanShield", specId = 264 },
}

Data.PRESENCE_BUFFS = {
    { spellId = 465,    providerClass = "PALADIN", key = "DevotionAura",   secret = true },
    { spellId = 20707,  providerClass = "WARLOCK", key = "Soulstone",      secret = true, checkAnyGroupMember = true },
    { spellId = 381637, providerClass = "ROGUE",   key = "AtrophicPoison", secret = true, checkAnyGroupMember = true },
}

Data.ASSA_DOUBLE_POISON_TALENT = 381801

Data.POISON_IDS = {
    ATROPHIC = 381637,
    NUMBING = 5761,
    CRIPPLING = 3408,
    AMPLIFYING = 381664,
    DEADLY = 2823,
    INSTANT = 315584,
    WOUND = 8679,
}

Data.CATEGORY_ICONS = {
    Flask = 1235111,
    Food = 104280,
    MHEnchant = 325395,
    OHEnchant = 325395,
    Rune = 1264426,
    RaidBuffs = 1126,
    Poisons = 2823,
    TargetedBuffs = 53563,
    SelfBuffs = 318038,
    PresenceBuffs = 465,
}

Data.SPEC_PRIMARY_STAT = {
    -- Death Knight
    [250] = "physical",   -- Blood
    [251] = "physical",   -- Frost
    [252] = "physical",   -- Unholy
    -- Demon Hunter
    [577] = "physical",   -- Havoc
    [581] = "physical",   -- Vengeance
    [1480] = "intellect", -- Devourer
    -- Druid
    [102] = "intellect",  -- Balance
    [103] = "physical",   -- Feral
    [104] = "physical",   -- Guardian
    [105] = "intellect",  -- Restoration
    -- Evoker
    [1467] = "intellect", -- Devastation
    [1468] = "intellect", -- Preservation
    [1473] = "intellect", -- Augmentation
    -- Hunter
    [253] = "physical",   -- Beast Mastery
    [254] = "physical",   -- Marksmanship
    [255] = "physical",   -- Survival
    -- Mage
    [62] = "intellect",   -- Arcane
    [63] = "intellect",   -- Fire
    [64] = "intellect",   -- Frost
    -- Monk
    [268] = "physical",   -- Brewmaster
    [269] = "physical",   -- Windwalker
    [270] = "intellect",  -- Mistweaver
    -- Paladin
    [65] = "intellect",   -- Holy
    [66] = "physical",    -- Protection
    [70] = "physical",    -- Retribution
    -- Priest
    [256] = "intellect",  -- Discipline
    [257] = "intellect",  -- Holy
    [258] = "intellect",  -- Shadow
    -- Rogue
    [259] = "physical",   -- Assassination
    [260] = "physical",   -- Outlaw
    [261] = "physical",   -- Subtlety
    -- Shaman
    [262] = "intellect",  -- Elemental
    [263] = "physical",   -- Enhancement
    [264] = "intellect",  -- Restoration
    -- Warlock
    [265] = "intellect",  -- Affliction
    [266] = "intellect",  -- Demonology
    [267] = "intellect",  -- Destruction
    -- Warrior
    [71] = "physical",    -- Arms
    [72] = "physical",    -- Fury
    [73] = "physical",    -- Protection
}

Data.RAID_BUFF_STAT_REQUIREMENT = { ArcaneIntellect = "intellect", BattleShout = "physical", }

Data.LOAD_CONDITIONS = {
    { key = "ALWAYS",   text = "Always" },
    { key = "ANYGROUP", text = "Any Group" },
    { key = "PARTY",    text = "In Party" },
    { key = "RAID",     text = "In Raid" },
    { key = "NOGROUP",  text = "No Group" },
}
