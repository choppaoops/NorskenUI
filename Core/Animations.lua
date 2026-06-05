---@class NRSKNUI
local NRSKNUI = select(2, ...)

local ipairs = ipairs

local Animations = {}
NRSKNUI.Animations = Animations

local DEFAULT_DURATION = 0.15

local function EaseOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

---@param frame Frame
---@param setter fun(r: number, g: number, b: number, a: number)
---@param initialColor table {r, g, b} or {[1], [2], [3]}
---@param duration? number
---@return fun(toR: number, toG: number, toB: number)
function Animations:CreateColorAnimator(frame, setter, initialColor, duration)
    duration = duration or DEFAULT_DURATION

    local curR = initialColor.r or initialColor[1]
    local curG = initialColor.g or initialColor[2]
    local curB = initialColor.b or initialColor[3]

    local animGroup = frame:CreateAnimationGroup()
    animGroup:CreateAnimation("Animation"):SetDuration(duration)

    local fromR, fromG, fromB = curR, curG, curB
    local toR, toG, toB = curR, curG, curB

    animGroup:SetScript("OnUpdate", function()
        local progress = EaseOutQuad(animGroup:GetProgress() or 0)
        curR = fromR + (toR - fromR) * progress
        curG = fromG + (toG - fromG) * progress
        curB = fromB + (toB - fromB) * progress
        setter(curR, curG, curB, 1)
    end)

    animGroup:SetScript("OnFinished", function()
        curR, curG, curB = toR, toG, toB
        setter(curR, curG, curB, 1)
    end)

    return function(newR, newG, newB)
        animGroup:Stop()
        fromR, fromG, fromB = curR, curG, curB
        toR, toG, toB = newR, newG, newB
        animGroup:Play()
    end
end

---@param frame Frame
---@param setter fun(r: number, g: number, b: number, a: number)
---@param baseColor table
---@param hoverColor table
---@param duration? number
---@return fun(isHover: boolean)
function Animations:CreateHoverColorAnimator(frame, setter, baseColor, hoverColor, duration)
    local animate = self:CreateColorAnimator(frame, setter, baseColor, duration)

    local baseR = baseColor.r or baseColor[1]
    local baseG = baseColor.g or baseColor[2]
    local baseB = baseColor.b or baseColor[3]
    local hoverR = hoverColor.r or hoverColor[1]
    local hoverG = hoverColor.g or hoverColor[2]
    local hoverB = hoverColor.b or hoverColor[3]

    return function(isHover)
        if isHover then
            animate(hoverR, hoverG, hoverB)
        else
            animate(baseR, baseG, baseB)
        end
    end
end

local WOBBLE_OFFSETS = { -6, 5, -4, 3, -2, 1 }
local WOBBLE_DURATION = 0.4

---@param frame table
function Animations:Wobble(frame)
    if frame._nui_wobble and frame._nui_wobble:IsPlaying() then return end

    if not frame._nui_wobble then
        local animGroup = frame:CreateAnimationGroup()
        local stepDuration = WOBBLE_DURATION / #WOBBLE_OFFSETS

        for i, offset in ipairs(WOBBLE_OFFSETS) do
            local anim = animGroup:CreateAnimation("Translation")
            anim:SetOffset(offset, 0)
            anim:SetDuration(stepDuration)
            anim:SetOrder(i)
            anim:SetSmoothing("OUT")
        end

        local reset = animGroup:CreateAnimation("Translation")
        reset:SetOffset(0, 0)
        reset:SetDuration(0.01)
        reset:SetOrder(#WOBBLE_OFFSETS + 1)

        frame._nui_wobble = animGroup
    end

    frame._nui_wobble:Play()
end
