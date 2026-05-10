---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("TotemTracker: Addon object not initialized. Check file load order!")
    return
end

---@class TotemTracker: AceModule, AceEvent-3.0
local TT = NorskenUI:NewModule("TotemTracker", "AceEvent-3.0")

local CreateFrame = CreateFrame
local ipairs = ipairs
local GetTotemInfo = GetTotemInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local GetTotemDuration = GetTotemDuration

local MAX_TOTEMS = GetNumTotemSlots()

local containerFrame = nil
local totemButtons = {}
local isPreviewActive = false
local updateTicker = nil

function TT:UpdateDB()
    self.db = NRSKNUI.db.profile.TotemTracker
end

function TT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function ApplyCooldownTextStyle(cooldown, db)
    if not cooldown then return end

    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            NRSKNUI:ApplyFont(region, db.FontFace, db.TimerFontSize, db.FontOutline)
            region:SetShadowOffset(0, 0)
            region:ClearAllPoints()
            region:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
        end
    end
end

function TT:CreateTotemButton(slot)
    local db = self.db

    local btn = CreateFrame("Button", "NRSKNUI_TotemButton" .. slot, containerFrame, "SecureActionButtonTemplate")
    btn:SetSize(db.IconSize, db.IconSize)
    btn:SetID(slot)

    btn:SetAttribute("type2", "destroytotem")
    btn:SetAttribute("totem-slot2", slot)
    btn:RegisterForClicks("AnyUp", "AnyDown")

    btn:SetScript("OnEnter", function(self)
        if GameTooltip:IsForbidden() or not self:IsVisible() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetTotem(self:GetID())
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
    NRSKNUI:ApplyZoom(btn.icon, 0.08)

    NRSKNUI:AddBorders(btn, { 0, 0, 0, 1 })

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    btn.highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    btn.highlight:SetColorTexture(1, 1, 1, 0.2)
    btn.highlight:SetBlendMode("ADD")

    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
    btn.cooldown:SetDrawEdge(false)
    btn.cooldown:SetDrawSwipe(db.Swipe)
    btn.cooldown:SetReverse(db.Reverse)
    btn.cooldown:SetDrawBling(false)
    btn.cooldown:SetHideCountdownNumbers(false)

    btn:SetAlpha(0)
    btn:Hide()

    return btn
end

function TT:CreateContainer()
    if containerFrame then return end

    containerFrame = CreateFrame("Frame", "NRSKNUI_TotemTracker", UIParent)
    containerFrame:SetSize(200, 50)
    containerFrame:SetClampedToScreen(true)

    for slot = 1, MAX_TOTEMS do totemButtons[slot] = self:CreateTotemButton(slot) end
end

function TT:UpdateContainerPosition()
    if not containerFrame then return end

    local db = self.db
    local position = db.Position
    local parent = NRSKNUI:ResolveAnchorFrame(db.anchorFrameType, db.ParentFrame)

    containerFrame:ClearAllPoints()

    local direction = db.GrowDirection
    if direction == "RIGHT" then
        containerFrame:SetPoint("LEFT", parent, position.AnchorTo, position.XOffset, position.YOffset)
    elseif direction == "LEFT" then
        containerFrame:SetPoint("RIGHT", parent, position.AnchorTo, position.XOffset, position.YOffset)
    elseif direction == "UP" then
        containerFrame:SetPoint("BOTTOM", parent, position.AnchorTo, position.XOffset, position.YOffset)
    elseif direction == "DOWN" then
        containerFrame:SetPoint("TOP", parent, position.AnchorTo, position.XOffset, position.YOffset)
    else
        containerFrame:SetPoint(position.AnchorFrom, parent, position.AnchorTo, position.XOffset, position.YOffset)
    end

    containerFrame:SetFrameStrata(db.Strata)
    containerFrame:SetParent(parent)
end

function TT:UpdateButtonSettings(btn)
    local db = self.db

    btn:SetSize(db.IconSize, db.IconSize)
    btn.cooldown:SetDrawSwipe(db.Swipe)
    btn.cooldown:SetReverse(db.Reverse)
    btn.cooldown:SetHideCountdownNumbers(not db.ShowTimer)
    ApplyCooldownTextStyle(btn.cooldown, db)
end

function TT:LayoutButtons()
    if not containerFrame then return end

    local db = self.db
    local direction = db.GrowDirection
    local spacing = db.IconSpacing
    local size = db.IconSize

    local totalWidth, totalHeight
    if direction == "RIGHT" or direction == "LEFT" then
        totalWidth = (size * MAX_TOTEMS) + (spacing * (MAX_TOTEMS - 1))
        totalHeight = size
    else
        totalWidth = size
        totalHeight = (size * MAX_TOTEMS) + (spacing * (MAX_TOTEMS - 1))
    end
    containerFrame:SetSize(totalWidth, totalHeight)

    for i, btn in ipairs(totemButtons) do
        btn:ClearAllPoints()

        if direction == "RIGHT" then
            local xOffset = (i - 1) * (size + spacing)
            btn:SetPoint("LEFT", containerFrame, "LEFT", xOffset, 0)
        elseif direction == "LEFT" then
            local xOffset = -((i - 1) * (size + spacing))
            btn:SetPoint("RIGHT", containerFrame, "RIGHT", xOffset, 0)
        elseif direction == "UP" then
            local yOffset = (i - 1) * (size + spacing)
            btn:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, yOffset)
        elseif direction == "DOWN" then
            local yOffset = -((i - 1) * (size + spacing))
            btn:SetPoint("TOP", containerFrame, "TOP", 0, yOffset)
        end
    end

    NRSKNUI:SnapFrameToPixels(containerFrame, db.ForcePixelPerfect)
end

function TT:UpdateTotems()
    if not self.db or not self.db.Enabled then return end

    local currentTime = GetTime()

    if isPreviewActive then
        for slot = 1, MAX_TOTEMS do
            local btn = totemButtons[slot]
            if btn then
                btn.icon:SetTexture("Interface\\Icons\\Spell_Nature_StoneSkinTotem")
                btn.cooldown:SetCooldown(currentTime - 30, 120)
                btn:SetAlpha(1)
            end
        end
        return
    end

    local inCombat = InCombatLockdown()

    for slot = 1, MAX_TOTEMS do
        local btn = totemButtons[slot]
        if btn then
            local _, _, _, _, icon = GetTotemInfo(slot)
            local duration = GetTotemDuration(slot)

            btn.icon:SetTexture(icon)

            -- If a totem exists, duration returns a DurationObject
            -- We can use this as a very scuffed way of only showing frames that have a totem when not in combat.
            if duration then
                btn.cooldown:SetCooldownFromDurationObject(duration)
                btn:SetAlpha(1)
                if not inCombat then btn:Show() end
            else
                btn.cooldown:Clear()
                btn:SetAlpha(0)
                if not inCombat then btn:Hide() end
            end
        end
    end
end

function TT:StartUpdateTicker()
    if updateTicker then return end
    updateTicker = C_Timer.NewTicker(0.1, function()
        if self.db and self.db.Enabled then self:UpdateTotems() end
    end)
end

function TT:StopUpdateTicker()
    if updateTicker then
        updateTicker:Cancel()
        updateTicker = nil
    end
end

function TT:ApplySettings()
    self:UpdateDB()
    self:UpdateContainerPosition()
    self:LayoutButtons()

    for slot = 1, MAX_TOTEMS do
        if totemButtons[slot] then self:UpdateButtonSettings(totemButtons[slot]) end
    end

    self:UpdateTotems()
end

function TT:ShowPreview()
    if not containerFrame then self:CreateContainer() end
    if not containerFrame then return end
    isPreviewActive = true

    for slot = 1, MAX_TOTEMS do
        local btn = totemButtons[slot]
        if btn then
            btn:Show()
            btn:SetAlpha(1)
        end
    end

    containerFrame:Show()
    self:ApplySettings()
end

function TT:HidePreview()
    isPreviewActive = false

    if not self.db.Enabled then
        if containerFrame then containerFrame:Hide() end
    else
        self:UpdateTotems()
    end
end

function TT:TogglePreview()
    if isPreviewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return isPreviewActive
end

function TT:IsPreviewActive()
    return isPreviewActive
end

function TT:OnCombatStart()
    for slot = 1, MAX_TOTEMS do
        local btn = totemButtons[slot]
        if btn then btn:Show() end
    end
end

function TT:OnCombatEnd()
    self:UpdateTotems()
end

function TT:OnEnable()
    if not self.db or not self.db.Enabled then return end

    self:CreateContainer()
    self:UpdateContainerPosition()
    self:LayoutButtons()

    for slot = 1, MAX_TOTEMS do
        if totemButtons[slot] then self:UpdateButtonSettings(totemButtons[slot]) end
    end

    if containerFrame then containerFrame:Show() end

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")

    self:StartUpdateTicker()

    C_Timer.After(0.5, function() self:UpdateTotems() end)

    if NRSKNUI.EditMode then
        NRSKNUI.EditMode:RegisterElement({
            key = "TotemTracker",
            displayName = "Totem Tracker",
            frame = containerFrame,
            getPosition = function()
                return self.db.Position
            end,
            setPosition = function(pos)
                self.db.Position.AnchorFrom = pos.AnchorFrom
                self.db.Position.AnchorTo = pos.AnchorTo
                self.db.Position.XOffset = pos.XOffset
                self.db.Position.YOffset = pos.YOffset
                self:ApplySettings()
            end,
            getParentFrame = function()
                return NRSKNUI:ResolveAnchorFrame(self.db.anchorFrameType, self.db.ParentFrame)
            end,
            guiPath = "TotemTracker",
        })
    end
end

function TT:OnDisable()
    isPreviewActive = false

    self:UnregisterAllEvents()
    self:StopUpdateTicker()

    for slot = 1, MAX_TOTEMS do
        local btn = totemButtons[slot]
        if btn then
            btn:SetAlpha(0)
            btn:Hide()
        end
    end

    if containerFrame then containerFrame:Hide() end
    if NRSKNUI.EditMode then NRSKNUI.EditMode:UnregisterElement("TotemTracker") end
end
