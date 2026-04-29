---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("HuntersMark: Addon object not initialized. Check file load order!")
    return
end

---@class HuntersMark: AceModule, AceEvent-3.0
local HUNTMARK = NorskenUI:NewModule("HuntersMark", "AceEvent-3.0")

local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitClass = UnitClass
local UnitIsBossMob = UnitIsBossMob
local IsInInstance = IsInInstance
local C_NamePlate = C_NamePlate
local next = next
local wipe = wipe
local type = type

local _, playerClass = UnitClass("player")
local isHunter = playerClass == "HUNTER"

local SPELL_ID = 257284
local markedUnits = {}
local pendingUnitUpdates = {}

HUNTMARK.isPreview = false

local function GetSafeUnitToken(namePlate)
    if not namePlate then return nil end
    local unit = namePlate.unitToken
    if not NRSKNUI:IsSafeValue(unit) then return nil end
    if type(unit) ~= "string" then return nil end
    return unit
end

local function IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "raid"
end

function HUNTMARK:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.HuntersMark
end

function HUNTMARK:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function HUNTMARK:CreateWarningFrame()
    local frame = CreateFrame("Frame", "NRSKNUI_HuntersMarkWarning", UIParent)
    frame:SetSize(200, 40)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(NRSKNUI.FONT, self.db.FontSize, "")
    text:SetPoint("CENTER")
    text:SetText("MISSING MARK")
    frame.text = text

    local leftIcon = NRSKNUI:CreateIconFrame(frame, self.db.FontSize, { zoom = 0.3 })
    leftIcon:SetPoint("RIGHT", text, "LEFT", -4, 0)
    frame.leftIcon = leftIcon

    local rightIcon = NRSKNUI:CreateIconFrame(frame, self.db.FontSize, { zoom = 0.3 })
    rightIcon:SetPoint("LEFT", text, "RIGHT", 4, 0)
    frame.rightIcon = rightIcon

    frame:Hide()
    self.frame = frame
    self:ApplySettings()
end

function HUNTMARK:UpdateWarningDisplay()
    if not isHunter then return end
    if self.isPreview then return end
    if not self.frame then return end

    if NRSKNUI:IsFullyRestricted() then
        wipe(markedUnits)
        self.frame:Hide()
        return
    end

    if not next(markedUnits) then
        self.frame:Hide()
        return
    end

    for _, hasAura in next, markedUnits do
        if hasAura then
            self.frame:Hide()
            return
        end
    end

    self.frame:Show()
end

function HUNTMARK:CheckUnitForMark(unit)
    if not isHunter then return end
    if NRSKNUI:IsFullyRestricted() then return end
    if not NRSKNUI:IsSafeValue(unit) then return end
    if type(unit) ~= "string" then return end
    if not UnitExists(unit) or not UnitIsBossMob(unit) then return end

    local hasMarkNow = false
    local hitSecret = false

    AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(auraInfo)
        if not auraInfo then return end

        if NRSKNUI:IsSecretValue(auraInfo.spellId) or NRSKNUI:IsSecretValue(auraInfo.sourceUnit) then
            hitSecret = true
            return
        end

        if auraInfo.spellId == SPELL_ID and auraInfo.sourceUnit == "player" then
            hasMarkNow = true
            return true
        end
    end, true)

    -- Assume mark present if we hit secrets to avoid false warnings
    if hitSecret then
        markedUnits[unit] = true
    else
        markedUnits[unit] = hasMarkNow
    end

    self:UpdateWarningDisplay()
end

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

        if not IsInRaid() then return end

        if event == "ENCOUNTER_START" or event == "PLAYER_REGEN_DISABLED" then
            wipe(markedUnits)
            self.frame:Hide()
            return
        end

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
        if not NRSKNUI:IsSafeValue(unit) then return end
        if type(unit) ~= "string" then return end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            markedUnits[unit] = nil
            pendingUnitUpdates[unit] = nil
            self:UpdateWarningDisplay()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            self:CheckUnitForMark(unit)
        elseif event == "UNIT_AURA" then
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

    if IsInRaid() then
        self:SetScanningActive(true)
    end
end

function HUNTMARK:ApplySettings()
    if not self.db or not self.frame then return end

    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)

    local text = self.frame.text
    if text then
        local color = self.db.Color
        NRSKNUI:ApplyFontToText(text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, self.db.FontShadow)
        text:SetTextColor(color[1], color[2], color[3], color[4])
    end

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

function HUNTMARK:OnEnable()
    if not isHunter then return end
    if not self.db.Enabled then return end

    self:StartScanning()

    NRSKNUI.EditMode:RegisterElement({
        key = "HuntersMark",
        displayName = "Hunters Mark Warning",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            self:ApplySettings()
        end,
        guiPath = "HuntersMark",
    })
end

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

function HUNTMARK:ShowPreview()
    if not self.frame then self:CreateWarningFrame() end
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

    if not self.scannerFrame then
        self:StartScanning()
        return
    end

    if IsInRaid() then
        wipe(markedUnits)
        for _, namePlate in next, C_NamePlate.GetNamePlates() do
            local safeUnit = GetSafeUnitToken(namePlate)
            if safeUnit then
                self:CheckUnitForMark(safeUnit)
            end
        end
    end
end
