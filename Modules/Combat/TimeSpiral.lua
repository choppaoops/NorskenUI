---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("TimeSpiral: Addon object not initialized. Check file load order!")
    return
end

---@class TimeSpiral: AceModule, AceEvent-3.0
local TSP = NorskenUI:NewModule("TimeSpiral", "AceEvent-3.0")

local LCG = LibStub("LibCustomGlow-1.0", true)

local CreateFrame = CreateFrame
local IsPlayerSpell = IsPlayerSpell
local IsSpellKnown = IsSpellKnown
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local next = next
local pairs = pairs
local math_floor = math.floor

TSP.activeProcs = {}

local TIME_SPIRAL_ICON = 4622479
local TIME_SPIRAL_DURATION = 10.5
local MOVEMENT_SPELL_IDS

function TSP:UpdateDB()
    self.db = NRSKNUI.db.profile.TimeSpiral
end

function TSP:DetectPlayerSpell()
    local specID = GetSpecializationInfo(GetSpecialization() or 0)
    if not specID then return nil end

    local spellData = NRSKNUI.MOVEMENT_SPELLS[specID]
    if spellData and C_SpellBook.IsSpellKnown(spellData.spellID) then
        self.playerSpellId = spellData.spellID
        self.playerIconId = spellData.iconID
        return spellData.spellID
    end
    return nil
end

function TSP:GetDisplayIcon()
    if self.playerIconId then return self.playerIconId end
    self:DetectPlayerSpell()
    return self.playerIconId or TIME_SPIRAL_ICON
end

function TSP:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function TSP:CreateFrame()
    if self.frame then return end

    local frame = NRSKNUI:CreateIconFrame(UIParent, self.db.IconSize, {
        name = "NRSKNUI_TimeSpiralFrame",
        zoom = 0.3,
        borderColor = { 0, 0, 0, 1 },
    })
    frame:EnableMouse(false)
    frame:SetMouseClickEnabled(false)
    frame:Hide()

    frame.icon:SetTexture(self:GetDisplayIcon())

    frame.text:ClearAllPoints()
    frame.text:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    frame.text:SetJustifyH("CENTER")

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(frame)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawSwipe(true)
    cooldown:SetReverse(true)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawBling(false)

    local timerText = cooldown:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(NRSKNUI.FONT, 16, "OUTLINE")
    timerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    timerText:SetText("")

    self.frame = frame
    self.cooldown = cooldown
    self.timerText = timerText

    self:ApplySettings()
end

function TSP:FilterSpell(spellId)
    local filterTalents = {
        [427640] = 195072, -- Inertia filters Fel Rush
        [427794] = 195072, -- Dash of Chaos filters Fel Rush
        [385899] = 385899, -- Soulburn
    }
    for talentId, filteredSpell in pairs(filterTalents) do
        if spellId == filteredSpell and (C_SpellBook.IsSpellKnown(talentId) or C_SpellBook.IsSpellInSpellBook(talentId)) then
            return true
        end
    end
    return false
end

function TSP:ApplySettings()
    if not self.frame then return end

    local iconSize = math_floor(self.db.IconSize + 0.5)
    self.frame:SetSize(iconSize, iconSize)
    self.frame.icon:SetTexture(self:GetDisplayIcon())

    self.frame.text:SetText(self.db.TextLabel)
    local fontSize = math_floor(self.db.FontSize + 0.5)
    NRSKNUI:ApplyFontToText(self.frame.text, self.db.FontFace, fontSize, self.db.FontOutline,
        self.db.FontShadow or {})

    local textColor = self.db.TextColor
    self.frame.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
    self.frame.text:SetShown(self.db.ShowText)
    if self.frame.text.softOutline then
        self.frame.text.softOutline:SetShown(self.db.ShowText and self.db.FontOutline == "SOFTOUTLINE")
    end

    local timerFontSize = math_floor(self.db.TimerFontSize + 0.5)
    NRSKNUI:ApplyFontToText(self.timerText, self.db.FontFace, timerFontSize, self.db.FontOutline,
        self.db.FontShadow or {})

    local timerColor = self.db.TimerTextColor
    self.timerText:SetTextColor(timerColor[1], timerColor[2], timerColor[3], timerColor[4])
    self.timerText:SetShown(self.db.ShowTimer)
    if self.timerText.softOutline then
        self.timerText.softOutline:SetShown(self.db.ShowTimer and self.db.FontOutline == "SOFTOUTLINE")
    end

    self:ApplyPosition()

    if self.glowActive then
        self:StopGlow()
        self:StartGlow()
    elseif self.db.GlowEnabled and self.frame:IsShown() then
        self:StartGlow()
    end
end

function TSP:ApplyPosition()
    if not self.db.Enabled or not self.frame then return end
    NRSKNUI:ApplyFramePosition(self.frame, self.db.Position, self.db)
    NRSKNUI:SnapFrame(self.frame)
end

function TSP:StartGlow()
    if not self.frame or not self.db.GlowEnabled or not LCG then return end

    local db = self.db
    local glowType = db.GlowType

    if glowType == "pixel" then
        LCG.PixelGlow_Start(self.frame, db.GlowColor, db.GlowLines, db.GlowFrequency, db.GlowLength, db.GlowThickness, 0,
            0, db.GlowBorder, nil)
    elseif glowType == "autocast" then
        LCG.AutoCastGlow_Start(self.frame, db.GlowColor, db.GlowLines, db.GlowFrequency, db.GlowScale, 1, 1, nil)
    elseif glowType == "button" then
        LCG.ButtonGlow_Start(self.frame, db.GlowColor, db.GlowFrequency)
    elseif glowType == "proc" then
        LCG.ProcGlow_Start(self.frame, { color = db.GlowColor, startAnim = db.GlowStartAnim, duration = db.GlowDuration })
    end

    self.glowActive = true
end

function TSP:StopGlow()
    if not self.frame or not LCG then return end

    LCG.PixelGlow_Stop(self.frame)
    LCG.AutoCastGlow_Stop(self.frame)
    LCG.ButtonGlow_Stop(self.frame)
    LCG.ProcGlow_Stop(self.frame)

    self.glowActive = false
end

function TSP:OnUpdate()
    if not self.durationObject or not self.db.ShowTimer then return end

    local remaining = self.durationObject:GetRemainingDuration()
    if not remaining or remaining <= 0 then
        self.timerText:SetText("")
        return
    end

    local decimals = self.durationObject:EvaluateRemainingDuration(NRSKNUI.curves.DurationDecimals)
    self.timerText:SetFormattedText('%.' .. decimals .. 'f', remaining)
end

function TSP:ShowProc()
    if not self.frame then self:CreateFrame() end
    if not self.frame then return end

    local now = GetTime()
    self.cooldown:SetCooldown(now, TIME_SPIRAL_DURATION)

    self.durationObject = C_DurationUtil.CreateDuration()
    self.durationObject:SetTimeFromStart(now, TIME_SPIRAL_DURATION)

    self:StartGlow()
    self.frame:Show()

    if self.hideTimer then self.hideTimer:Cancel() end
    self.hideTimer = C_Timer.NewTimer(TIME_SPIRAL_DURATION, function() self:HideProc() end)
end

function TSP:HideProc()
    if not self.frame then return end

    self:StopGlow()
    self.frame:Hide()
    self.durationObject = nil
    self.timerText:SetText("")

    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
end

function TSP:ShowPreview()
    if not self.frame then self:CreateFrame() end
    self.isPreview = true
    self:ApplySettings()

    local now = GetTime()
    self.cooldown:SetCooldown(now, TIME_SPIRAL_DURATION)

    self.durationObject = C_DurationUtil.CreateDuration()
    self.durationObject:SetTimeFromStart(now, TIME_SPIRAL_DURATION)

    self:StartGlow()
    self.frame:Show()
end

function TSP:HidePreview()
    self.isPreview = false
    self:StopGlow()
    self.durationObject = nil
    if self.timerText then self.timerText:SetText("") end
    if self.frame then self.frame:Hide() end
end

function TSP:OnEnable()
    if not self.db.Enabled then return end

    if not MOVEMENT_SPELL_IDS then
        MOVEMENT_SPELL_IDS = {}
        for _, data in pairs(NRSKNUI.MOVEMENT_SPELLS) do
            MOVEMENT_SPELL_IDS[data.spellID] = true
        end
    end

    self:DetectPlayerSpell()
    self:CreateFrame()
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)

    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function(_, spellId)
        if not spellId or not MOVEMENT_SPELL_IDS[spellId] then return end
        if self:FilterSpell(spellId) then return end

        self.playerSpellId = spellId
        self.frame.icon:SetTexture(self:GetDisplayIcon())
        self.activeProcs[spellId] = true
        self:ShowProc()
    end)

    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", function(_, spellId)
        if not spellId or not MOVEMENT_SPELL_IDS[spellId] then return end
        self.activeProcs[spellId] = nil
        if not next(self.activeProcs) then self:HideProc() end
    end)

    NRSKNUI.EditMode:RegisterElement({
        key = "TimeSpiral",
        displayName = "Time Spiral",
        frame = self.frame,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            self:ApplyPosition()
        end,
        getParentFrame = function()
            return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
        end,
        guiPath = "TimeSpiral",
    })
end

function TSP:OnDisable()
    if self.frame then
        self:StopGlow()
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end
    self.isPreview = false
    self.activeProcs = {}
    self.glowActive = false
    self.durationObject = nil
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
    self:UnregisterAllEvents()
end
