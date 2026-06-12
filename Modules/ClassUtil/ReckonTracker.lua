---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("ReckonTracker: Addon object not initialized. Check file load order!")
    return
end

---@class ReckonTracker: AceModule, AceEvent-3.0
local RECKON = NorskenUI:NewModule("ReckonTracker", "AceEvent-3.0")

local CreateFrame = CreateFrame
local UIParent = UIParent

local DEFAULT_PROC_GRANT_SPELL_ID = 1226019 -- Reap
local ICON_TEXTURE = 7554200                -- Consume icon
local DEFAULT_CONSUME_SPELL_ID = 473662     -- Consume

local isBuffActive = false
local isPreviewActive = false
local iconFrame = nil
local eventFrame = nil

function RECKON:UpdateDB()
    self.db = NRSKNUI.db.profile.ReckonTracker
end

function RECKON:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function CheckLoad()
    local spec = NRSKNUI.MySpec.id
    if spec ~= 1480 then return false end
    local talent = C_SpecializationInfo.GetPvpTalentInfo(5735)
    if not talent or not talent.selected then return false end
    return true
end

function RECKON:CreateFrame()
    if iconFrame then return end

    iconFrame = NRSKNUI:CreateIconFrame(UIParent, self.db.IconSize, {
        name = "NRSKNUI_ReckonTrackerIcon",
        zoom = 0.3,
        borderColor = { 0, 0, 0, 1 },
    })
    iconFrame:EnableMouse(false)
    iconFrame:SetMouseClickEnabled(false)
    iconFrame:Hide()

    iconFrame.icon:SetTexture(ICON_TEXTURE)

    self.frame = iconFrame
    self.iconFrame = iconFrame

    self:ApplySettings()
end

function RECKON:ApplySettings()
    if not iconFrame then return end

    iconFrame:SetIconSize(self.db.IconSize)
    self:ApplyPosition()

    if iconFrame.glowActive then
        iconFrame:RefreshGlow(self.db)
    elseif self.db.GlowEnabled and iconFrame:IsShown() then
        iconFrame:StartGlow(self.db)
    end
end

function RECKON:ApplyPosition()
    if not self.db.Enabled then return end
    if not iconFrame then return end
    NRSKNUI:ApplyFramePosition(iconFrame, self.db.Position, self.db)
end

function RECKON:ShowDisplay()
    if not iconFrame then self:CreateFrame() end
    if not iconFrame then return end
    if not CheckLoad() then return end

    isBuffActive = true
    iconFrame:StartGlow(self.db)
    iconFrame:Show()
end

function RECKON:HideDisplay()
    if not iconFrame then return end

    isBuffActive = false
    iconFrame:StopGlow()
    iconFrame:Hide()
end

function RECKON:OnSpellCast(spellID)
    if isPreviewActive then return end

    local procSpell = C_Spell.GetOverrideSpell(DEFAULT_PROC_GRANT_SPELL_ID)
    local consumeSpell = C_Spell.GetOverrideSpell(DEFAULT_CONSUME_SPELL_ID)

    if spellID == procSpell then
        self:ShowDisplay()
    elseif spellID == consumeSpell and isBuffActive then
        self:HideDisplay()
    end
end

function RECKON:ShowPreview()
    if not iconFrame then self:CreateFrame() end
    if not iconFrame then return end
    isPreviewActive = true
    self:ApplySettings()
    iconFrame:StartGlow(self.db)
    iconFrame:Show()
end

function RECKON:HidePreview()
    isPreviewActive = false
    if iconFrame then
        iconFrame:StopGlow()
        iconFrame:Hide()
    end
end

function RECKON:TogglePreview()
    if isPreviewActive then
        self:HidePreview()
    else
        self:ShowPreview()
    end
    return isPreviewActive
end

function RECKON:IsPreviewActive()
    return isPreviewActive
end

function RECKON:OnEnable()
    if not self.db or not self.db.Enabled then return end

    self:CreateFrame()
    C_Timer.After(0.5, function() self:ApplyPosition() end)

    if not eventFrame then eventFrame = CreateFrame("Frame") end
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:SetScript("OnEvent", function(_, _, _, _, spellID)
        self:OnSpellCast(spellID)
    end)

    self:RegisterEvent("PLAYER_DEAD", function()
        isBuffActive = false
        self:HideDisplay()
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        isBuffActive = false
        self:HideDisplay()
    end)

    if NRSKNUI.EditMode then
        NRSKNUI.EditMode:RegisterElement({
            key = "ReckonTracker",
            displayName = "Reckon Tracker",
            frame = iconFrame,
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
            guiPath = "ReckonTracker",
        })
    end
end

function RECKON:OnDisable()
    if iconFrame then
        iconFrame:StopGlow()
        iconFrame:Hide()
    end
    isBuffActive = false
    isPreviewActive = false
    self:UnregisterAllEvents()

    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnEvent", nil)
    end

    if NRSKNUI.EditMode then
        NRSKNUI.EditMode:UnregisterElement("ReckonTracker")
    end
end
