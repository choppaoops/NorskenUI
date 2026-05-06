---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("StanceTexts: Addon object not initialized. Check file load order!")
    return
end

---@class StanceTexts: AceModule, AceEvent-3.0
local STANCETEXTS = NorskenUI:NewModule("StanceTexts", "AceEvent-3.0")

local ipairs = ipairs
local tostring = tostring
local UnitClass = UnitClass
local GetShapeshiftForm, GetShapeshiftFormInfo = GetShapeshiftForm, GetShapeshiftFormInfo
local C_UnitAuras = C_UnitAuras
local UIParent = UIParent
local C_Timer = C_Timer

local playerClass = nil
local stanceTextFrame = nil
local isPreviewActive = false

---@param spellId number
---@param extraSpellIds? number[]
---@return boolean hasBuff
local function PlayerHasBuff(spellId, extraSpellIds)
    if not spellId then return false end

    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if auraData then
        return true
    end

    if extraSpellIds then
        for _, extraId in ipairs(extraSpellIds) do
            auraData = C_UnitAuras.GetPlayerAuraBySpellID(extraId)
            if auraData then
                return true
            end
        end
    end

    return false
end

local function CreateStanceTextFrame()
    if stanceTextFrame then return end
    local db = STANCETEXTS.db

    stanceTextFrame = NRSKNUI:CreateTextFrame(UIParent, 200, 30, {
        name = "NRSKNUI_StanceTextDisplay",
    })

    NRSKNUI:ApplyFramePosition(stanceTextFrame, db.Position, db)
    NRSKNUI:ApplyFontToText(stanceTextFrame.text, db.FontFace, db.FontSize, db.FontOutline, db.FontShadow)

    local textPoint = NRSKNUI:GetTextJustifyFromAnchor(db.Position.AnchorFrom)
    local textJustify = NRSKNUI:GetTextJustifyFromAnchor(db.Position.AnchorFrom)
    stanceTextFrame.text:ClearAllPoints()
    stanceTextFrame.text:SetPoint(textPoint, stanceTextFrame, textPoint, 0, 0)
    stanceTextFrame.text:SetJustifyH(textJustify)
    stanceTextFrame.text:SetTextColor(1, 1, 1, 1)

    stanceTextFrame:Hide()
end

function STANCETEXTS:UpdateStanceTextDisplay()
    if not self.db then return end

    if not self.db.Enabled then
        if stanceTextFrame then stanceTextFrame:Hide() end
        return
    end

    if playerClass ~= "WARRIOR" and playerClass ~= "PALADIN" then
        if stanceTextFrame then stanceTextFrame:Hide() end
        return
    end

    if not stanceTextFrame then CreateStanceTextFrame() end

    local currentForm = GetShapeshiftForm()
    local currentSpellId = nil

    if currentForm > 0 then
        local _, _, _, formSpellId = GetShapeshiftFormInfo(currentForm)
        currentSpellId = formSpellId
    end

    if playerClass == "PALADIN" then
        local paladinAuras = { 465, 317920, 32223 }
        for _, auraId in ipairs(paladinAuras) do
            if PlayerHasBuff(auraId) then
                currentSpellId = auraId
                break
            end
        end
    end

    if stanceTextFrame then
        if not currentSpellId then
            stanceTextFrame:Hide()
            return
        end

        local classData = self.db[playerClass]
        if not classData then
            stanceTextFrame:Hide()
            return
        end

        local stanceKey = tostring(currentSpellId)
        local stanceSettings = classData[stanceKey]

        if not stanceSettings or not stanceSettings.Enabled then
            stanceTextFrame:Hide()
            return
        end

        local text = stanceSettings.Text or "Stance"
        local color = stanceSettings.Color or { 1, 1, 1, 1 }

        stanceTextFrame.text:SetText(text)
        stanceTextFrame.text:SetTextColor(color[1], color[2], color[3], color[4] or 1)

        NRSKNUI:ApplyFontToText(stanceTextFrame.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, self.db.FontShadow)
        NRSKNUI:ApplyFramePosition(stanceTextFrame, self.db.Position, self.db)

        local textPoint = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
        local textJustify = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
        stanceTextFrame.text:ClearAllPoints()
        stanceTextFrame.text:SetPoint(textPoint, stanceTextFrame, textPoint, 0, 0)
        stanceTextFrame.text:SetJustifyH(textJustify)
        stanceTextFrame:Show()
    end
end

function STANCETEXTS:UpdateDB()
    self.db = NRSKNUI.db.profile.MissingBuffs.StanceText
end

function STANCETEXTS:OnInitialize()
    self:UpdateDB()
    local _, class = UnitClass("player")
    playerClass = class
    self:SetEnabledState(false)
end

function STANCETEXTS:OnEnable()
    if not self.db or not self.db.Enabled then return end

    CreateStanceTextFrame()

    C_Timer.After(0.5, function()
        self:ApplySettings()
    end)

    self:RegisterEvent("UNIT_AURA", function(_, unit)
        if unit ~= "player" then return end
        if isPreviewActive then return end
        self:UpdateStanceTextDisplay()
    end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, function() self:UpdateStanceTextDisplay() end) end)
    self:RegisterEvent("PLAYER_ALIVE", function() self:UpdateStanceTextDisplay() end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() self:UpdateStanceTextDisplay() end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", function() self:UpdateStanceTextDisplay() end)

    C_Timer.After(2, function() self:UpdateStanceTextDisplay() end)

    self:RegisterEditModeElements()
end

function STANCETEXTS:RegisterEditModeElements()
    if not NRSKNUI.EditMode then return end

    if not stanceTextFrame then CreateStanceTextFrame() end

    local db = self.db

    NRSKNUI.EditMode:RegisterElement({
        key = "StanceText",
        displayName = "Stance Text",
        frame = stanceTextFrame,
        getPosition = function()
            return db.Position or {}
        end,
        setPosition = function(pos)
            db.Position = db.Position or {}
            db.Position.AnchorFrom = pos.AnchorFrom
            db.Position.AnchorTo = pos.AnchorTo
            db.Position.XOffset = pos.XOffset
            db.Position.YOffset = pos.YOffset
            if stanceTextFrame then
                local anchorFrame = NRSKNUI:ResolveAnchorFrame(db.anchorFrameType, db.ParentFrame)
                stanceTextFrame:ClearAllPoints()
                stanceTextFrame:SetPoint(pos.AnchorFrom, anchorFrame, pos.AnchorTo, pos.XOffset, pos.YOffset)
            end
        end,
        guiPath = "stanceTexts",
    })
end

function STANCETEXTS:OnDisable()
    self:UnregisterAllEvents()
    if stanceTextFrame then
        stanceTextFrame:Hide()
    end

    if NRSKNUI.EditMode then
        NRSKNUI.EditMode:UnregisterElement("StanceText")
    end
end

function STANCETEXTS:Refresh()
    if self.db and self.db.Enabled then
        self:OnEnable()
        if not isPreviewActive then
            self:UpdateStanceTextDisplay()
        end
    else
        self:OnDisable()
    end
end

function STANCETEXTS:ApplySettings()
    if not self.db then return end
    if not self.db.Enabled then return end

    if isPreviewActive then
        self:RefreshPreview()
        return
    end

    if stanceTextFrame then
        NRSKNUI:ApplyFontToText(stanceTextFrame.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, self.db.FontShadow)
        NRSKNUI:ApplyFramePosition(stanceTextFrame, self.db.Position, self.db)

        local textPoint = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
        local textJustify = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
        stanceTextFrame.text:ClearAllPoints()
        stanceTextFrame.text:SetPoint(textPoint, stanceTextFrame, textPoint, 0, 0)
        stanceTextFrame.text:SetJustifyH(textJustify)

        if not self.db.Enabled then
            stanceTextFrame:Hide()
        end
    end

    self:UpdateStanceTextDisplay()
end

function STANCETEXTS:IsPaused()
    return isPreviewActive
end

function STANCETEXTS:RefreshPreview()
    if not isPreviewActive then return end
    self:ShowPreview()
end

function STANCETEXTS:ShowPreview()
    if not stanceTextFrame then CreateStanceTextFrame() end
    if not stanceTextFrame then return end
    isPreviewActive = true

    if not self.db.Enabled then
        stanceTextFrame:Hide()
        return
    end

    NRSKNUI:ApplyFontToText(stanceTextFrame.text, self.db.FontFace, self.db.FontSize, self.db.FontOutline, self.db.FontShadow)

    local previewText = "Battle Stance"
    local previewColor = { 1, 1, 1, 1 }

    local classData = self.db["WARRIOR"]
    if classData then
        local stanceSettings = classData["386164"]
        if stanceSettings then
            if stanceSettings.Text and stanceSettings.Text ~= "" then
                previewText = stanceSettings.Text
            end
            if stanceSettings.Color then
                previewColor = stanceSettings.Color
            end
        end
    end

    stanceTextFrame.text:SetText(previewText)
    stanceTextFrame.text:SetTextColor(previewColor[1], previewColor[2], previewColor[3], previewColor[4] or 1)

    NRSKNUI:ApplyFramePosition(stanceTextFrame, self.db.Position, self.db)

    local textPoint = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
    local textJustify = NRSKNUI:GetTextJustifyFromAnchor(self.db.Position.AnchorFrom)
    stanceTextFrame.text:ClearAllPoints()
    stanceTextFrame.text:SetPoint(textPoint, stanceTextFrame, textPoint, 0, 0)
    stanceTextFrame.text:SetJustifyH(textJustify)
    stanceTextFrame:Show()
end

function STANCETEXTS:HidePreview()
    isPreviewActive = false
    if stanceTextFrame then
        stanceTextFrame:Hide()
    end
    if self.db and self.db.Enabled then
        C_Timer.After(0.1, function() self:UpdateStanceTextDisplay() end)
    end
end
