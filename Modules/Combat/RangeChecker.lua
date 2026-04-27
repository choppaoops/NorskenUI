---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("RangeChecker: Addon object not initialized. Check file load order!")
    return
end

---@class RangeChecker: AceModule, AceEvent-3.0
local RANGE = NorskenUI:NewModule("RangeChecker", "AceEvent-3.0")
local LRC = LibStub("LibRangeCheck-3.0", true)

local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local InCombatLockdown = InCombatLockdown
local unpack = unpack
local tostring = tostring

function RANGE:UpdateDB()
    self.db = NRSKNUI.db.profile.RangeChecker
end

function RANGE:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function RANGE:BuildGradientPalette()
    local c1 = self.db.ColorOne
    local c2 = self.db.ColorTwo
    local c3 = self.db.ColorThree
    local c4 = self.db.ColorFour

    self.gradientPalette = {
        c1[1], c1[2], c1[3],
        c2[1], c2[2], c2[3],
        c3[1], c3[2], c3[3],
        c4[1], c4[2], c4[3],
    }
end

function RANGE:GetColorForRange(minRange)
    return NRSKNUI:ColorGradient(
        self.db.MaxRange - (minRange or 0),
        self.db.MaxRange,
        unpack(self.gradientPalette)
    )
end

function RANGE:FormatRangeText(minRange, maxRange)
    if minRange and maxRange then
        return minRange .. " - " .. maxRange
    elseif maxRange then
        return "0 - " .. maxRange
    elseif minRange then
        return tostring(minRange)
    end
    return "--"
end

function RANGE:CreateFrame()
    if self.frame then return end

    local frame = CreateFrame("Frame", "NRSKNUI_RangeCheckerFrame", UIParent)
    frame:SetSize(100, 25)
    NRSKNUI:ApplyFramePosition(frame, self.db.Position, self.db)
    frame:EnableMouse(false)
    frame:SetMouseClickEnabled(false)
    frame:Hide()

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetFont(NRSKNUI.FONT, 14, "")
    text:SetText("")
    text:SetJustifyH("CENTER")

    self.frame = frame
    self.text = text
    self:ApplySettings()
end

function RANGE:ApplySettings()
    self:BuildGradientPalette()
    if not self.frame or not self.text then return end
    NRSKNUI:ApplyFontToText(self.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, self.db.FontShadow)
    self:ApplyPosition()
end

function RANGE:ApplyPosition()
    if not self.db.Enabled or not self.frame then return end
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
end

function RANGE:ShouldShow()
    if not self.db.Enabled then return false end
    if self.isPreview then return true end
    if not UnitExists("target") then return false end
    if UnitIsUnit("target", "player") then return false end
    if self.db.CombatOnly and not InCombatLockdown() then return false end
    return true
end

function RANGE:UpdateRange()
    if not self.frame or not self.text then return end

    if not self:ShouldShow() then
        self.frame:Hide()
        return
    end

    local minRange, maxRange
    if self.isPreview then
        minRange, maxRange = 10, 12
    elseif LRC then
        minRange, maxRange = LRC:GetRange("target")
    end

    self.text:SetText(self:FormatRangeText(minRange, maxRange))

    local rangeValue = minRange or maxRange or 40
    if rangeValue ~= self.lastRangeValue then
        self.lastRangeValue = rangeValue
        local r, g, b = self:GetColorForRange(rangeValue)
        self.text:SetTextColor(r, g, b, 1)
    end

    local textWidth = self.text:GetStringWidth() or 50
    local textHeight = self.text:GetStringHeight() or 20
    self.frame:SetSize(textWidth + 10, textHeight + 4)
    self.frame:Show()
end

local updateElapsed = 0
function RANGE:OnUpdate(elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < self.db.UpdateThrottle then return end
    updateElapsed = 0
    self:UpdateRange()
end

function RANGE:ShowPreview()
    if not self.frame then self:CreateFrame() end
    self.isPreview = true
    self:ApplySettings()
    self:UpdateRange()
end

function RANGE:HidePreview()
    self.isPreview = false
    self:UpdateRange()
end

function RANGE:OnEnable()
    if not self.db.Enabled then return end
    if not LRC then
        NRSKNUI:Print("RangeChecker: LibRangeCheck-3.0 not found!")
        return
    end

    self:CreateFrame()
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:UpdateRange() end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:UpdateRange() end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:UpdateRange() end)
    self.frame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)
    self:UpdateRange()

    NRSKNUI.EditMode:RegisterElement({
        key = "RangeChecker",
        displayName = "Range Checker",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
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
        guiPath = "RangeChecker",
    })
end

function RANGE:OnDisable()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end
    self.isPreview = false
    self:UnregisterAllEvents()
end
