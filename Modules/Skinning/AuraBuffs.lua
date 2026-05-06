---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("BuffTracking: Addon object not initialized!")
    return
end

---@class BuffTracking: AceModule, AceEvent-3.0
local BUFFS = NorskenUI:NewModule("BuffTracking", "AceEvent-3.0")

BUFFS.buttons = {}

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs
local unpack = unpack
local format = string.format
local floor = math.floor
local wipe = wipe
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local RegisterAttributeDriver = RegisterAttributeDriver
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local C_UnitAuras = C_UnitAuras
local C_DurationUtil = C_DurationUtil
local GameTooltip = GameTooltip

local reusableDurationObj = C_DurationUtil.CreateDuration()

local DIRECTION_TO_POINT = {
    DOWN_RIGHT = "TOPLEFT",
    DOWN_LEFT = "TOPRIGHT",
    UP_RIGHT = "BOTTOMLEFT",
    UP_LEFT = "BOTTOMRIGHT",
    RIGHT_DOWN = "TOPLEFT",
    RIGHT_UP = "BOTTOMLEFT",
    LEFT_DOWN = "TOPRIGHT",
    LEFT_UP = "BOTTOMRIGHT",
}
local DIRECTION_TO_X_MULT = { DOWN_RIGHT = 1, DOWN_LEFT = -1, UP_RIGHT = 1, UP_LEFT = -1, RIGHT_DOWN = 1, RIGHT_UP = 1, LEFT_DOWN = -1, LEFT_UP = -1, }
local DIRECTION_TO_Y_MULT = { DOWN_RIGHT = -1, DOWN_LEFT = -1, UP_RIGHT = 1, UP_LEFT = 1, RIGHT_DOWN = -1, RIGHT_UP = 1, LEFT_DOWN = -1, LEFT_UP = 1, }
local IS_HORIZONTAL_GROWTH = { RIGHT_DOWN = true, RIGHT_UP = true, LEFT_DOWN = true, LEFT_UP = true, }

function BUFFS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.BuffTracking
end

function BUFFS:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function auraOnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")

    local auraIndex = button:GetAttribute("index")
    if auraIndex then
        local unit = button:GetParent():GetAttribute("unit")
        if GameTooltip:SetUnitAura(unit, auraIndex, "HELPFUL") then GameTooltip:Show() end
    elseif button:GetAttribute("target-slot") then
        if GameTooltip:SetInventoryItem("player", button:GetID()) then GameTooltip:Show() end
    end
end

local function auraOnLeave()
    GameTooltip:Hide()
end

local function auraUpdateBuff(button, auraIndex)
    local unit = button:GetParent():GetAttribute("unit")
    local auraInfo = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")
    if auraInfo then
        button.Icon:SetTexture(auraInfo.icon)

        local instanceID = auraInfo.auraInstanceID

        button.Count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(unit, instanceID, 2, 999))

        if button.Cooldown then
            local duration = C_UnitAuras.GetAuraDuration(unit, instanceID)
            if duration then
                button.Cooldown:SetCooldownFromDurationObject(duration)
                button.Cooldown:Show()
            else
                button.Cooldown:Hide()
            end
        end
    end
end

local function auraUpdateEnchant(button, inventorySlotIndex)
    local duration, count, _
    if inventorySlotIndex == 16 then
        _, duration, count = GetWeaponEnchantInfo()
    elseif inventorySlotIndex == 17 then
        _, _, _, _, _, duration, count = GetWeaponEnchantInfo()
    else
        return
    end

    button.Icon:SetTexture(GetInventoryItemTexture("player", inventorySlotIndex))
    button.Count:SetText(count and count > 1 and count or "")
    button:SetBorderColor(unpack(BUFFS.db.EnchantBorderColor))

    if button.Cooldown and duration then
        reusableDurationObj:SetTimeFromStart(GetTime(), duration / 1000)
        button.Cooldown:SetCooldownFromDurationObject(reusableDurationObj)
        button.Cooldown:Show()
    elseif button.Cooldown then
        button.Cooldown:Hide()
    end
end

local function auraOnAttributeChanged(button, attribute, ...)
    if attribute == "index" then
        auraUpdateBuff(button, ...)
    elseif attribute == "target-slot" then
        auraUpdateEnchant(button, ...)
    end
end

local function applyTimerStyle(button, db)
    local cooldownText = button.Cooldown:GetRegions()
    if cooldownText and cooldownText.SetFont then
        NRSKNUI:ApplyFont(cooldownText, db.FontFace, db.TimerFontSize, db.FontOutline)
        if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end
        if cooldownText.SetJustifyH then cooldownText:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(db.TimerPosition
            .AnchorFrom)) end
        cooldownText:ClearAllPoints()
        cooldownText:SetPoint(db.TimerPosition.AnchorFrom, button, db.TimerPosition.AnchorTo, db.TimerPosition.XOffset,
            db.TimerPosition.YOffset)
    end
end

local function auraButtonInit(button)
    if button._initialized then return end
    button._initialized = true
    BUFFS.buttons[button] = true

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0, 0, 0, 0.3)

    NRSKNUI:AddBorders(button, BUFFS.db.BorderColor)

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom)

    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetPoint(BUFFS.db.StackPosition.AnchorFrom, button, BUFFS.db.StackPosition.AnchorTo,
        BUFFS.db.StackPosition.XOffset, BUFFS.db.StackPosition.YOffset)
    button.Count:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(BUFFS.db.StackPosition.AnchorFrom))
    NRSKNUI:ApplyFont(button.Count, BUFFS.db.FontFace, BUFFS.db.FontSize, BUFFS.db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetDrawBling(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    applyTimerStyle(button, BUFFS.db)

    button:HookScript("OnAttributeChanged", auraOnAttributeChanged)
    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)
end

local function applyButtonSettings(button, db)
    if button.bg then button.bg:SetColorTexture(0, 0, 0, 0.3) end
    if button.SetBorderColor then button:SetBorderColor(unpack(db.BorderColor)) end
    if button.Count then
        NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
        button.Count:SetShadowOffset(0, 0)
        button.Count:ClearAllPoints()
        button.Count:SetPoint(db.StackPosition.AnchorFrom, button, db.StackPosition.AnchorTo,
            db.StackPosition.XOffset, db.StackPosition.YOffset)
        button.Count:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(db.StackPosition.AnchorFrom))
    end
    if button.Cooldown then applyTimerStyle(button, db) end
    if button.Icon then NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom) end
end

function BUFFS:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    for button in pairs(self.buttons) do applyButtonSettings(button, self.db) end
    if self.previewActive then self:ShowPreview() end
end

function BUFFS:CreateBuffFrame()
    if self.buffs then return end
    local spacing = self.db.IconSize + self.db.IconSpacing

    self.buffs = CreateFrame("Frame", "NorskenUIBuffFrame", UIParent, "SecureAuraHeaderTemplate")

    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.buffs:SetPoint(self.db.Position.AnchorFrom, anchorFrame, self.db.Position.AnchorTo, self.db.Position.XOffset,
        self.db.Position.YOffset)
    NRSKNUI:PixelPerfect(self.buffs)

    self.buffs:SetAttribute("template", "SecureAuraButtonTemplate")
    self.buffs:SetAttribute("unit", "player")
    self.buffs:SetAttribute("filter", self.db.Filter)
    self.buffs:SetAttribute("includeWeapons", self.db.IncludeWeaponEnchants and 1 or 0)
    self.buffs:SetAttribute("weaponTemplate", "SecureAuraButtonTemplate")

    self.buffs:SetAttribute("sortMethod", self.db.SortMethod)
    self.buffs:SetAttribute("sortDirection", self.db.SortDirection)
    self.buffs:SetAttribute("separateOwn", 1)

    local direction = self.db.GrowthDirection
    local point = DIRECTION_TO_POINT[direction]
    local xMult = DIRECTION_TO_X_MULT[direction]
    local yMult = DIRECTION_TO_Y_MULT[direction]

    self.buffs:SetAttribute("point", point)
    self.buffs:SetAttribute("wrapAfter", self.db.IconsPerRow)

    if IS_HORIZONTAL_GROWTH[direction] then
        self.buffs:SetAttribute("minWidth", self.db.IconsPerRow * spacing)
        self.buffs:SetAttribute("minHeight", self.db.MaxRows * spacing)
        self.buffs:SetAttribute("xOffset", xMult * spacing)
        self.buffs:SetAttribute("yOffset", 0)
        self.buffs:SetAttribute("wrapXOffset", 0)
        self.buffs:SetAttribute("wrapYOffset", yMult * spacing)
    else
        self.buffs:SetAttribute("minWidth", self.db.MaxRows * spacing)
        self.buffs:SetAttribute("minHeight", self.db.IconsPerRow * spacing)
        self.buffs:SetAttribute("xOffset", 0)
        self.buffs:SetAttribute("yOffset", yMult * spacing)
        self.buffs:SetAttribute("wrapXOffset", xMult * spacing)
        self.buffs:SetAttribute("wrapYOffset", 0)
    end
    self.buffs:SetAttribute("initialConfigFunction", format([[
        self:SetWidth(%d)
        self:SetHeight(%d)
    ]], self.db.IconSize, self.db.IconSize))

    RegisterAttributeDriver(self.buffs, "unit", "[vehicleui] vehicle; player")

    self.buffs:HookScript("OnAttributeChanged", function(_, attribute, ...)
        local prefix = attribute:sub(1, 5)
        if prefix == "child" or prefix == "tempe" then
            auraButtonInit(...)
        end
    end)
    self.buffs:Show()
end

function BUFFS:ApplyPosition()
    if InCombatLockdown() then return end
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)

    if self.buffs then
        self.buffs:ClearAllPoints()
        self.buffs:SetPoint(self.db.Position.AnchorFrom, anchorFrame, self.db.Position.AnchorTo,
            self.db.Position.XOffset, self.db.Position.YOffset)
        self.buffs:SetFrameStrata(self.db.Strata)
    end

    if self.previewActive and self.previewFrame then
        self.previewFrame:ClearAllPoints()
        self.previewFrame:SetPoint(self.db.Position.AnchorFrom, anchorFrame, self.db.Position.AnchorTo,
            self.db.Position.XOffset, self.db.Position.YOffset)
    end
end

function BUFFS:UpdatePosition(pos)
    if InCombatLockdown() then return end
    self.db.Position.AnchorFrom = pos.AnchorFrom
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

function BUFFS:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    -- Get rid off blizzy buff frames
    NRSKNUI:Hide('BuffFrame')
    CVarCallbackRegistry:UnregisterCallback('consolidateBuffs', BuffFrame)
    CVarCallbackRegistry:UnregisterCallback('collapseExpandBuffs', BuffFrame)

    self:CreateBuffFrame()

    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEditMode()
end

function BUFFS:RegisterEditMode()
    if not self.buffs then return end
    if not NRSKNUI.EditMode then return end
    NRSKNUI.EditMode:RegisterElement({
        key = "BuffTracking",
        displayName = "BUFFS",
        frame = self.buffs,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self:UpdatePosition(pos)
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "CustomSkin_Buffs",
    })
end

-- Preview

local PREVIEW_ICONS = {
    136048, -- Mark of the Wild
    135932, -- Arcane Intellect
    135987, -- Power Word: Fortitude
    132333, -- Blessing of Kings
    135995, -- Renew
    136085, -- Regrowth
    135964, -- Flask
    134830, -- Well Fed
}

local function CreatePreviewButton(parent, index, db)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(db.IconSize, db.IconSize)

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0, 0, 0, 0.3)

    NRSKNUI:AddBorders(button, db.BorderColor)

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom)
    local iconIndex = ((index - 1) % #PREVIEW_ICONS) + 1
    button.Icon:SetTexture(PREVIEW_ICONS[iconIndex])

    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetPoint(db.StackPosition.AnchorFrom, button, db.StackPosition.AnchorTo,
        db.StackPosition.XOffset, db.StackPosition.YOffset)
    button.Count:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(db.StackPosition.AnchorFrom))
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)
    if index % 4 == 1 then
        button.Count:SetText("2")
    elseif index % 4 == 2 then
        button.Count:SetText("3")
    end

    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetDrawBling(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    applyTimerStyle(button, db)

    if index % 3 ~= 0 then
        local duration = 15 + ((index * 7) % 45)
        local startTime = GetTime() - (duration * (0.2 + (index % 5) * 0.1))
        button.Cooldown:SetCooldown(startTime, duration)
        button.Cooldown:Show()
    else
        button.Cooldown:Hide()
    end

    return button
end

function BUFFS:ShowPreview()
    local spacing = self.db.IconSize + self.db.IconSpacing
    local previewCount = self.db.IconsPerRow * self.db.MaxRows

    if not self.previewFrame then
        self.previewFrame = CreateFrame("Frame", "NorskenUIBuffPreview", UIParent)
        self.previewButtons = {}
    end

    local direction = self.db.GrowthDirection
    local point = DIRECTION_TO_POINT[direction]
    local xMult = DIRECTION_TO_X_MULT[direction]
    local yMult = DIRECTION_TO_Y_MULT[direction]
    local horizontal = IS_HORIZONTAL_GROWTH[direction]

    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.previewFrame:ClearAllPoints()
    self.previewFrame:SetPoint(
        self.db.Position.AnchorFrom,
        anchorFrame,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )

    if horizontal then
        self.previewFrame:SetSize(self.db.IconsPerRow * spacing, self.db.MaxRows * spacing)
    else
        self.previewFrame:SetSize(self.db.MaxRows * spacing, self.db.IconsPerRow * spacing)
    end

    for _, btn in ipairs(self.previewButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    wipe(self.previewButtons)

    for i = 1, previewCount do
        local button = CreatePreviewButton(self.previewFrame, i, self.db)
        local col, row
        if horizontal then
            col = (i - 1) % self.db.IconsPerRow
            row = floor((i - 1) / self.db.IconsPerRow)
            button:SetPoint(point, self.previewFrame, point, col * xMult * spacing, row * yMult * spacing)
        else
            row = (i - 1) % self.db.IconsPerRow
            col = floor((i - 1) / self.db.IconsPerRow)
            button:SetPoint(point, self.previewFrame, point, col * xMult * spacing, row * yMult * spacing)
        end
        button:Show()
        self.previewButtons[i] = button
    end

    self.previewFrame:Show()
    self.previewActive = true
    if self.buffs then self.buffs:Hide() end
end

function BUFFS:HidePreview()
    if self.previewFrame then self.previewFrame:Hide() end
    self.previewActive = false
    if self.buffs and self.db.Enabled then self.buffs:Show() end
end

function BUFFS:TogglePreview()
    if self.previewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return self.previewActive
end

function BUFFS:IsPreviewActive()
    return self.previewActive or false
end
