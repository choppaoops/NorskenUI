---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("StanceIcons: Addon object not initialized. Check file load order!")
    return
end

---@class StanceIcons: AceModule, AceEvent-3.0
local STANCEICONS = NorskenUI:NewModule("StanceIcons", "AceEvent-3.0")

local ipairs = ipairs
local tonumber = tonumber
local UnitClass = UnitClass
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local CreateFrame = CreateFrame
local GetShapeshiftForm, GetShapeshiftFormInfo = GetShapeshiftForm, GetShapeshiftFormInfo
local C_Spell, C_SpellBook = C_Spell, C_SpellBook
local C_UnitAuras = C_UnitAuras
local C_ChallengeMode = C_ChallengeMode
local UIParent = UIParent
local C_Timer = C_Timer

local MISSING_TEXT = "MISSING"
local STANCE_TIMER_DURATION = 3

local StanceData = NRSKNUI.StanceData
local SPEC_ID_TO_NAME = StanceData.SPEC_ID_TO_NAME
local WARRIOR_STANCE_SPELLS = StanceData.WARRIOR.stanceSpellIds

local playerClass = nil
local stanceFrame = nil
local stanceTimerHandle = nil
local stanceTimerActive = false
local isPreviewActive = false

local function IsSpellKnown(spellId)
    return spellId and C_SpellBook.IsSpellKnown(spellId)
end

local function GetSpellTexture(spellId)
    if spellId and spellId > 0 then
        return C_Spell.GetSpellTexture(spellId)
    end
    return nil
end

---@param spellId number
---@param extraSpellIds? number[]
---@return boolean hasBuff
---@return number? expirationTime
local function PlayerHasBuff(spellId, extraSpellIds)
    if not spellId then return false, nil end

    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if auraData then
        return true, auraData.expirationTime
    end

    if extraSpellIds then
        for _, extraId in ipairs(extraSpellIds) do
            auraData = C_UnitAuras.GetPlayerAuraBySpellID(extraId)
            if auraData then
                return true, auraData.expirationTime
            end
        end
    end

    return false, nil
end

local function CreateStanceFrame()
    if stanceFrame then return end
    local db = STANCEICONS.db

    stanceFrame = NRSKNUI:CreateIconFrame(UIParent, db.IconSize, {
        name = "NRSKNUI_MissingStanceIcon",
    })

    stanceFrame.text:ClearAllPoints()
    stanceFrame.text:SetPoint("BOTTOM", stanceFrame, "TOP", 1, 4)

    local cooldown = CreateFrame("Cooldown", nil, stanceFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(stanceFrame)
    cooldown:SetFrameLevel(stanceFrame:GetFrameLevel() + 1)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.6)
    cooldown:SetReverse(true)
    cooldown:SetHideCountdownNumbers(false)

    ---@type FontString
    local cdText = cooldown:GetRegions()
    if cdText and cdText.SetFont then
        cdText:SetFont(NRSKNUI.FONT or STANDARD_TEXT_FONT, db.IconSize * 0.5, "OUTLINE")
        cdText:SetShadowColor(0, 0, 0, 0)
        cdText:SetShadowOffset(0, 0)
        cdText:ClearAllPoints()
        cdText:SetPoint("CENTER", stanceFrame, "CENTER", 1, 0)
    end

    stanceFrame.cooldown = cooldown

    NRSKNUI:ApplyFramePosition(stanceFrame, db.Position, db)
    NRSKNUI:SetTextFont(stanceFrame.text, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline, db.FontShadow)
    stanceFrame.text:SetTextColor(1, 1, 1, 1)
    stanceFrame:Hide()
end

local function ShowStanceIcon(spellId, reverseIcon, currentSpellId)
    if not stanceFrame then CreateStanceFrame() end
    local db = STANCEICONS.db
    if stanceFrame then
        local displaySpellId = (reverseIcon and currentSpellId) and currentSpellId or spellId
        local texture = GetSpellTexture(displaySpellId)
        stanceFrame.icon:SetTexture(texture)

        NRSKNUI:SetTextFont(stanceFrame.text, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline, db.FontShadow)
        local showText = db.ShowMissingText ~= false and not reverseIcon
        stanceFrame.text:SetText(showText and MISSING_TEXT or "")

        stanceFrame:SetSize(db.IconSize, db.IconSize)
        stanceFrame.icon:SetSize(db.IconSize, db.IconSize)

        NRSKNUI:ApplyFramePosition(stanceFrame, db.Position, db)

        stanceFrame:Show()
    end
end

local function ShowStanceTimer(spellId)
    if not stanceFrame then CreateStanceFrame() end
    if not stanceFrame then return end
    if not stanceFrame.cooldown then return end

    stanceTimerActive = true

    local texture = GetSpellTexture(spellId)
    if texture then
        stanceFrame.icon:SetTexture(texture)
    end
    stanceFrame.text:SetText("")

    stanceFrame.cooldown:SetAllPoints(stanceFrame)
    stanceFrame.cooldown:SetCooldown(GetTime(), STANCE_TIMER_DURATION)
    stanceFrame:Show()

    if stanceTimerHandle then
        stanceTimerHandle:Cancel()
    end

    stanceTimerHandle = C_Timer.NewTimer(STANCE_TIMER_DURATION, function()
        stanceTimerHandle = nil
        stanceTimerActive = false
        if stanceFrame and not isPreviewActive then
            STANCEICONS:CheckStances()
        end
    end)
end

function STANCEICONS:CheckStances()
    if playerClass == "WARRIOR" and stanceTimerActive then
        return
    end

    if stanceFrame then
        stanceFrame:Hide()
    end

    if not self.db then return end
    if not self.db.Enabled then return end

    local stancesDb = NRSKNUI.db.profile.MissingBuffs.Stances
    if not stancesDb then return end
    if stancesDb.Enabled == false then return end

    local currentSpecId = NRSKNUI.MySpec.id
    if not currentSpecId then return end
    local specName = SPEC_ID_TO_NAME[currentSpecId]

    local classSettings = stancesDb[playerClass]
    if not classSettings then return end

    if playerClass == "PRIEST" then
        if not classSettings.ShadowEnabled then return end
        if currentSpecId ~= 258 then return end

        if InCombatLockdown() or C_ChallengeMode.IsChallengeModeActive() then
            return
        end

        local shadowformSpellId = StanceData.PRIEST.shadowformSpellId
        local hasShadowform = PlayerHasBuff(shadowformSpellId, { StanceData.PRIEST.voidformSpellId })
        if not hasShadowform and IsSpellKnown(shadowformSpellId) then
            ShowStanceIcon(shadowformSpellId)
        end
        return
    end

    if playerClass == "DRUID" then
        local specData = StanceData.DRUID.specs[currentSpecId]
        if not specData then return end
        if not classSettings[specData.toggleKey] then return end

        if classSettings[specData.combatOnlyKey] and not InCombatLockdown() then
            return
        end

        local currentForm = GetShapeshiftForm()
        local currentSpellId = nil
        if currentForm > 0 then
            local _, _, _, formSpellId = GetShapeshiftFormInfo(currentForm)
            currentSpellId = formSpellId
        end

        if currentSpellId ~= specData.spellId then
            if IsSpellKnown(specData.spellId) then
                ShowStanceIcon(specData.spellId)
            end
        end
        return
    end

    if playerClass == "EVOKER" then
        if not classSettings.AugmentationEnabled then return end
        if currentSpecId ~= 1473 then return end

        local requiredSpellId = tonumber(classSettings.Augmentation) or StanceData.EVOKER.defaultAttunement

        local hasAttunement = PlayerHasBuff(requiredSpellId)
        if not hasAttunement and IsSpellKnown(requiredSpellId) then
            ShowStanceIcon(requiredSpellId)
        end
        return
    end

    if not specName then return end

    local specEnabledKey = specName .. "Enabled"
    if not classSettings[specEnabledKey] then return end

    local defaultStance = StanceData:GetDefaultStance(playerClass, specName)
    local requiredStanceId = tonumber(classSettings[specName]) or defaultStance
    if not requiredStanceId then return end

    local reverseIconKey = specName .. "ReverseIcon"
    local reverseIcon = classSettings[reverseIconKey] and true or false

    local currentForm = GetShapeshiftForm()
    local currentSpellId = nil
    if currentForm > 0 then
        local _, _, _, formSpellId = GetShapeshiftFormInfo(currentForm)
        currentSpellId = formSpellId
    end

    if playerClass == "PALADIN" then
        for _, auraId in ipairs(StanceData.PALADIN.auraSpellIds) do
            if PlayerHasBuff(auraId) then
                currentSpellId = auraId
                break
            end
        end
    end

    if currentSpellId ~= requiredStanceId then
        if IsSpellKnown(requiredStanceId) then
            ShowStanceIcon(requiredStanceId, reverseIcon, currentSpellId)
        end
    end
end

function STANCEICONS:UpdateDB()
    self.db = NRSKNUI.db.profile.MissingBuffs.StanceDisplay
end

function STANCEICONS:OnInitialize()
    self:UpdateDB()
    local _, class = UnitClass("player")
    playerClass = class
    self:SetEnabledState(false)
end

function STANCEICONS:OnEnable()
    if not self.db or not self.db.Enabled then return end

    CreateStanceFrame()

    C_Timer.After(0.5, function()
        self:ApplySettings()
    end)

    self:RegisterEvent("UNIT_AURA", function(_, unit)
        if unit ~= "player" then return end
        if isPreviewActive then return end
        self:CheckStances()
    end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, function() self:CheckStances() end) end)
    self:RegisterEvent("PLAYER_ALIVE", function() self:CheckStances() end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:CheckStances() end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:CheckStances() end)
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", function() C_Timer.After(0.5, function() self:CheckStances() end) end)
    self:RegisterEvent("SPELLS_CHANGED", function() C_Timer.After(0.5, function() self:CheckStances() end) end)
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function() C_Timer.After(1, function() self:CheckStances() end) end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() self:CheckStances() end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", function() self:CheckStances() end)

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit ~= "player" then return end
        if playerClass ~= "WARRIOR" then return end
        if not WARRIOR_STANCE_SPELLS[spellID] then return end
        if isPreviewActive then return end

        if not self.db or not self.db.Enabled then return end

        local stancesDb = NRSKNUI.db.profile.MissingBuffs.Stances
        local classSettings = stancesDb and stancesDb.WARRIOR
        if not classSettings then return end

        local specId = NRSKNUI.MySpec.id
        if not specId then return end
        local specName = SPEC_ID_TO_NAME[specId]
        if not specName then return end

        local specEnabledKey = specName .. "Enabled"
        if not classSettings[specEnabledKey] then return end

        local defaultStance = StanceData:GetDefaultStance("WARRIOR", specName)
        local requiredStanceId = tonumber(classSettings[specName]) or defaultStance

        if spellID == requiredStanceId then
            if stanceTimerHandle then
                stanceTimerHandle:Cancel()
                stanceTimerHandle = nil
            end
            stanceTimerActive = false
            if stanceFrame then
                stanceFrame:Hide()
            end
        else
            ShowStanceTimer(spellID)
        end
    end)

    C_Timer.After(2, function() self:CheckStances() end)

    self:RegisterEditModeElements()
end

function STANCEICONS:RegisterEditModeElements()
    if not NRSKNUI.EditMode then return end

    if not stanceFrame then CreateStanceFrame() end

    local db = self.db

    NRSKNUI.EditMode:RegisterElement({
        key = "MissingStanceIcon",
        displayName = "Missing Stance Icon",
        frame = stanceFrame,
        getPosition = function()
            return db.Position or {}
        end,
        setPosition = function(pos)
            db.Position = db.Position or {}
            db.Position.AnchorFrom = pos.AnchorFrom
            db.Position.AnchorTo = pos.AnchorTo
            db.Position.XOffset = pos.XOffset
            db.Position.YOffset = pos.YOffset
            if stanceFrame then
                local anchorFrame = NRSKNUI:ResolveAnchorFrame(db.anchorFrameType, db.ParentFrame)
                stanceFrame:ClearAllPoints()
                stanceFrame:SetPoint(pos.AnchorFrom, anchorFrame, pos.AnchorTo, pos.XOffset, pos.YOffset)
            end
        end,
        guiPath = "stanceIcons",
    })
end

function STANCEICONS:OnDisable()
    self:UnregisterAllEvents()
    if stanceFrame then
        stanceFrame:Hide()
    end

    if stanceTimerHandle then
        stanceTimerHandle:Cancel()
        stanceTimerHandle = nil
    end
    stanceTimerActive = false

    if NRSKNUI.EditMode then
        NRSKNUI.EditMode:UnregisterElement("MissingStanceIcon")
    end
end

function STANCEICONS:Refresh()
    if self.db and self.db.Enabled then
        self:OnEnable()
        if not isPreviewActive then
            self:CheckStances()
        end
    else
        self:OnDisable()
    end
end

function STANCEICONS:ApplySettings()
    if not self.db then return end
    if not self.db.Enabled then return end

    if isPreviewActive then
        self:RefreshPreview()
        return
    end

    local db = self.db

    if stanceFrame then
        stanceFrame:SetSize(db.IconSize, db.IconSize)
        NRSKNUI:ApplyFramePosition(stanceFrame, db.Position, db)
        NRSKNUI:SetTextFont(stanceFrame.text, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline, db.FontShadow)
    end
end

function STANCEICONS:IsPaused()
    return isPreviewActive
end

function STANCEICONS:RefreshPreview()
    if not isPreviewActive then return end
    self:ShowPreview()
end

function STANCEICONS:ShowPreview()
    if not stanceFrame then CreateStanceFrame() end
    isPreviewActive = true

    local db = self.db
    local previewStanceSpell = 386164
    local texture = GetSpellTexture(previewStanceSpell)

    if texture and stanceFrame then
        stanceFrame.icon:SetTexture(texture)
        stanceFrame.text:SetText(db.ShowMissingText ~= false and "MISSING" or "")
        stanceFrame:SetSize(db.IconSize, db.IconSize)
        NRSKNUI:SetTextFont(stanceFrame.text, NRSKNUI:GetEffectiveFont(db), db.FontSize, db.FontOutline, db.FontShadow)
        NRSKNUI:ApplyFramePosition(stanceFrame, db.Position, db)
        stanceFrame:Show()
    end
end

function STANCEICONS:HidePreview()
    isPreviewActive = false
    if stanceFrame then
        stanceFrame:Hide()
    end
    if self.db and self.db.Enabled then
        C_Timer.After(0.1, function() self:CheckStances() end)
    end
end
