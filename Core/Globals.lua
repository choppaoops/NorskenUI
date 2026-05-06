-- NorskenUI namespace
---@class NRSKNUI
---@diagnostic disable: undefined-field
local NRSKNUI = select(2, ...)
local N = select(1, ...)

NRSKNUI.AddOnName = C_AddOns.GetAddOnMetadata(N, "Title")
NRSKNUI.Version = C_AddOns.GetAddOnMetadata(N, "Version")
NRSKNUI.Author = C_AddOns.GetAddOnMetadata(N, "Author")

local print = print
local C_AddOns = C_AddOns
local EditModeManagerFrame = EditModeManagerFrame
local _G = _G

-- Get player data via LibSpecialization and let the Lib handle changes
do
    local LS = LibStub("LibSpecialization")
    NRSKNUI.MySpec = { id = nil, role = nil, position = nil, talents = nil }
    local function UpdateSpec()
        NRSKNUI.MySpec.id, NRSKNUI.MySpec.role, NRSKNUI.MySpec.position, NRSKNUI.MySpec.talents = LS.MySpecialization()
    end
    C_Timer.After(0.1, function()
        UpdateSpec()
    end)
    LS.RegisterPlayerSpecChange(NRSKNUI, UpdateSpec)
end

-- Check if ElvUI is loaded use ElvUI skinning is enabled
function NRSKNUI:ShouldNotLoadModule() return C_AddOns.IsAddOnLoaded("ElvUI") and NRSKNUI.db.profile.UseElvUI.Enabled end

-- Check if Blizzard Edit Mode is currently active
function NRSKNUI:IsEditModeActive() return EditModeManagerFrame and EditModeManagerFrame:IsShown() end

-- Print message with class colored addon name prefix
function NRSKNUI:Print(msg) print(self:ColorTextByTheme("Norsken") .. "UI:|r " .. msg) end

-- Preview Utilities --

local PreviewManager = { guiOpen = false, editModeActive = false, previewsActive = false, }
NRSKNUI.PreviewManager = PreviewManager

function PreviewManager:UpdatePreviewState()
    local shouldShowPreviews = self.guiOpen or self.editModeActive

    if shouldShowPreviews and not self.previewsActive then
        self:StartAllPreviews()
        self.previewsActive = true
    elseif not shouldShowPreviews and self.previewsActive then
        self:StopAllPreviews()
        self.previewsActive = false
    end
end

function PreviewManager:SetGUIOpen(open)
    self.guiOpen = open
    self:UpdatePreviewState()
end

function PreviewManager:SetEditModeActive(active)
    self.editModeActive = active
    self:UpdatePreviewState()
end

function PreviewManager:StartAllPreviews()
    if self._startingPreviews then return end
    self._startingPreviews = true
    for _, module in NorskenUI:IterateModules() do
        if module.ShowPreview and module.db and module.db.Enabled then module:ShowPreview() end
    end
    self._startingPreviews = false
end

function PreviewManager:StopAllPreviews()
    for _, module in NorskenUI:IterateModules() do
        if module.HidePreview then module:HidePreview() end
    end
end

function PreviewManager:IsPreviewActive()
    return self.previewsActive
end

-- Positioning Utilities --

-- Resolve anchor frame: SCREEN, UIPARENT or SELECTFRAME
function NRSKNUI:ResolveAnchorFrame(anchorFrameType, parentFrameName)
    if anchorFrameType == "SCREEN" or anchorFrameType == "UIPARENT" then
        return UIParent
    elseif anchorFrameType == "SELECTFRAME" and parentFrameName then
        local frame = _G[parentFrameName]
        return frame or UIParent
    end
    return UIParent
end

-- Get text justification based on anchor point
function NRSKNUI:GetTextJustifyFromAnchor(anchorPoint)
    if not anchorPoint then return "CENTER" end
    if anchorPoint == "RIGHT" or anchorPoint == "TOPRIGHT" or anchorPoint == "BOTTOMRIGHT" then
        return "RIGHT"
    elseif anchorPoint == "LEFT" or anchorPoint == "TOPLEFT" or anchorPoint == "BOTTOMLEFT" then
        return "LEFT"
    end
    return "CENTER"
end

-- Global apply position settings func
-- Example usage:
-- NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db, extra: true or empty)
---@param frame Frame
---@param posConfig table Position config with AnchorFrom, AnchorTo, XOffset, YOffset
---@param Config table Config with anchorFrameType, ParentFrame, Strata, ForcePixelPerfect
---@param SetParent boolean? If true, also set frame parent
function NRSKNUI:ApplyFramePosition(frame, posConfig, Config, SetParent)
    if not frame or not posConfig then return end
    local parent = self:ResolveAnchorFrame(Config.anchorFrameType, Config.ParentFrame)
    if SetParent then frame:SetParent(parent) end
    frame:ClearAllPoints()
    frame:SetPoint(
        posConfig.AnchorFrom or "CENTER",
        parent,
        posConfig.AnchorTo or "CENTER",
        posConfig.XOffset or 0,
        posConfig.YOffset or 0
    )
    frame:SetFrameStrata(Config.Strata or "MEDIUM")
    self:SnapFrameToPixels(frame, Config.ForcePixelPerfect)
end
