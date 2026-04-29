---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("Recuperate: Addon object not initialized. Check file load order!")
    return
end

---@class Recuperate: AceModule, AceEvent-3.0
local REC = NorskenUI:NewModule("Recuperate", "AceEvent-3.0")

local UnitHealthPercent = UnitHealthPercent
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local CreateFrame = CreateFrame
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
local C_Spell = C_Spell

local RECUPERATE_SPELL_ID = 1231411
local spellInfo = C_Spell.GetSpellInfo(RECUPERATE_SPELL_ID)

REC.isPreview = false

function REC:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.Recuperate
end

function REC:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function REC:OnHealthChange(_, unit)
    if unit ~= "player" then return end
    if self.isPreview then return end
    self:UpdateAlpha()
end

function REC:UpdateAlpha()
    if self.isPreview then return end
    if not self.button then return end

    if UnitIsDeadOrGhost("player") then
        self.button:SetAlpha(0)
        return
    end

    local alpha = UnitHealthPercent("player", true, NRSKNUI.curves.HealthMissingAlpha)
    self.button:SetAlpha(alpha)
end

function REC:GetVisibilityString()
    local loadInRaid = self.db.LoadInRaid
    local loadInParty = self.db.LoadInParty
    if not loadInRaid and not loadInParty then return "hide" end
    if loadInRaid and loadInParty then return "[combat] hide; [nogroup] hide; [dead] hide; show" end
    if loadInRaid then return "[combat] hide; [nogroup:raid] hide; [dead] hide; show" end
    return "[combat] hide; [group:raid] hide; [nogroup] hide; [dead] hide; show"
end

function REC:UpdateStateDriver()
    if not self.button then return end
    if self.isPreview then return end

    UnregisterStateDriver(self.button, "visibility")
    RegisterStateDriver(self.button, "visibility", self:GetVisibilityString())
    self:UpdateAlpha()
end

function REC:CreateButton()
    if self.button then return end

    local button = CreateFrame("Button", "NRSKNUI_RecuperateButton", UIParent,
        "SecureActionButtonTemplate, SecureHandlerStateTemplate")
    button:SetSize(self.db.Size, self.db.Size)
    button:Hide()

    RegisterStateDriver(button, "visibility", self:GetVisibilityString())

    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", RECUPERATE_SPELL_ID)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    NRSKNUI:ApplyZoom(button.icon, NRSKNUI.GlobalZoom)

    if spellInfo and spellInfo.iconID then button.icon:SetTexture(spellInfo.iconID) end

    NRSKNUI:AddBorders(button, { 0, 0, 0, 1 })

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button)
    button.highlight:SetColorTexture(1, 1, 1, 0.2)
    button.highlight:SetBlendMode("ADD")

    self.button = button
    self:ApplySettings()
    return button
end

function REC:ApplySettings()
    if not self.button then return end
    self.button:SetSize(self.db.Size, self.db.Size)
    NRSKNUI:ApplyFramePosition(self.button, self.db.Position, self.db)
end

function REC:OnEnable()
    if not self.db.Enabled then return end
    self:CreateButton()
    C_Timer.After(0.5, function() self:ApplySettings() end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAlpha")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateAlpha")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateAlpha")
    self:RegisterEvent("UNIT_HEALTH", "OnHealthChange")
    self:RegisterEvent("PLAYER_DEAD", "UpdateAlpha")
    self:RegisterEvent("PLAYER_UNGHOST", "UpdateAlpha")
    self:UpdateAlpha()

    NRSKNUI.EditMode:RegisterElement({
        key = "RecuperateButton",
        displayName = "Recuperate Button",
        frame = self.button,
        getPosition = function() return self.db.Position end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            NRSKNUI:ApplyFramePosition(self.button, self.db.Position, self.db)
        end,
        guiPath = "Recuperate",
    })
end

function REC:OnDisable()
    self:UnregisterAllEvents()
    if self.button then
        UnregisterStateDriver(self.button, "visibility")
        self.button:Hide()
    end
    self.isPreview = false
end

function REC:ShowPreview()
    if not self.button then self:CreateButton() end
    self.isPreview = true
    UnregisterStateDriver(self.button, "visibility")
    self.button:SetAlpha(1)
    self.button:Show()
    self:ApplySettings()
end

function REC:HidePreview()
    self.isPreview = false
    if not self.button then return end
    if self.db.Enabled then
        RegisterStateDriver(self.button, "visibility", self:GetVisibilityString())
        self:UpdateAlpha()
    else
        self.button:Hide()
    end
end
