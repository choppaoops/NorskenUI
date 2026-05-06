---@class NRSKNUI
local NRSKNUI = select(2, ...)

---@type NorskenUI
local NorskenUI = _G.NorskenUI

if not NorskenUI then
    error("MiscVars: Addon object not initialized. Check file load order!")
    return
end

---@class MiscVars: AceModule, AceEvent-3.0
local MVAR = NorskenUI:NewModule("MiscVars", "AceEvent-3.0")

local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local C_Timer = C_Timer
local C_CVar = C_CVar

MVAR._suppressCVarUpdate = false
MVAR.DEFS = {
    {
        key = "nameplateUseClassColorForFriendlyPlayerUnitNames",
        label = "Class Colored Friendly Nameplates",
        description = "Display the class color in friendly player nameplate names.",
        type = "boolean",
        default = false,
    },
    {
        key = "nameplateShowOnlyNameForFriendlyPlayerUnits",
        label = "Hide Friendly Nameplate Bars",
        description = "Hide every part of the nameplate except the name for friendly players.",
        type = "boolean",
        default = false,
    },
    {
        key = "ResampleAlwaysSharpen",
        label = "Sharpen Visuals",
        description = "Applies a sharpening filter to the game visuals.",
        type = "boolean",
        default = false,
    },
    {
        key = "cameraDistanceMaxZoomFactor",
        label = "Max Camera Distance",
        description = "Adjust the maximum distance the camera will follow behind you.",
        type = "number",
        min = 1,
        max = 2.6,
        step = 0.1,
        default = 1.9,
    },
    {
        key = "SpellQueueWindow",
        label = "Spell Queue Window",
        description = "Adjust how far ahead of the end of a cast spell you can queue another spell.",
        type = "number",
        min = 1,
        max = 400,
        step = 1,
        default = 400,
    },
}

function MVAR:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.MiscVars
end

function MVAR:OnInitialize()
    self:UpdateDB()
    self:SyncFromCVars()
    self:SetEnabledState(false)
end

local function ToCVarValue(value, cvarType)
    if cvarType == "boolean" then
        return value and 1 or 0
    elseif cvarType == "number" then
        return tostring(value)
    end
    return value
end

local function FromCVarValue(value, cvarType)
    if cvarType == "boolean" then
        return value == "1"
    elseif cvarType == "number" then
        return tonumber(value) or 0
    end
    return value
end

function MVAR:ApplySettings()
    if not self.db.Enabled then return end

    for _, def in ipairs(self.DEFS) do
        local key = def.key
        local dbValue = self.db[key]
        local currentCVar = C_CVar.GetCVar(key)
        local currentValue = FromCVarValue(currentCVar, def.type)

        if dbValue == nil then
            self.db[key] = currentValue
        else
            if dbValue ~= currentValue then C_CVar.SetCVar(key, ToCVarValue(dbValue, def.type)) end
        end
    end
end

function MVAR:SyncFromCVars()
    for _, def in ipairs(self.DEFS) do
        local key = def.key
        local current = C_CVar.GetCVar(key)
        self.db[key] = FromCVarValue(current, def.type)
    end
end

function MVAR:CVAR_UPDATE(_, cvarName)
    for _, def in ipairs(self.DEFS) do
        if def.key == cvarName then
            local current = C_CVar.GetCVar(cvarName)
            self.db[cvarName] = FromCVarValue(current, def.type)
        end
    end

    if NRSKNUI.GUIFrame and not self._suppressCVarUpdate then NRSKNUI.GUIFrame:RefreshContent() end
end

function MVAR:OnEnable()
    if not self.db.Enabled then return end
    self:RegisterEvent("CVAR_UPDATE")
    C_Timer.After(1, function() self:ApplySettings() end)
end
