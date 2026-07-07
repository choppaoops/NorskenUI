---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local CreateFrame = CreateFrame
local CreateColor = CreateColor
local type = type

---@class NUISeparator : Frame, BackdropTemplate
---@field SetEnabled fun(self: NUISeparator, enabled: boolean)

---@class NUISeparatorConfig
---@field useLabel? boolean
---@field height? number

---@param parent Frame
---@param labelText? string Separator label text
---@param config? NUISeparatorConfig
---@return NUISeparator
function GUIFrame:CreateSeparator(parent, labelText, config)
    if type(config) ~= "table" then config = {} end
    local useLabel = config.useLabel or false
    local height = config.height or 6
    local offset = useLabel and 5 or 0

    local separator = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    separator:SetHeight(height)
    separator:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    separator:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    local r, g, b = Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3]

    local separatorTexture = separator:CreateTexture(nil, "ARTWORK")
    separatorTexture:SetHeight(2)
    separatorTexture:SetPoint("LEFT", separator, "LEFT", 0, -offset)
    separatorTexture:SetPoint("RIGHT", separator, "RIGHT", 0, -offset)
    separatorTexture:SetColorTexture(1, 1, 1, 1)
    separatorTexture:SetGradient("HORIZONTAL", CreateColor(r, g, b, 1), CreateColor(r, g, b, 1))
    separatorTexture:SetTexelSnappingBias(0)
    separatorTexture:SetSnapToPixelGrid(false)

    if useLabel then
        local headerLabel = separator:CreateFontString(nil, "OVERLAY")
        headerLabel:SetPoint("LEFT", separator, "LEFT", 0, offset)
        NRSKNUI:ApplyThemeFont(headerLabel, "normal")
        headerLabel:SetText(labelText)
        headerLabel:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    end

    function separator:SetEnabled(enabled)
        if enabled then
            separator:SetAlpha(1)
        else
            separator:SetAlpha(0.5)
        end
    end

    ---@cast separator NUISeparator
    return separator
end
