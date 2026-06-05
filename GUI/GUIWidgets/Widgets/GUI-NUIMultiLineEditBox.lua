---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local tostring = tostring
local Mixin = Mixin
local CreateFrame = CreateFrame
local C_Timer = C_Timer

---@class NUIMultiLineEditBoxMixin : Frame
---@field editBox EditBox
---@field container Frame|BackdropTemplate
---@field scrollFrame ScrollFrame
---@field rowHeight number
local NUIMultiLineEditBoxMixin = {}

---@param val string
function NUIMultiLineEditBoxMixin:SetValue(val)
    self.editBox:SetText(val or "")
    self.editBox:SetCursorPosition(0)
end

---@return string
function NUIMultiLineEditBoxMixin:GetValue()
    return self.editBox:GetText()
end

---@param enabled boolean
function NUIMultiLineEditBoxMixin:SetEnabled(enabled)
    if enabled then
        self:SetAlpha(1)
        self.editBox:EnableMouse(true)
        self.editBox:EnableKeyboard(true)
        self.container:EnableMouse(true)
    else
        self:SetAlpha(0.4)
        self.editBox:EnableMouse(false)
        self.editBox:EnableKeyboard(false)
        self.editBox:ClearFocus()
        self.container:EnableMouse(false)
    end
end

---```lua
---config = {
---    value = string?,           -- Initial text value
---    height = number?,          -- Container height (default 80)
---    tooltip = string?,         -- Tooltip text on hover
---    syntaxHighlight = boolean?, -- Enable Lua syntax highlighting
---    callback = function(text)?, -- Called on focus lost with new text
---}
---```
---@param parent Frame
---@param labelText string
---@param config NUIMultiLineEditBoxConfig
---@return NUIMultiLineEditBox
function GUIFrame:CreateMultiLineEditBox(parent, labelText, config)
    config = config or {}
    local value = tostring(config.value or "")
    local callback = config.callback
    local tooltip = config.tooltip
    local containerHeight = config.height or 80
    local syntaxHighlight = config.syntaxHighlight

    local rowHeight = 14 + containerHeight + 4
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(rowHeight)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 1)
    label:SetJustifyH("LEFT")
    NRSKNUI:ApplyThemeFont(label, "small")
    label:SetText(labelText or "")
    label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    row.label = label

    local container = CreateFrame("Frame", nil, row, "BackdropTemplate")
    container:SetHeight(containerHeight)
    container:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    container:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -14)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], 1)
    container:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    row.container = container

    local animateBorder = NRSKNUI.Animations:CreateHoverColorAnimator(
        container,
        function(r, g, b, a) container:SetBackdropBorderColor(r, g, b, a) end,
        Theme.border,
        Theme.accent,
        Theme.animDuration
    )

    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -18, 6)
    row.scrollFrame = scrollFrame

    local scrollbar = NRSKNUI.GUI.CreateScrollbar(scrollFrame, {
        width = 8,
        thumbHeight = 24,
        padding = { top = 3, bottom = 3, right = 3 },
        scrollStep = 20,
    })
    row.scrollbar = scrollbar

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    editBox:SetCountInvisibleLetters(false)
    editBox:EnableMouse(true)
    scrollFrame:SetScrollChild(editBox)
    row.editBox = editBox

    local function UpdateScrollbar()
        local contentHeight = editBox:GetHeight() or 0
        local frameHeight = scrollFrame:GetHeight() or 0
        scrollbar:UpdateVisibility(contentHeight, frameHeight)
    end

    editBox:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
        local _, maxVal = scrollbar:GetMinMaxValues()
        if maxVal <= 0 then return end
        local offset = scrollbar:GetValue()
        if -y < offset then
            scrollbar:SetValue(-y)
        else
            local scrollHeight = scrollFrame:GetHeight()
            y = -y + cursorHeight - scrollHeight
            if y > offset then
                scrollbar:SetValue(y)
            end
        end
    end)

    editBox:SetScript("OnTextChanged", function()
        C_Timer.After(0, UpdateScrollbar)
    end)

    if syntaxHighlight and IndentationLib and IndentationLib.enable then
        IndentationLib.enable(editBox, nil, 2)
    end

    local scrollWidth = scrollFrame:GetWidth()
    editBox:SetWidth(scrollWidth > 0 and scrollWidth - 14 or 186)

    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        editBox:SetWidth(width - 14)
        UpdateScrollbar()
    end)

    editBox:SetText(value)
    editBox:SetCursorPosition(0)

    editBox:SetScript("OnEscapePressed", function(eb)
        eb:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusLost", function(eb)
        eb:HighlightText(0, 0)
        container:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
        borderR, borderG, borderB = Theme.border[1], Theme.border[2], Theme.border[3]
        if callback then
            callback(eb:GetText())
        end
    end)

    editBox:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        borderR, borderG, borderB = Theme.accent[1], Theme.accent[2], Theme.accent[3]
    end)

    editBox:SetScript("OnEnter", function(eb)
        if not eb:HasFocus() then
            animateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    editBox:SetScript("OnLeave", function(eb)
        if not eb:HasFocus() and not container:IsMouseOver() then
            animateBorder(false)
        end
        GameTooltip:Hide()
    end)

    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    container:SetScript("OnEnter", function()
        if not editBox:HasFocus() then
            animateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    container:SetScript("OnLeave", function()
        if not editBox:HasFocus() and not container:IsMouseOver() then
            animateBorder(false)
        end
        GameTooltip:Hide()
    end)

    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    scrollFrame:SetScript("OnEnter", function()
        if not editBox:HasFocus() then
            animateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    scrollFrame:SetScript("OnLeave", function()
        if not editBox:HasFocus() and not container:IsMouseOver() then
            animateBorder(false)
        end
        GameTooltip:Hide()
    end)

    scrollbar:HookScript("OnEnter", function()
        if not editBox:HasFocus() then
            animateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    scrollbar:HookScript("OnLeave", function()
        if not editBox:HasFocus() and not container:IsMouseOver() then
            animateBorder(false)
        end
        GameTooltip:Hide()
    end)

    Mixin(row, NUIMultiLineEditBoxMixin)
    row.rowHeight = rowHeight

    return row
end
