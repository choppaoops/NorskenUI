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
        -- The 13 real per-class aura variants (they all share the "Blessing of
        -- the Bronze" name and are all on Blizzard's restricted-context aura
        -- whitelist). 364342 is only the cast spell, kept above as castSpellId.
        extraBuffSpellIds = { 381732, 381741, 381746, 381749, 381750, 381751, 381752, 381753, 381754, 381756, 381757, 381758 }
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
    { spellId = 53563,  class = "PALADIN", specId = 65,   targetType = "any",    maxTargets = 1, key = "BeaconOfLight",         excludeIfTalent = 200025 },
    { spellId = 156910, class = "PALADIN", specId = 65,   targetType = "any",    maxTargets = 1, key = "BeaconOfFaith",         talentId = 156910 },

    { spellId = 360827, class = "EVOKER",  specId = 1473, targetType = "any",    maxTargets = 1, key = "BlisteringScales",      includeSelf = true,      talentId = 360827 },
    { spellId = 412710, class = "EVOKER",  specId = 1473, targetType = "any",    maxTargets = 1, key = "Timelessness",          talentId = 412710 },
    { spellId = 369459, class = "EVOKER",  specId = 1473, targetType = "healer", maxTargets = 1, key = "SourceOfMagic" },

    { spellId = 974,    class = "SHAMAN",  specId = 264,  targetType = "any",    maxTargets = 1, key = "EarthShieldOthers",     excludeSelf = true },

    { spellId = 474750, class = "DRUID",   targetType = "any",    maxTargets = 1, key = "SymbioticRelationship", talentId = 474750, selfBuffSpellId = 474754 },

    { spellId = 434763, class = "MONK",    specId = 270,  targetType = "any",    maxTargets = 1, key = "LinkedSpirits",         talentId = 434774 },
}

Data.ELEMENTAL_ORBIT_TALENT = 383010
Data.EARTH_SHIELD_SELF_BUFF = 383648

Data.SELF_BUFFS = {
    { spellId = 210126, class = "MAGE",    key = "ArcaneFamiliar",    talentId = 205022,        specId = 62 },
    { spellId = 196099, class = "WARLOCK", key = "GrimoireSacrifice", talentId = 108503,        castSpellId = 108503 },
    { spellId = 319778, class = "SHAMAN",  key = "FlametongueWeapon", enchantId = 5400 },
    { spellId = 319773, class = "SHAMAN",  key = "WindfuryWeapon",    enchantId = 5401 },
    { spellId = 382021, class = "SHAMAN",  key = "EarthlivingWeapon", enchantId = 6498 },
    { spellId = 974,    class = "SHAMAN",  key = "EarthShieldSelf",   groupId = "ShamanShield" },
    { spellId = 192106, class = "SHAMAN",  key = "LightningShield",   groupId = "ShamanShield" },
    { spellId = 52127,  class = "SHAMAN",  key = "WaterShield",       groupId = "ShamanShield", specId = 264 },
}

Data.PRESENCE_BUFFS = {
    { spellId = 465,    providerClass = "PALADIN", key = "DevotionAura" },
    { spellId = 20707,  providerClass = "WARLOCK", key = "Soulstone",      checkAnyGroupMember = true },
    { spellId = 381637, providerClass = "ROGUE",   key = "AtrophicPoison", checkAnyGroupMember = true },
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

-- Blizzard whitelists specific spell IDs for C_UnitAuras.GetUnitAuraBySpellID()
-- (and GetPlayerAuraBySpellID) during restricted contexts: combat lockdown,
-- boss encounters, M+ keystones, and PvP instances. Non-whitelisted spells
-- silently return nil there, indistinguishable from "buff missing". Any aura
-- spell ID NOT in this table is treated as unsafe to query while restricted,
-- so IsAuraTrackable() skips it instead of showing a false reminder.
-- Mirrors the whitelist maintained by the BuffReminders addon (confirmed via
-- in-game testing); keep in sync if Blizzard changes the list.
Data.AURA_WHITELIST = {
    -- Long-term raid buffs
    [1126] = true,    -- Mark of the Wild
    [1459] = true,    -- Arcane Intellect
    [6673] = true,    -- Battle Shout
    [21562] = true,   -- Power Word: Fortitude
    [369459] = true,  -- Source of Magic
    [462854] = true,  -- Skyfury
    [474754] = true,  -- Symbiotic Relationship

    -- Blessing of the Bronze (per-class aura variants)
    [381732] = true,  -- Death Knight
    [381741] = true,  -- Demon Hunter
    [381746] = true,  -- Druid
    [381748] = true,  -- Evoker
    [381749] = true,  -- Hunter
    [381750] = true,  -- Mage
    [381751] = true,  -- Monk
    [381752] = true,  -- Paladin
    [381753] = true,  -- Priest
    [381754] = true,  -- Rogue
    [381756] = true,  -- Shaman
    [381757] = true,  -- Warlock
    [381758] = true,  -- Warrior

    -- Healer buffs and HoTs
    [355941] = true,  -- Dream Breath (Preservation Evoker)
    [363502] = true,  -- Dream Flight
    [364343] = true,  -- Echo
    [366155] = true,  -- Reversion
    [367364] = true,  -- Echo Reversion
    [373267] = true,  -- Lifebind
    [376788] = true,  -- Echo Dream Breath
    [360827] = true,  -- Blistering Scales (Augmentation Evoker)
    [395152] = true,  -- Ebon Might
    [410089] = true,  -- Prescience
    [410263] = true,  -- Inferno's Blessing
    [410686] = true,  -- Symbiotic Bloom
    [413984] = true,  -- Shifting Sands
    [774] = true,     -- Rejuvenation (Restoration Druid)
    [8936] = true,    -- Regrowth
    [33763] = true,   -- Lifebloom
    [48438] = true,   -- Wild Growth
    [155777] = true,  -- Germination
    [17] = true,      -- Power Word: Shield (Discipline Priest)
    [194384] = true,  -- Atonement
    [1253593] = true, -- Void Shield
    [139] = true,     -- Renew (Holy Priest)
    [41635] = true,   -- Prayer of Mending
    [77489] = true,   -- Echo of Light
    [115175] = true,  -- Soothing Mist (Mistweaver Monk)
    [119611] = true,  -- Renewing Mist
    [124682] = true,  -- Enveloping Mist
    [450769] = true,  -- Aspect of Harmony
    [974] = true,     -- Earth Shield (Restoration Shaman)
    [383648] = true,  -- Earth Shield (passive self-buff)
    [61295] = true,   -- Riptide
    [53563] = true,   -- Beacon of Light (Holy Paladin)
    [156322] = true,  -- Eternal Flame
    [156910] = true,  -- Beacon of Faith
    [1244893] = true, -- Beacon of the Savior

    -- Long-term self buffs
    [433568] = true,  -- Rite of Sanctification
    [433583] = true,  -- Rite of Adjuration

    -- Rogue poisons
    [2823] = true,    -- Deadly Poison
    [3408] = true,    -- Crippling Poison
    [5761] = true,    -- Numbing Poison
    [8679] = true,    -- Wound Poison
    [315584] = true,  -- Instant Poison
    [381637] = true,  -- Atrophic Poison
    [381664] = true,  -- Amplifying Poison

    -- Shaman imbuements
    [319773] = true,  -- Windfury Weapon
    [319778] = true,  -- Flametongue Weapon
    [382021] = true,  -- Earthliving Weapon
    [382022] = true,  -- Earthliving Weapon
    [457481] = true,  -- Tidecaller's Guard
    [457496] = true,  -- Tidecaller's Guard
    [462742] = true,  -- Thunderstrike Ward
    [462757] = true,  -- Thunderstrike Ward
}
