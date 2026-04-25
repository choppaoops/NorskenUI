-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Safety check
if not NorskenUI then
    error("HuntersMark: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class HuntersMark: AceModule
local HUNTMARK = NorskenUI:NewModule("HuntersMark")

-- Localization
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitClass = UnitClass
local UnitIsBossMob = UnitIsBossMob
local IsInInstance = IsInInstance
local next = next
local wipe = wipe
local type = type

-- Class check
local _, playerClass = UnitClass("player")
local isHunter = playerClass == "HUNTER"

-- Module locals
local SPELL_ID = 257284 -- Hunter's Mark
local markedUnits = {}
local pendingUnitUpdates = {} -- Coalescing table for UNIT_AURA events

-- Get safe unit token from nameplate
local function GetSafeUnitToken(namePlate)
    if not namePlate then return nil end
    local unit = namePlate.unitToken
    if not NRSKNUI:IsSafeValue(unit) then return nil end
    if type(unit) ~= "string" then return nil end
    return unit
end

-- Update db, used for profile changes
function HUNTMARK:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.HuntersMark
end

-- Module init
function HUNTMARK:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Check if player is in raid, if not, we dont try to track anything
local function IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "raid"
end

-- Create container frame with separate icon textures
function HUNTMARK:CreateWarningFrame()
    local frame = CreateFrame("Frame", "NRSKNUI_HuntersMarkWarning", UIParent)
    frame:SetSize(200, 40)

    -- Center text
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(NRSKNUI.FONT, self.db.FontSize or 22, "")
    text:SetPoint("CENTER")
    text:SetText("MISSING MARK")
    frame.text = text

    -- Left icon
    local leftIcon = NRSKNUI:CreateIconFrame(frame, self.db.FontSize, { zoom = 0.3 })
    leftIcon:SetPoint("RIGHT", text, "LEFT", -4, 0)
    frame.leftIcon = leftIcon

    -- Right icon
    local rightIcon = NRSKNUI:CreateIconFrame(frame, self.db.FontSize, { zoom = 0.3 })
    rightIcon:SetPoint("LEFT", text, "RIGHT", 4, 0)
    frame.rightIcon = rightIcon

    frame:Hide()
    self.frame = frame
    self:ApplySettings()
end

-- Main update func that we use to determine if text is to be shown or hidden
function HUNTMARK:UpdateWarningDisplay()
    if not isHunter then return end
    if self.isPreview then return end
    if not self.frame then return end

    -- During full restriction: hide and stop tracking entirely
    if NRSKNUI:IsFullyRestricted() then
        wipe(markedUnits)
        self.frame:Hide()
        return
    end

    -- No boss nameplates visible, hide warning
    if not next(markedUnits) then
        self.frame:Hide()
        return
    end

    -- Check if any visible boss has mark
    for _, hasAura in next, markedUnits do
        if hasAura then
            self.frame:Hide()
            return
        end
    end

    -- Boss nameplate exists but missing mark
    self.frame:Show()
end

-- Function that uses AuraUtil to check if hunter mark exists and its applied by the player
-- We dont care about other hunters marks
function HUNTMARK:CheckUnitForMark(unit)
    if not isHunter then return end
    if NRSKNUI:IsFullyRestricted() then return end

    -- Validate unit is safe to use
    if not NRSKNUI:IsSafeValue(unit) then return end
    if type(unit) ~= "string" then return end
    if not UnitExists(unit) or not UnitIsBossMob(unit) then return end

    local hasMarkNow = false
    local hitSecret = false

    AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(auraInfo)
        if not auraInfo then return end

        -- If any aura field is secret, flag it and skip this aura
        if NRSKNUI:IsSecretValue(auraInfo.spellId) or NRSKNUI:IsSecretValue(auraInfo.sourceUnit) then
            hitSecret = true
            return
        end

        if auraInfo.spellId == SPELL_ID and auraInfo.sourceUnit == "player" then
            hasMarkNow = true
            return true
        end
    end, true)

    -- If we hit secrets, assume mark is present (avoid false warnings)
    if hitSecret then
        markedUnits[unit] = true
    else
        markedUnits[unit] = hasMarkNow
    end

    self:UpdateWarningDisplay()
end

-- Enable/disable nameplate scanning based on raid instance
function HUNTMARK:SetScanningActive(active)
    if not isHunter then return end
    if not self.scannerFrame then return end

    if active then
        self.scannerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.scannerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.scannerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.scannerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.scannerFrame:RegisterEvent("ENCOUNTER_START")
        self.scannerFrame:RegisterEvent("ENCOUNTER_END")
        self.scannerFrame:RegisterUnitEvent("UNIT_AURA",
            "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5",
            "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "target")
    else
        self.scannerFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        self.scannerFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.scannerFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self.scannerFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.scannerFrame:UnregisterEvent("ENCOUNTER_START")
        self.scannerFrame:UnregisterEvent("ENCOUNTER_END")
        self.scannerFrame:UnregisterEvent("UNIT_AURA")
        wipe(markedUnits)
        self.frame:Hide()
    end
end

-- Handle events to use for scanning
function HUNTMARK:StartScanning()
    if not isHunter then return end
    if self.isPreview then return end
    if self.scannerFrame then return end

    self:CreateWarningFrame()

    local scanner = CreateFrame("Frame")
    scanner:RegisterEvent("PLAYER_ENTERING_WORLD")

    scanner:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(0.5, function()
                self:SetScanningActive(IsInRaid())
            end)
            return
        end

        -- Only process other events when in a raid instance
        if not IsInRaid() then return end

        -- Combat/encounter events: restriction system handles state, just hide and wipe
        if event == "ENCOUNTER_START" or event == "PLAYER_REGEN_DISABLED" then
            wipe(markedUnits)
            self.frame:Hide()
            return
        end

        -- When restrictions release, rescan all nameplates
        if event == "ENCOUNTER_END" or event == "PLAYER_REGEN_ENABLED" then
            if NRSKNUI:IsFullyRestricted() then return end
            wipe(markedUnits)
            for _, namePlate in next, C_NamePlate.GetNamePlates() do
                local safeUnit = GetSafeUnitToken(namePlate)
                if safeUnit then
                    self:CheckUnitForMark(safeUnit)
                end
            end
            return
        end

        if NRSKNUI:IsFullyRestricted() then return end

        -- Validate unit is safe before processing
        if not NRSKNUI:IsSafeValue(unit) then return end
        if type(unit) ~= "string" then return end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            markedUnits[unit] = nil
            pendingUnitUpdates[unit] = nil -- Cancel any pending update for removed unit
            self:UpdateWarningDisplay()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            self:CheckUnitForMark(unit)
        elseif event == "UNIT_AURA" then
            -- Coalesce UNIT_AURA events per-unit to prevent redundant scans
            if pendingUnitUpdates[unit] then return end
            pendingUnitUpdates[unit] = true
            C_Timer.After(0, function()
                pendingUnitUpdates[unit] = nil
                if NRSKNUI:IsFullyRestricted() then return end
                self:CheckUnitForMark(unit)
            end)
        end
    end)

    self.scannerFrame = scanner

    -- Initial check if already in raid instance
    if IsInRaid() then
        self:SetScanningActive(true)
    end
end

-- Apply settings func, called from GUI and when profile changes
function HUNTMARK:ApplySettings()
    if not self.db or not self.frame then return end

    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)

    -- Text settings
    local text = self.frame.text
    if text then
        local color = self.db.Color or { 1, 0, 0, 1 }
        NRSKNUI:ApplyFontToText(text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, {})
        text:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end

    -- Icon settings
    local texture = C_Spell.GetSpellTexture(SPELL_ID)

    if self.frame.leftIcon then
        self.frame.leftIcon:SetIconSize(self.db.FontSize)
        self.frame.leftIcon.icon:SetTexture(texture)
    end

    if self.frame.rightIcon then
        self.frame.rightIcon:SetIconSize(self.db.FontSize)
        self.frame.rightIcon.icon:SetTexture(texture)
    end
end

-- Register with EditMode if not already registered
function HUNTMARK:RegisterEditMode()
    if self.editModeRegistered or not NRSKNUI.EditMode then return end

    NRSKNUI.EditMode:RegisterElement({
        key = "HuntersMark",
        displayName = "HuntersMark",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom, self.db.Position.AnchorTo = pos.AnchorFrom, pos.AnchorTo
            self.db.Position.XOffset, self.db.Position.YOffset = pos.XOffset, pos.YOffset
            self:ApplySettings()
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "HuntersMark",
    })
    self.editModeRegistered = true
end

-- Module OnEnable
function HUNTMARK:OnEnable()
    if not isHunter then return end
    if not self.db.Enabled then return end

    self:StartScanning()
    self:RegisterEditMode()
end

-- Module OnDisable
function HUNTMARK:OnDisable()
    if self.scannerFrame then
        self.scannerFrame:UnregisterAllEvents()
        self.scannerFrame:SetScript("OnEvent", nil)
        self.scannerFrame = nil
    end
    if self.frame then
        self.frame:Hide()
        self.frame = nil
    end
    wipe(markedUnits)
    self.isPreview = false
end

-- Preview mode support for GUI and Edit Mode
function HUNTMARK:ShowPreview()
    if not self.frame then
        self:CreateWarningFrame()
    end

    self:RegisterEditMode()
    self.isPreview = true
    self.frame:SetAlpha(1)
    self.frame:Show()
    self:ApplySettings()
end

function HUNTMARK:HidePreview()
    self.isPreview = false
    if not self.frame then return end
    self.frame:Hide()

    if not self.db.Enabled then return end

    -- If module was enabled during preview, scanner never started - start it now
    if not self.scannerFrame then
        self:StartScanning()
        return
    end

    if IsInRaid() then
        -- Rescan all visible nameplates to restore real tracking state
        wipe(markedUnits)
        for _, namePlate in next, C_NamePlate.GetNamePlates() do
            local safeUnit = GetSafeUnitToken(namePlate)
            if safeUnit then
                self:CheckUnitForMark(safeUnit)
            end
        end
    end
end
