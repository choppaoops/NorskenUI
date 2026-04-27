---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("Automation: Addon object not initialized. Check file load order!")
    return
end

---@class Automation: AceModule, AceEvent-3.0, AceHook-3.0
local AUTO = NorskenUI:NewModule("Automation", "AceEvent-3.0", "AceHook-3.0")

local pcall = pcall
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local RepairAllItems = RepairAllItems
local CanMerchantRepair = CanMerchantRepair
local GetRepairAllCost = GetRepairAllCost
local CanGuildBankRepair = CanGuildBankRepair
local GetMoney = GetMoney
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local CinematicFrame_CancelCinematic = CinematicFrame_CancelCinematic
local GameMovieFinished = GameMovieFinished

function AUTO:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.Automation
end

function AUTO:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local cinematicFrame = nil
local function SetupSkipCinematics()
    if not AUTO.db.SkipCinematics then return end
    if cinematicFrame then return end

    cinematicFrame = CreateFrame("Frame")
    cinematicFrame:RegisterEvent("CINEMATIC_START")
    cinematicFrame:RegisterEvent("PLAY_MOVIE")
    cinematicFrame:SetScript("OnEvent", function(_, event)
        if event == "CINEMATIC_START" then
            CinematicFrame_CancelCinematic()
        elseif event == "PLAY_MOVIE" then
            pcall(GameMovieFinished)
        end
    end)
end

function AUTO:SetupTalkingHeadHider()
    if self._talkingHeadHooked then return end
    self._talkingHeadHooked = true

    local function HideTalkingHead(frame)
        if AUTO.db and AUTO.db.HideTalkingHead and frame then frame:Hide() end
    end

    if TalkingHeadFrame then
        self:SecureHook(TalkingHeadFrame, "PlayCurrent", HideTalkingHead)
        self:SecureHook(TalkingHeadFrame, "Reset", HideTalkingHead)
    else
        self:SecureHook("TalkingHead_LoadUI", function()
            if TalkingHeadFrame then
                self:SecureHook(TalkingHeadFrame, "PlayCurrent", HideTalkingHead)
                self:SecureHook(TalkingHeadFrame, "Reset", HideTalkingHead)
            end
        end)
    end
end

local merchantFrame = nil
local function SetupAutoSellRepair()
    if merchantFrame then return end

    merchantFrame = CreateFrame("Frame")
    merchantFrame:RegisterEvent("MERCHANT_SHOW")
    merchantFrame:SetScript("OnEvent", function()
        if AUTO.db.AutoSellJunk then
            if not IsShiftKeyDown() and C_MerchantFrame.GetNumJunkItems() > 0 then
                C_MerchantFrame.SellAllJunkItems()
            end
        end

        if AUTO.db.AutoRepair and CanMerchantRepair() then
            local repairCost, canRepair = GetRepairAllCost()
            if repairCost and canRepair and repairCost > 0 then
                if AUTO.db.UseGuildFunds and CanGuildBankRepair() then
                    local guildBankMoney = GetGuildBankWithdrawMoney()
                    if guildBankMoney >= repairCost then
                        RepairAllItems(true)
                        return
                    end
                end

                if GetMoney() >= repairCost then RepairAllItems(false) end
            end
        end
    end)
end

local function SetupAutoRoleCheck()
    if not AUTO.db.AutoRoleCheck then return end

    if LFGListApplicationDialog and not AUTO._lfgHooked then
        AUTO._lfgHooked = true
        LFGListApplicationDialog:HookScript("OnShow", function()
            if not IsShiftKeyDown() and LFGListApplicationDialog.SignUpButton then
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end

    if LFDRoleCheckPopup and not AUTO._lfdHooked then
        AUTO._lfdHooked = true
        LFDRoleCheckPopup:HookScript("OnShow", function()
            if not IsShiftKeyDown() and LFDRoleCheckPopupAcceptButton then LFDRoleCheckPopupAcceptButton:Click() end
        end)
    end
end

local function SetupAutoFillDelete()
    if not AUTO.db.AutoFillDelete then return end
    if AUTO._deleteHooked then return end
    AUTO._deleteHooked = true

    hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
        if self.EditBox then self.EditBox:SetText("DELETE") end
    end)
end

local function ApplyAutoLoot()
    C_CVar.SetCVar("autoLootDefault", AUTO.db.AutoLoot and "1" or "0")
end

local function ApplyHideHelptips()
    if not AUTO.db.HideHelptips then return end
    C_CVar.RegisterCVar("hideHelptips", 1)
    for index = 1, NUM_LE_FRAME_TUTORIALS do C_CVar.SetCVarBitfield("closedInfoFrames", index, true) end
    for index = 1, #Enum.FrameTutorialAccount do C_CVar.SetCVarBitfield("closedInfoFramesAccountWide", index, true) end
end

function AUTO:ApplySettings()
    if not self.db.Enabled then return end

    SetupSkipCinematics()
    self:SetupTalkingHeadHider()
    SetupAutoSellRepair()
    SetupAutoRoleCheck()
    SetupAutoFillDelete()
    ApplyAutoLoot()
    ApplyHideHelptips()
end

function AUTO:OnEnable()
    if not self.db.Enabled then return end
    C_Timer.After(1.0, function() self:ApplySettings() end)
end

function AUTO:OnDisable()
    -- Hooks cannot be removed, but the db checks prevent actions
end
