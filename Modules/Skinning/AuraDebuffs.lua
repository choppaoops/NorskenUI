-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("DebuffTracking: Addon object not initialized!")
    return
end

-- Create module
---@class DebuffTracking: AceModule, AceEvent-3.0
local DEBUFFS = NorskenUI:NewModule("DebuffTracking", "AceEvent-3.0")

-- Store references to all initialized buttons
DEBUFFS.buttons = {}

-- Localization
local CreateFrame = CreateFrame
local unpack = unpack
local format = string.format
local floor = math.floor
local wipe = wipe
local pairs = pairs
local RegisterAttributeDriver = RegisterAttributeDriver
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local GameTooltip = GameTooltip
local C_UnitAuras = C_UnitAuras

-- Update db, used for profile changes
function DEBUFFS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.DebuffTracking
end

-- Module init
function DEBUFFS:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Tooltip enter
local function auraOnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")

    local auraIndex = button:GetAttribute("index")
    if auraIndex then
        local unit = button:GetParent():GetAttribute("unit")
        if GameTooltip:SetUnitAura(unit, auraIndex, "HARMFUL") then
            GameTooltip:Show()
        end
    end
end

-- Tooltip leave
local function auraOnLeave()
    GameTooltip:Hide()
end

-- Update debuff button data
local function auraUpdateDebuff(button, auraIndex)
    local unit = button:GetParent():GetAttribute("unit")
    local auraInfo = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HARMFUL")
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

-- Attribute changed handler
local function auraOnAttributeChanged(button, attribute, ...)
    if attribute == "index" then auraUpdateDebuff(button, ...) end
end

-- Initialize a single aura button
local function auraButtonInit(button)
    if button._initialized then return end
    button._initialized = true

    -- Store reference
    DEBUFFS.buttons[button] = true

    local db = DEBUFFS.db

    -- Add backdrop/background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(unpack(db.BackgroundColor))

    -- Add borders
    NRSKNUI:AddBorders(button, db.BorderColor)

    -- Icon texture
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom)

    -- Count text
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

    -- Cooldown frame
    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetPoint("CENTER", button, "CENTER", 0, 3)
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    -- Apply timer font size, position, and remove shadow from cooldown timer text
    local timerFontSize = db.TimerFontSize or 20
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
    button:HookScript("OnAttributeChanged", auraOnAttributeChanged)
    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)
end

-- Apply visual settings to a single button
local function applyButtonSettings(button, db)
    if button.bg then button.bg:SetColorTexture(unpack(db.BackgroundColor)) end
    if button.SetBorderColor then button:SetBorderColor(unpack(db.BorderColor)) end
    if button.Count then
        NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
        button.Count:SetShadowOffset(0, 0)
    end
    if button.Cooldown then
        local timerFontSize = db.TimerFontSize or 20
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
    if button.Icon then NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom) end
end

-- Apply settings to all initialized buttons
function DEBUFFS:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    for button in pairs(self.buttons) do applyButtonSettings(button, self.db) end
    if self.previewActive then self:ShowPreview() end
end

-- Create the main debuff frame
function DEBUFFS:CreateDebuffFrame()
    if self.debuffs then return end
    local spacing = self.db.IconSize + self.db.IconSpacing

    -- Create secure aura header
    self.debuffs = CreateFrame("Frame", "NorskenUIDebuffFrame", UIParent, "SecureAuraHeaderTemplate")

    -- Position
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.debuffs:SetPoint(
        self.db.Position.AnchorFrom,
        anchorFrame,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    NRSKNUI:PixelPerfect(self.debuffs)

    -- Set up templates and filters
    self.debuffs:SetAttribute("template", "SecureAuraButtonTemplate")
    self.debuffs:SetAttribute("unit", "player")
    self.debuffs:SetAttribute("filter", "HARMFUL")

    -- Sorting
    self.debuffs:SetAttribute("sortMethod", self.db.SortMethod)
    self.debuffs:SetAttribute("sortDirection", self.db.SortDirection)

    -- Position and size for aura buttons
    self.debuffs:SetAttribute("point", "TOPRIGHT")
    self.debuffs:SetAttribute("minWidth", self.db.IconsPerRow * spacing)
    self.debuffs:SetAttribute("minHeight", self.db.MaxRows * spacing)
    self.debuffs:SetAttribute("xOffset", -spacing)
    self.debuffs:SetAttribute("wrapYOffset", -spacing)
    self.debuffs:SetAttribute("wrapAfter", self.db.IconsPerRow)
    self.debuffs:SetAttribute("initialConfigFunction", format([[
        self:SetWidth(%d)
        self:SetHeight(%d)
    ]], self.db.IconSize, self.db.IconSize))

    -- Register attribute driver for vehicle support
    RegisterAttributeDriver(self.debuffs, "unit", "[vehicleui] vehicle; player")

    -- Hook attribute changes so we can skin aura buttons
    self.debuffs:HookScript("OnAttributeChanged", function(_, attribute, ...)
        if attribute:sub(1, 5) == "child" then auraButtonInit(...) end
    end)
    self.debuffs:Show()
end

-- Apply position from db settings (called by GUI and EditMode)
function DEBUFFS:ApplyPosition()
    if InCombatLockdown() then return end
    local anchorFrame = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)

    -- Update main frame position
    if self.debuffs then
        self.debuffs:ClearAllPoints()
        self.debuffs:SetPoint(
            self.db.Position.AnchorFrom,
            anchorFrame,
            self.db.Position.AnchorTo,
            self.db.Position.XOffset,
            self.db.Position.YOffset
        )
        self.debuffs:SetFrameStrata(self.db.Strata or "MEDIUM")
        NRSKNUI:SnapFrameToPixels(self.debuffs)
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

-- Update position, for drag positioning in edit mode
function DEBUFFS:UpdatePosition(pos)
    if InCombatLockdown() then return end
    self.db.Position.AnchorFrom = pos.AnchorFrom
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

-- Module OnEnable
function DEBUFFS:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    NRSKNUI:Hide('DebuffFrame') -- Yeet Blizzard's default debuff frame

    self:CreateDebuffFrame()

    -- Delayed positioning to ensure custom anchor frames exist
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEditMode()
end

-- Register with EditMode system
function DEBUFFS:RegisterEditMode()
    if not self.debuffs then return end
    if not NRSKNUI.EditMode then return end
    NRSKNUI.EditMode:RegisterElement({
        key = "DebuffTracking",
        displayName = "DEBUFFS",
        frame = self.debuffs,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self:UpdatePosition(pos)
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "CustomSkin_Debuffs",
    })
end

-- Preview stuff

-- Sample debuff icons for preview
local PREVIEW_ICONS = {
    136139, -- Curse of Weakness
    136188, -- Shadow Word: Pain
    132090, -- Corruption
    135849, -- Faerie Fire
    132095, -- Sunder Armor
    136197, -- Wound Poison
}

-- Create a single preview button
local function CreatePreviewButton(parent, index, db)
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
    NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom)
    local iconIndex = ((index - 1) % #PREVIEW_ICONS) + 1
    button.Icon:SetTexture(PREVIEW_ICONS[iconIndex])

    -- Count text
    button.Count = button:CreateFontString(nil, "OVERLAY")
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.Count:SetJustifyH("RIGHT")
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)
    -- Show stack count on some icons
    if index % 4 == 1 then
        button.Count:SetText(2)
    elseif index % 4 == 2 then
        button.Count:SetText(5)
    end

    -- Cooldown frame
    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(false)
    button.Cooldown:SetHideCountdownNumbers(false)

    -- Apply timer font size and position
    local timerFontSize = db.TimerFontSize or 20
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
    if index % 3 ~= 0 then
        local duration = 8 + ((index * 5) % 30)
        local startTime = GetTime() - (duration * (0.2 + (index % 5) * 0.1))
        button.Cooldown:SetCooldown(startTime, duration)
        button.Cooldown:Show()
    else
        button.Cooldown:Hide()
    end

    return button
end

-- Show preview with fake debuff icons
function DEBUFFS:ShowPreview()
    local spacing = self.db.IconSize + self.db.IconSpacing
    local previewCount = self.db.IconsPerRow * self.db.MaxRows

    -- Create preview frame if needed
    if not self.previewFrame then
        self.previewFrame = CreateFrame("Frame", "NorskenUIDebuffPreview", UIParent)
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
    if self.debuffs then self.debuffs:Hide() end
end

-- Hide preview
function DEBUFFS:HidePreview()
    if self.previewFrame then self.previewFrame:Hide() end
    self.previewActive = false
    if self.debuffs and self.db.Enabled then self.debuffs:Show() end
end

-- Toggle preview
function DEBUFFS:TogglePreview()
    if self.previewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return self.previewActive
end

-- Check if preview is active
function DEBUFFS:IsPreviewActive()
    return self.previewActive or false
end
