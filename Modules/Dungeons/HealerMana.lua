---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("HealerMana: Addon object not initialized. Check file load order!")
    return
end

---@class HealerMana: AceModule, AceEvent-3.0, AceTimer-3.0
local HM = NorskenUI:NewModule("HealerMana", "AceEvent-3.0", "AceTimer-3.0")

local LibSpec = LibStub("LibSpecialization")

local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsConnected = UnitIsConnected
local UnitClass = UnitClass
local UnitName = UnitName
local UnitPowerPercent = UnitPowerPercent
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetSpecializationInfoByID = GetSpecializationInfoByID
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local pairs = pairs
local wipe = wipe
local issecretvalue = issecretvalue

HM.healerFrames = {}
HM.libSpecCache = {}

local HEALER_ICONS = { DRUID = 136041, MONK = 608952, PALADIN = 135920, SHAMAN = 136052, EVOKER = 4622476, }

local PREVIEW_HEALER_SPECS = {
    { class = "DRUID",   icon = 136041 },
    { class = "MONK",    icon = 608952 },
    { class = "PALADIN", icon = 135920 },
    { class = "PRIEST",  icon = 135940 },
    { class = "PRIEST",  icon = 237541 },
    { class = "SHAMAN",  icon = 136052 },
    { class = "EVOKER",  icon = 4622476 },
}

function HM:UpdateDB()
    if NRSKNUI.db and NRSKNUI.db.profile then
        self.db = NRSKNUI.db.profile.HealerMana
    end
end

function HM:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function HM:HideFrame()
    self.currentHealer = nil
    if self.healerFrames[1] then
        self.healerFrames[1]:Hide()
    end
    if self.containerFrame then
        self.containerFrame:Hide()
    end
end

function HM:UpdateManaDisplay(frame, unit, connected)
    if connected then
        local manaColor = self.db.HighManaColor
        frame.mana:SetTextColor(manaColor[1], manaColor[2], manaColor[3])
        frame.icon:SetVertexColor(1, 1, 1)
        local pct = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        frame.mana:SetText(string.format("%.0f%%", pct))
    else
        frame.mana:SetTextColor(0.5, 0.5, 0.5)
        frame.mana:SetText("OFFLINE")
        frame.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

function HM:CreateHealerFrame(index)
    local frame = CreateFrame("Frame", "NorskenUI_HealerMana_" .. index, self.containerFrame)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)

    frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconFrame:SetSize(self.db.IconSize, self.db.IconSize)
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.iconFrame:SetBackdropColor(0, 0, 0, 1)
    frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)

    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetPoint("BOTTOMLEFT", frame.iconFrame, "RIGHT", 4, self.db.NameYOffset)
    frame.name:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(frame.name, self.db.FontFace, self.db.NameFontSize, self.db.FontOutline, self.db.FontShadow)

    frame.mana = frame:CreateFontString(nil, "OVERLAY")
    frame.mana:SetPoint("TOPLEFT", frame.iconFrame, "RIGHT", 4, self.db.ManaYOffset)
    frame.mana:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(frame.mana, self.db.FontFace, self.db.ManaFontSize, self.db.FontOutline, self.db.FontShadow)

    frame:Hide()
    return frame
end

function HM:GetHealerFrame(index)
    if not self.healerFrames[index] then
        self.healerFrames[index] = self:CreateHealerFrame(index)
    end
    return self.healerFrames[index]
end

function HM:UpdateFrameAppearance(frame)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)
    frame.iconFrame:SetSize(self.db.IconSize, self.db.IconSize)

    frame.name:ClearAllPoints()
    frame.name:SetPoint("BOTTOMLEFT", frame.iconFrame, "RIGHT", 4, self.db.NameYOffset)
    NRSKNUI:ApplyFontToText(frame.name, self.db.FontFace, self.db.NameFontSize, self.db.FontOutline, self.db.FontShadow)

    frame.mana:ClearAllPoints()
    frame.mana:SetPoint("TOPLEFT", frame.iconFrame, "RIGHT", 4, self.db.ManaYOffset)
    NRSKNUI:ApplyFontToText(frame.mana, self.db.FontFace, self.db.ManaFontSize, self.db.FontOutline, self.db.FontShadow)
end

function HM:CreateContainer()
    if self.containerFrame then return self.containerFrame end

    local frame = CreateFrame("Frame", "NorskenUI_HealerMana_Container", UIParent)
    frame:SetSize(self.db.FrameWidth, self.db.IconSize)

    self.containerFrame = frame
    self:ApplyPosition()
    return frame
end

function HM:ApplyPosition()
    if not self.containerFrame then return end
    NRSKNUI:ApplyFramePosition(self.containerFrame, self.db.Position, self.db)
end

function HM:PositionFrame()
    local frame = self.healerFrames[1]
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.containerFrame, "TOPLEFT", 0, 0)
    end
    self.containerFrame:SetSize(self.db.FrameWidth, self.db.IconSize)
end

function HM:OnLibSpecUpdate(specID, role, _, playerName)
    if role == "HEALER" then
        self.libSpecCache[playerName] = specID
        if self.db and self.db.Enabled and not self.isPreview then
            self:FindHealer()
        end
    end
end

function HM:FindHealer()
    if not self.db or not self.db.Enabled then return end
    if self.isPreview then return end

    if not IsInGroup() or IsInRaid() then
        self:HideFrame()
        return
    end

    local healerUnit, healerConnected

    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
            healerUnit = unit
            healerConnected = UnitIsConnected(unit)
            break
        end
    end

    if not healerUnit then
        self:HideFrame()
        return
    end

    local healerName = UnitName(healerUnit)
    if issecretvalue and issecretvalue(healerName) then
        healerName = "Healer"
    end
    local _, healerClass = UnitClass(healerUnit)

    self.currentHealer = {
        unit = healerUnit,
        name = healerName,
        specID = self.libSpecCache[healerName],
        class = healerClass,
        classColor = NRSKNUI:GetClassColor(healerClass),
        connected = healerConnected,
    }

    self:UpdateHealerFrame()
end

function HM:UpdateHealerFrame()
    local healer = self.currentHealer
    if not healer then return end
    local frame = self:GetHealerFrame(1)

    -- All classes have 1 heal spec except priest
    -- So we only do extra checks for when the healer is a priest
    local icon
    if healer.class == "PRIEST" then
        local specID = healer.specID
        if specID and specID ~= 0 then
            _, _, _, icon = GetSpecializationInfoByID(specID)
        end
    else
        icon = HEALER_ICONS[healer.class]
    end

    if icon then
        frame.icon:SetTexture(icon)
        NRSKNUI:ApplyZoom(frame.icon, NRSKNUI.GlobalZoom)
    end

    frame.name:SetText(healer.name)
    frame.name:SetTextColor(healer.classColor[1], healer.classColor[2], healer.classColor[3])

    self:UpdateManaDisplay(frame, healer.unit, healer.connected)

    self:PositionFrame()
    frame:Show()
    self.containerFrame:Show()
end

function HM:UpdateMana()
    if self.isPreview then return end

    local healer = self.currentHealer
    if not healer then return end

    local frame = self.healerFrames[1]
    if not frame or not frame:IsShown() then return end

    local connected = UnitIsConnected(healer.unit)
    healer.connected = connected

    self:UpdateManaDisplay(frame, healer.unit, connected)
end

function HM:ShowPreview()
    self:UpdateDB()
    if not self.db then return end

    self.isPreview = true
    self:CreateContainer()

    local randomSpec = PREVIEW_HEALER_SPECS[math.random(1, #PREVIEW_HEALER_SPECS)]

    self.currentHealer = {
        unit = "player",
        name = UnitName("player"),
        class = randomSpec.class,
        classColor = NRSKNUI:GetClassColor(randomSpec.class),
    }

    local frame = self:GetHealerFrame(1)
    self:UpdateFrameAppearance(frame)

    frame.icon:SetTexture(randomSpec.icon)
    frame.icon:SetVertexColor(1, 1, 1)
    NRSKNUI:ApplyZoom(frame.icon, NRSKNUI.GlobalZoom)

    frame.name:SetText(self.currentHealer.name)
    local cc = self.currentHealer.classColor
    frame.name:SetTextColor(cc[1], cc[2], cc[3])

    local manaColor = self.db.HighManaColor
    frame.mana:SetTextColor(manaColor[1], manaColor[2], manaColor[3])
    frame.mana:SetText(string.format("%d%%", math.random(1, 100)))

    self:PositionFrame()
    frame:Show()
    self.containerFrame:Show()
end

function HM:HidePreview()
    self.isPreview = false
    self:HideFrame()

    if self.db and self.db.Enabled then
        self:FindHealer()
    end
end

function HM:ApplySettings()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then
        if self.containerFrame then
            self.containerFrame:Hide()
        end
        return
    end

    self:CreateContainer()
    self:ApplyPosition()

    for _, frame in pairs(self.healerFrames) do
        self:UpdateFrameAppearance(frame)
    end

    self:FindHealer()

    if self.isPreview then
        self:ShowPreview()
    end
end

function HM:Refresh()
    self:UpdateDB()

    if self.isPreview then
        if self.healerFrames[1] then
            self:UpdateFrameAppearance(self.healerFrames[1])
        end
        if self.containerFrame then
            self.containerFrame:SetSize(self.db.FrameWidth, self.db.IconSize)
            self:ApplyPosition()
        end
        return
    end

    self.currentHealer = nil
    wipe(self.libSpecCache)

    for _, frame in pairs(self.healerFrames) do frame:Hide() end
    wipe(self.healerFrames)

    if self.containerFrame then
        self.containerFrame:Hide()
        self.containerFrame = nil
    end

    self:ApplySettings()
end

function HM:StartUpdates()
    if self.updateTimer then return end
    self.updateTimer = self:ScheduleRepeatingTimer("UpdateMana", 1)
end

function HM:StopUpdates()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
end

function HM:OnEnable()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end

    LibSpec.RegisterGroup(self, function(specID, role, position, playerName)
        HM:OnLibSpecUpdate(specID, role, position, playerName)
    end)

    self:ApplySettings()
    self:StartUpdates()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "FindHealer")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "FindHealer")

    -- Delayed to ensure anchor frames exist on load
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    NRSKNUI.EditMode:RegisterElement({
        key = "HealerMana",
        displayName = "Healer Mana",
        frame = self.containerFrame,
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
        guiPath = "HealerMana",
    })
end

function HM:OnDisable()
    self:StopUpdates()
    self:UnregisterAllEvents()
    LibSpec.UnregisterGroup(self)
    wipe(self.libSpecCache)
    self.currentHealer = nil
    self.isPreview = false
    if self.containerFrame then self.containerFrame:Hide() end
    for _, frame in pairs(self.healerFrames) do frame:Hide() end
end
