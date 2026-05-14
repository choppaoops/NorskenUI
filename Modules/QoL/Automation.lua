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
local GetNumQuestChoices = GetNumQuestChoices
local GetQuestReward = GetQuestReward
local GetNumActiveQuests = GetNumActiveQuests
local GetActiveTitle = GetActiveTitle
local ipairs = ipairs
local AcceptQuest = AcceptQuest
local GetNumAvailableQuests = GetNumAvailableQuests
local CompleteQuest = CompleteQuest
local GetQuestID = GetQuestID
local IsQuestCompletable = IsQuestCompletable

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
        if NRSKNUI:IsFullyRestricted() then return end
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
        if NRSKNUI:IsFullyRestricted() then return end

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
            if NRSKNUI:IsFullyRestricted() then return end
            if not IsShiftKeyDown() and LFGListApplicationDialog.SignUpButton then
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end

    if LFDRoleCheckPopup and not AUTO._lfdHooked then
        AUTO._lfdHooked = true
        LFDRoleCheckPopup:HookScript("OnShow", function()
            if NRSKNUI:IsFullyRestricted() then return end
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

local questCompleteFrame = nil
local function SetupAutoCompleteQuest()
    if not AUTO.db.AutoCompleteQuest then return end
    if questCompleteFrame then return end

    questCompleteFrame = CreateFrame("Frame")
    questCompleteFrame:RegisterEvent("QUEST_COMPLETE")
    questCompleteFrame:RegisterEvent("QUEST_GREETING")
    questCompleteFrame:RegisterEvent("GOSSIP_SHOW")
    questCompleteFrame:SetScript("OnEvent", function(_, event)
        if NRSKNUI:IsFullyRestricted() then return end
        if IsShiftKeyDown() then return end

        if event == "QUEST_COMPLETE" then
            local numChoices = GetNumQuestChoices()
            if numChoices <= 1 then GetQuestReward(numChoices) end
        elseif event == "QUEST_GREETING" then
            local numActive = GetNumActiveQuests()
            for i = 1, numActive do
                local _, isComplete = GetActiveTitle(i)
                if isComplete then
                    C_GossipInfo.SelectActiveQuest(i)
                    return
                end
            end
        elseif event == "GOSSIP_SHOW" then
            local activeQuests = C_GossipInfo.GetActiveQuests()
            if activeQuests then
                for _, quest in ipairs(activeQuests) do
                    if quest.isComplete then
                        C_GossipInfo.SelectActiveQuest(quest.questID)
                        return
                    end
                end
            end
        end
    end)
end

local VOIDCORES_GOLD_QUEST_ID = 95279
local function ShouldSkipForVoidcores(quests)
    if not AUTO.db.AutoVoidcoresGold then return false end
    if C_QuestLog.IsQuestFlaggedCompleted(VOIDCORES_GOLD_QUEST_ID) then return false end
    if not quests then return false end
    for _, quest in ipairs(quests) do
        if quest.questID == VOIDCORES_GOLD_QUEST_ID then return true end
    end
    return false
end

local questAcceptFrame = nil
local function SetupAutoAcceptQuest()
    if not AUTO.db.AutoAcceptQuest then return end
    if questAcceptFrame then return end

    questAcceptFrame = CreateFrame("Frame")
    questAcceptFrame:RegisterEvent("QUEST_DETAIL")
    questAcceptFrame:RegisterEvent("QUEST_GREETING")
    questAcceptFrame:RegisterEvent("GOSSIP_SHOW")
    questAcceptFrame:SetScript("OnEvent", function(_, event)
        if NRSKNUI:IsFullyRestricted() then return end
        if IsShiftKeyDown() then return end

        if event == "QUEST_DETAIL" then
            AcceptQuest()
        elseif event == "QUEST_GREETING" then
            local numQuests = GetNumAvailableQuests()
            if numQuests > 0 then C_GossipInfo.SelectAvailableQuest(1) end
        elseif event == "GOSSIP_SHOW" then
            local quests = C_GossipInfo.GetAvailableQuests()
            if ShouldSkipForVoidcores(quests) then return end
            if quests and #quests > 0 then C_GossipInfo.SelectAvailableQuest(quests[1].questID) end
        end
    end)
end

local voidcoresFrame = nil
local function SetupAutoVoidcoresGold()
    if not AUTO.db.AutoVoidcoresGold then return end
    if voidcoresFrame then return end

    voidcoresFrame = CreateFrame("Frame")
    voidcoresFrame:RegisterEvent("GOSSIP_SHOW")
    voidcoresFrame:RegisterEvent("QUEST_DETAIL")
    voidcoresFrame:RegisterEvent("QUEST_PROGRESS")
    voidcoresFrame:SetScript("OnEvent", function(_, event)
        if NRSKNUI:IsFullyRestricted() then return end
        if IsShiftKeyDown() then return end
        if C_QuestLog.IsQuestFlaggedCompleted(VOIDCORES_GOLD_QUEST_ID) then return end

        if event == "GOSSIP_SHOW" then
            local quests = C_GossipInfo.GetAvailableQuests()
            if quests then
                for _, quest in ipairs(quests) do
                    if quest.questID == VOIDCORES_GOLD_QUEST_ID then
                        C_GossipInfo.SelectAvailableQuest(VOIDCORES_GOLD_QUEST_ID)
                        return
                    end
                end
            end
        elseif event == "QUEST_DETAIL" then
            if QuestInfoFrame and QuestInfoFrame.questLog and QuestInfoFrame.questLog.questID == VOIDCORES_GOLD_QUEST_ID then
                AcceptQuest()
            elseif GetQuestID and GetQuestID() == VOIDCORES_GOLD_QUEST_ID then
                AcceptQuest()
            end
        elseif event == "QUEST_PROGRESS" then
            if GetQuestID and GetQuestID() == VOIDCORES_GOLD_QUEST_ID then
                if IsQuestCompletable and IsQuestCompletable() then
                    CompleteQuest()
                end
            end
        end
    end)
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
    SetupAutoCompleteQuest()
    SetupAutoAcceptQuest()
    SetupAutoVoidcoresGold()
end

function AUTO:OnEnable()
    if not self.db.Enabled then return end
    C_Timer.After(1.0, function() self:ApplySettings() end)
end

function AUTO:OnDisable()
    if cinematicFrame then cinematicFrame:UnregisterAllEvents() end
    if merchantFrame then merchantFrame:UnregisterAllEvents() end
    if questCompleteFrame then questCompleteFrame:UnregisterAllEvents() end
    if questAcceptFrame then questAcceptFrame:UnregisterAllEvents() end
    if voidcoresFrame then voidcoresFrame:UnregisterAllEvents() end
    self:UnhookAll()
    self._talkingHeadHooked = nil
end
