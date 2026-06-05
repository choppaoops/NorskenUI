---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("DebuffTrackingDefault: Addon object not initialized!")
    return
end

---@class DebuffTrackingDefault: AceModule, AceEvent-3.0
local DEBUFFS = NorskenUI:NewModule("DebuffTrackingDefault", "AceEvent-3.0")

DEBUFFS.buttons = {}
DEBUFFS.buttonPool = {}
DEBUFFS.auraCache = {}

local CreateFrame = CreateFrame
local wipe = wipe
local tinsert = table.insert
local tsort = table.sort
local math_min = math.min
local math_floor = math.floor
local GetTime = GetTime
local GameTooltip = GameTooltip
local C_UnitAuras = C_UnitAuras

local function GetAnchorPoint(db)
    local h, v = db.GrowHorizontal or "LEFT", db.GrowVertical or "DOWN"
    if h == "LEFT" and v == "DOWN" then return "TOPRIGHT"
    elseif h == "LEFT" and v == "UP" then return "BOTTOMRIGHT"
    elseif h == "RIGHT" and v == "DOWN" then return "TOPLEFT"
    else return "BOTTOMLEFT" end
end

function DEBUFFS:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.DebuffTrackingDefault
end

function DEBUFFS:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function ApplyCooldownTextStyle(cooldown, db)
    local cooldownText = cooldown:GetRegions()
    if not cooldownText or not cooldownText.SetFont then return end

    NRSKNUI:ApplyFont(cooldownText, NRSKNUI:GetEffectiveFont(db), db.TimerFontSize, db.FontOutline)
    if cooldownText.SetShadowOffset then cooldownText:SetShadowOffset(0, 0) end

    local pos = db.TimerPosition
    cooldownText:ClearAllPoints()
    cooldownText:SetPoint(pos.AnchorFrom, cooldown:GetParent(), pos.AnchorTo, pos.XOffset, pos.YOffset)
end

local function auraOnEnter(button)
    if not button.auraInstanceID then return end
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetUnitAuraByAuraInstanceID("player", button.auraInstanceID)
    GameTooltip:Show()
end

local function auraOnLeave()
    GameTooltip:Hide()
end

local function CreateAuraButton(parent)
    local db = DEBUFFS.db

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(db.IconSize, db.IconSize)
    button:EnableMouse(true)

    DEBUFFS.buttons[button] = true

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0, 0, 0, 0.3)

    NRSKNUI:AddBorders(button, db.BorderColor, button, 1)

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
    NRSKNUI:ApplyFont(button.Count, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline)
    button.Count:SetShadowOffset(0, 0)

    button:SetScript("OnEnter", auraOnEnter)
    button:SetScript("OnLeave", auraOnLeave)
    button:Hide()

    return button
end

local function UpdateAuraButton(button, data)
    if not data then
        button:Hide()
        return
    end

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
    local anchorPoint = GetAnchorPoint(db)
    local visibleCount = 0

    for _, button in ipairs(self.buttonPool) do
        if button:IsShown() then
            visibleCount = visibleCount + 1
            local col = (visibleCount - 1) % iconsPerRow
            local row = math_floor((visibleCount - 1) / iconsPerRow)
            button:ClearAllPoints()
            button:SetPoint(anchorPoint, self.frame, anchorPoint, col * spacing * growH, row * spacing * growV)
        end
    end
end

function DEBUFFS:RefreshAllAuras()
    if not self.frame then return end

    local db = self.db
    wipe(self.auraCache)

    local auraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs("player", "HARMFUL")
    if not auraInstanceIDs then return end

    local dataIndex = 0
    for _, auraInstanceID in ipairs(auraInstanceIDs) do
        local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
        if aura then
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

function DEBUFFS:UNIT_AURA(_, unit)
    if unit ~= "player" then return end
    self:RefreshAllAuras()
end

function DEBUFFS:PLAYER_ENTERING_WORLD()
    self:RefreshAllAuras()
end

local function GetFrameSize(db)
    local w = db.IconsPerRow * db.IconSize + (db.IconsPerRow - 1) * db.IconSpacing
    local h = db.MaxRows * db.IconSize + (db.MaxRows - 1) * db.IconSpacing
    return w, h
end

local function ApplyButtonSettings(button, db)
    button:SetSize(db.IconSize, db.IconSize)
    if button.Count then
        NRSKNUI:ApplyFont(button.Count, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline)
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
    if NRSKNUI:ShouldNotLoadModule() then return end
    for button in pairs(self.buttons) do ApplyButtonSettings(button, self.db) end

    if self.frame then
        self.frame:SetSize(GetFrameSize(self.db))
        self:ApplyPosition()
        self:RefreshAllAuras()
    end

    if self.previewActive then self:ShowPreview() end
end

function DEBUFFS:CreateFrame()
    if self.frame then return end

    self.frame = CreateFrame("Frame", "NorskenUIDebuffDefaultFrame", UIParent)
    self.frame:SetSize(GetFrameSize(self.db))
    self:ApplyPosition()
    self.frame:Show()
end

function DEBUFFS:ApplyPosition()
    if not self.frame then return end
    local anchorPoint = GetAnchorPoint(self.db)
    local parent = NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
    self.frame:ClearAllPoints()
    self.frame:SetPoint(anchorPoint, parent, self.db.Position.AnchorTo, self.db.Position.XOffset, self.db.Position.YOffset)
    self.frame:SetFrameStrata(self.db.Strata or "MEDIUM")
    NRSKNUI:SnapFrameToPixels(self.frame, self.db.ForcePixelPerfect)
end

function DEBUFFS:UpdatePosition(pos)
    self.db.Position.AnchorTo = pos.AnchorTo
    self.db.Position.XOffset = pos.XOffset
    self.db.Position.YOffset = pos.YOffset
    self:ApplyPosition()
end

function DEBUFFS:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    NRSKNUI:Hide('DebuffFrame')

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
        key = "DebuffTrackingDefault",
        displayName = "DEBUFFS (Default)",
        frame = self.frame,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos) self:UpdatePosition(pos) end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "CustomSkin_DebuffsDefault",
    })
end

-- Preview

local PREVIEW_ICONS = { 136139, 136188, 132090, 135849, 132095, 136197 }

function DEBUFFS:ShowPreview()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.frame then self:CreateFrame() end

    local db = self.db
    local spacing = db.IconSize + db.IconSpacing
    local previewCount = db.IconsPerRow * db.MaxRows

    while #self.buttonPool < previewCount do tinsert(self.buttonPool, CreateAuraButton(self.frame)) end

    local growH = db.GrowHorizontal == "LEFT" and -1 or 1
    local growV = db.GrowVertical == "DOWN" and -1 or 1
    local anchorPoint = GetAnchorPoint(db)

    for i, button in ipairs(self.buttonPool) do
        if i <= previewCount then
            ApplyButtonSettings(button, db)

            local col = (i - 1) % db.IconsPerRow
            local row = math_floor((i - 1) / db.IconsPerRow)
            button:ClearAllPoints()
            button:SetPoint(anchorPoint, self.frame, anchorPoint, col * spacing * growH, row * spacing * growV)

            local iconIndex = ((i - 1) % #PREVIEW_ICONS) + 1
            button.Icon:SetTexture(PREVIEW_ICONS[iconIndex])
            button.auraInstanceID = nil

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

    self.frame:Show()
    self.previewActive = true
end

function DEBUFFS:HidePreview()
    self.previewActive = false
    if self.frame and self.db.Enabled then
        self:RefreshAllAuras()
    elseif self.frame then
        for _, button in ipairs(self.buttonPool) do button:Hide() end
    end
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
