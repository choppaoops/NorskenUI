---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("BloodlustTracker: Addon object not initialized. Check file load order!")
    return
end

---@class BloodlustTracker: AceModule, AceEvent-3.0
local BLT = NorskenUI:NewModule("BloodlustTracker", "AceEvent-3.0")

local GetTime = GetTime
local issecretvalue = issecretvalue
local pairs = pairs

local TIMER_DURATION = 40
local SATED_DEBUFFS = {
    [57723] = true,  -- Drums
    [57724] = true,  -- Shaman
    [80354] = true,  -- Mage
    [95809] = true,  -- Hunter
    [160455] = true, -- Hunter
    [264689] = true, -- Hunter
    [390435] = true, -- Evoker
}

local SATED_DEBUFFS_ICONS = {
    [57723] = 7549207,  -- Midnight Drums
    [57724] = 136012,   -- Bloodlust Shaman
    [80354] = 458224,   -- Mage
    [160455] = 136224,  -- Primal Rage Hunter
    [264689] = 136224,  -- Primal Rage Hunter
    [95809] = 136224,   -- Primal Rage Hunter
    [390435] = 4723908, -- Evoker
}

BLT.isPreview = false
BLT.timerActive = false
BLT.timerStart = 0

function BLT:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.BloodlustTracker
end

function BLT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function BLT:CreateFrame()
    if self.frame then return end

    local frame = NRSKNUI:CreateIconFrame(UIParent, self.db.Size, {
        name = "NRSKNUI_BloodlustTracker",
        zoom = NRSKNUI.GlobalZoom,
        borderColor = { 0, 0, 0, 1 },
        textPoint = "CENTER",
        textOffset = { 0, 0 },
    })

    frame.icon:SetTexture(136012)

    NRSKNUI:SetTextFont(frame.text, NRSKNUI:GetEffectiveFont(self.db), self.db.FontSize, self.db.FontOutline, {})
    frame.text:SetTextColor(1, 1, 1, 1)

    frame:Hide()
    self.frame = frame
end

function BLT:ApplySettings()
    if not self.frame then return end

    self.frame:SetIconSize(self.db.Size)
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
    NRSKNUI:SetTextFont(self.frame.text, NRSKNUI:GetEffectiveFont(self.db), self.db.FontSize, self.db.FontOutline, {})
end

local function ApplySatedIcon(spellId)
    if not BLT.frame then return end
    local icon = SATED_DEBUFFS_ICONS[spellId]
    if icon then
        BLT.frame.icon:SetTexture(icon)
    else
        BLT.frame.icon:SetTexture(136012)
    end
end

function BLT:CheckAddedAuras(addedAuras)
    if self.isPreview then return end
    if not addedAuras then return end
    for _, auraInfo in pairs(addedAuras) do
        if auraInfo and auraInfo.auraInstanceID then
            local fullAuraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInfo.auraInstanceID)
            if fullAuraData and fullAuraData.spellId and not issecretvalue(fullAuraData.spellId) then
                if SATED_DEBUFFS[fullAuraData.spellId] then
                    ApplySatedIcon(fullAuraData.spellId)
                    self:StartTimer()
                    return
                end
            end
        end
    end
end

function BLT:StartTimer()
    if not self.frame then return end

    self.timerActive = true
    self.timerStart = GetTime()
    self.frame:Show()
    self:StartUpdateLoop()
end

function BLT:StopTimer()
    self.timerActive = false
    self.timerStart = 0

    if self.frame and not self.isPreview then
        self.frame:Hide()
    end

    self:StopUpdateLoop()
end

function BLT:UpdateTimer()
    if not self.timerActive or not self.frame then return end

    local elapsed = GetTime() - self.timerStart
    local remaining = TIMER_DURATION - elapsed

    if remaining <= 0 then
        self:StopTimer()
        return
    end

    self.frame.text:SetText(string.format("%d", remaining))
end

function BLT:StartUpdateLoop()
    if not self.frame then return end

    self.frame:SetScript("OnUpdate", function(_, elapsed)
        self.updateAccum = (self.updateAccum or 0) + elapsed
        if self.updateAccum >= 0.1 then
            self.updateAccum = 0
            self:UpdateTimer()
        end
    end)
end

function BLT:StopUpdateLoop()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    self.updateAccum = 0
end

function BLT:OnAuraChange(_, unit, updateInfo)
    if unit ~= "player" then return end
    if not updateInfo or not updateInfo.addedAuras then return end

    self:CheckAddedAuras(updateInfo.addedAuras)
end

function BLT:OnEnable()
    if not self.db.Enabled then return end

    self:CreateFrame()
    C_Timer.After(0.5, function() self:ApplySettings() end)

    self:RegisterEvent("UNIT_AURA", "OnAuraChange")

    NRSKNUI.EditMode:RegisterElement({
        key = "BloodlustTracker",
        displayName = "Bloodlust Tracker",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
        end,
        guiPath = "BloodlustTracker",
    })
end

function BLT:OnDisable()
    self:UnregisterAllEvents()
    self:StopTimer()
    if self.frame then
        self.frame:Hide()
    end
    self.isPreview = false
end

function BLT:ShowPreview()
    if not self.frame then self:CreateFrame() end
    self.isPreview = true
    self.frame.icon:SetTexture(136012)
    self.frame.text:SetText("40")
    self.frame:SetAlpha(1)
    self.frame:Show()
    self:ApplySettings()
end

function BLT:HidePreview()
    self.isPreview = false
    if not self.frame then return end
    if self.db.Enabled and self.timerActive then return end
    self.frame:Hide()
end
