---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local select = select

local TOGGLE_WIDTH = 48
local TOGGLE_HEIGHT = 24
local KNOB_SIZE = 22
local KNOB_CROSS = 22
local KNOB_PADDING = 1
local ANIMATION_DURATION = 0.18
local OFF_POSITION = KNOB_PADDING
local ON_POSITION = TOGGLE_WIDTH - KNOB_SIZE - KNOB_PADDING
local CHECK_TEXTURE = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\ok-iconBlack.tga"
local CROSS_TEXTURE = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\cross-small.png"

---Toggle checkbox with optional message popup
---```lua
---config = {
---    value = boolean,       -- Initial checked state
---    callback = function,   -- Called when value changes
---    msgPopup = boolean,    -- Show popup message on toggle
---    msgText = string,      -- Popup text prefix
---    msgOn = string,        -- Text for "on" state
---    msgOff = string,       -- Text for "off" state
---}
---```
---@param parent Frame
---@param labelText string
---@param config NUICheckboxConfig
---@return NUICheckbox
function GUIFrame:CreateCheckbox(parent, labelText, config)
    config = config or {}
    local initialState = config.value or false
    local onValueChanged = config.callback
    local msgPopup = config.msgPopup
    local msgText = config.msgText
    local msgOn = config.msgOn or "Enabled"
    local msgOff = config.msgOff or "Disabled"
    local tooltip = config.tooltip

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(36)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 1)
    label:SetJustifyH("LEFT")
    NRSKNUI:ApplyThemeFont(label, "small")
    label:SetText(labelText or "")
    label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    row.label = label

    local toggle = CreateFrame("Frame", nil, row, "BackdropTemplate")
    toggle:SetSize(TOGGLE_WIDTH, TOGGLE_HEIGHT)
    toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    toggle:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    toggle:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], 1)
    toggle:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local knob = CreateFrame("Frame", nil, toggle, "BackdropTemplate")
    knob:SetSize(KNOB_SIZE, KNOB_SIZE)
    knob:SetPoint("LEFT", toggle, "LEFT", OFF_POSITION, 0)
    knob:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = -1, right = -1, top = 0, bottom = 0 },
    })
    knob:SetBackdropColor(0, 0, 0, 1)
    knob:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local knobTexture = knob:CreateTexture(nil, "ARTWORK")
    knobTexture:SetAllPoints()
    knobTexture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.6)
    knobTexture:SetTexelSnappingBias(0)
    knobTexture:SetSnapToPixelGrid(false)

    local checkmark = knob:CreateTexture(nil, "OVERLAY")
    checkmark:SetSize(KNOB_SIZE, KNOB_SIZE)
    checkmark:SetPoint("CENTER", knob, "CENTER", 0, 0)
    checkmark:SetTexture(CHECK_TEXTURE)
    checkmark:SetVertexColor(1, 1, 1, 1)
    checkmark:SetTexelSnappingBias(0)
    checkmark:SetSnapToPixelGrid(false)
    checkmark:Hide()

    local crossmark = knob:CreateTexture(nil, "OVERLAY")
    crossmark:SetSize(KNOB_CROSS, KNOB_CROSS)
    crossmark:SetPoint("CENTER", knob, "CENTER", 0, 0)
    crossmark:SetTexture(CROSS_TEXTURE)
    crossmark:SetVertexColor(1, 1, 1, 0.8)
    crossmark:SetTexelSnappingBias(0)
    crossmark:SetSnapToPixelGrid(false)
    crossmark:Hide()

    local animGroup = knob:CreateAnimationGroup()
    local slideAnim = animGroup:CreateAnimation("Translation")
    slideAnim:SetDuration(ANIMATION_DURATION)
    slideAnim:SetSmoothing("OUT")

    local state = initialState or false
    local isAnimating = false
    local knobR, knobG, knobB, knobA = Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.6

    local colorAnimGroup = toggle:CreateAnimationGroup()
    colorAnimGroup:SetLooping("NONE")

    local colorAnim = colorAnimGroup:CreateAnimation("Animation")
    colorAnim:SetDuration(ANIMATION_DURATION)

    local colorFrom = {}
    local colorTo = {}

    local function AnyAnimating()
        return animGroup:IsPlaying() or colorAnimGroup:IsPlaying()
    end

    local function UpdateIcons()
        if state then
            checkmark:Show()
            crossmark:Hide()
            checkmark:SetVertexColor(1, 1, 1, 1)
        else
            checkmark:Hide()
            crossmark:Show()
            crossmark:SetVertexColor(1, 1, 1, 0.8)
        end
    end

    colorAnimGroup:SetScript("OnUpdate", function(self)
        local progress = self:GetProgress() or 0
        local r = colorFrom.bgR + (colorTo.bgR - colorFrom.bgR) * progress
        local g = colorFrom.bgG + (colorTo.bgG - colorFrom.bgG) * progress
        local b = colorFrom.bgB + (colorTo.bgB - colorFrom.bgB) * progress
        toggle:SetBackdropColor(r, g, b, 1)

        local rT = colorFrom.knobR + (colorTo.knobR - colorFrom.knobR) * progress
        local gT = colorFrom.knobG + (colorTo.knobG - colorFrom.knobG) * progress
        local bT = colorFrom.knobB + (colorTo.knobB - colorFrom.knobB) * progress
        local aT = colorFrom.knobA + (colorTo.knobA - colorFrom.knobA) * progress

        knobTexture:SetColorTexture(rT, gT, bT, aT)
        knobR, knobG, knobB, knobA = rT, gT, bT, aT
    end)

    colorAnimGroup:SetScript("OnFinished", function()
        toggle:SetBackdropColor(colorTo.bgR, colorTo.bgG, colorTo.bgB, 1)
        knobTexture:SetColorTexture(colorTo.knobR, colorTo.knobG, colorTo.knobB, colorTo.knobA)
        knobR, knobG, knobB, knobA =
            colorTo.knobR, colorTo.knobG, colorTo.knobB, colorTo.knobA
        UpdateIcons()
    end)

    local function UpdateColors(toState, instant)
        UpdateIcons()
        if instant then
            if toState then
                toggle:SetBackdropColor(Theme.accent[1] * 0.5, Theme.accent[2] * 0.5, Theme.accent[3] * 0.5, 1)
                knobTexture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                knobR, knobG, knobB, knobA = Theme.accent[1], Theme.accent[2], Theme.accent[3], 1
            else
                toggle:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], 1)
                knobTexture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.4)
                knobR, knobG, knobB, knobA = Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.4
            end

            knobR, knobG, knobB, knobA = knobTexture:GetVertexColor()
            UpdateIcons()
        else
            colorAnimGroup:Stop()
            colorFrom.bgR, colorFrom.bgG, colorFrom.bgB = toggle:GetBackdropColor()
            colorFrom.knobR, colorFrom.knobG, colorFrom.knobB, colorFrom.knobA = knobR, knobG, knobB, knobA

            colorTo.bgR = toState and Theme.accent[1] * 0.5 or Theme.bgDark[1]
            colorTo.bgG = toState and Theme.accent[2] * 0.5 or Theme.bgDark[2]
            colorTo.bgB = toState and Theme.accent[3] * 0.5 or Theme.bgDark[3]
            colorTo.knobR = Theme.accent[1]
            colorTo.knobG = Theme.accent[2]
            colorTo.knobB = Theme.accent[3]
            colorTo.knobA = toState and 1 or 0.4

            colorAnimGroup:Play()
            UpdateIcons()
        end
    end

    local function AnimateToState(toState, instant)
        if isAnimating and not instant then return end

        isAnimating = true
        state = toState

        local targetX = toState and ON_POSITION or OFF_POSITION
        local currentX = select(4, knob:GetPoint())
        local deltaX = targetX - currentX

        if instant or math.abs(deltaX) < 1 then
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", toggle, "LEFT", targetX, 0)
            UpdateColors(toState, true)
            isAnimating = false
        else
            UpdateColors(toState, false)

            animGroup:Stop()
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", toggle, "LEFT", currentX, 0)

            slideAnim:SetOffset(deltaX, 0)

            animGroup:SetScript("OnFinished", function()
                knob:ClearAllPoints()
                knob:SetPoint("LEFT", toggle, "LEFT", targetX, 0)
                isAnimating = false
                UpdateIcons()
            end)

            animGroup:Play()
        end
    end

    AnimateToState(state, true)

    local button = CreateFrame("Button", nil, toggle)
    button:SetAllPoints()
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function()
        if AnyAnimating() then return end

        local newState = not state
        AnimateToState(newState, false)

        if onValueChanged then
            C_Timer.After(ANIMATION_DURATION, function()
                onValueChanged(newState, function(revert)
                    if revert then
                        AnimateToState(not newState, false)
                    end
                end)
            end)
        end

        if msgPopup then
            local toggleOnOrOff = ""
            if newState then
                toggleOnOrOff = "|cff4DCC66" .. msgOn .. "|r"
            else
                toggleOnOrOff = "|cffE64D4D" .. msgOff .. "|r"
            end
            NRSKNUI:CreateMessagePopup(2, (msgText .. ": " .. toggleOnOrOff), 15, UIParent, 0, 400)
        end
    end)

    button:SetScript("OnEnter", function()
        local hoverBrightness = 1.2
        local baseA = state and 1 or 0.6
        knobTexture:SetColorTexture(
            Theme.accent[1] * hoverBrightness,
            Theme.accent[2] * hoverBrightness,
            Theme.accent[3] * hoverBrightness,
            baseA
        )
        knobR, knobG, knobB, knobA =
            Theme.accent[1] * hoverBrightness,
            Theme.accent[2] * hoverBrightness,
            Theme.accent[3] * hoverBrightness,
            baseA
    end)

    button:SetScript("OnLeave", function()
        if state then
            knobTexture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            knobR, knobG, knobB, knobA = Theme.accent[1], Theme.accent[2], Theme.accent[3], 1
        else
            knobTexture:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.4)
            knobR, knobG, knobB, knobA = Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.4
        end
    end)

    toggle.SetValue = function(_, value, instant)
        if value ~= state then
            AnimateToState(value, instant)
            if onValueChanged and not instant then
                C_Timer.After(ANIMATION_DURATION, function()
                    onValueChanged(value)
                end)
            end
        end
    end

    toggle.GetValue = function()
        return state
    end

    function row:SetEnabled(enabled)
        if enabled then
            toggle:SetAlpha(1)
            label:SetAlpha(1)
            button:EnableMouse(true)
        else
            toggle:SetAlpha(0.5)
            label:SetAlpha(0.5)
            button:EnableMouse(false)
        end
    end

    row.toggle = toggle

    -- Tooltip support
    if tooltip then
        local tooltipText = type(tooltip) == "table" and tooltip.text or tooltip
        local tooltipDefault = type(tooltip) == "table" and tooltip.default

        local function SetupTooltip(frame)
            local oldEnter = frame:GetScript("OnEnter")
            local oldLeave = frame:GetScript("OnLeave")
            frame:SetScript("OnEnter", function(self, ...)
                if oldEnter then oldEnter(self, ...) end
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(labelText or "", Theme.accent[1], Theme.accent[2], Theme.accent[3])
                GameTooltip:AddLine(tooltipText, Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], true)
                if tooltipDefault ~= nil then
                    local defaultStr = type(tooltipDefault) == "boolean" and (tooltipDefault and "On" or "Off") or tostring(tooltipDefault)
                    GameTooltip:AddLine("Default: " .. defaultStr, Theme.success[1], Theme.success[2], Theme.success[3])
                end
                GameTooltip:Show()
            end)
            frame:SetScript("OnLeave", function(self, ...)
                if oldLeave then oldLeave(self, ...) end
                GameTooltip:Hide()
            end)
        end
        SetupTooltip(toggle)
        SetupTooltip(button)
    end

    return row
end
