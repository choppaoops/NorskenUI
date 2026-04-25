---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("Gateway: Addon object not initialized. Check file load order!")
    return
end

---@class Gateway: AceModule, AceEvent-3.0
local GATE = NorskenUI:NewModule("Gateway", "AceEvent-3.0")

local C_Item = C_Item
local C_Timer = C_Timer
local IsUsableItem = C_Item.IsUsableItem
local GetItemCount = C_Item.GetItemCount
local GetItemInfo = C_Item.GetItemInfo
local UnitClass = UnitClass
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local unpack = unpack

local GATEWAY_ITEM_ID = 188152

GATE.isPreview = false

function GATE:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.Gateway
end

function GATE:OnInitialize()
    self:UpdateDB()
    self.wasUsable = false
    self.hasItem = false
    self.itemName = nil
    self.hasWarlockInGroup = false
    self:SetEnabledState(false)
end

function GATE:CheckGroupForWarlock()
    local _, _, playerClassID = UnitClass("player")
    if playerClassID == 9 then
        self.hasWarlockInGroup = true
        return true
    end

    if not IsInGroup() then
        self.hasWarlockInGroup = false
        return false
    end

    local numMembers = GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"
    local maxCheck = IsInRaid() and numMembers or (numMembers - 1)

    for i = 1, maxCheck do
        local unit = prefix .. i
        local _, _, classID = UnitClass(unit)
        if classID == 9 then
            self.hasWarlockInGroup = true
            return true
        end
    end

    self.hasWarlockInGroup = false
    return false
end

function GATE:OnEnable()
    if not self.db.Enabled then return end
    self:CreateAlertFrame()
    C_Timer.After(0.5, function() self:ApplySettings() end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "FullUpdate")
    self:RegisterEvent("BAG_UPDATE", "FullUpdate")
    self:RegisterEvent("SPELL_UPDATE_USABLE", "CheckUsable")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupChanged")
    self:FullUpdate()

    if NRSKNUI.EditMode and not self.editModeRegistered then
        NRSKNUI.EditMode:RegisterElement({
            key = "GatewayAlert",
            displayName = "Gateway Alert",
            frame = self.alertFrame,
            getPosition = function() return self.db.Position end,
            setPosition = function(pos)
                self.db.Position.AnchorFrom = pos.AnchorFrom
                self.db.Position.AnchorTo = pos.AnchorTo
                self.db.Position.XOffset = pos.XOffset
                self.db.Position.YOffset = pos.YOffset
                NRSKNUI:ApplyFramePosition(self.alertFrame, self.db.Position, self.db)
            end,
            guiPath = "gateway",
        })
        self.editModeRegistered = true
    end
end

function GATE:OnDisable()
    self:UnregisterAllEvents()
    if self.alertFrame then self.alertFrame:Hide() end
    self.wasUsable = false
    self.hasItem = false
    self.isPreview = false
    self.hasWarlockInGroup = false
end

function GATE:OnGroupChanged()
    self:CheckGroupForWarlock()
    self:CheckUsable()
end

function GATE:FullUpdate()
    C_Timer.After(0.5, function()
        self:CheckGroupForWarlock()
        local count = GetItemCount(GATEWAY_ITEM_ID)
        self.hasItem = count and count > 0
        if self.hasItem then
            if not self.itemName then self.itemName = GetItemInfo(GATEWAY_ITEM_ID) end
            self:CheckUsable()
        else
            self:UpdateState(false)
        end
    end)
end

function GATE:CheckUsable()
    if not self.hasItem then
        self:UpdateState(false)
        return
    end

    if not self.hasWarlockInGroup then
        self:UpdateState(false)
        return
    end

    self:UpdateState(IsUsableItem(GATEWAY_ITEM_ID) and true or false)
end

function GATE:UpdateState(isUsable)
    if self.isPreview then return end
    if isUsable == self.wasUsable then return end
    self.wasUsable = isUsable

    if isUsable then
        self.alertFrame.text:SetText("GATE USABLE")
        self.alertFrame:SetAlpha(1)
        self.alertFrame:Show()
    else
        if self.alertFrame then self.alertFrame:Hide() end
    end
    self:SendMessage("NRSKNUI_GATEWAY_STATE_CHANGED", isUsable)
end

function GATE:CreateAlertFrame()
    if self.alertFrame then return end

    local frame = NRSKNUI:CreateTextFrame(UIParent, 300, 40, { name = "NRSKNUI_GatewayAlert" })
    frame:Hide()

    self.alertFrame = frame
    self:ApplySettings()
    return frame
end

function GATE:ApplySettings()
    if not self.alertFrame then return end
    NRSKNUI:ApplyFramePosition(self.alertFrame, self.db.Position, self.db)
    self.alertFrame.text:SetTextColor(unpack(self.db.Color))
    NRSKNUI:ApplyFontToText(self.alertFrame.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline,
        self.db.FontShadow)

    if self.db.Strata then self.alertFrame:SetFrameStrata(self.db.Strata) end
end

function GATE:ShowPreview()
    if not self.alertFrame then self:CreateAlertFrame() end

    if NRSKNUI.EditMode and not self.editModeRegistered then
        NRSKNUI.EditMode:RegisterElement({
            key = "GatewayAlert",
            displayName = "Gateway Alert",
            frame = self.alertFrame,
            getPosition = function() return self.db.Position end,
            setPosition = function(pos)
                self.db.Position.AnchorFrom = pos.AnchorFrom
                self.db.Position.AnchorTo = pos.AnchorTo
                self.db.Position.XOffset = pos.XOffset
                self.db.Position.YOffset = pos.YOffset
                NRSKNUI:ApplyFramePosition(self.alertFrame, self.db.Position, self.db)
            end,
            guiPath = "gateway",
        })
        self.editModeRegistered = true
    end

    self.isPreview = true
    self.alertFrame.text:SetText("GATE USABLE")
    self.alertFrame:SetAlpha(1)
    self.alertFrame:Show()
    self:ApplySettings()
end

function GATE:HidePreview()
    self.isPreview = false
    if self.db.Enabled then
        self.wasUsable = nil
        self:CheckUsable()
    else
        if self.alertFrame then self.alertFrame:Hide() end
    end
end
