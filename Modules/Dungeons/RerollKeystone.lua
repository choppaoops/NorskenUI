---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("RerollKeystone: Addon object not initialized. Check file load order!")
    return
end

---@class RerollKeystone: AceModule, AceEvent-3.0
local RK = NorskenUI:NewModule("RerollKeystone", "AceEvent-3.0")

local GetTime = GetTime
local GetRealZoneText = GetRealZoneText
local select = select
local GetInstanceInfo = GetInstanceInfo
local C_Timer = C_Timer
local C_ChallengeMode = C_ChallengeMode
local C_MythicPlus = C_MythicPlus

RK.isPreview = false
RK.timerActive = false
RK.timerStart = 0
RK.timerHandle = nil
RK.initialKeyMapID = nil
RK.hasRerolled = false

local function IsInMythicKeystone()
    local difficultyID = select(3, GetInstanceInfo())
    return difficultyID == 8
end

local function CanRerollKey()
    local info = C_ChallengeMode.GetChallengeCompletionInfo()
    if not info then return false end
    local keyStoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if not keyStoneLevel then return false end
    return info.onTime and keyStoneLevel <= info.level
end

function RK:UpdateDB()
    self.db = NRSKNUI.db.profile.RerollKeystone
end

function RK:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function RK:CreateFrame()
    if self.frame then return end

    local frame = NRSKNUI:CreateIconFrame(UIParent, self.db.Size, { name = "NRSKNUI_RerollKeystone", })

    frame.icon:SetTexture(525134)

    frame.text:SetPoint("BOTTOM", frame, "TOP", 0, 8)
    NRSKNUI:ApplyFontToText(frame.text, NRSKNUI:GetEffectiveFont(self.db), self.db.FontSize, self.db.FontOutline, {})
    frame.text:SetTextColor(unpack(self.db.FontColor))

    local keyText = frame:CreateFontString(nil, "OVERLAY")
    keyText:SetPoint("TOP", frame, "BOTTOM", 0, -8)
    NRSKNUI:ApplyFontToText(keyText, NRSKNUI:GetEffectiveFont(self.db), self.db.FontSizeKey, self.db.FontOutline, {})
    keyText:SetTextColor(unpack(self.db.FontColorKey))
    frame.keyText = keyText

    frame:Hide()
    self.frame = frame
end

function RK:ApplySettings()
    if not self.frame then return end
    local font = NRSKNUI:GetEffectiveFont(self.db)

    self.frame:SetIconSize(self.db.Size)
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
    NRSKNUI:ApplyFontToText(self.frame.text, font, self.db.FontSize, self.db.FontOutline, {})
    self.frame.text:SetTextColor(unpack(self.db.FontColor))
    NRSKNUI:ApplyFontToText(self.frame.keyText, font, self.db.FontSizeKey, self.db.FontOutline, {})
    self.frame.keyText:SetTextColor(unpack(self.db.FontColorKey))

    self.frame:RefreshGlow(self.db)
end

function RK:UpdateDisplay()
    if not self.frame then return end
    local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    local keyMapID = C_MythicPlus.GetOwnedKeystoneMapID()
    self.frame.text:SetText(self.hasRerolled and "NEW KEY" or "REROLL KEY?")
    if keyLevel and keyMapID then self.frame.keyText:SetFormattedText("%s - %d", GetRealZoneText(keyMapID), keyLevel) end
end

function RK:CheckTimer()
    if not self.timerActive then return end
    local elapsed = GetTime() - self.timerStart
    if elapsed >= 300 then self:StopTimer() end
end

function RK:StartTimer()
    if self.timerActive then return end
    if not CanRerollKey() then return end

    self.timerActive = true
    self.timerStart = GetTime()
    self.initialKeyMapID = C_MythicPlus.GetOwnedKeystoneMapID()

    if not self.frame then self:CreateFrame() end
    self:ApplySettings()
    self:UpdateDisplay()
    self.frame:Show()
    if self.db.GlowEnabled then self.frame:StartGlow(self.db) end

    self.timerHandle = C_Timer.NewTicker(1, function()
        self:CheckTimer()
    end)

    self:RegisterEvent("ITEM_CHANGED", function()
        if not self.timerActive then return end
        C_Timer.After(1, function()
            local currentMapID = C_MythicPlus.GetOwnedKeystoneMapID()
            if not self.hasRerolled and currentMapID ~= self.initialKeyMapID then
                self.hasRerolled = true
                self:UpdateDisplay()
            end
        end)
    end)
end

function RK:StopTimer()
    self.timerActive = false
    self.timerStart = 0
    self.initialKeyMapID = nil
    self.hasRerolled = false

    if self.timerHandle then
        self.timerHandle:Cancel()
        self.timerHandle = nil
    end

    self:UnregisterEvent("ITEM_CHANGED")
    if self.frame then self.frame:StopGlow() end

    if self.frame and not self.isPreview then self.frame:Hide() end
end

function RK:OnEnable()
    if not self.db.Enabled then return end

    self:CreateFrame()

    C_Timer.After(0.5, function() self:ApplySettings() end)

    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", function()
        if not self.db.Enabled or not IsInMythicKeystone() then return end
        C_Timer.After(1, function() self:StartTimer() end)
    end)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        if self.timerActive and not IsInMythicKeystone() then self:StopTimer() end
    end)
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function() self:StopTimer() end)

    NRSKNUI.EditMode:RegisterElement({
        key = "RerollKeystone",
        displayName = "Reroll Keystone",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
        end,
        guiPath = "RerollKeystone",
    })
end

function RK:OnDisable()
    self:StopTimer()
    if self.frame then
        self.frame:StopGlow()
        self.frame:Hide()
    end
    self.isPreview = false
end

function RK:ShowPreview()
    if not self.frame then self:CreateFrame() end
    self.isPreview = true
    self.frame.text:SetText("REROLL KEY?")
    self.frame.keyText:SetText("Algeth'ar Academy - 21")
    self.frame:SetAlpha(1)
    self.frame:Show()
    self:ApplySettings()
    if self.db.GlowEnabled then self.frame:StartGlow(self.db) end
end

function RK:HidePreview()
    self.isPreview = false
    if not self.frame then return end
    self.frame:StopGlow()
    if not self.timerActive then self.frame:Hide() end
end
