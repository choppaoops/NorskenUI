---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("BenchAlert: Addon object not initialized. Check file load order!")
    return
end

---@class PotionReady: AceModule, AceEvent-3.0
local POT = NorskenUI:NewModule("PotionReady", "AceEvent-3.0")

local unpack = unpack
local select = select
local GetTime = GetTime
local GetInstanceInfo = GetInstanceInfo
local C_Timer = C_Timer

-- R2 Light's Potential but can be any dmg pot, since they all share cd
local POTION_ID = 241308

-- Chache pot state to avoid unnecessary checks
local potionOnCooldown = false

function POT:UpdateDB()
    self.db = NRSKNUI.db.profile.PotionReady
end

function POT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function POT:OnEnable()
    if not self.db.Enabled then return end
    self:CreateAlertFrame()
    C_Timer.After(0.5, function() self:ApplySettings() end)
    self:EditModeReg()

    -- Only check pot state if not already on cooldown
    self:RegisterEvent("BAG_UPDATE_COOLDOWN", function()
        if not potionOnCooldown then POT:UpdateCooldownState() end
    end)

    -- Pot cooldown is reset on M+ key start and boss resets, kills or wipes
    self:RegisterEvent("CHALLENGE_MODE_START", "UpdateCooldownState")
    self:RegisterEvent("ENCOUNTER_END", function()
        if select(2, GetInstanceInfo()) == "raid" then POT:UpdateCooldownState() end
    end)

    -- Check inital pot state, reloads and logins for example
    self:UpdateCooldownState()
end

function POT:OnDisable()
    self:UnregisterAllEvents()
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
        self.cooldownTimer = nil
    end
    if self.alertFrame then self.alertFrame:Hide() end
    self.isPreview = false
end

function POT:CreateAlertFrame()
    if self.alertFrame then return end
    local frame = NRSKNUI:CreateTextFrame(UIParent, 300, 40, { name = "NRSKNUI_PotionReady" })
    frame:Hide()
    self.alertFrame = frame
    return frame
end

function POT:ApplySettings()
    if not self.alertFrame then return end
    local frame = self.alertFrame
    local db = self.db

    frame.text:SetTextColor(unpack(db.Color))
    NRSKNUI:ApplyFontToText(frame.text, db.FontFace, db.FontSize, db.FontOutline, db.FontShadow)
    frame.text:SetText(db.Text)

    local w = frame.text:GetStringWidth()
    local h = frame.text:GetStringHeight()
    frame:SetSize(w + 4, h + 4)

    NRSKNUI:ApplyFramePosition(frame, self.db.Position, db)

    local textPoint = NRSKNUI:GetTextJustifyFromAnchor(db.Position.AnchorFrom)
    frame.text:ClearAllPoints()
    frame.text:SetPoint(textPoint, frame, textPoint, 0, 0)
    frame.text:SetJustifyH(textPoint)

    if db.Strata then frame:SetFrameStrata(db.Strata) end
end

function POT:UpdateCooldownState()
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
        self.cooldownTimer = nil
    end

    local startTime, duration = C_Item.GetItemCooldown(POTION_ID)
    local remaining = duration > 0 and (startTime + duration) - GetTime() or 0
    if remaining > 0 then
        potionOnCooldown = true
        if self.alertFrame then self.alertFrame:Hide() end
        self.cooldownTimer = C_Timer.NewTimer(remaining, function()
            self.cooldownTimer = nil
            self:UpdateCooldownState()
        end)
    else
        potionOnCooldown = false
        if self.db.Enabled and self.alertFrame then
            self.alertFrame.text:SetText(self.db.Text)
            self.alertFrame:Show()
        end
    end
end

function POT:ShowPreview()
    if not self.alertFrame then self:CreateAlertFrame() end
    self:EditModeReg()
    self.isPreview = true
    self:ApplySettings()
    self.alertFrame.text:SetText(self.db.Text)
    self.alertFrame:Show()
end

function POT:HidePreview()
    self.isPreview = false
    if not self.db.Enabled and self.alertFrame then self.alertFrame:Hide() end
end

function POT:EditModeReg()
    if NRSKNUI.EditMode and not self.editModeRegistered then
        NRSKNUI.EditMode:RegisterElement({
            key = "PotionReady",
            displayName = "Potion Ready",
            frame = self.alertFrame,
            getPosition = function() return self.db.Position end,
            setPosition = function(pos)
                self.db.Position.AnchorFrom = pos.AnchorFrom
                self.db.Position.AnchorTo = pos.AnchorTo
                self.db.Position.XOffset = pos.XOffset
                self.db.Position.YOffset = pos.YOffset
                NRSKNUI:ApplyFramePosition(self.alertFrame, self.db.Position, self.db)
            end,
            guiPath = "potionready",
        })
        self.editModeRegistered = true
    end
end
