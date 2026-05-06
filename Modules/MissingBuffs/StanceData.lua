---@class NRSKNUI
local NRSKNUI = select(2, ...)

NRSKNUI.StanceData = {}
local Data = NRSKNUI.StanceData

Data.SPEC_ID_TO_NAME = {
    [71] = "Arms",
    [72] = "Fury",
    [73] = "Protection",
    [65] = "Holy",
    [66] = "Protection",
    [70] = "Retribution",
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Restoration",
    [256] = "Discipline",
    [257] = "Holy",
    [258] = "Shadow",
    [1467] = "Devastation",
    [1468] = "Preservation",
    [1473] = "Augmentation",
}

Data.WARRIOR = {
    stanceSpellIds = {
        [386164] = true,
        [386196] = true,
        [386208] = true,
    },
    stances = {
        [386164] = { name = "Battle Stance",    icon = 132349 },
        [386196] = { name = "Berserker Stance", icon = 132275 },
        [386208] = { name = "Defensive Stance", icon = 132341 },
    },
    specs = {
        Arms       = { defaultStance = 386164, icon = 132355 },
        Fury       = { defaultStance = 386196, icon = 132347 },
        Protection = { defaultStance = 386208, icon = 132341 },
    },
}

Data.PALADIN = {
    auras = {
        [465]    = { name = "Devotion Aura",      icon = 135893 },
        [317920] = { name = "Concentration Aura", icon = 135933 },
        [32223]  = { name = "Crusader Aura",      icon = 135890 },
    },
    auraSpellIds = { 465, 317920, 32223 },
    specs = {
        Holy        = { defaultStance = 465,   icon = 135920 },
        Protection  = { defaultStance = 465,   icon = 236264 },
        Retribution = { defaultStance = 32223, icon = 535595 },
    },
}

Data.DRUID = {
    forms = {
        [24858] = { name = "Moonkin Form", icon = 136096 },
        [768]   = { name = "Cat Form",     icon = 132115 },
        [5487]  = { name = "Bear Form",    icon = 132276 },
    },
    specs = {
        [102] = { name = "Balance",  toggleKey = "BalanceEnabled",  combatOnlyKey = "BalanceCombatOnly",  spellId = 24858, icon = 136096 },
        [103] = { name = "Feral",    toggleKey = "FeralEnabled",    combatOnlyKey = "FeralCombatOnly",    spellId = 768,   icon = 132115 },
        [104] = { name = "Guardian", toggleKey = "GuardianEnabled", combatOnlyKey = "GuardianCombatOnly", spellId = 5487,  icon = 132276 },
    },
}

Data.PRIEST = {
    shadowformSpellId = 232698,
    voidformSpellId = 194249,
    specs = {
        Shadow = { icon = 136207 },
    },
}

Data.EVOKER = {
    attunements = {
        [403264] = { name = "Black Attunement",  icon = 5198700 },
        [403265] = { name = "Bronze Attunement", icon = 5198700 },
    },
    defaultAttunement = 403264,
    specs = {
        Augmentation = { icon = 5198700 },
    },
}

function Data:GetStanceOptions(classKey)
    local options = {}

    if classKey == "WARRIOR" then
        for spellId, data in pairs(self.WARRIOR.stances) do
            options[#options + 1] = { key = tostring(spellId), text = data.name }
        end
    elseif classKey == "PALADIN" then
        for spellId, data in pairs(self.PALADIN.auras) do
            options[#options + 1] = { key = tostring(spellId), text = data.name }
        end
    elseif classKey == "DRUID" then
        for spellId, data in pairs(self.DRUID.forms) do
            options[#options + 1] = { key = tostring(spellId), text = data.name }
        end
    elseif classKey == "EVOKER" then
        for spellId, data in pairs(self.EVOKER.attunements) do
            options[#options + 1] = { key = tostring(spellId), text = data.name }
        end
    end

    return options
end

function Data:GetStanceTextData(classKey)
    local stances = {}

    if classKey == "WARRIOR" then
        for spellId, data in pairs(self.WARRIOR.stances) do
            stances[#stances + 1] = { key = tostring(spellId), text = data.name, textureId = data.icon }
        end
    elseif classKey == "PALADIN" then
        for spellId, data in pairs(self.PALADIN.auras) do
            stances[#stances + 1] = { key = tostring(spellId), text = data.name, textureId = data.icon }
        end
    end

    return stances
end

function Data:GetSpecIcon(classKey, specName)
    local classData = self[classKey]
    if classData and classData.specs and classData.specs[specName] then
        return classData.specs[specName].icon
    end
    return nil
end

function Data:GetDefaultStance(classKey, specName)
    local classData = self[classKey]
    if classData and classData.specs and classData.specs[specName] then
        return classData.specs[specName].defaultStance
    end
    return nil
end
