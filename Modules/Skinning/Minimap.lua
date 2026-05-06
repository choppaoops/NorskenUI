---@class NRSKNUI
local NRSKNUI = select(2, ...)
local Theme = NRSKNUI.Theme

if not NorskenUI then
    error("Minimap: Addon object not initialized. Check file load order!")
    return
end

---@class Minimap: AceModule, AceEvent-3.0
local MAP = NorskenUI:NewModule("Minimap", "AceEvent-3.0")

local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local CreateFrame = CreateFrame
local unpack = unpack
local LibStub = LibStub
local InCombatLockdown = InCombatLockdown
local IsMouseButtonDown = IsMouseButtonDown
local _G = _G
local mailBtn = MiniMapMailIcon
local qBtn = QueueStatusButton

local hooked = {
    border = false,
    queuePosition = false,
    addonCompEnter = false,
    bugSackButton = nil,
}

local lastAppliedSize = nil
local pendingSizeRefresh = false
local pendingCombatUpdate = false

function MAP:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Minimap
end

function MAP:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function DisableMinimapEditMode()
    if not MinimapCluster then return end
    MinimapCluster.SetIsInEditMode = nop
    MinimapCluster.OnEditModeEnter = nop
    MinimapCluster.OnEditModeExit = nop
    MinimapCluster.HasActiveChanges = nop
    MinimapCluster.HighlightSystem = nop
    MinimapCluster.SelectSystem = nop
    MinimapCluster.system = nil
end

function MAP:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    self:StripBlizzMap()
    self:CreateBugSackButton()
    self:ApplySettings()

    if not hooked.queuePosition then
        hooksecurefunc(QueueStatusButton, "UpdatePosition", function()
            self:UpdateQueueBtn()
        end)
        hooked.queuePosition = true
    end

    C_Timer.After(0.5, DisableMinimapEditMode)

    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    NRSKNUI.EditMode:RegisterElement({
        key = "Minimap",
        displayName = "Minimap",
        frame = Minimap,
        getPosition = function()
            local pos = self.db.Position
            return {
                AnchorFrom = pos.AnchorFrom,
                AnchorTo = pos.AnchorTo,
                XOffset = pos.X,
                YOffset = pos.Y,
            }
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.X = pos.XOffset
            self.db.Position.Y = pos.YOffset
            Minimap:ClearAllPoints()
            Minimap:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
        end,
        guiPath = "Minimap",
    })
end

function MAP:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    pendingCombatUpdate = false
    self:ApplySettings()
end

function MAP:PLAYER_ENTERING_WORLD()
    C_Timer.After(0.1, function()
        self:ApplySettings()
    end)
end

function MAP:StripBlizzMap()
    Minimap:SetParent(UIParent)
    if not Minimap.Layout then Minimap.Layout = nop end

    MinimapCluster.Tracking:SetParent(Minimap)
    MinimapCluster.IndicatorFrame.MailFrame:SetParent(Minimap)
    MinimapCluster.InstanceDifficulty:SetParent(Minimap)

    Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
    MinimapCompassTexture:SetTexture(nil)

    NRSKNUI:Hide("MinimapCluster")
    NRSKNUI:Hide("MinimapCompassTexture")
    NRSKNUI:Hide("MinimapCluster", "BorderTop")
    NRSKNUI:Hide("MinimapCluster", "ZoneTextButton")
    NRSKNUI:Hide("Minimap", "ZoomIn")
    NRSKNUI:Hide("Minimap", "ZoomOut")
    NRSKNUI:Hide("Minimap", "ZoomHitArea")
    NRSKNUI:Hide("GameTimeFrame")

    MinimapCluster.Tracking:ClearAllPoints()
    MinimapCluster.Tracking.Button:SetMenuAnchor(AnchorUtil.CreateAnchor("TOPRIGHT", Minimap, "BOTTOMLEFT"))

    self:SkinAddonCompartment()
end

function MAP:SkinAddonCompartment()
    if not AddonCompartmentFrame then return end

    if self.db.HideAddOnComp then
        AddonCompartmentFrame:ClearAllPoints()
        AddonCompartmentFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 9999, 9999)
        return
    end

    for _, region in ipairs({ AddonCompartmentFrame:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local layer = region:GetDrawLayer()
            if layer == "ARTWORK" or layer == "HIGHLIGHT" then
                region:Hide()
                region:SetAlpha(0)
            end
        end
    end

    local bg = NRSKNUI:CreateStandardBackdrop(
        AddonCompartmentFrame,
        "AddonCompartmentFrame_BG",
        AddonCompartmentFrame:GetFrameLevel() - 1,
        NRSKNUI.Media.Background,
        NRSKNUI.Media.Border
    )
    bg:SetAllPoints(AddonCompartmentFrame)

    if not hooked.addonCompEnter then
        AddonCompartmentFrame:HookScript("OnEnter", function()
            bg:SetBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        end)
        AddonCompartmentFrame:HookScript("OnLeave", function()
            bg:SetBorderColor(0, 0, 0, 1)
        end)
        hooked.addonCompEnter = true
    end

    ---@class AddonCompartmentFrame
    ---@field Text FontString
    AddonCompartmentFrame:ClearAllPoints()
    AddonCompartmentFrame:SetSize(20, 20)
    AddonCompartmentFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
    AddonCompartmentFrame:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    AddonCompartmentFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    AddonCompartmentFrame.Text:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    AddonCompartmentFrame.Text:SetShadowColor(0, 0, 0, 0)
    AddonCompartmentFrame.Text:SetShadowOffset(0, 0)
end

function MAP:UpdateMinimapBorder()
    if not hooked.border then
        Minimap.Border = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        Minimap.Border:SetAllPoints(Minimap)
        Minimap.Border:SetFrameLevel(Minimap:GetFrameLevel() + 1)
        hooked.border = true
    end

    Minimap.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = self.db.Border.Thickness,
    })
    Minimap.Border:SetBackdropBorderColor(unpack(self.db.Border.Color))
end

function MAP:UpdateMailBtn()
    if not mailBtn then return end
    local mailFrame = MinimapCluster.IndicatorFrame.MailFrame
    mailBtn:ClearAllPoints()
    mailBtn:SetPoint("CENTER", mailFrame, "CENTER", 0, 0)
    mailFrame:SetScale(self.db.Mail.Scale)
    mailFrame:ClearAllPoints()
    mailFrame:SetPoint(self.db.Mail.Anchor, Minimap, self.db.Mail.Anchor, self.db.Mail.X, self.db.Mail.Y)
end

function MAP:UpdateInstanceBtn()
    local instanceBtnDB = self.db.InstanceDifficulty
    local instanceFrame = MinimapCluster.InstanceDifficulty
    instanceFrame:SetScale(instanceBtnDB.Scale)
    instanceFrame:ClearAllPoints()
    instanceFrame:SetPoint(instanceBtnDB.Anchor, Minimap, instanceBtnDB.Anchor, instanceBtnDB.X, instanceBtnDB.Y)
    for _, child in ipairs({ instanceFrame.ChallengeMode, instanceFrame.Default, instanceFrame.Guild }) do
        child:ClearAllPoints()
        child:SetPoint("CENTER", instanceFrame, "CENTER", 0, 0)
    end
end

function MAP:UpdateQueueBtn()
    if not qBtn then return end

    local queueBtnDB = self.db.QueueStatus
    qBtn:SetParent(Minimap)
    qBtn:ClearAllPoints()
    qBtn:SetPoint(queueBtnDB.Anchor, Minimap, queueBtnDB.Anchor, queueBtnDB.X, queueBtnDB.Y)
    qBtn:SetScale(queueBtnDB.Scale)
    qBtn:SetFrameLevel(10)
end

---@param skipZoom? boolean Set true during live slider dragging to prevent mouse capture loss
function MAP:ApplyPosSize(skipZoom)
    Minimap:ClearAllPoints()
    Minimap:SetPoint(
        self.db.Position.AnchorFrom, UIParent, self.db.Position.AnchorTo,
        self.db.Position.X, self.db.Position.Y
    )

    local newSize = self.db.Size
    Minimap:SetSize(newSize, newSize)

    if not skipZoom and lastAppliedSize ~= newSize then
        lastAppliedSize = newSize
        Minimap:SetZoom(1)
        Minimap:SetZoom(0)
    end
end

function MAP:UpdateSize()
    local newSize = self.db.Size
    Minimap:SetSize(newSize, newSize)

    if not pendingSizeRefresh then
        pendingSizeRefresh = true
        local function CheckAndRefresh()
            if IsMouseButtonDown("LeftButton") then
                C_Timer.After(0.1, CheckAndRefresh)
                return
            end
            pendingSizeRefresh = false
            if lastAppliedSize ~= self.db.Size then
                lastAppliedSize = self.db.Size
                Minimap:SetZoom(1)
                Minimap:SetZoom(0)
            end
        end
        C_Timer.After(0.1, CheckAndRefresh)
    end
end

function MAP:CreateBugSackButton()
    if not self.db.BugSack.Enabled then
        if hooked.bugSackButton then
            hooked.bugSackButton:Hide()
        end
        return
    end

    if not C_AddOns.IsAddOnLoaded("BugSack") then return end
    local ldb = LibStub("LibDataBroker-1.1", true)
    if not ldb then return end
    local bugSackLDB = ldb:GetDataObjectByName("BugSack")
    if not bugSackLDB then return end
    local bugAddon = _G["BugSack"]
    if not bugAddon or not bugAddon.UpdateDisplay or not bugAddon.GetErrors then return end

    if not hooked.bugSackButton then
        local btn = CreateFrame("Button", "NRSKNABugSackButton", Minimap, "BackdropTemplate")
        btn.Text = btn:CreateFontString(nil, "OVERLAY")
        btn.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        btn.Text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.Text:SetTextColor(1, 1, 1)
        btn.Text:SetText("|cFF40FF400|r")

        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        btn:SetBackdropBorderColor(0, 0, 0, 1)

        btn:SetScript("OnClick", function(self, mouseButton)
            if bugSackLDB.OnClick then
                bugSackLDB.OnClick(self, mouseButton)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            btn:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            if bugSackLDB.OnTooltipShow then
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -2, -1)
                bugSackLDB.OnTooltipShow(GameTooltip)
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", function()
            btn:SetBackdropBorderColor(0, 0, 0, 1)
            GameTooltip:Hide()
        end)

        hooksecurefunc(bugAddon, "UpdateDisplay", function()
            local count = #bugAddon:GetErrors(BugGrabber:GetSessionId())
            if count == 0 then
                btn.Text:SetText("|cFF40FF40" .. count .. "|r")
            else
                btn.Text:SetText("|cFFFF4040" .. count .. "|r")
            end
        end)

        hooked.bugSackButton = btn
    end

    self:UpdateBugSackButton()
end

function MAP:UpdateBugSackButton()
    local btn = hooked.bugSackButton
    local db = self.db.BugSack
    if btn and db then
        btn:SetSize(db.Size, db.Size)
        btn:ClearAllPoints()
        btn:SetPoint(db.Anchor, Minimap, db.Anchor, db.X, db.Y)
        btn.Text:SetFont("Fonts\\FRIZQT__.TTF", db.Size-4, "OUTLINE")
        btn:Show()
    end
end

function MAP:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    if InCombatLockdown() then
        if not pendingCombatUpdate then
            pendingCombatUpdate = true
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        return
    end

    self:ApplyPosSize()
    self:UpdateMinimapBorder()
    self:UpdateMailBtn()
    self:UpdateInstanceBtn()
    self:UpdateQueueBtn()
    self:UpdateBugSackButton()
end
