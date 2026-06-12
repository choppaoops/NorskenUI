---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then return end

---@class DragonRiding: AceModule, AceEvent-3.0
local DR = NorskenUI:NewModule("DragonRiding", "AceEvent-3.0")

local CreateFrame = CreateFrame
local ipairs = ipairs
local C_Timer = C_Timer
local C_Spell = C_Spell
local C_PlayerInfo = C_PlayerInfo
local C_UnitAuras = C_UnitAuras
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED

local VIGOR_SPELL = 372610
local THRILL_SPELL = 377234
local SECOND_WIND_SPELL = 425782
local WHIRLING_SURGE_SPELL = 361584
local BORDER_WIDTH = 1

local numVigor = 0

local function CreatePill(parent, height, texture)
    local pill = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    pill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = BORDER_WIDTH,
        insets = { left = -1, right = -1, top = -1, bottom = -1 },
    })
    pill:SetBackdropColor(0, 0, 0, 0.8)
    pill:SetBackdropBorderColor(0, 0, 0, 1)
    pill:SetStatusBarTexture(texture or "Interface\\Buttons\\WHITE8x8")
    pill:SetHeight(height)
    pill:SetStatusBarColor(0.75, 0.75, 0.75)
    return pill
end

local function ResizePillsToFit(container, pills, numPills, spacing)
    local maxWidth = container:GetWidth()
    local totalSpacing = spacing * (numPills - 1)
    local barWidth = math.floor((maxWidth - totalSpacing) / numPills)
    local leftover = math.floor((maxWidth - totalSpacing) - (barWidth * numPills))

    for i = 1, numPills do
        if pills[i] then
            pills[i]:SetWidth(i <= leftover and barWidth + 1 or barWidth)
        end
    end
end

local function UpdateWhirlingSurge(self)
    local pill = self.surgeFrame[1]
    if not pill then return end

    local charges = C_Spell.GetSpellCharges(WHIRLING_SURGE_SPELL)
    local duration
    if charges and charges.currentCharges > 0 then
        duration = C_Spell.GetSpellChargeDuration(WHIRLING_SURGE_SPELL)
    else
        duration = C_Spell.GetSpellCooldownDuration(WHIRLING_SURGE_SPELL)
    end

    if duration and not duration:IsZero() then
        pill:SetTimerDuration(duration)
    else
        pill:SetMinMaxValues(0, 1)
        pill:SetValue(1)
    end
end

local function UpdateSecondWind(self)
    local charges = C_Spell.GetSpellCharges(SECOND_WIND_SPELL)
    if not charges then return end

    for i = 1, 3 do
        local pill = self.secondWindFrame[i]
        if pill then
            if charges.currentCharges >= i then
                pill:SetMinMaxValues(0, 1)
                pill:SetValue(1)
            elseif charges.currentCharges + 1 == i then
                local duration = C_Spell.GetSpellChargeDuration(SECOND_WIND_SPELL)
                if duration then pill:SetTimerDuration(duration) end
            else
                pill:SetMinMaxValues(0, 1)
                pill:SetValue(0)
            end
        end
    end
end

local function UpdateVigor(self)
    local charges = C_Spell.GetSpellCharges(VIGOR_SPELL)
    if not charges then return end

    local db = self.db
    local spacing = db.Spacing
    local texture = NRSKNUI:GetStatusbarPath(NRSKNUI:GetEffectiveStatusBar(db))
    for i = 1, charges.maxCharges do
        local pill = self.vigorFrame[i]
        if not pill then
            pill = CreatePill(self.vigorFrame, self.vigorFrame:GetHeight(), texture)
            self.vigorFrame[i] = pill
            pill:SetPoint(i == 1 and 'LEFT' or 'LEFT', i == 1 and self.vigorFrame or self.vigorFrame[i - 1],
                i == 1 and 'LEFT' or 'RIGHT', i == 1 and 0 or spacing, 0)
        end

        if charges.currentCharges >= i then
            pill:SetMinMaxValues(0, 1)
            pill:SetValue(1)
        elseif charges.currentCharges + 1 == i then
            local duration = C_Spell.GetSpellChargeDuration(VIGOR_SPELL)
            if duration then pill:SetTimerDuration(duration) end
        else
            pill:SetMinMaxValues(0, 1)
            pill:SetValue(0)
        end
    end

    if numVigor ~= charges.maxCharges then
        numVigor = charges.maxCharges
        ResizePillsToFit(self.vigorFrame, self.vigorFrame, numVigor, spacing)
    end
end

local function UpdateVigorColor(self)
    local db = self.db
    local color
    if C_UnitAuras.GetAuraDataBySpellName('player', C_Spell.GetSpellName(THRILL_SPELL), 'HELPFUL') then
        color = db.Colors.VigorThrill
    else
        color = db.Colors.Vigor
    end

    local count = self.isPreview and 6 or numVigor
    for i = 1, count do
        if self.vigorFrame[i] then
            self.vigorFrame[i]:SetStatusBarColor(color[1], color[2], color[3])
        end
    end
end

local function UpdateSpeed(self)
    local speed = self.speedText
    if not speed then return end

    local st = self.db.SpeedText
    if not st or not st.Enabled then
        speed:SetText('')
        return
    end

    local fontFile = speed:GetFont()
    if not fontFile then
        NRSKNUI:SetTextFont(speed, NRSKNUI:GetEffectiveFont(st), st.FontSize, st.FontOutline, st.FontShadow)
        if not speed:GetFont() then return end
    end

    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
    if isGliding then
        speed:SetFormattedText('%d%%', forwardSpeed / BASE_MOVEMENT_SPEED * 100 + 0.5)
    else
        speed:SetText('')
    end
end

function DR:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.DragonRiding
end

function DR:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function DR:CreateFrames()
    if self.container then return end
    local db = self.db
    local spacing = db.Spacing
    local barHeight = db.BarHeight
    local texture = NRSKNUI:GetStatusbarPath(NRSKNUI:GetEffectiveStatusBar(db))
    local totalHeight = (barHeight * 3) + (spacing * 2) + 20

    self.parent = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate')
    self.parent:Hide()

    self.container = CreateFrame('Frame', 'NRSKNUI_DragonRidingContainer', self.parent)
    self.container:SetSize(db.Width, totalHeight)
    self.container:SetPoint(db.Position.AnchorFrom, UIParent, db.Position.AnchorTo, db.Position.XOffset,
        db.Position.YOffset)
    NRSKNUI:SnapFrameToPixels(self.container)

    self.secondWindFrame = CreateFrame('Frame', nil, self.container)
    self.secondWindFrame:SetPoint('BOTTOMLEFT')
    self.secondWindFrame:SetPoint('BOTTOMRIGHT')
    self.secondWindFrame:SetHeight(barHeight)

    local swColor = db.Colors.SecondWind
    for i = 1, 3 do
        local pill = CreatePill(self.secondWindFrame, barHeight, texture)
        pill:SetStatusBarColor(swColor[1], swColor[2], swColor[3])
        self.secondWindFrame[i] = pill
        pill:SetPoint(i == 1 and 'LEFT' or 'LEFT', i == 1 and self.secondWindFrame or self.secondWindFrame[i - 1],
            i == 1 and 'LEFT' or 'RIGHT', i == 1 and 0 or spacing, 0)
    end
    ResizePillsToFit(self.secondWindFrame, self.secondWindFrame, 3, spacing)

    self.surgeFrame = CreateFrame('Frame', nil, self.container)
    self.surgeFrame:SetPoint('BOTTOMLEFT', self.secondWindFrame, 'TOPLEFT', 0, spacing)
    self.surgeFrame:SetPoint('BOTTOMRIGHT', self.secondWindFrame, 'TOPRIGHT', 0, spacing)
    self.surgeFrame:SetHeight(barHeight)

    local surgePill = CreatePill(self.surgeFrame, barHeight, texture)
    surgePill:SetStatusBarColor(db.Colors.WhirlingSurge[1], db.Colors.WhirlingSurge[2], db.Colors.WhirlingSurge[3])
    surgePill:SetPoint('LEFT')
    surgePill:SetPoint('RIGHT')
    self.surgeFrame[1] = surgePill

    self.vigorFrame = CreateFrame('Frame', nil, self.container)
    self.vigorFrame:SetPoint('BOTTOMLEFT', self.surgeFrame, 'TOPLEFT', 0, spacing)
    self.vigorFrame:SetPoint('BOTTOMRIGHT', self.surgeFrame, 'TOPRIGHT', 0, spacing)
    self.vigorFrame:SetHeight(barHeight)

    local st = db.SpeedText or {}
    self.speedOverlay = CreateFrame('Frame', nil, self.container)
    self.speedOverlay:SetAllPoints(self.container)
    self.speedOverlay:SetFrameLevel(self.container:GetFrameLevel() + 10)
    self.speedText = NRSKNUI:CreateText(self.speedOverlay, 'OVERLAY')
    self.speedText:SetWordWrap(false)
    self.speedText:SetPoint('BOTTOM', self.vigorFrame, 'TOP', st.XOffset or 0, (st.YOffset or 0) + 2)
    NRSKNUI:SetTextFont(self.speedText, NRSKNUI:GetEffectiveFont(st), st.FontSize, st.FontOutline, st.FontShadow)
    self.speedText:SetText("")
end

function DR:Refresh()
    if not self.container then return end
    local db = self.db
    local barHeight = db.BarHeight
    local spacing = db.Spacing
    local texture = NRSKNUI:GetStatusbarPath(NRSKNUI:GetEffectiveStatusBar(db))
    local totalHeight = (barHeight * 3) + (spacing * 2) + 20

    self.container:SetSize(db.Width, totalHeight)

    self.secondWindFrame:SetHeight(barHeight)
    self.surgeFrame:SetHeight(barHeight)
    self.vigorFrame:SetHeight(barHeight)

    self.surgeFrame:ClearAllPoints()
    self.surgeFrame:SetPoint('BOTTOMLEFT', self.secondWindFrame, 'TOPLEFT', 0, spacing)
    self.surgeFrame:SetPoint('BOTTOMRIGHT', self.secondWindFrame, 'TOPRIGHT', 0, spacing)

    self.vigorFrame:ClearAllPoints()
    self.vigorFrame:SetPoint('BOTTOMLEFT', self.surgeFrame, 'TOPLEFT', 0, spacing)
    self.vigorFrame:SetPoint('BOTTOMRIGHT', self.surgeFrame, 'TOPRIGHT', 0, spacing)

    local swColor = db.Colors.SecondWind
    for i = 1, 3 do
        if self.secondWindFrame[i] then
            self.secondWindFrame[i]:SetHeight(barHeight)
            self.secondWindFrame[i]:SetStatusBarTexture(texture)
            self.secondWindFrame[i]:SetStatusBarColor(swColor[1], swColor[2], swColor[3])
            if i > 1 then
                self.secondWindFrame[i]:ClearAllPoints()
                self.secondWindFrame[i]:SetPoint('LEFT', self.secondWindFrame[i - 1], 'RIGHT', spacing, 0)
            end
        end
    end
    ResizePillsToFit(self.secondWindFrame, self.secondWindFrame, 3, spacing)

    local surgeColor = db.Colors.WhirlingSurge
    if self.surgeFrame[1] then
        self.surgeFrame[1]:SetHeight(barHeight)
        self.surgeFrame[1]:SetStatusBarTexture(texture)
        self.surgeFrame[1]:SetStatusBarColor(surgeColor[1], surgeColor[2], surgeColor[3])
    end

    local vigorCount = self.isPreview and 6 or numVigor
    for i = 1, vigorCount do
        if self.vigorFrame[i] then
            self.vigorFrame[i]:SetHeight(barHeight)
            self.vigorFrame[i]:SetStatusBarTexture(texture)
            if i > 1 then
                self.vigorFrame[i]:ClearAllPoints()
                self.vigorFrame[i]:SetPoint('LEFT', self.vigorFrame[i - 1], 'RIGHT', spacing, 0)
            end
        end
    end
    if vigorCount > 0 then
        ResizePillsToFit(self.vigorFrame, self.vigorFrame, vigorCount, spacing)
    end
    UpdateVigorColor(self)

    local st = db.SpeedText or {}
    NRSKNUI:SetTextFont(self.speedText, NRSKNUI:GetEffectiveFont(st), st.FontSize, st.FontOutline, st.FontShadow)
    self.speedText:ClearAllPoints()
    self.speedText:SetPoint('BOTTOM', self.vigorFrame, 'TOP', st.XOffset or 0, (st.YOffset or 0) + 2)

    if st.Enabled then
        if self.isPreview then
            self.speedText:SetText('420%')
        end
    else
        self.speedText:SetText('')
    end
end

function DR:ApplyPosition()
    if not self.container then return end
    local pos = self.db.Position
    self.container:ClearAllPoints()
    self.container:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
    NRSKNUI:SnapFrameToPixels(self.container)
end

function DR:ApplySettings()
    self:Refresh()
    self:ApplyPosition()
    if self.parent and self.parent:IsShown() then
        UpdateVigor(self)
        UpdateVigorColor(self)
        UpdateWhirlingSurge(self)
        UpdateSecondWind(self)
    end
end

function DR:ShowPreview()
    if not self.container then self:CreateFrames() end
    self.isPreview = true

    if self.speedTicker then
        self.speedTicker:Cancel()
        self.speedTicker = nil
    end

    for _, frame in ipairs({ self.vigorFrame, self.surgeFrame, self.secondWindFrame }) do
        if frame then
            frame:UnregisterAllEvents()
            frame:SetScript('OnEvent', nil)
        end
    end

    if self.parent then
        UnregisterStateDriver(self.parent, 'visibility')
        self.parent:Show()
    end

    local spacing = self.db.Spacing
    local texture = NRSKNUI:GetStatusbarPath(self.db.StatusBarTexture)
    for i = 1, 6 do
        if not self.vigorFrame[i] then
            local pill = CreatePill(self.vigorFrame, self.vigorFrame:GetHeight(), texture)
            self.vigorFrame[i] = pill
            pill:SetPoint(i == 1 and 'LEFT' or 'LEFT', i == 1 and self.vigorFrame or self.vigorFrame[i - 1],
                i == 1 and 'LEFT' or 'RIGHT', i == 1 and 0 or spacing, 0)
        end
    end

    self:ApplySettings()

    for i = 1, 6 do
        self.vigorFrame[i]:SetMinMaxValues(0, 1)
        self.vigorFrame[i]:SetValue(i <= 4 and 1 or (i == 5 and 0.6 or 0))
    end

    for i = 1, 3 do
        self.secondWindFrame[i]:SetMinMaxValues(0, 1)
        self.secondWindFrame[i]:SetValue(i <= 2 and 1 or 0.3)
    end

    self.surgeFrame[1]:SetMinMaxValues(0, 1)
    self.surgeFrame[1]:SetValue(1)
end

function DR:HidePreview()
    self.isPreview = false
    if self.parent then
        RegisterStateDriver(self.parent, 'visibility', '[bonusbar:5] show; hide')
        if self.parent:IsShown() then self:OnShowHandler() end
    end
end

function DR:OnShowHandler()
    if self.isPreview then return end

    local st = self.db.SpeedText or {}
    if self.speedText and not self.speedText:GetFont() then
        NRSKNUI:SetTextFont(self.speedText, NRSKNUI:GetEffectiveFont(st), st.FontSize, st.FontOutline, st.FontShadow)
    end

    self.vigorFrame:RegisterEvent('SPELL_UPDATE_CHARGES')
    self.vigorFrame:SetScript('OnEvent', function() C_Timer.After(0, function() UpdateVigor(self) end) end)
    self.vigorFrame:RegisterUnitEvent('UNIT_AURA', 'player')
    self.vigorFrame:HookScript('OnEvent', function() C_Timer.After(0, function() UpdateVigorColor(self) end) end)

    self.surgeFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    self.surgeFrame:RegisterEvent('SPELL_UPDATE_CHARGES')
    self.surgeFrame:SetScript('OnEvent', function() C_Timer.After(0, function() UpdateWhirlingSurge(self) end) end)

    self.secondWindFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    self.secondWindFrame:RegisterEvent('SPELL_UPDATE_CHARGES')
    self.secondWindFrame:SetScript('OnEvent', function() C_Timer.After(0, function() UpdateSecondWind(self) end) end)

    self.speedTicker = C_Timer.NewTicker(0.2, function() UpdateSpeed(self) end)

    UpdateVigor(self)
    UpdateVigorColor(self)
    UpdateWhirlingSurge(self)
    UpdateSecondWind(self)
end

function DR:OnHideHandler()
    if self.isPreview then return end

    self.vigorFrame:UnregisterEvent('SPELL_UPDATE_CHARGES')
    self.vigorFrame:UnregisterEvent('UNIT_AURA')
    self.surgeFrame:UnregisterEvent('SPELL_UPDATE_COOLDOWN')
    self.surgeFrame:UnregisterEvent('SPELL_UPDATE_CHARGES')
    self.secondWindFrame:UnregisterEvent('SPELL_UPDATE_COOLDOWN')
    self.secondWindFrame:UnregisterEvent('SPELL_UPDATE_CHARGES')

    if self.speedTicker then
        self.speedTicker:Cancel()
        self.speedTicker = nil
    end
end

function DR:OnEnable()
    if not self.db.Enabled then return end

    self:CreateFrames()
    self:ApplySettings()

    self.parent:HookScript('OnShow', function() self:OnShowHandler() end)
    self.parent:HookScript('OnHide', function() self:OnHideHandler() end)

    RegisterStateDriver(self.parent, 'visibility', '[bonusbar:5] show; hide')

    NRSKNUI.EditMode:RegisterElement({
        key = "DragonRiding",
        displayName = "Skyriding UI",
        frame = self.container,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            if self.container then
                self.container:ClearAllPoints()
                self.container:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
            end
        end,
        getParentFrame = function() return UIParent end,
        guiPath = "DragonRiding",
    })
end

function DR:OnDisable()
    if self.parent then
        self.parent:Hide()
        UnregisterStateDriver(self.parent, 'visibility')
    end
    if self.speedTicker then
        self.speedTicker:Cancel()
        self.speedTicker = nil
    end
end
