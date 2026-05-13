---@class NRSKNUI
local NRSKNUI = select(2, ...)
local Theme = NRSKNUI.Theme

if not NorskenUI then
    error("CharacterPanel: Addon object not initialized. Check file load order!")
    return
end

---@class CharacterPanel: AceModule, AceEvent-3.0, AceHook-3.0
local CHAR = NorskenUI:NewModule("CharacterPanel", "AceEvent-3.0", "AceHook-3.0")

local GetAverageItemLevel = GetAverageItemLevel
local GetInventoryItemLink = GetInventoryItemLink
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local C_Item = C_Item
local C_Container = C_Container
local CreateFrame = CreateFrame
local pairs = pairs
local ipairs = ipairs
local format = string.format
local floor, abs, min, max = math.floor, math.abs, math.min, math.max
local tinsert = table.insert
local wipe = table.wipe
local C_Timer = C_Timer

local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4
local LE_ITEM_CLASS_GEM = Enum.ItemClass.Gem or 3
local SocketInventoryItem = SocketInventoryItem
local AcceptSockets = AcceptSockets
local CloseSocketInfo = CloseSocketInfo
local InCombatLockdown = InCombatLockdown
local ClearCursor = ClearCursor
local HideUIPanel = HideUIPanel

local SLOT_FRAMES = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [5] = "CharacterChestSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [9] = "CharacterWristSlot",
    [10] = "CharacterHandsSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
    [15] = "CharacterBackSlot",
    [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot",
}

local ITEM_TRACKS = {
    { keyword = "Myth",       letter = "M", color = { 1.00, 0.50, 0.00 } },
    { keyword = "Hero",       letter = "H", color = { 0.78, 0.30, 0.78 } },
    { keyword = "Champion",   letter = "C", color = { 0.00, 0.70, 1.00 } },
    { keyword = "Veteran",    letter = "V", color = { 0.00, 0.80, 0.00 } },
    { keyword = "Adventurer", letter = "A", color = { 0.70, 0.70, 0.70 } },
}

local CRAFTED_TRACKS = {
    { minIlvl = 285, letter = "C", color = { 1.00, 0.50, 0.00 } }, -- Mythic Crafted
    { minIlvl = 272, letter = "C", color = { 0.78, 0.30, 0.78 } }, -- Heroic Crafted
    { minIlvl = 259, letter = "C", color = { 0.00, 0.70, 1.00 } }, -- Normal Crafted
}

local qualityAtlasPattern = "|A:(Professions%-ChatIcon%-Quality%-[^:]+):%d+:%d+"

local function GetQualityAtlasFromLink(link)
    if not link then return nil end
    return link:match(qualityAtlasPattern)
end

local function SetQualityAtlas(texture, atlas)
    if not atlas then
        texture:Hide()
        return
    end
    texture:SetAtlas(atlas, false)
    texture:Show()
end

local function GetGemStatsFromLink(link)
    if not link then return nil end
    local data = C_TooltipInfo.GetHyperlink(link)
    if not data or not data.lines then return nil end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text and text:match("^%+%d+") then
            return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        end
    end
    return nil
end

function CHAR:UpdateDB() self.db = NRSKNUI.db.profile.CharacterPanel end

function CHAR:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function CHAR:UpdateItemLevelText()
    local itemLevelFrame = CharacterStatsPane and CharacterStatsPane.ItemLevelFrame
    if not itemLevelFrame or not itemLevelFrame.Value then return end

    local _, avgItemLevelEquipped = GetAverageItemLevel()
    if self.db.Enabled and self.db.DecimalItemLevel then
        itemLevelFrame.Value:SetText(format("%.2f", avgItemLevelEquipped))
    else
        itemLevelFrame.Value:SetText(format("%d", floor(avgItemLevelEquipped)))
    end
end

function CHAR:SetupDecimalItemLevel()
    if self._decimalIlvlHooked then return end
    self._decimalIlvlHooked = true

    self:SecureHook("PaperDollFrame_SetItemLevel", function(_, unit)
        if not self.db.DecimalItemLevel then return end
        if unit ~= "player" then return end
        self:UpdateItemLevelText()
    end)
end

function CHAR:ApplyFont(fontString, size)
    local db = self.db
    local fontFace = db.FontFace or "Expressway"
    local outline = db.FontOutline or "OUTLINE"
    local shadow = db.FontShadow or {}

    NRSKNUI:ApplyFontToText(fontString, fontFace, size, outline, {})

    if shadow.Enabled and outline ~= "SOFTOUTLINE" then
        local color = shadow.Color or { 0, 0, 0, 1 }
        fontString:SetShadowColor(color[1], color[2], color[3], color[4])
        fontString:SetShadowOffset(shadow.OffsetX or 1, shadow.OffsetY or -1)
    else
        fontString:SetShadowColor(0, 0, 0, 0)
    end
end

function CHAR:StyleCharacterTexts()
    local levelText = CharacterLevelText
    if levelText then
        self:ApplyFont(levelText, self.db.LevelTextSize or 12)
        levelText:SetWidth(0)
        levelText:SetWordWrap(true)
    end

    local nameText = CharacterFrameTitleText
    if nameText then
        self:ApplyFont(nameText, self.db.NameTextSize or 12)
    end

    self:StyleStatsPaneTexts()
end

function CHAR:StyleStatsPaneTexts()
    local statsPane = CharacterStatsPane
    if not statsPane then return end

    local categorySize = self.db.CategoryFontSize or 12

    if statsPane.ItemLevelCategory and statsPane.ItemLevelCategory.Title then
        self:ApplyFont(statsPane.ItemLevelCategory.Title, categorySize)
    end

    if statsPane.ItemLevelFrame and statsPane.ItemLevelFrame.Value then
        self:ApplyFont(statsPane.ItemLevelFrame.Value, self.db.IlvlValueSize or 16)
    end

    local categories = { statsPane.AttributesCategory, statsPane.EnhancementsCategory }
    for _, category in ipairs(categories) do
        if category and category.Title then
            self:ApplyFont(category.Title, categorySize)
        end
    end

    self:RefreshStatFonts()
end

function CHAR:RefreshStatFonts()
    -- Fonts are applied via hooksecurefunc on PaperDollFrame_SetLabelAndText
    -- Calling PaperDollFrame_UpdateStats() directly causes taint with secret values
end

-- Item Track Indicators --

function CHAR:GetItemTrack(slotID)
    local data = C_TooltipInfo.GetInventoryItem("player", slotID)
    if not data or not data.lines then return nil end

    local isCrafted = false
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text then
            if text:find("Upgrade Level:") then
                for _, track in ipairs(ITEM_TRACKS) do if text:find(track.keyword) then return track end end
            end
            if text:find("Crafted") then isCrafted = true end
        end
    end

    if isCrafted then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            local ilvl = GetDetailedItemLevelInfo(itemLink)
            if ilvl then
                for _, track in ipairs(CRAFTED_TRACKS) do if ilvl >= track.minIlvl then return track end end
            end
        end
    end

    return nil
end

local RIGHT_SLOTS = {
    [6] = true,  -- Waist
    [7] = true,  -- Legs
    [8] = true,  -- Feet
    [10] = true, -- Hands
    [11] = true, -- Finger0
    [12] = true, -- Finger1
    [13] = true, -- Trinket0
    [14] = true, -- Trinket1
    [17] = true, -- SecondaryHand
}

function CHAR:CreateTrackOverlay(slotFrame, slotID)
    if slotFrame._trackOverlay then return slotFrame._trackOverlay end

    local isRight = RIGHT_SLOTS[slotID]
    local overlay = CreateFrame("Frame", nil, slotFrame)
    overlay:SetSize(14, 14)
    overlay:SetFrameLevel(slotFrame:GetFrameLevel() + 10)

    if isRight then
        overlay:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMRIGHT", 1, 0)
    else
        overlay:SetPoint("BOTTOMLEFT", slotFrame, "BOTTOMLEFT", 0, 0)
    end

    overlay.text = overlay:CreateFontString(nil, "OVERLAY")
    NRSKNUI:ApplyFontToText(overlay.text, "Expressway", 12, "OUTLINE", {})
    overlay.text:SetShadowColor(0, 0, 0, 0)

    if isRight then
        overlay.text:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
        overlay.text:SetJustifyH("RIGHT")
    else
        overlay.text:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
        overlay.text:SetJustifyH("LEFT")
    end

    overlay:Hide()
    slotFrame._trackOverlay = overlay
    return overlay
end

function CHAR:UpdateSlotTrackIndicator(slotID)
    local frameName = SLOT_FRAMES[slotID]
    if not frameName then return end

    local slotFrame = _G[frameName]
    if not slotFrame then return end

    local overlay = self:CreateTrackOverlay(slotFrame, slotID)
    local track = self:GetItemTrack(slotID)

    if track then
        overlay.text:SetText(track.letter)
        overlay.text:SetTextColor(track.color[1], track.color[2], track.color[3])
        overlay:Show()
    else
        overlay:Hide()
    end
end

function CHAR:UpdateAllTrackIndicators()
    if not self.db.TrackIndicators or not self.db.TrackIndicators.Enabled then return end
    for slotID in pairs(SLOT_FRAMES) do
        self:UpdateSlotTrackIndicator(slotID)
    end
end

function CHAR:HideAllTrackIndicators()
    for _, frameName in pairs(SLOT_FRAMES) do
        local slotFrame = _G[frameName]
        if slotFrame and slotFrame._trackOverlay then
            slotFrame._trackOverlay:Hide()
        end
    end
end

function CHAR:SetupTrackIndicators()
    if not self.db.TrackIndicators or not self.db.TrackIndicators.Enabled then return end
    if self._trackIndicatorsHooked then return end
    self._trackIndicatorsHooked = true

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(_, slotID)
        if self.db.TrackIndicators and self.db.TrackIndicators.Enabled then
            self:UpdateSlotTrackIndicator(slotID)
        end
    end)

    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", function()
            if self.db.TrackIndicators and self.db.TrackIndicators.Enabled then
                self:UpdateAllTrackIndicators()
            end
        end)
    end
end

function CHAR:SetupStatTextHook()
    if self._statTextHooked then return end
    self._statTextHooked = true

    hooksecurefunc("PaperDollFrame_SetLabelAndText", function(statFrame)
        if not self.db.Enabled then return end
        if CharacterStatsPane and statFrame == CharacterStatsPane.ItemLevelFrame then return end
        local statsSize = self.db.StatsFontSize or 12
        if statFrame.Label then
            self:ApplyFont(statFrame.Label, statsSize)
        end
        if statFrame.Value then
            self:ApplyFont(statFrame.Value, statsSize)
        end
    end)
end

function CHAR:UpdateLevelTextWithFaction()
    local levelText = CharacterLevelText
    if not levelText then return end

    local text = levelText:GetText()
    if not text then return end

    text = text:gsub(" |c%x%x%x%x%x%x%x%x%([AH]%)|r$", "")

    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then
        text = text .. " |cff3399ff(A)|r"
    elseif faction == "Horde" then
        text = text .. " |cffe63333(H)|r"
    end

    levelText:SetText(text)
end

function CHAR:SetupLevelTextHook()
    if self._levelTextHooked then return end
    self._levelTextHooked = true

    hooksecurefunc("PaperDollFrame_SetLevel", function()
        if self.db.Enabled then
            self:UpdateLevelTextWithFaction()
        end
    end)
end

function CHAR:ApplySettings()
    if not self.db.Enabled then return end
    self:SetupDecimalItemLevel()
    self:UpdateItemLevelText()
    self:StyleCharacterTexts()
    self:SetupStatTextHook()
    self:SetupLevelTextHook()
    self:UpdateLevelTextWithFaction()
    self:SetupGemSocketHelper()
    self:SetupTrackIndicators()
    if self.db.GemSocketHelper.Enabled and PaperDollFrame and PaperDollFrame:IsShown() then
        self:RefreshSocketButtons()
    end
    if self.db.TrackIndicators and self.db.TrackIndicators.Enabled and PaperDollFrame and PaperDollFrame:IsShown() then
        self:UpdateAllTrackIndicators()
    end
end

function CHAR:OnEnable()
    if not self.db.Enabled then return end
    self:ApplySettings()
end

function CHAR:OnDisable()
    self:UpdateItemLevelText()
    self:DisableGemSocketHelper()
    self:HideAllTrackIndicators()
end

-- Gem Socket Helper --

local scanTooltip
local gemCache = {}
local socketCache = {}

local function GetScanTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "NRSKNUIScanTooltip", nil, "GameTooltipTemplate")
        scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return scanTooltip
end

function CHAR:ScanItemSockets(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then return nil end

    local result = {
        slotID = slotID,
        itemLink = itemLink,
        sockets = {},
        totalCount = 0,
        filledCount = 0,
        emptyCount = 0,
    }

    for socketIndex = 1, 3 do
        local gemName, gemLink = C_Item.GetItemGem(itemLink, socketIndex)
        if gemLink then
            result.filledCount = result.filledCount + 1
            result.totalCount = result.totalCount + 1
            local gemID = C_Item.GetItemInfoInstant(gemLink)
            local gemIcon = gemID and C_Item.GetItemIconByID(gemID)
            tinsert(result.sockets, {
                index = socketIndex,
                filled = true,
                gemLink = gemLink,
                gemName = gemName,
                gemID = gemID,
                icon = gemIcon,
            })
        end
    end

    local tt = GetScanTooltip()
    tt:ClearLines()
    tt:SetInventoryItem("player", slotID)

    for i = 1, tt:NumLines() do
        local line = _G["NRSKNUIScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                for _, socketType in ipairs(NRSKNUI.GEM_SOCKET_TYPES) do
                    local localeString = _G[socketType.locale]
                    if localeString and text:find(localeString, 1, true) then
                        result.emptyCount = result.emptyCount + 1
                        result.totalCount = result.totalCount + 1
                        tinsert(result.sockets, {
                            index = result.totalCount,
                            filled = false,
                            socketType = socketType.name,
                            icon = socketType.icon,
                        })
                    end
                end
            end
        end
    end

    return result.totalCount > 0 and result or nil
end

function CHAR:ScanAllEquippedSockets()
    wipe(socketCache)
    for _, slotID in ipairs(NRSKNUI.SOCKETABLE_SLOTS) do
        local socketInfo = self:ScanItemSockets(slotID)
        if socketInfo then tinsert(socketCache, socketInfo) end
    end
    return socketCache
end

function CHAR:ScanBagsForGems()
    wipe(gemCache)
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(info.itemID)
                if classID == LE_ITEM_CLASS_GEM then
                    local existing = gemCache[info.itemID]
                    if existing then
                        existing.count = existing.count + info.stackCount
                    else
                        gemCache[info.itemID] = {
                            itemID = info.itemID,
                            icon = info.iconFileID,
                            count = info.stackCount,
                            link = info.hyperlink,
                            bagID = bag,
                            slotID = slot,
                        }
                    end
                end
            end
        end
    end
    return gemCache
end

local TITLE_HEIGHT = 24
local HOVER_DURATION = 0.12
local ITEM_ROW_PADDING = 4
local POPUP_PADDING = 2
local STANDARD_BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }

local function IsMouseOverGemUI()
    if CHAR.gemPopup and CHAR.gemPopup:IsMouseOver() then return true end
    if CHAR.gemPopup then
        for _, btn in pairs(CHAR.gemPopup.buttons) do
            if btn:IsShown() and btn:IsMouseOver() then return true end
        end
    end
    if CHAR.currentSocketBtn and CHAR.currentSocketBtn:IsMouseOver() then return true end
    if CHAR.socketContainer then
        for _, socketBtn in pairs(CHAR.socketContainer.buttons) do
            if socketBtn:IsShown() and socketBtn:IsMouseOver() then return true end
        end
    end
    return false
end

local function CreateQualityOverlay(parent, anchor)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:SetSize(16, 16)
    frame:SetPoint("TOPLEFT", anchor or parent, "TOPLEFT", -5, 5)
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:Hide()
    return frame, texture
end

function CHAR:CreateSocketContainer()
    if self.socketContainer then return self.socketContainer end

    local db = self.db.GemSocketHelper
    local container = CreateFrame("Frame", "NRSKNUISocketContainer", PaperDollFrame)
    container:SetPoint("TOPLEFT", CharacterFrameTab3 or CharacterFrameTab2, "TOPRIGHT", 4, -6)
    container:SetSize(200, db.SocketButtonSize)
    container:Hide()

    container.buttons = {}
    self.socketContainer = container
    return container
end

function CHAR:CreateSocketButton(index)
    local db = self.db.GemSocketHelper
    local container = self.socketContainer

    if container.buttons[index] then return container.buttons[index] end

    local btn = CreateFrame("Button", nil, container)
    btn:SetSize(db.SocketButtonSize, db.SocketButtonSize)

    if index == 1 then
        btn:SetPoint("LEFT", container, "LEFT", 0, 0)
    else
        btn:SetPoint("LEFT", container.buttons[index - 1], "RIGHT", db.SocketButtonSpacing, 0)
    end

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    NRSKNUI:ApplyZoom(btn.icon, NRSKNUI.GlobalZoom)

    NRSKNUI:AddBorders(btn, Theme.border)

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    btn.highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    btn.highlight:SetColorTexture(1, 1, 1, 0.2)
    btn.highlight:SetBlendMode("ADD")

    btn.qualityFrame, btn.quality = CreateQualityOverlay(btn)

    btn:SetScript("OnEnter", function(self)
        CHAR.currentSocketBtn = self
        CHAR:ShowGemPopup(self)
        if self.socketInfo then
            CHAR:ShowSlotHighlight(self.socketInfo.slotID)
        end
        if self.socket and self.socket.filled and self.socket.gemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 40, 0)
            GameTooltip:SetHyperlink(self.socket.gemLink)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        C_Timer.After(0.05, function()
            if IsMouseOverGemUI() then return end
            CHAR:HideGemPopup()
            CHAR:HideSlotHighlight()
        end)
    end)

    btn:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            NRSKNUI:Print("Cannot socket during combat")
            return
        end
        if self.socketInfo then
            SocketInventoryItem(self.socketInfo.slotID)
        end
    end)

    container.buttons[index] = btn
    return btn
end

function CHAR:CreateGemPopup()
    if self.gemPopup then return self.gemPopup end

    local popup = CreateFrame("Frame", "NRSKNUIGemPopup", UIParent, "BackdropTemplate")
    popup:SetBackdrop(STANDARD_BACKDROP)
    popup:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
    popup:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    popup:SetSize(280, 50)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetClipsChildren(true)
    popup:Hide()

    popup.title = popup:CreateFontString(nil, "OVERLAY")
    popup.title:SetPoint("TOPLEFT", 6, -6)
    NRSKNUI:ApplyFontToText(popup.title, "Expressway", 14, "OUTLINE", {})
    popup.title:SetText("Gems")
    popup.title:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3])

    popup.separator = popup:CreateTexture(nil, "ARTWORK")
    popup.separator:SetHeight(1)
    popup.separator:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -TITLE_HEIGHT)
    popup.separator:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, -TITLE_HEIGHT)
    popup.separator:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    popup.noGems = popup:CreateFontString(nil, "OVERLAY")
    popup.noGems:SetPoint("CENTER", 0, -8)
    NRSKNUI:ApplyFontToText(popup.noGems, "Expressway", 14, "OUTLINE", {})
    popup.noGems:SetText("No compatible gems")
    popup.noGems:SetTextColor(Theme.textMuted[1], Theme.textMuted[2], Theme.textMuted[3])
    popup.noGems:Hide()

    popup:EnableMouse(true)
    popup:SetScript("OnEnter", function()
        if CHAR.currentSocketBtn and CHAR.currentSocketBtn.socketInfo then
            CHAR:ShowSlotHighlight(CHAR.currentSocketBtn.socketInfo.slotID)
        end
    end)
    popup:SetScript("OnLeave", function()
        C_Timer.After(0.05, function()
            if IsMouseOverGemUI() then return end
            CHAR:HideGemPopup()
            CHAR:HideSlotHighlight()
        end)
    end)

    popup.buttons = {}
    self.gemPopup = popup
    return popup
end

local POPUP_ICON_SIZE = 24

function CHAR:CreateGemButton(index)
    local popup = self.gemPopup
    local iconSize = POPUP_ICON_SIZE
    local rowHeight = POPUP_ICON_SIZE + ITEM_ROW_PADDING

    if popup.buttons[index] then return popup.buttons[index] end

    local btn = CreateFrame("Button", "NRSKNUIGemBtn" .. index, popup)
    btn:SetHeight(rowHeight)
    btn:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_PADDING, -TITLE_HEIGHT - (index - 1) * rowHeight)
    btn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -POPUP_PADDING, -TITLE_HEIGHT - (index - 1) * rowHeight)

    btn.iconFrame = CreateFrame("Frame", nil, btn)
    btn.iconFrame:SetSize(iconSize, iconSize)
    btn.iconFrame:SetPoint("LEFT", 0, 0)
    NRSKNUI:AddBorders(btn.iconFrame, Theme.border)

    btn.icon = btn.iconFrame:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    NRSKNUI:ApplyZoom(btn.icon, NRSKNUI.GlobalZoom)

    btn.qualityFrame, btn.quality = CreateQualityOverlay(btn, btn.iconFrame)

    btn.stats = btn:CreateFontString(nil, "OVERLAY")
    btn.stats:SetPoint("LEFT", btn.iconFrame, "RIGHT", 6, 0)
    btn.stats:SetPoint("RIGHT", btn, "RIGHT", -24, 0)
    btn.stats:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(btn.stats, "Expressway", 12, "OUTLINE", {})
    btn.stats:SetTextColor(Theme.textPrimary[1], Theme.textPrimary[2], Theme.textPrimary[3])
    btn.stats:SetShadowColor(0, 0, 0, 0)

    btn.count = btn:CreateFontString(nil, "OVERLAY")
    btn.count:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    NRSKNUI:ApplyFontToText(btn.count, "Expressway", 12, "OUTLINE", {})
    btn.count:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3])
    btn.count:SetShadowColor(0, 0, 0, 0)

    local hoverBg = btn:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(1, 1, 1, 0.05)
    hoverBg:SetAlpha(0)
    btn._hoverBg = hoverBg
    btn._hoverTarget = 0

    btn:SetScript("OnUpdate", function(self, elapsed)
        local current = self._hoverBg:GetAlpha()
        if abs(current - self._hoverTarget) > 0.01 then
            local speed = elapsed / HOVER_DURATION
            if self._hoverTarget > current then
                self._hoverBg:SetAlpha(min(current + speed, self._hoverTarget))
            else
                self._hoverBg:SetAlpha(max(current - speed, self._hoverTarget))
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        self._hoverTarget = 1
        if self.targetSlotID then CHAR:ShowSlotHighlight(self.targetSlotID) end
        if self.gemData and self.gemData.link then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 40, 0)
            GameTooltip:SetHyperlink(self.gemData.link)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        self._hoverTarget = 0
        GameTooltip:Hide()
        C_Timer.After(0.05, function()
            if IsMouseOverGemUI() then return end
            CHAR:HideGemPopup()
            CHAR:HideSlotHighlight()
        end)
    end)

    btn:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            NRSKNUI:Print("Cannot socket during combat")
            return
        end
        if self.gemData and self.targetSlotID and self.targetSocketIndex then
            SocketInventoryItem(self.targetSlotID)
            C_Container.PickupContainerItem(self.gemData.bagID, self.gemData.slotID)
            C_ItemSocketInfo.ClickSocketButton(self.targetSocketIndex)
            ClearCursor()
            AcceptSockets()
            CloseSocketInfo()
            if ItemSocketingFrame then
                HideUIPanel(ItemSocketingFrame)
            end
            CHAR:HideGemPopup()
            CHAR:HideSlotHighlight()
            C_Timer.After(0.1, function()
                if InCombatLockdown() then return end
                CHAR:RefreshSocketButtons()
            end)
        end
    end)

    popup.buttons[index] = btn
    return btn
end

function CHAR:RefreshSocketButtons()
    if not self.socketContainer then return end
    if not self.db.GemSocketHelper.Enabled then return end

    local allSockets = self:ScanAllEquippedSockets()
    local db = self.db.GemSocketHelper
    local buttonIndex = 1

    self.socketContainer:SetHeight(db.SocketButtonSize)

    for _, itemSocketInfo in ipairs(allSockets) do
        for _, socket in ipairs(itemSocketInfo.sockets) do
            if not db.ShowOnlyEmpty or not socket.filled then
                local btn = self:CreateSocketButton(buttonIndex)
                btn.socketInfo = itemSocketInfo
                btn.socket = socket

                btn:SetSize(db.SocketButtonSize, db.SocketButtonSize)
                btn:ClearAllPoints()
                if buttonIndex == 1 then
                    btn:SetPoint("LEFT", self.socketContainer, "LEFT", 0, 0)
                else
                    btn:SetPoint("LEFT", self.socketContainer.buttons[buttonIndex - 1], "RIGHT", db.SocketButtonSpacing,
                        0)
                end

                if socket.filled and socket.icon then
                    btn.icon:SetTexture(socket.icon)
                    btn:SetAlpha(1)
                    local atlas = GetQualityAtlasFromLink(socket.gemLink)
                    SetQualityAtlas(btn.quality, atlas)
                else
                    btn.icon:SetTexture(socket.icon or 458977)
                    btn:SetAlpha(0.6)
                    btn.quality:Hide()
                end

                btn:Show()
                buttonIndex = buttonIndex + 1
            end
        end
    end

    for i = buttonIndex, #self.socketContainer.buttons do self.socketContainer.buttons[i]:Hide() end

    local totalWidth = (buttonIndex - 1) * (db.SocketButtonSize + db.SocketButtonSpacing)
    self.socketContainer:SetWidth(totalWidth > 0 and totalWidth or 1)

    if buttonIndex > 1 then
        self.socketContainer:Show()
    else
        self.socketContainer:Hide()
    end
end

function CHAR:ShowGemPopup(socketBtn)
    if not socketBtn.socket then
        self:HideGemPopup()
        return
    end

    local popup = self:CreateGemPopup()
    local gems = self:ScanBagsForGems()

    local gemList = {}
    local currentGemID = socketBtn.socket.gemID
    for _, gemData in pairs(gems) do
        if gemData.itemID ~= currentGemID then tinsert(gemList, gemData) end
    end

    if socketBtn.socket.filled then
        popup.title:SetText("Replace Gem")
    else
        popup.title:SetText("Socket Gem")
    end

    local minWidth = popup.title:GetStringWidth() + 26
    local rowHeight = POPUP_ICON_SIZE + ITEM_ROW_PADDING

    local targetHeight
    if #gemList == 0 then
        popup.noGems:Show()
        popup.separator:Hide()
        popup.noGems:SetText(socketBtn.socket.filled and "No replacement gems" or "No compatible gems")
        for _, btn in pairs(popup.buttons) do btn:Hide() end
        popup:SetWidth(max(200, minWidth))
        targetHeight = 50
    else
        popup.noGems:Hide()
        popup.separator:Show()
        for i, gemData in ipairs(gemList) do
            local btn = self:CreateGemButton(i)
            btn.gemData = gemData
            btn.targetSlotID = socketBtn.socketInfo.slotID
            btn.targetSocketIndex = socketBtn.socket.index
            btn.icon:SetTexture(gemData.icon)
            btn.count:SetText(gemData.count .. "x")
            btn._hoverBg:SetAlpha(0)
            btn._hoverTarget = 0

            btn:SetHeight(rowHeight)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_PADDING, -TITLE_HEIGHT - (i - 1) * rowHeight)
            btn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -POPUP_PADDING, -TITLE_HEIGHT - (i - 1) * rowHeight)
            btn.iconFrame:SetSize(POPUP_ICON_SIZE, POPUP_ICON_SIZE)

            local stats = GetGemStatsFromLink(gemData.link)
            btn.stats:SetText(stats or "")

            local atlas = GetQualityAtlasFromLink(gemData.link)
            SetQualityAtlas(btn.quality, atlas)

            btn:Show()
        end
        for i = #gemList + 1, #popup.buttons do popup.buttons[i]:Hide() end

        popup:SetWidth(280)
        targetHeight = #gemList * rowHeight + TITLE_HEIGHT
    end

    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", socketBtn, "BOTTOMLEFT", 0, -1)
    popup:SetHeight(targetHeight)
    popup:Show()
end

function CHAR:HideGemPopup()
    if self.gemPopup then self.gemPopup:Hide() end
end

function CHAR:ShowSlotHighlight(slotID)
    self:HideSlotHighlight()

    local frameName = SLOT_FRAMES[slotID]
    if not frameName then return end

    local slotFrame = _G[frameName]
    if not slotFrame then return end

    if not self.slotHighlight then
        self.slotHighlight = CreateFrame("Frame", nil, UIParent)
        self.slotHighlight:SetFrameStrata("DIALOG")

        self.slotHighlight.texture = self.slotHighlight:CreateTexture(nil, "OVERLAY")
        self.slotHighlight.texture:SetAllPoints()
        self.slotHighlight.texture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.4)
        self.slotHighlight.texture:SetBlendMode("ADD")

        NRSKNUI:AddBorders(self.slotHighlight, { Theme.accent[1], Theme.accent[2], Theme.accent[3], 1 })
    end
    self.slotHighlight:SetAllPoints(slotFrame)
    self.slotHighlight:Show()
end

function CHAR:HideSlotHighlight()
    if self.slotHighlight then self.slotHighlight:Hide() end
end

function CHAR:SetupGemSocketHelper()
    if not self.db.GemSocketHelper.Enabled then return end
    if self._gemSocketHooked then return end
    self._gemSocketHooked = true

    self:CreateSocketContainer()
    self:CreateGemPopup()

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "RefreshSocketButtons")
    self:RegisterEvent("BAG_UPDATE_DELAYED", function()
        if self.socketContainer and self.socketContainer:IsShown() then self:RefreshSocketButtons() end
    end)

    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", function()
            if CHAR.db.GemSocketHelper.Enabled then CHAR:RefreshSocketButtons() end
        end)
        PaperDollFrame:HookScript("OnHide", function()
            if CHAR.socketContainer then CHAR.socketContainer:Hide() end
            CHAR:HideGemPopup()
            CHAR:HideSlotHighlight()
        end)
    end
end

function CHAR:DisableGemSocketHelper()
    if self.socketContainer then self.socketContainer:Hide() end
    self:HideGemPopup()
end
