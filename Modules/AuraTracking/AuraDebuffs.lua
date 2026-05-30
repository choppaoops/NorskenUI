---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("DebuffTracking: Addon object not initialized!")
    return
end

---@class DebuffTracking: AceModule, AceEvent-3.0
local DEBUFFS = NorskenUI:NewModule("DebuffTracking", "AceEvent-3.0")

DEBUFFS.buttons = {}
DEBUFFS.buttonPool = {}
DEBUFFS.auraCache = {}
DEBUFFS.activeAuras = {}

local CreateFrame = CreateFrame
local issecretvalue = issecretvalue
local unpack = unpack
local pairs, ipairs = pairs, ipairs
local wipe = wipe
local tinsert = table.insert
local tsort = table.sort
local math_min = math.min
local math_floor = math.floor
local GetTime = GetTime
local GameTooltip = GameTooltip
local C_UnitAuras = C_UnitAuras

local pendingFullRefresh = false

local DISPEL_ICON_ATLASES = {
    [NRSKNUI.Enum.DispelType.Magic] = "RaidFrame-Icon-DebuffMagic",
    [NRSKNUI.Enum.DispelType.Curse] = "RaidFrame-Icon-DebuffCurse",
    [NRSKNUI.Enum.DispelType.Disease] = "RaidFrame-Icon-DebuffDisease",
    [NRSKNUI.Enum.DispelType.Poison] = "RaidFrame-Icon-DebuffPoison",
    [NRSKNUI.Enum.DispelType.Bleed] = "RaidFrame-Icon-DebuffBleed",
}

local DISPEL_CURVE_NAMES = {
    [NRSKNUI.Enum.DispelType.Magic] = "Magic",
    [NRSKNUI.Enum.DispelType.Curse] = "Curse",
    [NRSKNUI.Enum.DispelType.Disease] = "Disease",
    [NRSKNUI.Enum.DispelType.Poison] = "Poison",
    [NRSKNUI.Enum.DispelType.Bleed] = "Bleed",
}

local FILTER_NAMES = {
    "PLAYER",
    "RAID",
    "INCLUDE_NAME_PLATE_ONLY",
    "CROWD_CONTROL",
    "RAID_IN_COMBAT",
    "RAID_PLAYER_DISPELLABLE",
    "IMPORTANT"
}

local DEFAULT_BLOCKLIST = {
    [390435] = { label = "BL (Hunter)", enabled = true, default = true },
    [57723] = { label = "BL (Drums)", enabled = true, default = true },
    [95809] = { label = "BL (Hunter)", enabled = true, default = true },
    [80354] = { label = "BL (Mage)", enabled = true, default = true },
    [308312] = { label = "Time Trial", enabled = true, default = true },
    [57724] = { label = "BL (Shaman)", enabled = true, default = true },
    [160455] = { label = "BL (Hunter)", enabled = true, default = true },
    [264689] = { label = "BL (Hunter)", enabled = true, default = true },
}

function DEBUFFS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.DebuffTracking
    self:BuildFilterStrings()
    NRSKNUI:LoadDispelColorsFromDB()
end

function DEBUFFS:OnInitialize()
    self:UpdateDB()
    self:ApplyDefaultBlocklist()
    self:SetEnabledState(false)
end

function DEBUFFS:ApplyDefaultBlocklist()
    if not self.db.Blocklist then
        self.db.Blocklist = {}
    end
    for spellId, entry in pairs(DEFAULT_BLOCKLIST) do
        if self.db.Blocklist[spellId] == nil then
            self.db.Blocklist[spellId] = { label = entry.label, enabled = entry.enabled, default = true }
        end
    end
end

function DEBUFFS:BuildFilterStrings()
    self.filterStrings = wipe(self.filterStrings or {})
    if not self.db.Filters then return end

    for _, name in ipairs(FILTER_NAMES) do
        if self.db.Filters[name] then
            tinsert(self.filterStrings, "HARMFUL" .. "|" .. name)
        end
    end
end

local function ShouldShowAura(auraInstanceID, aura, db, filterStrings)
    if not aura then return false end

    local isFilteredOut = C_UnitAuras.IsAuraFilteredOutByInstanceID("player", auraInstanceID, "HARMFUL")
    if not issecretvalue(isFilteredOut) and isFilteredOut then
        return false
    end

    -- Check blocklist filter, this only works for non secret auras
    local spellId = aura.spellId
    if spellId and not issecretvalue(spellId) then
        local entry = db.Blocklist and db.Blocklist[spellId]
        if entry and (entry == true or (type(entry) == "table" and entry.enabled)) then
            return false
        end
    end

    -- Check Blizzard filters
    if filterStrings and #filterStrings > 0 then
        for _, filter in ipairs(filterStrings) do
            local filtered = C_UnitAuras.IsAuraFilteredOutByInstanceID("player", auraInstanceID, filter)
            if not issecretvalue(filtered) and not filtered then
                return false
            end
        end
    end

    return true
end

local function GetBorderColor(auraInstanceID, db)
    if db.BorderColorMode == "dispel" then
        local colorCurve = NRSKNUI:GetDispelColorCurve()
        if colorCurve then
            local color = C_UnitAuras.GetAuraDispelTypeColor("player", auraInstanceID, colorCurve)
            if not color then color = colorCurve:Evaluate(0) end
            if color then return { color:GetRGBA() } end
        end
    end
    return db.BorderColor
end

local function ApplyCooldownTextStyle(cooldown, db)
    local cooldownText = cooldown:GetRegions()
    if not cooldownText or not cooldownText.SetFont then return end

    NRSKNUI:ApplyFont(cooldownText, db.FontFace, db.TimerFontSize, db.FontOutline)
    if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end

    local pos = db.TimerPosition
    cooldownText:ClearAllPoints()
    cooldownText:SetPoint(pos.AnchorFrom, cooldown:GetParent(), pos.AnchorTo, pos.XOffset, pos.YOffset)
end

local function auraOnEnter(button)
    if not DEBUFFS.db.ShowTooltips then return end
    if not button.auraInstanceID then return end
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetUnitAuraByAuraInstanceID("player", button.auraInstanceID)
    GameTooltip:Show()
end

local function auraOnLeave()
    GameTooltip:Hide()
end

local function ApplyMouseSettings(frame, db)
    local allowMotion = db.ShowTooltips
    frame:EnableMouse(allowMotion)
    if frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(false) end
    if frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(allowMotion) end
    for _, child in ipairs({ frame:GetChildren() }) do
        child:EnableMouse(false)
        if child.SetMouseClickEnabled then child:SetMouseClickEnabled(false) end
        if child.SetMouseMotionEnabled then child:SetMouseMotionEnabled(false) end
    end
end

local function CreateAuraButton(parent)
    local db = DEBUFFS.db

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(db.IconSize, db.IconSize)

    DEBUFFS.buttons[button] = true

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0, 0, 0, 0.3)

    NRSKNUI:AddBorders(button, { 0, 0, 0, 1 }, button, 1)

    button.Overlay = button:CreateTexture(nil, "BORDER")
    button.Overlay:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\AuraOverlay.png")
    button.Overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.Overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom)

    button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.Cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.Cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetDrawSwipe(db.Swipe)
    button.Cooldown:SetReverse(db.Reverse)
    button.Cooldown:SetDrawBling(false)
    button.Cooldown:SetHideCountdownNumbers(false)
    ApplyCooldownTextStyle(button.Cooldown, db)

    button.Count = button.Cooldown:CreateFontString(nil, "OVERLAY")
    local stackPos = db.StackPosition or
        { AnchorFrom = "BOTTOMRIGHT", AnchorTo = "BOTTOMRIGHT", XOffset = -1, YOffset = 1 }
    button.Count:SetPoint(stackPos.AnchorFrom, button, stackPos.AnchorTo, stackPos.XOffset, stackPos.YOffset)
    button.Count:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(stackPos.AnchorFrom))
    NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)
    button:Hide()

    button.DispelOverlay = CreateFrame("Frame", nil, button)
    button.DispelOverlay:SetAllPoints()
    button.DispelOverlay:SetFrameLevel(button.Cooldown:GetFrameLevel() + 1)

    button.DispelIcons = {}
    for dispelIndex, atlas in pairs(DISPEL_ICON_ATLASES) do
        local icon = button.DispelOverlay:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        icon:SetAtlas(atlas)
        icon:SetAlpha(0)
        button.DispelIcons[dispelIndex] = icon
    end

    ApplyMouseSettings(button, db)

    return button
end

local function UpdateAuraButton(button, data)
    if not data then
        button:Hide()
        return
    end

    local db = DEBUFFS.db

    button.auraInstanceID = data.auraInstanceID
    button.Icon:SetTexture(data.icon)

    local count = C_UnitAuras.GetAuraApplicationDisplayCount("player", data.auraInstanceID, 2, 999)
    button.Count:SetText(count)

    local duration = C_UnitAuras.GetAuraDuration("player", data.auraInstanceID)
    if duration then
        button.Cooldown:SetCooldownFromDurationObject(duration)
        button.Cooldown:Show()
    else
        button.Cooldown:Hide()
    end

    -- Overlay color by dispel type
    if button.Overlay then
        local overlayColor = GetBorderColor(data.auraInstanceID, db)
        button.Overlay:SetVertexColor(unpack(overlayColor))
    end

    -- Dispel icons visibility based on dispel type
    if button.DispelIcons then
        local dispelAlphaCurves = NRSKNUI.curves.DispelAlpha
        for dispelIndex, icon in pairs(button.DispelIcons) do
            local curveName = DISPEL_CURVE_NAMES[dispelIndex]
            local curve = curveName and dispelAlphaCurves[curveName]
            if curve then
                local color = C_UnitAuras.GetAuraDispelTypeColor("player", data.auraInstanceID, curve)
                if color then
                    local _, _, _, a = color:GetRGBA()
                    icon:SetAlpha(a)
                else
                    icon:SetAlpha(0)
                end
            end
        end
    end

    button:Show()
end

local function SortAuras(a, b)
    return a.auraInstanceID < b.auraInstanceID
end

local function PositionButtons(self)
    local db = self.db
    local spacing = db.IconSize + db.IconSpacing
    local iconsPerRow = db.IconsPerRow
    local growH = db.GrowHorizontal == "LEFT" and -1 or 1
    local growV = db.GrowVertical == "DOWN" and -1 or 1
    local visibleCount = 0

    for _, button in ipairs(self.buttonPool) do
        if button:IsShown() then
            visibleCount = visibleCount + 1
            local col = (visibleCount - 1) % iconsPerRow
            local row = math_floor((visibleCount - 1) / iconsPerRow)
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", col * spacing * growH, row * spacing * growV)
        end
    end
end

function DEBUFFS:RefreshAllAuras()
    if not self.frame then return end

    local db = self.db
    wipe(self.auraCache)
    wipe(self.activeAuras)

    local auraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs("player", "HARMFUL")
    if not auraInstanceIDs then return end

    local dataIndex = 0
    for _, auraInstanceID in ipairs(auraInstanceIDs) do
        local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
        if aura and ShouldShowAura(auraInstanceID, aura, db, self.filterStrings) then
            self.activeAuras[auraInstanceID] = true
            dataIndex = dataIndex + 1
            self.auraCache[dataIndex] = aura
        end
    end

    if dataIndex > 1 then tsort(self.auraCache, SortAuras) end

    local maxVisible = math_min(db.IconsPerRow * db.MaxRows, dataIndex)

    while #self.buttonPool < maxVisible do tinsert(self.buttonPool, CreateAuraButton(self.frame)) end

    for i = 1, #self.buttonPool do
        if i <= maxVisible and self.auraCache[i] then
            UpdateAuraButton(self.buttonPool[i], self.auraCache[i])
        else
            self.buttonPool[i]:Hide()
        end
    end

    PositionButtons(self)
end

function DEBUFFS:ProcessAuraUpdate(addedAuras, updatedIDs, removedIDs)
    if not self.frame then return end

    local changed = false
    local db = self.db

    if removedIDs then
        for _, auraInstanceID in ipairs(removedIDs) do
            if self.activeAuras[auraInstanceID] then
                self.activeAuras[auraInstanceID] = nil
                changed = true
            end
        end
    end

    if addedAuras then
        for _, aura in ipairs(addedAuras) do
            if ShouldShowAura(aura.auraInstanceID, aura, db, self.filterStrings) then
                self.activeAuras[aura.auraInstanceID] = true
                changed = true
            end
        end
    end

    if updatedIDs then
        for _, auraInstanceID in ipairs(updatedIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
            local shouldShow = aura and ShouldShowAura(auraInstanceID, aura, db, self.filterStrings)
            local wasShowing = self.activeAuras[auraInstanceID]

            if shouldShow and not wasShowing then
                self.activeAuras[auraInstanceID] = true
                changed = true
            elseif not shouldShow and wasShowing then
                self.activeAuras[auraInstanceID] = nil
                changed = true
            elseif shouldShow and wasShowing then
                changed = true
            end
        end
    end

    if changed then self:RefreshAllAuras() end
end

function DEBUFFS:QueueFullRefresh()
    if pendingFullRefresh then return end
    pendingFullRefresh = true

    C_Timer.After(0, function()
        pendingFullRefresh = false
        DEBUFFS:RefreshAllAuras()
    end)
end

function DEBUFFS:UNIT_AURA(_, unit, updateInfo)
    if unit ~= "player" then return end
    if not self.frame then return end

    if not updateInfo or updateInfo.isFullUpdate then
        self:QueueFullRefresh()
        return
    end

    if not updateInfo.addedAuras
        and not updateInfo.updatedAuraInstanceIDs
        and not updateInfo.removedAuraInstanceIDs then
        return
    end

    self:ProcessAuraUpdate(updateInfo.addedAuras, updateInfo.updatedAuraInstanceIDs, updateInfo.removedAuraInstanceIDs)
end

function DEBUFFS:PLAYER_ENTERING_WORLD()
    self:QueueFullRefresh()
end

local function GetFrameSize(db)
    local w = db.IconsPerRow * db.IconSize + (db.IconsPerRow - 1) * db.IconSpacing
    local h = db.MaxRows * db.IconSize + (db.MaxRows - 1) * db.IconSpacing
    return w, h
end

local function ApplyButtonSettings(button, db)
    button:SetSize(db.IconSize, db.IconSize)
    ApplyMouseSettings(button, db)
    if button.Count then
        NRSKNUI:ApplyFont(button.Count, db.FontFace, db.FontSize, db.FontOutline)
        button.Count:SetShadowOffset(0, 0)
        local stackPos = db.StackPosition or
            { AnchorFrom = "BOTTOMRIGHT", AnchorTo = "BOTTOMRIGHT", XOffset = -1, YOffset = 1 }
        button.Count:ClearAllPoints()
        button.Count:SetPoint(stackPos.AnchorFrom, button, stackPos.AnchorTo, stackPos.XOffset, stackPos.YOffset)
        button.Count:SetJustifyH(NRSKNUI:GetTextJustifyFromAnchor(stackPos.AnchorFrom))
    end
    if button.Cooldown then
        ApplyCooldownTextStyle(button.Cooldown, db)
        button.Cooldown:SetDrawSwipe(db.Swipe)
        button.Cooldown:SetReverse(db.Reverse)
    end
    if button.Icon then NRSKNUI:ApplyZoom(button.Icon, NRSKNUI.GlobalZoom) end
end

function DEBUFFS:ApplySettings()
    self:BuildFilterStrings()

    for button in pairs(self.buttons) do ApplyButtonSettings(button, self.db) end

    if self.frame then
        self.frame:SetSize(GetFrameSize(self.db))
        self:RefreshAllAuras()
    end

    if self.previewActive then self:ShowPreview() end
end

function DEBUFFS:CreateFrame()
    if self.frame then return end

    self.frame = CreateFrame("Frame", "NorskenUIDebuffFrame", UIParent)
    self.frame:SetSize(GetFrameSize(self.db))
    self.frame:EnableMouse(false)
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
    self.frame:Show()
end

function DEBUFFS:ApplyPosition()
    if self.frame then NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db) end
    if self.previewActive and self.previewFrame then
        NRSKNUI:ApplyFramePosition(self.previewFrame, self.db.Position,
            self.db)
    end
end

function DEBUFFS:UpdatePosition(pos)
    self.db.Position.AnchorFrom = pos.AnchorFrom
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

function DEBUFFS:OnEnable()
    if not self.db.Enabled then return end

    self:CreateFrame()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RefreshAllAuras()

    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self:RegisterEditMode()
end

function DEBUFFS:OnDisable()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    if self.frame then self.frame:Hide() end
end

function DEBUFFS:RegisterEditMode()
    if not self.frame or not NRSKNUI.EditMode then return end

    NRSKNUI.EditMode:RegisterElement({
        key = "DebuffTracking",
        displayName = "DEBUFFS",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos) self:UpdatePosition(pos) end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "CustomSkin_Debuffs",
    })
end

-- Preview stuff

local PREVIEW_ICONS = { 136139, 136188, 132090, 135849, 132095, 136197, }
local PREVIEW_DISPEL_TYPES = { 0, 1, 2, 3, 4, 11 } -- None, Magic, Curse, Disease, Poison, Bleed

function DEBUFFS:ShowPreview()
    local db = self.db
    local spacing = db.IconSize + db.IconSpacing
    local previewCount = db.IconsPerRow * db.MaxRows

    if not self.previewFrame then
        self.previewFrame = CreateFrame("Frame", "NorskenUIDebuffPreview", UIParent)
        self.previewButtons = {}
    end

    NRSKNUI:ApplyFramePosition(self.previewFrame, db.Position, db)
    self.previewFrame:SetSize(GetFrameSize(db))

    while #self.previewButtons < previewCount do tinsert(self.previewButtons, CreateAuraButton(self.previewFrame)) end

    local growH = db.GrowHorizontal == "LEFT" and -1 or 1
    local growV = db.GrowVertical == "DOWN" and -1 or 1

    for i, button in ipairs(self.previewButtons) do
        if i <= previewCount then
            ApplyButtonSettings(button, db)

            local col = (i - 1) % db.IconsPerRow
            local row = math_floor((i - 1) / db.IconsPerRow)
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", self.previewFrame, "TOPRIGHT", col * spacing * growH, row * spacing * growV)

            local iconIndex = ((i - 1) % #PREVIEW_ICONS) + 1
            button.Icon:SetTexture(PREVIEW_ICONS[iconIndex])
            button.auraInstanceID = nil

            if button.Overlay then
                if db.BorderColorMode == "dispel" then
                    local dispelType = PREVIEW_DISPEL_TYPES[iconIndex]
                    local color = NRSKNUI:GetDispelColor(dispelType)
                    button.Overlay:SetVertexColor(unpack(color))
                else
                    button.Overlay:SetVertexColor(unpack(db.BorderColor))
                end
            end

            if button.DispelIcons then
                local dispelType = PREVIEW_DISPEL_TYPES[iconIndex]
                for dispelIndex, icon in pairs(button.DispelIcons) do
                    icon:SetAlpha(dispelIndex == dispelType and 1 or 0)
                end
            end

            if i % 4 == 1 then
                button.Count:SetText(2)
            elseif i % 4 == 2 then
                button.Count:SetText(5)
            else
                button.Count:SetText("")
            end

            if i % 3 ~= 0 then
                local duration = 20 + ((i * 5) % 30)
                local startTime = GetTime() - (duration * (0.2 + (i % 5) * 0.1))
                button.Cooldown:SetCooldown(startTime, duration)
                button.Cooldown:Show()
            else
                button.Cooldown:Hide()
            end

            button:Show()
        else
            button:Hide()
        end
    end

    self.previewFrame:Show()
    self.previewActive = true
    if self.frame then self.frame:Hide() end
end

function DEBUFFS:HidePreview()
    if self.previewFrame then self.previewFrame:Hide() end
    self.previewActive = false
    if self.frame and self.db.Enabled then self.frame:Show() end
end

function DEBUFFS:TogglePreview()
    if self.previewActive then
        self:HidePreview()
        self:ShowPreview()
    end
end

function DEBUFFS:IsPreviewActive()
    return self.previewActive or false
end
