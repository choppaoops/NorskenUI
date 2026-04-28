---@class NRSKNUI
local NRSKNUI = select(2, ...)

local ipairs, pairs, type = ipairs, pairs, type
local pcall = pcall

NRSKNUI.LSM = LibStub("LibSharedMedia-3.0")
NRSKNUI.SB = NRSKNUI.PATH .. [[Statusbars\]] .. 'NorskenUI.blp'

if NRSKNUI.LSM then
    NRSKNUI.LSM:Register('font', 'Expressway', NRSKNUI.FONT)
    NRSKNUI.LSM:Register('statusbar', 'NorskenUI', NRSKNUI.SB)
    NRSKNUI.LSM:Register('sound', '|cffe51039NorskenWhisper|r', [[Interface\AddOns\NorskenUI\Media\Sounds\Whisper.ogg]])
    NRSKNUI.LSM:Register('border', 'WHITE8X8', [[Interface\Buttons\WHITE8X8]])
end

-- Preload LSM media on login
do
    local CreateFrame = CreateFrame
    local C_Timer = C_Timer

    local function PreloadLSMMedia()
        if not NRSKNUI.LSM then return end
        local mediaTypes = { "font", "statusbar", "sound", "border" }
        for _, mediaType in ipairs(mediaTypes) do
            local media = NRSKNUI.LSM:HashTable(mediaType)
            if media then
                for name in pairs(media) do NRSKNUI.LSM:Fetch(mediaType, name) end
            end
        end
    end

    local preloadFrame = CreateFrame("Frame")
    preloadFrame:RegisterEvent("PLAYER_LOGIN")
    preloadFrame:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        C_Timer.After(1.5, PreloadLSMMedia)
    end)
end

-- TODO: In 12.0.7 new api will be available for font/asset validation, but use pcall method for now
-- Font validation
local fontProbe = UIParent:CreateFontString()
fontProbe:Hide()

local DEFAULT_FONT = "Expressway"

---@param fontPath string
---@return boolean
function NRSKNUI:IsFontValid(fontPath)
    if not fontPath or fontPath == "" then return false end
    return pcall(fontProbe.SetFont, fontProbe, fontPath, 12, "")
end

local function IsFontKey(key)
    if type(key) ~= "string" then return false end
    return key == "Font" or key:match("FontFace$")
end

local function ValidateFontsRecursive(tbl, defaults)
    if type(tbl) ~= "table" then return end
    local LSM = NRSKNUI.LSM
    if not LSM then return end

    for key, value in pairs(tbl) do
        if IsFontKey(key) and type(value) == "string" then
            if not LSM:IsValid("font", value) then
                local defaultVal = defaults and defaults[key] or DEFAULT_FONT
                if not LSM:IsValid("font", defaultVal) then
                    defaultVal = DEFAULT_FONT
                end
                tbl[key] = defaultVal
            end
        elseif type(value) == "table" then
            local subDefaults = defaults and defaults[key]
            ValidateFontsRecursive(value, subDefaults)
        end
    end
end

function NRSKNUI:ValidateProfileFonts()
    if not self.db or not self.db.profile then return end
    local defaults = self.db.defaults and self.db.defaults.profile
    ValidateFontsRecursive(self.db.profile, defaults)
end

---@param mediaType string
---@param name string
---@param fallback string
---@return string
function NRSKNUI:GetMediaPath(mediaType, name, fallback)
    if NRSKNUI.LSM and name then
        local path = NRSKNUI.LSM:Fetch(mediaType, name)
        if path then return path end
    end
    return fallback
end

function NRSKNUI:GetFontPath(fontName) return self:GetMediaPath("font", fontName, "Fonts\\FRIZQT__.TTF") end

function NRSKNUI:GetStatusbarPath(barName)
    return self:GetMediaPath("statusbar", barName,
        "Interface\\TargetingFrame\\UI-StatusBar")
end

-- Sound validation
do
    local soundCache, cacheBuilt = {}, false
    local PlaySoundFile = PlaySoundFile

    local function BuildSoundCache()
        if cacheBuilt or not NRSKNUI.LSM then return end
        local sounds = NRSKNUI.LSM:HashTable("sound")
        if sounds then for _, path in pairs(sounds) do soundCache[path] = true end end
        cacheBuilt = true
    end

    ---@param path string|number
    ---@return boolean
    function NRSKNUI:IsSoundValid(path)
        if not path or path == "" or path == "None" then return false end
        if type(path) == "number" then return true end
        if path:lower():find("^sound[\\/]+") then return true end
        BuildSoundCache()
        return soundCache[path] or false
    end

    ---@param path string|number
    ---@param channel string?
    function NRSKNUI:PlaySound(path, channel)
        if not self:IsSoundValid(path) then return end
        PlaySoundFile(path, channel or "Master")
    end
end

-- Convert font outline value for SetFont API (NONE/SOFTOUTLINE -> "")
function NRSKNUI:GetFontOutline(outline)
    if not outline or outline == "NONE" or outline == "SOFTOUTLINE" or outline == "" then return "" end
    return outline
end

---@param fontString FontString
---@param fontName string
---@param fontSize number
---@param fontOutline string
---@return boolean
function NRSKNUI:ApplyFont(fontString, fontName, fontSize, fontOutline)
    if not fontString then return false end

    local fontPath = self:GetFontPath(fontName)
    if not self:IsFontValid(fontPath) then fontPath = "Fonts\\FRIZQT__.TTF" end

    local size = (fontSize and fontSize > 0) and fontSize or 12
    return fontString:SetFont(fontPath, size, self:GetFontOutline(fontOutline)) or false
end
