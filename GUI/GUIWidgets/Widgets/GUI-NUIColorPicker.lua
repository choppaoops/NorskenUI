---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local CreateFrame = CreateFrame
local Mixin = Mixin
local ColorPickerFrame = ColorPickerFrame

-- Custom made backdrop for the swatch by Norsken
local NUI_BG = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\NUIcolorPickerBG.png"

---@alias OnColorChanged fun(r: number, g: number, b: number, a: number)

---@class NUIColorSwatch : Button, BackdropTemplate
---@field r number
---@field g number
---@field b number
---@field a number
---@field isNUIColorPicker boolean
---@field colorPickerRow NUIColorPicker

---@class NUIColorPickerMixin : Frame
---@field swatch NUIColorSwatch
---@field hexText FontString
---@field _callback? OnColorChanged
local NUIColorPickerMixin = {}

---@param r number
---@param g number
---@param b number
---@param a? number
function NUIColorPickerMixin:SetColor(r, g, b, a)
    a = a or 1
    self.swatch.r, self.swatch.g, self.swatch.b, self.swatch.a = r, g, b, a
    self.swatch:SetBackdropColor(r, g, b, a)
    self.hexText:SetText("#" .. NRSKNUI:RGBAToHex(r, g, b))
    if self._callback then self._callback(r, g, b, a) end
end

---@return number, number, number, number
function NUIColorPickerMixin:GetColor()
    return self.swatch.r, self.swatch.g, self.swatch.b, self.swatch.a
end

---@param enabled boolean
function NUIColorPickerMixin:SetEnabled(enabled)
    if enabled then
        self:SetAlpha(1)
        self.swatch:EnableMouse(true)
    else
        self:SetAlpha(0.4)
        self.swatch:EnableMouse(false)
    end
end

---@class NUIColorPicker : NUIColorPickerMixin
---@field label FontString

---@class NUIColorPickerConfig
---@field color? number[]
---@field callback? OnColorChanged

---Color picker with swatch and hex display
---```lua
---config = {
---    color = {r, g, b, a},   -- Initial RGBA color
---    callback = function,    -- Called when color changes
---}
---```
---@param parent Frame
---@param labelText string
---@param config NUIColorPickerConfig
---@return NUIColorPicker
function GUIFrame:CreateColorPicker(parent, labelText, config)
    config = config or {}
    local color = config.color or { 1, 1, 1, 1 }
    local callback = config.callback

    local row = CreateFrame("Frame", nil, parent) --[[@as NUIColorPicker]]
    row:SetHeight(34)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 1)
    label:SetJustifyH("LEFT")
    NRSKNUI:ApplyThemeFont(label, "small")
    label:SetText(labelText or "")
    label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    row.label = label

    local swatchBg = row:CreateTexture(nil, "BACKGROUND")
    swatchBg:SetSize(48, 24)
    swatchBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    swatchBg:SetTexture(NUI_BG)
    swatchBg:SetAlpha(0.8)
    swatchBg:SetTexelSnappingBias(0)
    swatchBg:SetSnapToPixelGrid(false)

    local swatch = CreateFrame("Button", nil, row, "BackdropTemplate") --[[@as NUIColorSwatch]]
    swatch:SetSize(48, 24)
    swatch:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    swatch:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
    swatch:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    swatch.r, swatch.g, swatch.b, swatch.a = color[1], color[2], color[3], color[4] or 1
    swatch.isNUIColorPicker = true
    swatch.colorPickerRow = row
    row.swatch = swatch

    local hexText = row:CreateFontString(nil, "OVERLAY")
    hexText:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    NRSKNUI:ApplyThemeFont(hexText, "small")
    hexText:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    hexText:SetText("#" .. NRSKNUI:RGBAToHex(color[1], color[2], color[3]))
    hexText:SetShadowColor(0, 0, 0, 0)
    row.hexText = hexText

    row._callback = callback

    Mixin(row, NUIColorPickerMixin)

    local animateBorder = NRSKNUI.Animations:CreateHoverColorAnimator(
        swatch,
        function(r, g, b, a) swatch:SetBackdropBorderColor(r, g, b, a) end,
        Theme.border,
        Theme.accent,
        Theme.animDuration
    )

    swatch:SetScript("OnEnter", function() animateBorder(true) end)
    swatch:SetScript("OnLeave", function() animateBorder(false) end)
    swatch:SetScript("OnClick", function()
        local prevR, prevG, prevB, prevA = swatch.r, swatch.g, swatch.b, swatch.a
        local info = {
            r = prevR,
            g = prevG,
            b = prevB,
            opacity = prevA,
            hasOpacity = true
        }
        info.swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            row:SetColor(r or 1, g or 1, b or 1, a or 1)
        end
        info.opacityFunc = info.swatchFunc
        info.cancelFunc = function()
            row:SetColor(prevR, prevG, prevB, prevA)
        end
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    self:RegisterSearchableWidget(row, labelText)
    ---@cast row NUIColorPicker
    return row
end
