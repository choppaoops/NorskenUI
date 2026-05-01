---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("CombatTimer: Addon object not initialized. Check file load order!")
    return
end

---@class CombatTimer: AceModule, AceEvent-3.0
local CT = NorskenUI:NewModule("CombatTimer", "AceEvent-3.0")

local CreateFrame = CreateFrame
local GetTime = GetTime
local IsEncounterInProgress = IsEncounterInProgress
local math_floor, math_max = math.floor, math.max
local string_format = string.format

NRSKNUI.lastCombatDuration = 0

function CT:UpdateDB()
    self.db = NRSKNUI.db.profile.CombatTimer
end

function CT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function FormatTime(total_seconds, format)
    local mins = math_floor(total_seconds / 60)
    local secs = math_floor(total_seconds % 60)

    if format == "MM:SS:MS" then
        local frac = total_seconds - math_floor(total_seconds)
        local ms = math_floor(frac * 10)
        return string_format("%02d:%02d:%d", mins, secs, ms)
    end

    return string_format("%02d:%02d", mins, secs)
end

function CT:CreateFrame()
    if self.frame then return end

    local frame = CreateFrame("Frame", "NRSKNUI_CombatTimerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(100, 25)
    frame:SetFrameLevel(100)
    frame:EnableMouse(false)
    frame:SetMouseClickEnabled(false)
    frame:Hide()

    local text = frame:CreateFontString("NRSKNUI_CombatTimerText", "OVERLAY")
    text:SetPoint("CENTER")
    text:SetFont(NRSKNUI.FONT, 14, "")
    text:SetText("00:00")

    self.frame = frame
    self.text = text
end

function CT:UpdateFrameSize()
    if not self.frame or not self.text then return end

    local currentText = self.text:GetText()
    local refText = (self.db.Format == "MM:SS:MS") and "00:00:0" or "00:00"
    self.text:SetText(refText)

    local backdrop = self.db.Backdrop
    local w = math_floor(self.text:GetStringWidth() + backdrop.bgWidth)
    local h = math_floor(self.text:GetStringHeight() + backdrop.bgHeight)

    self.text:SetText(currentText or refText)
    self.frame:SetSize(math_max(w, 40), math_max(h, 20))
end

function CT:UpdateText()
    if not self.text then return end

    local total_time = self.running and (GetTime() - self.startTime) or NRSKNUI.lastCombatDuration
    local status = FormatTime(total_time, self.db.Format)

    if status ~= self.lastDisplayedText then
        self.text:SetText(status)
        self.lastDisplayedText = status
    end
end

function CT:ApplySettings()
    if not self.frame or not self.text then return end

    self.refreshRate = (self.db.Format == "MM:SS:MS") and 0.1 or 0.25
    NRSKNUI:ApplyFontToText(self.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, {})

    local point = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
    local xOffset = point == "LEFT" and 4 or point == "RIGHT" and -4 or 0
    self.text:ClearAllPoints()
    self.text:SetPoint(point, self.frame, point, xOffset, 0)
    self.text:SetJustifyH(point)

    local textColor = (self.running or self.db.CombatOnly) and self.db.ColorInCombat or self.db.ColorOutOfCombat
    self.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])

    local backdrop = self.db.Backdrop
    if backdrop.Enabled then
        self.frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = backdrop.BorderSize,
        })
        self.frame:SetBackdropColor(unpack(backdrop.Color))
        self.frame:SetBackdropBorderColor(unpack(backdrop.BorderColor))
    else
        self.frame:SetBackdrop(nil)
    end

    self:UpdateFrameSize()
    self:UpdateText()
    self:ApplyPosition()
end

function CT:OnUpdate(elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < self.refreshRate then return end
    self.elapsed = self.elapsed - self.refreshRate

    self:UpdateText()
end

function CT:StartTimer(isEncounterEvent)
    if not self.running then
        self.startTime = GetTime()
        self.running = true
        self.isEncounter = isEncounterEvent
        self.elapsed = 0
        NRSKNUI.lastCombatDuration = 0
        self.lastDisplayedText = ""

        self.frame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)
        self.frame:Show()
        self:ApplySettings()
    elseif isEncounterEvent then
        self.isEncounter = true
    end
end

function CT:StopTimer(isEncounterEvent)
    if not self.running then return end

    local shouldStop = (self.isEncounter == isEncounterEvent) or (self.isEncounter and not C_InstanceEncounter.IsEncounterInProgress())
    if not shouldStop then return end

    NRSKNUI.lastCombatDuration = GetTime() - self.startTime
    self.running = false
    self.isEncounter = false
    self.startTime = 0
    self.frame:SetScript("OnUpdate", nil)

    if self.db.CombatOnly then self.frame:Hide() end

    if self.db.PrintEnd then
        NRSKNUI:Print("Combat lasted " .. FormatTime(NRSKNUI.lastCombatDuration, self.db.Format))
    end

    self:ApplySettings()
end

function CT:ShowPreview()
    if not self.frame then self:CreateFrame() end
    self.isPreview = true
    self.elapsed = 0
    self.frame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)
    self.frame:Show()
    self:ApplySettings()
end

function CT:HidePreview()
    self.isPreview = false
    if not self.frame then return end
    if not self.running then
        self.frame:SetScript("OnUpdate", nil)
        if self.db.CombatOnly then
            self.frame:Hide()
        end
    end
end

function CT:ApplyPosition()
    if not self.frame then return end
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
end

function CT:OnEnable()
    self:CreateFrame()
    self:ApplySettings()

    -- Need to have a delayed positioning so that frames properly exists when trying to anchor to them on load
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:StartTimer(false) end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:StopTimer(false) end)
    self:RegisterEvent("ENCOUNTER_START", function() self:StartTimer(true) end)
    self:RegisterEvent("ENCOUNTER_END", function() self:StopTimer(true) end)

    if not self.db.CombatOnly then self.frame:Show() end

    NRSKNUI.EditMode:RegisterElement({
        key = "CombatTimer",
        displayName = "Combat Timer",
        frame = self.frame,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            self:ApplyPosition()
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "combatTimer",
    })
end

function CT:OnDisable()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end
    self.running = false
    self.isPreview = false
    self:UnregisterAllEvents()
end
