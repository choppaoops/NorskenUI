-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Localization Setup
local IsInInstance = IsInInstance
local LibStub = LibStub
local string_gsub = string.gsub
local ReloadUI = ReloadUI
local Theme = NRSKNUI.Theme

local aceAddon = LibStub("AceAddon-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LDS = LibStub("LibDualSpec-1.0")

-- Constants
local DEFAULT_PROFILE = "Default"

-- Create the main addon object
---@class NorskenUI : AceAddon-3.0, AceEvent-3.0, AceHook-3.0
local NorskenUI = aceAddon:NewAddon("NorskenUI", "AceEvent-3.0", "AceHook-3.0")
_G.NorskenUI = NorskenUI

-- Encounter state
NRSKNUI.encounterActive = false

-- OnInitialize: Called when the addon is initialized
function NorskenUI:OnInitialize()
    local defaults = NRSKNUI:GetDefaultDB()
    if not defaults then
        defaults = { profile = {} }
    end
    NRSKNUI.db = LibStub("AceDB-3.0"):New("NorskenUIDB", defaults, true)
    if LDS then
        LDS:EnhanceDatabase(NRSKNUI.db, "NorskenUI")
    end

    -- Ensure global Theme table exists with defaults (AceDB doesn't always merge new global defaults)
    if not NRSKNUI.db.global.Theme then
        NRSKNUI.db.global.Theme = defaults.global.Theme
    else
        -- Merge missing keys from defaults
        for key, value in pairs(defaults.global.Theme) do
            if NRSKNUI.db.global.Theme[key] == nil then
                NRSKNUI.db.global.Theme[key] = value
            end
        end
    end

    if NRSKNUI.db.global and NRSKNUI.db.global.UseGlobalProfile then
        local profileName = NRSKNUI.db.global.GlobalProfile or DEFAULT_PROFILE
        NRSKNUI.db:SetProfile(profileName)
    end

    -- Validate fonts on initial load
    NRSKNUI:ValidateProfileFonts()

    -- Profile change callbacks
    NRSKNUI.db.RegisterCallback(NRSKNUI, "OnProfileChanged", function()
        NRSKNUI:ValidateProfileFonts()
        if NRSKNUI.ProfileManager then
            NRSKNUI.ProfileManager:RefreshAllModules()
        end
    end)
    NRSKNUI.db.RegisterCallback(NRSKNUI, "OnProfileCopied", function()
        NRSKNUI:ValidateProfileFonts()
        if NRSKNUI.ProfileManager then
            NRSKNUI.ProfileManager:RefreshAllModules()
        end
    end)
    NRSKNUI.db.RegisterCallback(NRSKNUI, "OnProfileReset", function()
        NRSKNUI:ValidateProfileFonts()
        if NRSKNUI.ProfileManager then
            NRSKNUI.ProfileManager:RefreshAllModules()
        end
    end)

    -- Set UIParent scale to perfect for pixel-perfect rendering
    NRSKNUI:UIScale()

    -- Slight delay so that current Theme color can be applied to the minimap icon
    C_Timer.After(1, function()
        NRSKNUI:SetupMinimapIcon()
    end)
end

function NRSKNUI:SetupMinimapIcon()
    if not LDB or not LDBIcon then return end
    local MyLDB = LDB:NewDataObject("NorskenUI", {
        type = "launcher",
        text = "NorskenUI",
        icon = "Interface\\AddOns\\NorskenUI\\Media\\Logo\\logocookingsPT1128x128OTBRED.png",
        iconR = Theme.accent[1],
        iconG = Theme.accent[2],
        iconB = Theme.accent[3],
        OnClick = function(_, button)
            if button == "LeftButton" then
                if NRSKNUI.GUIFrame then
                    NRSKNUI.GUIFrame:Toggle()
                end
            elseif button == "RightButton" then
                if NRSKNUI.EditMode then
                    NRSKNUI.EditMode:Toggle()
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(NRSKNUI:ColorTextByTheme("Norsken") .. "|cffb3b3b3UI|r")
            tt:AddLine("Left-Click to open options", 0.70, 0.70, 0.70)
            tt:AddLine("Right-Click to toggle anchors", 0.70, 0.70, 0.70)
        end,
    })
    LDBIcon:Register("NorskenUI", MyLDB, NRSKNUI.db.profile.Minimap)
end

local function OnEncounterEnd()
    local _, instanceType = IsInInstance()
    if instanceType == "raid" and NRSKNUI.encounterActive then
        NRSKNUI.encounterActive = false
    end
end

local function OnEncounterStart()
    local _, instanceType = IsInInstance()
    if instanceType == "raid" then
        NRSKNUI.encounterActive = true
    end
end

local function OnPlayerEnteringWorld()
    -- Automatically refresh all AceAddon modules
    for name, module in NorskenUI:IterateModules() do
        if module:IsEnabled() and module.ApplySettings then
            module:ApplySettings()
        end
    end
end

-- Setup slash commands
local function SetupSlashCommands()
    SLASH_NRSKNUI1 = "/nui"
    SLASH_NRSKNUI2 = "/norskenui"
    SlashCmdList["NRSKNUI"] = function(msg)
        msg = (msg or ""):lower()
        msg = string_gsub(msg, "^%s+", "")
        msg = string_gsub(msg, "%s+$", "")
        if msg == "" or msg == "gui" then
            if NRSKNUI.GUIFrame then
                NRSKNUI.GUIFrame:Toggle()
            end
        elseif msg == "edit" or msg == "unlock" then
            if NRSKNUI.EditMode then
                NRSKNUI.EditMode:Toggle()
            end
        end
    end

    -- Show login message if enabled
    if NRSKNUI.db and NRSKNUI.db.profile.Minimap.LoginMessage ~= false then
        NRSKNUI:Print(NRSKNUI:ColorTextByTheme("/nui") .. " to open the configuration window.")
    end

    -- TODO: Add these into gui so user can toggle
    -- /rl instead of /reload shortcut :)
    SLASH_NRSKNUI_RL1 = "/rl"
    SlashCmdList["NRSKNUI_RL"] = function() ReloadUI() end

    -- /fs instead of /fstack shortcut :)
    SLASH_NRSKNUI_FS1 = "/fs"
    SlashCmdList["NRSKNUI_FS"] = function()
        UIParentLoadAddOn("Blizzard_DebugTools")
        FrameStackTooltip_Toggle()
    end
end

-- OnEnable: Called when the addon is enabled
function NorskenUI:OnEnable()
    -- Method to fix old frame sizing data that messes up sidebar width
    local currentVersion = NRSKNUI:GetDefaultDB().global.GUIState.GUIFrameLayoutVersion or 1
    local rawState = _G.NorskenUIDB and _G.NorskenUIDB.global and _G.NorskenUIDB.global.GUIState
    if (rawState and rawState.GUIFrameLayoutVersion or 0) < currentVersion then
        local frame = NRSKNUI.db.global.GUIState.frame
        if frame then frame.width, frame.height = nil, nil end
        NRSKNUI.db.global.GUIState.GUIFrameLayoutVersion = currentVersion
    end

    if NRSKNUI.RefreshTheme then NRSKNUI:RefreshTheme() end
    SetupSlashCommands()

    -- Automatically enable modules based on their saved settings
    for name, module in self:IterateModules() do
        if module.db and module.db.Enabled then
            self:EnableModule(name)
        end
    end

    -- Event Registration
    self:RegisterEvent("ENCOUNTER_END", OnEncounterEnd)
    self:RegisterEvent("ENCOUNTER_START", OnEncounterStart)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", OnPlayerEnteringWorld)
end
