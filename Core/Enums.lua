---@class NRSKNUI
local NRSKNUI = select(2, ...)

NRSKNUI.Enum = {}
NRSKNUI.Enum.DispelType = {
    -- https://wago.tools/db2/SpellDispelType
    None = 0,
    Magic = 1,
    Curse = 2,
    Disease = 3,
    Poison = 4,
    Enrage = 9,
    Bleed = 11,
}
