---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GetPhysicalScreenSize = GetPhysicalScreenSize
local type = type
local CreateFrame = CreateFrame
local select = select
local next = next
local pcall = pcall
local getmetatable = getmetatable
local hooksecurefunc = hooksecurefunc
local EnumerateFrames = EnumerateFrames
local string_format = string.format
local math_floor = math.floor
local UIParent = UIParent

function NRSKNUI:UIMult()
    local uiScale = self.uiScale or (UIParent and UIParent:GetEffectiveScale()) or 1
    self.mult = self.perfect / uiScale
end

function NRSKNUI:PixelBestSize()
    local perfectScale = self.perfect or 1
    if perfectScale < 0.4 then return 0.4 end
    if perfectScale > 1.15 then return 1.15 end
    return perfectScale
end

function NRSKNUI:UIScale()
    UIParent:SetScale(self.perfect)
    self.uiScale = self.perfect
    self:UIMult()
end

---@param event string
function NRSKNUI:PixelScaleChanged(event)
    if event == "UI_SCALE_CHANGED" then
        self.physicalWidth, self.physicalHeight = GetPhysicalScreenSize()
        self.resolution = string_format("%dx%d", self.physicalWidth, self.physicalHeight)
        self.perfect = 768 / self.physicalHeight
    end
    self:UIScale()
    if self.UpdateSpells then self:UpdateSpells() end
end

do
    ---@param obj table
    function NRSKNUI:PixelPerfect(obj)
        if obj.SetTexelSnappingBias then
            obj:SetTexelSnappingBias(0)
            obj:SetSnapToPixelGrid(false)
        elseif obj.GetObjectType then
            obj:SetIgnoreParentScale(true)
            local SCALE = 768 / select(2, GetPhysicalScreenSize())
            obj:SetScale(SCALE)
        end
    end
end

---@param x number?
---@return number
function NRSKNUI:Scale(x)
    if not x or type(x) ~= "number" then return 0 end

    local m = self.mult or 1
    if m == 1 or x == 0 then return x end

    local y = m > 1 and m or -m
    return x - x % (x < 0 and y or -y)
end

---@param value number?
---@return number
function NRSKNUI:SnapToPixel(value)
    if not value or type(value) ~= "number" then return 0 end
    local scale = self.perfect
    return math_floor(value / scale + 0.5) * scale
end

---@param frame Frame?
---@return string point
---@return number x
---@return number y
function NRSKNUI:CalculateFramePosition(frame)
    if not frame then return "CENTER", 0, 0 end
    local centerX, centerY = UIParent:GetCenter()
    local screenWidth = UIParent:GetRight()
    local frameX, frameY = frame:GetCenter()
    if not frameX or not frameY then return "CENTER", 0, 0 end
    local point = "BOTTOM"
    local x, y
    if frameY >= centerY then
        point = "TOP"
        y = -(UIParent:GetTop() - frame:GetTop())
    else
        y = frame:GetBottom()
    end
    if frameX >= (screenWidth * 2 / 3) then
        point = point .. "RIGHT"
        x = frame:GetRight() - screenWidth
    elseif frameX <= (screenWidth / 3) then
        point = point .. "LEFT"
        x = frame:GetLeft()
    else
        x = frameX - centerX
    end
    return point, math_floor(x + 0.5), math_floor(y + 0.5)
end

---@param frame Frame?
---@param forceAbsolute boolean? If true, recalculate anchor from screen position
function NRSKNUI:SnapFrameToPixels(frame, forceAbsolute)
    if not frame then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    if not point then return end

    if forceAbsolute then
        local newPoint, x, y = self:CalculateFramePosition(frame)
        frame:ClearAllPoints()
        frame:SetPoint(newPoint, UIParent, newPoint, x, y)
    else
        local scale = self.perfect
        local snappedX = math_floor((xOfs or 0) / scale + 0.5) * scale
        local snappedY = math_floor((yOfs or 0) / scale + 0.5) * scale
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo or UIParent, relativePoint or point, snappedX, snappedY)
    end
end

---@param frame Frame?
function NRSKNUI:SnapFrameSize(frame)
    if not frame then return end
    local width, height = frame:GetSize()
    frame:SetSize(math_floor(width + 0.5), math_floor(height + 0.5))
end

---@param frame Frame?
function NRSKNUI:SnapFrame(frame)
    if not frame then return end
    self:SnapFrameSize(frame)
    self:SnapFrameToPixels(frame)
end

NRSKNUI.physicalWidth, NRSKNUI.physicalHeight = GetPhysicalScreenSize()
NRSKNUI.resolution = string_format("%dx%d", NRSKNUI.physicalWidth, NRSKNUI.physicalHeight)
NRSKNUI.perfect = 768 / NRSKNUI.physicalHeight
NRSKNUI:UIMult()

-- GUI Widget Pixel Perfection System
do
    local function ScaleValue(x)
        local m = NRSKNUI.mult
        if m == 1 or x == 0 then
            return x
        else
            local y = m > 1 and m or -m
            return x - x % (x < 0 and y or -y)
        end
    end

    local function WatchPixelSnap(frame, snap)
        if frame and not frame:IsForbidden() and frame.NUIPixelSnapDisabled and snap then frame.NUIPixelSnapDisabled = nil end
    end

    local function DisablePixelSnap(frame)
        if frame and not frame:IsForbidden() and not frame.NUIPixelSnapDisabled then
            if frame.SetSnapToPixelGrid then
                frame:SetSnapToPixelGrid(false)
                frame:SetTexelSnappingBias(0)
            elseif frame.GetStatusBarTexture then
                local texture = frame:GetStatusBarTexture()
                if type(texture) == "table" and texture.SetSnapToPixelGrid then
                    texture:SetSnapToPixelGrid(false)
                    texture:SetTexelSnappingBias(0)
                end
            end
            frame.NUIPixelSnapDisabled = true
        end
    end

    local function Size(frame, width, height, ...)
        local w = ScaleValue(width)
        frame:SetSize(w, height and ScaleValue(height) or w, ...)
    end

    local function Width(frame, width, ...) frame:SetWidth(ScaleValue(width), ...) end
    local function Height(frame, height, ...) frame:SetHeight(ScaleValue(height), ...) end
    local function Point(obj, arg1, arg2, arg3, arg4, arg5, ...)
        if not arg2 then arg2 = obj:GetParent() end
        if type(arg2) == "number" then arg2 = ScaleValue(arg2) end
        if type(arg3) == "number" then arg3 = ScaleValue(arg3) end
        if type(arg4) == "number" then arg4 = ScaleValue(arg4) end
        if type(arg5) == "number" then arg5 = ScaleValue(arg5) end
        obj:SetPoint(arg1, arg2, arg3, arg4, arg5, ...)
    end

    local function SetInside(obj, anchor, xOffset, yOffset, anchor2)
        if not anchor then anchor = obj:GetParent() end
        if not xOffset then xOffset = 1 end
        if not yOffset then yOffset = 1 end
        local x = ScaleValue(xOffset)
        local y = ScaleValue(yOffset)
        if pcall(obj.GetPoint, obj) then obj:ClearAllPoints() end
        DisablePixelSnap(obj)
        obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, -y)
        obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", -x, y)
    end

    local function SetOutside(obj, anchor, xOffset, yOffset, anchor2)
        if not anchor then anchor = obj:GetParent() end
        if not xOffset then xOffset = 1 end
        if not yOffset then yOffset = 1 end
        local x = ScaleValue(xOffset)
        local y = ScaleValue(yOffset)
        if pcall(obj.GetPoint, obj) then obj:ClearAllPoints() end
        DisablePixelSnap(obj)
        obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", -x, y)
        obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", x, -y)
    end

    local WidgetAPI = {
        Size = Size,
        Width = Width,
        Height = Height,
        Point = Point,
        SetInside = SetInside,
        SetOutside = SetOutside,
        DisablePixelSnap = DisablePixelSnap,
    }

    local function AddWidgetAPI(object)
        local mt = getmetatable(object)
        if not mt or not mt.__index then return end
        local mk = mt.__index
        for method, func in next, WidgetAPI do if not object[method] then mk[method] = func end end
        if not mk.NUIDisabledPixelSnap then
            if mk.SetSnapToPixelGrid then hooksecurefunc(mk, "SetSnapToPixelGrid", WatchPixelSnap) end
            if mk.SetStatusBarTexture then hooksecurefunc(mk, "SetStatusBarTexture", DisablePixelSnap) end
            if mk.SetColorTexture then hooksecurefunc(mk, "SetColorTexture", DisablePixelSnap) end
            if mk.SetVertexColor then hooksecurefunc(mk, "SetVertexColor", DisablePixelSnap) end
            if mk.CreateTexture then hooksecurefunc(mk, "CreateTexture", DisablePixelSnap) end
            if mk.SetTexCoord then hooksecurefunc(mk, "SetTexCoord", DisablePixelSnap) end
            if mk.SetTexture then hooksecurefunc(mk, "SetTexture", DisablePixelSnap) end
            mk.NUIDisabledPixelSnap = true
        end
    end

    local handled = { Frame = true }
    local baseFrame = CreateFrame("Frame")
    AddWidgetAPI(baseFrame)
    AddWidgetAPI(baseFrame:CreateTexture())
    AddWidgetAPI(baseFrame:CreateFontString())
    AddWidgetAPI(baseFrame:CreateMaskTexture())

    local frame = EnumerateFrames()
    while frame do
        local objType = frame:GetObjectType()
        if not frame:IsForbidden() and not handled[objType] then
            AddWidgetAPI(frame)
            handled[objType] = true
        end
        frame = EnumerateFrames(frame)
    end
    AddWidgetAPI(CreateFrame("ScrollFrame"))
    NRSKNUI.ScaleValue = ScaleValue
    NRSKNUI.DisablePixelSnap = DisablePixelSnap
end

local pixelPerfectFrame = CreateFrame("Frame")
pixelPerfectFrame:RegisterEvent("UI_SCALE_CHANGED")
pixelPerfectFrame:SetScript("OnEvent", function(_, event) NRSKNUI:PixelScaleChanged(event) end)
