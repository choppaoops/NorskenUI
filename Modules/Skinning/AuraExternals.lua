-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("ExternalBuffTracking: Addon object not initialized!")
    return
end

-- Create module
---@class ExternalBuffTracking: AceModule, AceEvent-3.0
local EXTERNALS = NorskenUI:NewModule("ExternalBuffTracking", "AceEvent-3.0")

-- Store references to all initialized buttons
EXTERNALS.buttons = {}

-- Localization
local CreateFrame = CreateFrame
local unpack = unpack
local GetTime = GetTime
local pairs, ipairs = pairs, ipairs
local wipe = wipe
local tinsert = table.insert
local tsort = table.sort
local math_min = math.min
local math_floor = math.floor
local GameTooltip = GameTooltip
local C_UnitAuras = C_UnitAuras

-- Coalescing flag for UNIT_AURA events
local pendingAuraUpdate = false

-- Reusable tables to avoid garbage creation
local slotsCache = {}
local auraDataCache = {}
local FILTER = "HELPFUL|EXTERNAL_DEFENSIVE"
local FILTER_PLAYER = FILTER .. "|PLAYER"

-- Update db, used for profile changes
function EXTERNALS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.ExternalBuffTracking
end

-- Module init
function EXTERNALS:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Tooltip enter
local function auraOnEnter(button)
    if not button.auraInstanceID then return end
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetUnitAuraByAuraInstanceID("player", button.auraInstanceID)
    GameTooltip:Show()
end

-- Tooltip leave
local function auraOnLeave()
    GameTooltip:Hide()
end

-- Create a single aura button
local function CreateAuraButton(parent, index)
    local db = EXTERNALS.db
    local iconSize = db.IconSize

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(iconSize, iconSize)
    button:EnableMouse(true)

    -- Store reference
    EXTERNALS.buttons[button] = true

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

    -- Count text (bottom right)
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

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
        NRSKNUI:ApplyFont(cooldownText, db.FontFace, timerFontSize, db.FontOutline)
        if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end
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
    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)

    button:Hide()
    return button
end

-- Update a single button with aura data
local function UpdateAuraButton(button, unit, data)
    if not data then
        button:Hide()
        return
    end

    button.auraInstanceID = data.auraInstanceID
    button.Icon:SetTexture(data.icon)

    -- Count
    local count = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 999)
    button.Count:SetText(count)

    if button.Cooldown then
        local duration = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)
        if duration then
            button.Cooldown:SetCooldownFromDurationObject(duration)
            button.Cooldown:Show()
        else
            button.Cooldown:Hide()
        end
    end

    button:Show()
end

-- Position buttons in a grid
local function PositionButtons(self)
    local spacing = self.db.IconSize + self.db.IconSpacing
    local iconsPerRow = self.db.IconsPerRow
    local visibleCount = 0

    for i, button in ipairs(self.buttonPool) do
        if button:IsShown() then
            visibleCount = visibleCount + 1
            local col = (visibleCount - 1) % iconsPerRow
            local row = math_floor((visibleCount - 1) / iconsPerRow)

            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -col * spacing, -row * spacing)
        end
    end
end

-- Sort auras
local function SortAuras(a, b)
    if a.isPlayerAura ~= b.isPlayerAura then
        return a.isPlayerAura
    end
    return a.auraInstanceID < b.auraInstanceID
end

-- Full update of all auras
function EXTERNALS:UpdateAuras()
    if not self.frame then return end

    local db = self.db
    local unit = "player"

    -- Get all aura slots matching the filter (reuse table)
    wipe(slotsCache)
    slotsCache[1], slotsCache[2], slotsCache[3], slotsCache[4], slotsCache[5],
    slotsCache[6], slotsCache[7], slotsCache[8], slotsCache[9], slotsCache[10],
    slotsCache[11], slotsCache[12], slotsCache[13], slotsCache[14], slotsCache[15],
    slotsCache[16], slotsCache[17], slotsCache[18], slotsCache[19], slotsCache[20] = C_UnitAuras.GetAuraSlots(unit, FILTER)

    -- Collect aura data (reuse table)
    wipe(auraDataCache)
    local dataIndex = 0
    for i = 2, 20 do -- Skip first return (continuation token), max reasonable slots
        local slot = slotsCache[i]
        if not slot then break end
        local data = C_UnitAuras.GetAuraDataBySlot(unit, slot)
        if data then
            -- Check if it's from the player (use cached filter string)
            data.isPlayerAura = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, FILTER_PLAYER)
            dataIndex = dataIndex + 1
            auraDataCache[dataIndex] = data
        end
    end

    -- Sort auras
    if dataIndex > 1 then
        tsort(auraDataCache, SortAuras)
    end

    -- Calculate max visible
    local maxVisible = math_min(db.IconsPerRow * db.MaxRows, dataIndex)

    -- Ensure we have enough buttons
    while #self.buttonPool < maxVisible do
        local button = CreateAuraButton(self.frame, #self.buttonPool + 1)
        tinsert(self.buttonPool, button)
    end

    -- Update buttons
    for i = 1, #self.buttonPool do
        if i <= maxVisible and auraDataCache[i] then
            UpdateAuraButton(self.buttonPool[i], unit, auraDataCache[i])
        else
            self.buttonPool[i]:Hide()
        end
    end

    -- Position visible buttons
    PositionButtons(self)
end

-- Apply visual settings to a single button
local function applyButtonSettings(button, db)
    button:SetSize(db.IconSize, db.IconSize)
    if button.bg then button.bg:SetColorTexture(unpack(db.BackgroundColor)) end
    if button.SetBorderColor then button:SetBorderColor(unpack(db.BorderColor)) end
    if button.Count then
        NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
        button.Count:SetShadowOffset(0, 0)
    end
    if button.Cooldown then
        local timerFontSize = db.TimerFontSize or 14
        local timerPos = db.TimerPosition or {}
        local cooldownText = button.Cooldown:GetRegions()
        if cooldownText and cooldownText.SetFont then
            NRSKNUI:ApplyFont(cooldownText, db.FontFace, timerFontSize, db.FontOutline)
            if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end
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
function EXTERNALS:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end

    for button in pairs(self.buttons) do applyButtonSettings(button, self.db) end
    if self.frame then PositionButtons(self) end
    if self.previewActive then self:ShowPreview() end
end

-- Create the main external buff frame
function EXTERNALS:CreateFrame()
    if self.frame then return end
    local spacing = self.db.IconSize + self.db.IconSpacing

    -- Create container frame
    self.frame = CreateFrame("Frame", "NorskenUIExternalBuffFrame", UIParent)
    self.frame:SetSize(self.db.IconsPerRow * spacing, self.db.MaxRows * spacing)

    -- Position
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.frame:SetPoint(
        self.db.Position.AnchorFrom,
        anchorFrame,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    NRSKNUI:PixelPerfect(self.frame)
    self.buttonPool = {}
    self.frame:Show()
end

-- Apply position from db settings
function EXTERNALS:ApplyPosition()
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)

    -- Update main frame position
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(
            self.db.Position.AnchorFrom,
            anchorFrame,
            self.db.Position.AnchorTo,
            self.db.Position.XOffset,
            self.db.Position.YOffset
        )
        self.frame:SetFrameStrata(self.db.Strata or "MEDIUM")
        NRSKNUI:SnapFrameToPixels(self.frame)
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

-- Update position, this one is for dragging in edit mode
function EXTERNALS:UpdatePosition(pos)
    self.db.Position.AnchorFrom = pos.AnchorFrom
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

-- UNIT_AURA event handler (coalesced to prevent multiple updates per frame)
function EXTERNALS:UNIT_AURA(_, unit)
    if unit ~= "player" or pendingAuraUpdate then return end
    pendingAuraUpdate = true
    C_Timer.After(0, function()
        pendingAuraUpdate = false
        EXTERNALS:UpdateAuras()
    end)
end

-- Module OnEnable
function EXTERNALS:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    self:CreateFrame()
    self:RegisterEvent("UNIT_AURA")
    self:UpdateAuras()

    -- Delayed positioning to ensure custom anchor frames exist like UUF_Player for example
    C_Timer.After(0.5, function() self:ApplyPosition() end)
    self:RegisterEditMode()
end

-- Module OnDisable
function EXTERNALS:OnDisable()
    self:UnregisterEvent("UNIT_AURA")
    if self.frame then self.frame:Hide() end
end

-- Register with EditMode system
function EXTERNALS:RegisterEditMode()
    if not self.frame then return end
    if not NRSKNUI.EditMode then return end
    NRSKNUI.EditMode:RegisterElement({
        key = "ExternalBuffTracking",
        displayName = "EXTERNALS",
        frame = self.frame,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self:UpdatePosition(pos)
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "CustomSkin_Externals",
    })
end

-- Preview stuff

-- Random icons for preview
local PREVIEW_ICONS = {
    135936, -- Pain Suppression
    136097, -- Ironbark
    135966, -- Blessing of Sacrifice
    135928, -- Guardian Spirit
    237586, -- Life Cocoon
    136120, -- Hand of Protection
}

-- Create a single preview button
local function CreatePreviewButton(parent, index, db)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(db.IconSize, db.IconSize)

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
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

    -- Cooldown frame
    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    -- Apply timer font size and position
    local timerFontSize = db.TimerFontSize or 16
    local timerPos = db.TimerPosition or {}
    local cooldownText = button.Cooldown:GetRegions()
    if cooldownText and cooldownText.SetFont then
        NRSKNUI:ApplyFont(cooldownText, db.FontFace, timerFontSize, db.FontOutline)
        if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end
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
    local duration = 6 + ((index * 3) % 12)
    local startTime = GetTime() - (duration * (0.15 + (index % 4) * 0.1))
    button.Cooldown:SetCooldown(startTime, duration)
    button.Cooldown:Show()

    return button
end

-- Show preview with fake external buff icons
function EXTERNALS:ShowPreview()
    local spacing = self.db.IconSize + self.db.IconSpacing
    local previewCount = self.db.IconsPerRow * self.db.MaxRows

    -- Create preview frame if needed
    if not self.previewFrame then
        self.previewFrame = CreateFrame("Frame", "NorskenUIExternalPreview", UIParent)
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
        local row = math_floor((i - 1) / self.db.IconsPerRow)
        button:SetPoint("TOPRIGHT", self.previewFrame, "TOPRIGHT", -col * spacing, -row * spacing)
        button:Show()
        self.previewButtons[i] = button
    end

    self.previewFrame:Show()
    self.previewActive = true

    -- Hide the real frame while previewing
    if self.frame then
        self.frame:Hide()
    end
end

-- Hide preview
function EXTERNALS:HidePreview()
    if self.previewFrame then self.previewFrame:Hide() end
    self.previewActive = false
    if self.frame and self.db.Enabled then self.frame:Show() end
end

-- Toggle preview
function EXTERNALS:TogglePreview()
    if self.previewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return self.previewActive
end

-- Check if preview is active
function EXTERNALS:IsPreviewActive()
    return self.previewActive or false
end
