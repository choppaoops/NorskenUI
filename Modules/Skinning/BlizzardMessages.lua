---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("BlizzardMessages: Addon object not initialized. Check file load order!")
    return
end

---@class BlizzardMessages: AceModule, AceEvent-3.0
local BM = NorskenUI:NewModule("BlizzardMessages", "AceEvent-3.0")

local GetTime = GetTime
local C_Timer = C_Timer
local UIParent = UIParent
local _G = _G

function BM:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.BlizzardMessages
end

function BM:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function BM:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end
    C_Timer.After(1.0, function()
        if self:IsEnabled() then
            self:ApplySettings()
        end
    end)
end

function BM:ApplyFont(fontObject, size)
    if not fontObject then return end
    local fontName = NRSKNUI:GetEffectiveFont(self.db)
    local fontPath = NRSKNUI:GetFontPath(fontName)
    local outline = NRSKNUI:GetFontOutline(self.db.FontOutline) or ""
    fontObject:SetFont(fontPath, size, outline)

    local shadowDb = self.db.FontShadow
    if shadowDb and shadowDb.Enabled then
        local c = shadowDb.Color or { 0, 0, 0, 1 }
        fontObject:SetShadowColor(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
        fontObject:SetShadowOffset(shadowDb.OffsetX or 1, shadowDb.OffsetY or -1)
    else
        fontObject:SetShadowColor(0, 0, 0, 0)
        fontObject:SetShadowOffset(0, 0)
    end
end

function BM:ZoneTextStyling()
    local zoneDB = self.db.ZoneText
    if zoneDB.Hide then
        _G.ZoneTextFrame:UnregisterAllEvents()
    else
        self:ApplyFont(_G.ZoneTextFont, zoneDB.MainZone.Size)
        self:ApplyFont(_G.WorldMapTextFont, zoneDB.MainZone.Size)
        self:ApplyFont(_G.SubZoneTextFont, zoneDB.SubZone.Size)
        self:ApplyFont(_G.PVPArenaTextString, zoneDB.SubZone.Size)
        self:ApplyFont(_G.PVPInfoTextString, zoneDB.SubZone.Size)

        _G.ZoneTextFrame:ClearAllPoints()
        _G.ZoneTextFrame:SetPoint(zoneDB.MainZone.Anchor, UIParent, zoneDB.MainZone.Anchor, zoneDB.MainZone.X,
            zoneDB.MainZone.Y)
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED")
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end
end

function BM:StyleUIErrorsFrame()
    local errorsDB = self.db.UIErrorsFrame
    local frame = _G.UIErrorsFrame
    if not errorsDB or not frame then return end

    if errorsDB.Hide then
        frame:Hide()
        frame:SetAlpha(0)
    else
        frame:Show()
        frame:SetAlpha(1)
        self:ApplyFont(_G.ErrorFont, errorsDB.Size)

        if errorsDB.Position then
            frame:ClearAllPoints()
            local anchor = errorsDB.Position.Anchor or "TOP"
            local x = errorsDB.Position.X or 0
            local y = errorsDB.Position.Y or -100
            frame:SetPoint(anchor, UIParent, anchor, x, y)
        end
    end
end

function BM:StyleActionStatusText()
    local statusDB = self.db.ActionStatusText
    local frame = _G.ActionStatus
    if not statusDB or not frame or not frame.Text then return end

    if statusDB.Hide then
        frame.Text:Hide()
        frame.Text:SetAlpha(0)
    else
        frame.Text:Show()
        frame.Text:SetAlpha(1)

        self:ApplyFont(frame.Text, statusDB.Size)

        if statusDB.Position then
            frame.Text:ClearAllPoints()
            local anchor = statusDB.Position.Anchor or "TOP"
            local x = statusDB.Position.X or 0
            local y = statusDB.Position.Y or -150
            frame.Text:SetPoint(anchor, UIParent, anchor, x, y)
        end
    end
end

function BM:StyleChatBubbles()
    local bubblesDB = self.db.ChatBubbles
    local font = _G.ChatBubbleFont
    if not bubblesDB or not bubblesDB.Enabled or not font then return end

    self:ApplyFont(font, bubblesDB.Size)
end

function BM:ResetUIErrorsFrame()
    local frame = _G.UIErrorsFrame
    if not frame then return end
    frame:Show()
    frame:SetAlpha(1)
    if _G.ErrorFont and _G.ErrorFont.SetFont then
        _G.ErrorFont:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
end

function BM:ResetActionStatusText()
    local frame = _G.ActionStatus
    if not frame or not frame.Text then return end
    frame.Text:Show()
    frame.Text:SetAlpha(1)
    frame.Text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("TOP", UIParent, "TOP", 0, -150)
end

function BM:ResetZoneText()
    if _G.ZoneTextFrame then
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED")
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        _G.ZoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end
end

function BM:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    self:UpdateDB()
    if not self.db or not self.db.Enabled then
        self:Reset()
        return
    end
    self:StyleUIErrorsFrame()
    self:StyleActionStatusText()
    self:StyleChatBubbles()
    self:ZoneTextStyling()
end

function BM:Reset()
    self:ResetUIErrorsFrame()
    self:ResetActionStatusText()
    self:ResetZoneText()
end

function BM:PreviewUIErrors()
    local frame = _G.UIErrorsFrame
    if frame then
        frame:Clear()
        frame:AddMessage("Error Message Text", 1, 0.1, 0.1, 1.0, 5)
    end
end

function BM:PreviewActionStatus()
    local frame = _G.ActionStatus
    if frame and frame.Text then
        frame.Text:SetText("Action Status Text")
        frame:Show()
        frame.startTime = GetTime()
        frame.holdTime = 5
        frame.fadeTime = 1
    end
end

function BM:PreviewZone()
    local zoneFrame = _G.ZoneTextFrame
    local zoneText = _G.ZoneTextString
    if zoneFrame and zoneText then
        zoneText:SetText("Main Zone Text")
        zoneFrame:Show()
        zoneFrame.fadingOut = false
        zoneFrame.startTime = GetTime()
    end

    local subFrame = _G.SubZoneTextFrame
    local subText = _G.SubZoneTextString
    if subFrame and subText then
        subText:SetText("Sub Zone Text")
        subFrame:Show()
        subFrame.fadingOut = false
        subFrame.startTime = GetTime()
    end

    local pvpArena = _G.PVPArenaTextString
    if pvpArena then
        pvpArena:SetText("(PVP Arena Text)")
        pvpArena:Show()
        pvpArena.fadingOut = false
        pvpArena.startTime = GetTime()
    end

    local pvpInfo = _G.PVPInfoTextString
    if pvpInfo then
        pvpInfo:SetText("(PVP Info Text)")
        pvpInfo:Show()
        pvpInfo.fadingOut = false
        pvpInfo.startTime = GetTime()
    end
end

function BM:OnDisable()
    self:Reset()
end
