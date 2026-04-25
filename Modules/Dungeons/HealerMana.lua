-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("HealerMana: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class HealerMana: AceModule, AceEvent-3.0, AceTimer-3.0
local HM = NorskenUI:NewModule("HealerMana", "AceEvent-3.0", "AceTimer-3.0")

-- Localization
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsConnected = UnitIsConnected
local UnitClass = UnitClass
local UnitName = UnitName
local UnitPowerPercent = UnitPowerPercent
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetInspectSpecialization = GetInspectSpecialization
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local pairs = pairs
local wipe = wipe
local issecretvalue = issecretvalue

-- Module state
HM.healerFrames = {}
HM.containerFrame = nil
HM.updateTimer = nil
HM.currentHealer = nil

-- Update db reference
function HM:UpdateDB()
    if NRSKNUI.db and NRSKNUI.db.profile then
        self.db = NRSKNUI.db.profile.HealerMana
    end
end

-- Module init
function HM:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Healing spec icon fallbacks by class
local HEALER_SPEC_ICONS = {
    DRUID = 136041,   -- Restoration
    MONK = 608952,    -- Mistweaver
    PALADIN = 135920, -- Holy
    PRIEST = 135940,  -- Discipline
    SHAMAN = 136052,  -- Restoration
    EVOKER = 4622476, -- Preservation
}

-- Get spec icon for a spec ID
local function GetSpecIcon(specID)
    if not specID or specID == 0 then return nil end
    local _, _, _, icon = GetSpecializationInfoByID(specID)
    return icon
end

-- Check if unit is a healer
local function IsHealer(unit)
    local role = UnitGroupRolesAssigned(unit)
    return role == "HEALER"
end

-- Display mana percent in the frame
local function DisplayManaPercent(fontString, unit)
    local pct = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
    fontString:SetText(string.format("%.0f%%", pct))
end

-- Create a healer frame
function HM:CreateHealerFrame(index)
    local frame = CreateFrame("Frame", "NorskenUI_HealerMana_" .. index, self.containerFrame)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)

    -- Icon container with border
    frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconFrame:SetSize(self.db.IconSize, self.db.IconSize)
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.iconFrame:SetBackdropColor(0, 0, 0, 1)
    frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Icon texture
    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Name
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetPoint("LEFT", frame.iconFrame, "RIGHT", self.db.NameXOffset, self.db.NameYOffset)
    frame.name:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(frame.name, self.db.FontFace, self.db.NameFontSize, self.db.FontOutline or "OUTLINE")

    -- Mana
    frame.mana = frame:CreateFontString(nil, "OVERLAY")
    frame.mana:SetPoint("LEFT", frame.iconFrame, "RIGHT", self.db.ManaXOffset, self.db.ManaYOffset)
    frame.mana:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(frame.mana, self.db.FontFace, self.db.ManaFontSize, self.db.FontOutline or "OUTLINE")

    frame:Hide()
    return frame
end

-- Get or create healer frame
function HM:GetHealerFrame(index)
    if not self.healerFrames[index] then
        self.healerFrames[index] = self:CreateHealerFrame(index)
    end
    return self.healerFrames[index]
end

-- Update healer frame appearance
function HM:UpdateFrameAppearance(frame)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)
    frame.iconFrame:SetSize(self.db.IconSize, self.db.IconSize)

    frame.name:ClearAllPoints()
    frame.name:SetPoint("LEFT", frame.iconFrame, "RIGHT", self.db.NameXOffset, self.db.NameYOffset)
    NRSKNUI:ApplyFontToText(frame.name, self.db.FontFace, self.db.NameFontSize, self.db.FontOutline)

    frame.mana:ClearAllPoints()
    frame.mana:SetPoint("LEFT", frame.iconFrame, "RIGHT", self.db.ManaXOffset, self.db.ManaYOffset)
    NRSKNUI:ApplyFontToText(frame.mana, self.db.FontFace, self.db.ManaFontSize, self.db.FontOutline)
end

-- Create container frame
function HM:CreateContainer()
    if self.containerFrame then return self.containerFrame end

    local frame = CreateFrame("Frame", "NorskenUI_HealerMana_Container", UIParent)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)
    frame:SetFrameStrata(self.db.Strata or "HIGH")

    local pos = self.db.Position
    frame:ClearAllPoints()
    frame:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)

    self.containerFrame = frame
    return frame
end

-- Position the healer frame
function HM:PositionFrame()
    local frame = self.healerFrames[1]
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.containerFrame, "TOPLEFT", 0, 0)
    end
    self.containerFrame:SetSize(self.db.FrameWidth, self.db.IconSize)
end

-- Find and cache the first healer in party
function HM:FindHealer()
    if not self.db or not self.db.Enabled then return end
    local inGroup = IsInGroup()
    local inRaid = IsInRaid()

    -- Only show in party
    if not inGroup or inRaid then
        self.currentHealer = nil
        if self.healerFrames[1] then
            self.healerFrames[1]:Hide()
        end
        if self.containerFrame then
            self.containerFrame:Hide()
        end
        return
    end

    -- Find healer
    local healerUnit, healerName, healerSpecID, healerClass

    if IsHealer("player") then
        healerUnit = "player"
    else
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitIsConnected(unit) and IsHealer(unit) then
                healerUnit = unit
                break
            end
        end
    end

    -- No healer found
    if not healerUnit then
        self.currentHealer = nil
        if self.healerFrames[1] then
            self.healerFrames[1]:Hide()
        end
        if self.containerFrame then
            self.containerFrame:Hide()
        end
        return
    end

    -- Cache healer info (UnitName can return secret in M+)
    healerName = UnitName(healerUnit)
    if issecretvalue and issecretvalue(healerName) then
        healerName = "Healer"
    end
    healerSpecID = GetInspectSpecialization(healerUnit)
    _, healerClass = UnitClass(healerUnit)

    self.currentHealer = {
        unit = healerUnit,
        name = healerName,
        specID = healerSpecID,
        class = healerClass,
        classColor = NRSKNUI:GetClassColor(healerClass),
    }

    -- Update frame with static info
    self:UpdateHealerFrame()
end

-- Update healer frame with cached info
function HM:UpdateHealerFrame()
    local healer = self.currentHealer
    if not healer then return end
    local frame = self:GetHealerFrame(1)

    -- Set icon
    local icon = GetSpecIcon(healer.specID)
    if icon then
        frame.icon:SetTexture(icon)
        frame.icon:SetTexCoord(0, 1, 0, 1)
        if NRSKNUI.ApplyZoom then
            NRSKNUI:ApplyZoom(frame.icon, 0.3)
        end
    else
        -- Fallback to healing spec icon if spec not available yet
        local fallbackIcon = HEALER_SPEC_ICONS[healer.class]
        if fallbackIcon then
            frame.icon:SetTexture(fallbackIcon)
            frame.icon:SetTexCoord(0, 1, 0, 1)
            if NRSKNUI.ApplyZoom then
                NRSKNUI:ApplyZoom(frame.icon, 0.3)
            end
        end
    end

    -- Set name with class color
    frame.name:SetText(healer.name)
    frame.name:SetTextColor(healer.classColor[1], healer.classColor[2], healer.classColor[3])

    -- Set mana color
    local manaColor = self.db.HighManaColor
    frame.mana:SetTextColor(manaColor[1], manaColor[2], manaColor[3])

    -- Update mana value
    DisplayManaPercent(frame.mana, healer.unit)

    -- Position and show
    self:PositionFrame()
    frame:Show()
    self.containerFrame:Show()
end

-- Update only mana text
function HM:UpdateMana()
    local healer = self.currentHealer
    if not healer then return end

    local frame = self.healerFrames[1]
    if not frame or not frame:IsShown() then return end

   DisplayManaPercent(frame.mana, healer.unit)
end

-- Apply settings
function HM:ApplySettings()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then
        if self.containerFrame then
            self.containerFrame:Hide()
        end
        return
    end

    -- Create/update container
    self:CreateContainer()

    -- Update container position
    local pos = self.db.Position
    self.containerFrame:ClearAllPoints()
    self.containerFrame:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
    self.containerFrame:SetFrameStrata(self.db.Strata or "HIGH")

    -- Update existing frame appearances
    for _, frame in pairs(self.healerFrames) do
        self:UpdateFrameAppearance(frame)
    end

    -- Force update
    self:FindHealer()
end

-- Refresh all frames
function HM:Refresh()
    -- Clear cache
    self.currentHealer = nil

    -- Hide and clear all frames
    for _, frame in pairs(self.healerFrames) do frame:Hide() end
    wipe(self.healerFrames)

    -- Recreate container
    if self.containerFrame then
        self.containerFrame:Hide()
        self.containerFrame = nil
    end

    self:ApplySettings()
end

-- Start update timer for mana checks on the healer
function HM:StartUpdates()
    if self.updateTimer then return end
    self.updateTimer = self:ScheduleRepeatingTimer("UpdateMana", 1)
end

-- Stop update timer
function HM:StopUpdates()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
end

-- Module OnEnable
function HM:OnEnable()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end
    self:ApplySettings()
    self:StartUpdates()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "FindHealer")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "FindHealer")
end

-- Module OnDisable
function HM:OnDisable()
    self:StopUpdates()
    self:UnregisterAllEvents()
    self.currentHealer = nil
    if self.containerFrame then self.containerFrame:Hide() end
    for _, frame in pairs(self.healerFrames) do frame:Hide() end
end
