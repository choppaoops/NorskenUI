-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("BuffTracking: Addon object not initialized!")
    return
end

-- Create module
---@class BuffTracking: AceModule, AceEvent-3.0
local BUFFS = NorskenUI:NewModule("BuffTracking", "AceEvent-3.0")

-- Store references to all initialized buttons
BUFFS.buttons = {}

-- Localization
local CreateFrame = CreateFrame
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

-- Reusable duration object to avoid garbage creation
local reusableDurationObj = C_DurationUtil.CreateDuration()

-- Update db, used for profile changes
function BUFFS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.BuffTracking
end

-- Module init
function BUFFS:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Tooltip enter
local function auraOnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")

    local auraIndex = button:GetAttribute("index")
    if auraIndex then
        local unit = button:GetParent():GetAttribute("unit")
        if GameTooltip:SetUnitAura(unit, auraIndex, "HELPFUL") then
            GameTooltip:Show()
        end
    elseif button:GetAttribute("target-slot") then
        if GameTooltip:SetInventoryItem("player", button:GetID()) then
            GameTooltip:Show()
        end
    end
end

-- Tooltip leave
local function auraOnLeave()
    GameTooltip:Hide()
end

-- Update buff button data
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

-- Update weapon enchant button data
local function auraUpdateEnchant(button, inventorySlotIndex)
    local duration, count, _
    if inventorySlotIndex == 16 then     -- main hand
        _, duration, count = GetWeaponEnchantInfo()
    elseif inventorySlotIndex == 17 then -- off hand
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

-- Attribute changed handler
local function auraOnAttributeChanged(button, attribute, ...)
    if attribute == "index" then
        auraUpdateBuff(button, ...)
    elseif attribute == "target-slot" then
        auraUpdateEnchant(button, ...)
    end
end

-- Initialize a single aura button
local function auraButtonInit(button)
    if button._initialized then return end
    button._initialized = true

    -- Store reference
    BUFFS.buttons[button] = true

    local db = BUFFS.db
    local fontPath = NRSKNUI:GetFontPath(db.FontFace)
    local fontOutline = NRSKNUI:GetFontOutline(db.FontOutline)

    -- Add backdrop/background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(unpack(db.BackgroundColor))

    -- Add borders
    NRSKNUI:AddBorders(button, db.BorderColor)

    -- Icon texture
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    NRSKNUI:ApplyZoom(button.Icon, db.IconZoom)

    -- Count text
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetFont(fontPath, db.FontSize, fontOutline)
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    button.Count:SetShadowOffset(0, 0)

    -- Cooldown frame
    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    -- Apply timer font size, position, and remove shadow from cooldown timer text
    local timerFontSize = db.TimerFontSize or 14
    local timerPos = db.TimerPosition or {}
    local cooldownText = button.Cooldown:GetRegions()
    if cooldownText and cooldownText.SetFont then
        cooldownText:SetFont(fontPath, timerFontSize, fontOutline)
        cooldownText:SetShadowOffset(0, 0)
        cooldownText:ClearAllPoints()
        cooldownText:SetPoint(
            timerPos.AnchorFrom or "CENTER",
            button,
            timerPos.AnchorTo or "CENTER",
            timerPos.XOffset or 0,
            timerPos.YOffset or 0
        )
    end

    -- Script handlers
    button:HookScript("OnAttributeChanged", auraOnAttributeChanged)
    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)
end

-- Apply visual settings to a single button
local function applyButtonSettings(button, db, fontPath, fontOutline)
    if button.bg then button.bg:SetColorTexture(unpack(db.BackgroundColor)) end
    if button.SetBorderColor then button:SetBorderColor(unpack(db.BorderColor)) end
    if button.Count then button.Count:SetFont(fontPath, db.FontSize, fontOutline) end
    if button.Cooldown then
        local timerFontSize = db.TimerFontSize or 14
        local timerPos = db.TimerPosition or {}
        local cooldownText = button.Cooldown:GetRegions()
        if cooldownText and cooldownText.SetFont then
            cooldownText:SetFont(fontPath, timerFontSize, fontOutline)
            cooldownText:ClearAllPoints()
            cooldownText:SetPoint(
                timerPos.AnchorFrom or "CENTER",
                button,
                timerPos.AnchorTo or "CENTER",
                timerPos.XOffset or 0,
                timerPos.YOffset or 0
            )
        end
    end
    if button.Icon then NRSKNUI:ApplyZoom(button.Icon, db.IconZoom) end
end

-- Apply settings to all initialized buttons
function BUFFS:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    local fontPath = NRSKNUI:GetFontPath(self.db.FontFace)
    local fontOutline = NRSKNUI:GetFontOutline(self.db.FontOutline)
    for button in pairs(self.buttons) do applyButtonSettings(button, self.db, fontPath, fontOutline) end
    if self.previewActive then self:ShowPreview() end
end

-- Create the main buff frame
function BUFFS:CreateBuffFrame()
    if self.buffs then return end
    local spacing = self.db.IconSize + self.db.IconSpacing

    -- Create secure aura header
    self.buffs = CreateFrame("Frame", "NorskenUIBuffFrame", UIParent, "SecureAuraHeaderTemplate")

    -- Position
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.buffs:SetPoint(
        self.db.Position.AnchorFrom,
        anchorFrame,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    NRSKNUI:PixelPerfect(self.buffs)

    -- Set up templates and filters
    self.buffs:SetAttribute("template", "SecureAuraButtonTemplate")
    self.buffs:SetAttribute("unit", "player")
    self.buffs:SetAttribute("filter", self.db.Filter)
    self.buffs:SetAttribute("includeWeapons", self.db.IncludeWeaponEnchants and 1 or 0)
    self.buffs:SetAttribute("weaponTemplate", "SecureAuraButtonTemplate")

    -- Sorting
    self.buffs:SetAttribute("sortMethod", self.db.SortMethod)
    self.buffs:SetAttribute("sortDirection", self.db.SortDirection)

    -- Position and size for aura buttons
    self.buffs:SetAttribute("point", "TOPRIGHT")
    self.buffs:SetAttribute("minWidth", self.db.IconsPerRow * spacing)
    self.buffs:SetAttribute("minHeight", self.db.MaxRows * spacing)
    self.buffs:SetAttribute("xOffset", -spacing)
    self.buffs:SetAttribute("wrapYOffset", -spacing)
    self.buffs:SetAttribute("wrapAfter", self.db.IconsPerRow)
    self.buffs:SetAttribute("initialConfigFunction", format([[
        self:SetWidth(%d)
        self:SetHeight(%d)
    ]], self.db.IconSize, self.db.IconSize))

    -- Register attribute driver for vehicle support
    RegisterAttributeDriver(self.buffs, "unit", "[vehicleui] vehicle; player")

    -- Hook attribute changes so we can skin aura buttons
    self.buffs:HookScript("OnAttributeChanged", function(_, attribute, ...)
        local prefix = attribute:sub(1, 5)
        if prefix == "child" or prefix == "tempe" then
            auraButtonInit(...)
        end
    end)
    self.buffs:Show()
end

-- Apply position from db settings
function BUFFS:ApplyPosition()
    if InCombatLockdown() then return end
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)

    -- Update main frame position
    if self.buffs then
        self.buffs:ClearAllPoints()
        self.buffs:SetPoint(
            self.db.Position.AnchorFrom,
            anchorFrame,
            self.db.Position.AnchorTo,
            self.db.Position.XOffset,
            self.db.Position.YOffset
        )
        self.buffs:SetFrameStrata(self.db.Strata or "MEDIUM")
        NRSKNUI:SnapFrameToPixels(self.buffs)
    end

    -- Also update preview frame position if active
    if self.previewActive and self.previewFrame then
        self.previewFrame:ClearAllPoints()
        self.previewFrame:SetPoint(
            self.db.Position.AnchorFrom,
            anchorFrame,
            self.db.Position.AnchorTo,
            self.db.Position.XOffset,
            self.db.Position.YOffset
        )
    end
end

-- Update position
function BUFFS:UpdatePosition(pos)
    if InCombatLockdown() then return end
    self.db.Position.AnchorFrom = pos.AnchorFrom
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

-- Module OnEnable
function BUFFS:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    NRSKNUI:Hide('BuffFrame')
    CVarCallbackRegistry:UnregisterCallback('consolidateBuffs', BuffFrame)
    CVarCallbackRegistry:UnregisterCallback('collapseExpandBuffs', BuffFrame)

    self:CreateBuffFrame()

    -- Delayed positioning to ensure custom anchor frames exist
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEditMode()
end

-- Register with EditMode system
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

-- Preview stuff

-- Sample buff icons for preview
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

-- Create a single preview button
local function CreatePreviewButton(parent, index, db)
    local fontPath = NRSKNUI:GetFontPath(db.FontFace)
    local fontOutline = NRSKNUI:GetFontOutline(db.FontOutline)
    local iconSize = db.IconSize

    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(iconSize, iconSize)

    -- Add backdrop/background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(unpack(db.BackgroundColor))

    -- Add borders
    NRSKNUI:AddBorders(button, db.BorderColor)

    -- Icon texture
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    NRSKNUI:ApplyZoom(button.Icon, db.IconZoom)
    local iconIndex = ((index - 1) % #PREVIEW_ICONS) + 1
    button.Icon:SetTexture(PREVIEW_ICONS[iconIndex])

    -- Count text
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetFont(fontPath, db.FontSize, fontOutline)
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    button.Count:SetShadowOffset(0, 0)
    -- Show stack count on some icons
    if index % 4 == 1 then
        button.Count:SetText(2)
    elseif index % 4 == 2 then
        button.Count:SetText(3)
    end

    -- Cooldown frame
    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    -- Apply timer font size and position
    local timerFontSize = db.TimerFontSize or 14
    local timerPos = db.TimerPosition or {}
    local cooldownText = button.Cooldown:GetRegions()
    if cooldownText and cooldownText.SetFont then
        cooldownText:SetFont(fontPath, timerFontSize, fontOutline)
        cooldownText:SetShadowOffset(0, 0)
        cooldownText:ClearAllPoints()
        cooldownText:SetPoint(
            timerPos.AnchorFrom or "CENTER",
            button,
            timerPos.AnchorTo or "CENTER",
            timerPos.XOffset or 0,
            timerPos.YOffset or 0
        )
    end

    -- Set a fake cooldown for preview
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

-- Show preview with fake buff icons
function BUFFS:ShowPreview()
    local spacing = self.db.IconSize + self.db.IconSpacing
    local previewCount = self.db.IconsPerRow * self.db.MaxRows

    -- Create preview frame if needed
    if not self.previewFrame then
        self.previewFrame = CreateFrame("Frame", "NorskenUIBuffPreview", UIParent)
        self.previewButtons = {}
    end

    -- Position preview frame
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.previewFrame:ClearAllPoints()
    self.previewFrame:SetPoint(
        self.db.Position.AnchorFrom,
        anchorFrame,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    self.previewFrame:SetSize(self.db.IconsPerRow * spacing, self.db.MaxRows * spacing)

    -- Clear old buttons
    for _, btn in ipairs(self.previewButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    wipe(self.previewButtons)

    -- Create preview buttons
    for i = 1, previewCount do
        local button = CreatePreviewButton(self.previewFrame, i, self.db)
        local col = (i - 1) % self.db.IconsPerRow
        local row = floor((i - 1) / self.db.IconsPerRow)
        button:SetPoint("TOPRIGHT", self.previewFrame, "TOPRIGHT", -col * spacing, -row * spacing)
        button:Show()
        self.previewButtons[i] = button
    end

    self.previewFrame:Show()
    self.previewActive = true
    if self.buffs then self.buffs:Hide() end
end

-- Hide preview
function BUFFS:HidePreview()
    if self.previewFrame then self.previewFrame:Hide() end
    self.previewActive = false
    if self.buffs and self.db.Enabled then self.buffs:Show() end
end

-- Toggle preview
function BUFFS:TogglePreview()
    if self.previewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return self.previewActive
end

-- Check if preview is active
function BUFFS:IsPreviewActive()
    return self.previewActive or false
end
