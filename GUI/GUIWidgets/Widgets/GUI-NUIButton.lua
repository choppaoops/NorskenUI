---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local CreateFrame = CreateFrame
local type = type
local Mixin = Mixin

---@class NUIButtonMixin : Button, BackdropTemplate
---@field icon? Texture
---@field text FontString
---@field explicitHeight? boolean
---@field _callback? OnClickCallback
---@field _tooltip? string
local NUIButtonMixin = {}

---@param newLabel string
function NUIButtonMixin:SetLabel(newLabel)
    self.text:SetText(newLabel)
end

---@param newImage string|number
function NUIButtonMixin:SetImage(newImage)
    if self.icon then self.icon:SetTexture(newImage) end
end

---@param enabled boolean
function NUIButtonMixin:SetEnabled(enabled)
    if enabled then
        self:Enable()
        self:SetAlpha(1)
        self:EnableMouse(true)
    else
        self:Disable()
        self:SetAlpha(0.5)
        self:EnableMouse(false)
    end
end

---@param newCallback OnClickCallback
function NUIButtonMixin:SetCallback(newCallback)
    self._callback = newCallback
end

---@param newTooltip string
function NUIButtonMixin:SetTooltip(newTooltip)
    self._tooltip = newTooltip
end

function NUIButtonMixin:UpdateColors()
    local bg = self._bgColor or Theme.bgMedium
    self:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    self:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    self.text:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
end

---Themed button with optional icon and tooltip
---```lua
---config = {
---    tooltip = string,        -- Tooltip shown on hover
---    callback = function,     -- Called on click
---    image = string|number,   -- Icon texture path or FileDataID
---    imageSize = number,      -- Icon size (default: 16)
---    width = number,          -- Width in pixels (default: 120)
---    height = number,         -- Height in pixels (default: 24)
---}
---```
---@param parent Frame
---@param buttonText? string Button label text
---@param config? NUIButtonConfig
---@return NUIButton
function GUIFrame:CreateButton(parent, buttonText, config)
    if type(config) ~= "table" then config = {} end

    local text = buttonText or "Button"
    local image = config.image
    local imageSize = config.imageSize or 16
    local explicitWidth = config.width
    local height = config.height or 24
    local bgColor = config.bgColor or Theme.bgMedium

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(height)
    if config.height then button.explicitHeight = true end
    button:SetWidth(explicitWidth or 120)
    button._bgColor = bgColor

    button._callback = config.callback
    button._tooltip = config.tooltip

    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 1)
    button:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local animateBorder = NRSKNUI.Animations:CreateHoverColorAnimator(
        button,
        function(r, g, b, a) button:SetBackdropBorderColor(r, g, b, a) end,
        Theme.border,
        Theme.accent,
        Theme.animDuration
    )

    local contentWidth = 0
    local iconWidget, textWidget

    if image then
        iconWidget = button:CreateTexture(nil, "ARTWORK")
        iconWidget:SetSize(imageSize, imageSize)
        iconWidget:SetTexture(image)
        contentWidth = contentWidth + imageSize
    end

    textWidget = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    NRSKNUI:ApplyThemeFont(textWidget, "normal")
    textWidget:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    textWidget:SetText(text)
    contentWidth = contentWidth + textWidget:GetStringWidth()

    if image and text and text ~= "" then
        contentWidth = contentWidth + 6
    end

    if iconWidget and textWidget then
        iconWidget:SetPoint("LEFT", button, "CENTER", -contentWidth / 2, 0)
        textWidget:SetPoint("LEFT", iconWidget, "RIGHT", 6, 0)
    elseif iconWidget then
        iconWidget:SetPoint("CENTER")
    else
        textWidget:SetPoint("CENTER")
    end

    button:SetScript("OnEnter", function(btn)
        animateBorder(true)
        if btn._tooltip then
            GameTooltip:SetOwner(btn, "ANCHOR_TOP", 0, 4)
            GameTooltip:SetText(btn._tooltip, Theme.accent[1], Theme.accent[2], Theme.accent[3], 1, false)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(btn)
        animateBorder(false)
        btn:SetBackdropColor(btn._bgColor[1], btn._bgColor[2], btn._bgColor[3], 1)
        GameTooltip:Hide()
    end)

    button:SetScript("OnMouseDown", function(btn)
        btn:SetBackdropColor(Theme.selectedBg[1], Theme.selectedBg[2], Theme.selectedBg[3], Theme.selectedBg[4])
    end)

    button:SetScript("OnMouseUp", function(btn)
        btn:SetBackdropColor(btn._bgColor[1], btn._bgColor[2], btn._bgColor[3], 1)
    end)

    button:SetScript("OnClick", function(btn)
        if btn._callback then btn._callback() end
    end)

    button.icon = iconWidget
    button.text = textWidget

    Mixin(button, NUIButtonMixin)

    return button
end
