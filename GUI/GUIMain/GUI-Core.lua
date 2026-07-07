---@class NRSKNUI
local NRSKNUI = select(2, ...)
NRSKNUI.GUIFrame = NRSKNUI.GUIFrame or {}
NRSKNUI.GUI = NRSKNUI.GUI or {}
---@class GUIFrame
---@field ContentBuilders table<string, fun(scrollChild: Frame, yOffset: number): number>
---@field PanelBuilders table<string, function>
---@field contentCleanupCallbacks table<string, function>
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Localization Setup
local type = type
local CreateFrame = CreateFrame
local tostring = tostring
local error = error
local pcall = pcall
local table_insert = table.insert
local wipe = wipe
local pairs = pairs
local print = print
local ipairs = ipairs

-- Content Registry System
GUIFrame.ContentBuilders = {}
GUIFrame.PanelBuilders = {}
GUIFrame.contentCleanupCallbacks = {}

---@param itemId string
---@param builderFunc fun(scrollChild: Frame, yOffset: number): number
function GUIFrame:RegisterContent(itemId, builderFunc)
    if type(builderFunc) ~= "function" then
        error("RegisterContent: builderFunc must be a function for item: " .. tostring(itemId))
    end
    self.ContentBuilders[itemId] = builderFunc
end

-- Unregister a content builder
function GUIFrame:UnregisterContent(itemId)
    self.ContentBuilders[itemId] = nil
end

-- Check if content builder exists
function GUIFrame:HasContent(itemId)
    return self.ContentBuilders[itemId] ~= nil
end

function GUIFrame:RegisterPanel(itemId, builderFunc)
    if type(builderFunc) ~= "function" then
        error("RegisterPanel: builderFunc must be a function for item: " .. tostring(itemId))
    end
    self.PanelBuilders[itemId] = builderFunc
end

-- Unregister a panel builder
function GUIFrame:UnregisterPanel(itemId)
    self.PanelBuilders[itemId] = nil
end

-- Check if panel builder exists
function GUIFrame:HasPanel(itemId)
    return self.PanelBuilders[itemId] ~= nil
end

function GUIFrame:RegisterContentCleanup(key, callback)
    if type(key) == "string" and type(callback) == "function" then
        self.contentCleanupCallbacks[key] = callback
    end
end

-- Unregister a cleanup callback
function GUIFrame:UnregisterContentCleanup(key)
    if key then
        self.contentCleanupCallbacks[key] = nil
    end
end

-- Fire all content cleanup callbacks (called before changing content)
GUIFrame.onCloseCallbacks = {}

-- Register an on-close callback
function GUIFrame:RegisterOnCloseCallback(key, callback)
    if type(key) == "string" and type(callback) == "function" then
        self.onCloseCallbacks[key] = callback
    end
end

-- Unregister an on-close callback
function GUIFrame:UnregisterOnCloseCallback(key)
    if key then
        self.onCloseCallbacks[key] = nil
    end
end

-- Fire all on-close callbacks, called from GUIFrame:Hide
function GUIFrame:FireOnCloseCallbacks()
    for key, callback in pairs(self.onCloseCallbacks) do
        local ok, err = pcall(callback)
        if not ok and NRSKNUI.debug then
            print("|cFFFF0000[NRSKNUI]|r On-close callback '" .. key .. "' failed: " .. tostring(err))
        end
    end
end

function GUIFrame:ShowDBError(scrollChild, yOffset)
    local errorCard = self:CreateCard(scrollChild, "Error", yOffset)
    errorCard:AddLabel("Database not available")
    return errorCard:GetNextOffset()
end

---@class NUICardMixin : Frame
---@field content Frame
---@field header? Frame
---@field titleText? FontString
---@field headerHeight number
---@field contentHeight number
---@field rows table
---@field currentY number
---@field _yOffset number
local NUICardMixin = {}

---@param widget Frame
---@param height? number
---@param spacing? number
---@return Frame
function NUICardMixin:AddRow(widget, height, spacing)
    height = height or widget:GetHeight() or 24
    spacing = spacing or Theme.paddingSmall

    widget:SetParent(self.content)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.currentY)
    widget:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -self.currentY)

    self.currentY = self.currentY + height + spacing
    table_insert(self.rows, widget)

    self.content:SetHeight(self.currentY)
    self:UpdateHeight()

    return widget
end

---@param text string
---@param fontObject? string
---@return FontString
function NUICardMixin:AddLabel(text, fontObject)
    local label = self.content:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.currentY)
    label:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -self.currentY)
    label:SetJustifyH("LEFT")
    NRSKNUI:ApplyThemeFont(label, fontObject or "normal")
    label:SetText(text)
    label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)

    local height = label:GetStringHeight() or 14
    self.currentY = self.currentY + height + Theme.paddingSmall
    self.content:SetHeight(self.currentY)
    self:UpdateHeight()

    return label
end

---@return Texture
function NUICardMixin:AddSeparator()
    local sep = self.content:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(Theme.borderSize)
    sep:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.currentY - Theme.paddingSmall)
    sep:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -self.currentY - Theme.paddingSmall)
    sep:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 0.5)

    self.currentY = self.currentY + Theme.borderSize + Theme.paddingSmall * 2
    self.content:SetHeight(self.currentY)
    self:UpdateHeight()

    return sep
end

---@param amount? number
function NUICardMixin:AddSpacing(amount)
    amount = amount or Theme.paddingMedium
    self.currentY = self.currentY + amount
    self.content:SetHeight(self.currentY)
    self:UpdateHeight()
end

function NUICardMixin:UpdateHeight()
    local totalHeight = self.headerHeight + self.currentY + Theme.paddingSmall * 2
    self:SetHeight(totalHeight)
    self.contentHeight = totalHeight
end

---@return number
function NUICardMixin:GetContentHeight()
    return self.contentHeight
end

function NUICardMixin:Reset()
    for _, row in ipairs(self.rows) do
        if row.Hide then row:Hide() end
        if row.SetParent then row:SetParent(nil) end
    end
    wipe(self.rows)
    self.currentY = 0
    self.contentHeight = 0
    self.content:SetHeight(1)
    self:SetHeight(self.headerHeight + Theme.paddingMedium * 2)
end

---@param enabled boolean
function NUICardMixin:SetEnabled(enabled)
    if enabled then
        self:SetAlpha(1)
        if self.header then self.header:SetAlpha(1) end
        if self.titleText then self.titleText:SetAlpha(1) end
    else
        self:SetAlpha(0.5)
        if self.header then self.header:SetAlpha(0.5) end
        if self.titleText then self.titleText:SetAlpha(0.5) end
    end
end

---@return number
function NUICardMixin:GetNextOffset()
    return self._yOffset + self:GetContentHeight() + Theme.paddingSmall
end

---@class NUICard : NUICardMixin

---Container with optional header. Call GetNextOffset() after adding rows
---@param parent Frame
---@param title string
---@param yOffset number
---@param width? number
---@return NUICard
function GUIFrame:CreateCard(parent, title, yOffset, width)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:EnableMouse(false)

    -- Use anchor-based width so cards auto-resize when parent (scrollChild) resizes
    if width then
        card:SetWidth(width)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", Theme.paddingSmall, -(yOffset or 0))
    else
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", Theme.paddingSmall, -(yOffset or 0))
        card:SetPoint("RIGHT", parent, "RIGHT", -Theme.paddingSmall, 0)
    end

    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = Theme.borderSize,
    })
    card:SetBackdropColor(Theme.bgLight[1], Theme.bgLight[2], Theme.bgLight[3], Theme.bgLight[4])
    card:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])

    -- Initialize card properties
    card.contentHeight = 0
    card.rows = {}
    card._yOffset = yOffset or 0

    -- Header
    local headerHeight = 0
    if title and title ~= "" then
        headerHeight = 32

        local header = CreateFrame("Frame", nil, card, "BackdropTemplate")
        header:SetHeight(headerHeight)
        header:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
        header:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = Theme.borderSize,
        })
        header:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
        header:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])
        card.header = header

        local titleText = header:CreateFontString(nil, "OVERLAY")
        titleText:SetPoint("LEFT", header, "LEFT", Theme.paddingMedium, 0)
        NRSKNUI:ApplyThemeFont(titleText, "large")
        titleText:SetText(title)
        titleText:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        card.titleText = titleText
    end
    card.headerHeight = headerHeight

    -- Content container
    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", card, "TOPLEFT", Theme.paddingMedium, -headerHeight - Theme.paddingSmall)
    content:SetPoint("TOPRIGHT", card, "TOPRIGHT", -Theme.paddingMedium, -headerHeight - Theme.paddingSmall)
    content:SetHeight(1)
    content:EnableMouse(false)
    card.content = content
    card.currentY = 0

    -- Apply mixin methods
    Mixin(card, NUICardMixin)

    card:UpdateHeight()

    ---@cast card NUICard
    return card
end

---@class NUIRowMixin : Frame
---@field widgets table
---@field nextX number
---@field _rowHeight number
local NUIRowMixin = {}

---@param widget Frame
---@param widthPct? number
---@param spacing? number
---@param xOffset? number
---@param yOffset? number
function NUIRowMixin:AddWidget(widget, widthPct, spacing, xOffset, yOffset)
    widthPct = widthPct or 0.5
    spacing = spacing or Theme.paddingSmall
    xOffset = xOffset or 0
    yOffset = yOffset or 0

    widget:SetParent(self)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self, "TOPLEFT", self.nextX + xOffset, yOffset)

    if not widget.explicitHeight then
        widget:SetHeight(self._rowHeight)
    end

    widget._widthPct = widthPct
    widget._spacing = spacing
    widget._xOffset = xOffset
    widget._yOffset = yOffset
    table_insert(self.widgets, widget)
    self.nextX = self.nextX + 10
end

---@class NUIRow : NUIRowMixin

---Horizontal layout container, total width values should sum to 1.0
---@param parent Frame
---@param height? number
---@return NUIRow
function GUIFrame:CreateRow(parent, height)
    height = height or 24
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(height)
    row:EnableMouse(false)
    row.widgets = {}
    row.nextX = 0
    row._rowHeight = height

    Mixin(row, NUIRowMixin)

    row:SetScript("OnSizeChanged", function(self, width)
        local x = 0
        local count = #self.widgets
        for i, widget in ipairs(self.widgets) do
            local isLast = (i == count)
            local spacing = isLast and 0 or (widget._spacing or Theme.paddingSmall)
            local widgetWidth = width * widget._widthPct - spacing
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", self, "TOPLEFT", x + (widget._xOffset or 0), widget._yOffset or 0)
            widget:SetWidth(widgetWidth)
            x = x + widgetWidth + spacing
        end
    end)

    ---@cast row NUIRow
    return row
end