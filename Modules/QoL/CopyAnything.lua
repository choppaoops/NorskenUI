---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("CopyAnything: Addon object not initialized. Check file load order!")
    return
end

---@class CopyAnything: AceModule, AceEvent-3.0
local CopyAnything = NorskenUI:NewModule("CopyAnything", "AceEvent-3.0")

local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local IsAltKeyDown = IsAltKeyDown
local select = select
local strsplit = strsplit
local strupper = strupper
local issecretvalue = issecretvalue
local GetMacroIndexByName = GetMacroIndexByName
local GetMacroSpell = GetMacroSpell
local GetMacroItem = GetMacroItem
local tonumber = tonumber
local tostring = tostring
local CreateFrame = CreateFrame
local type = type
local InCombatLockdown = InCombatLockdown
local C_AddOns = C_AddOns
local GetTime = GetTime

local lastCopyTime = 0

function CopyAnything:UpdateDB() self.db = NRSKNUI.db.profile.Miscellaneous.CopyAnything end

function CopyAnything:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function CheckModifiers(mod)
    if not mod then return true end

    if type(mod) == "string" then
        local t = {}
        mod = mod:lower()

        if mod:find("ctrl") then t.ctrl = true end
        if mod:find("shift") then t.shift = true end
        if mod:find("alt") then t.alt = true end

        mod = t
    end

    if mod.shift and not IsShiftKeyDown() then return false end
    if mod.ctrl and not IsControlKeyDown() then return false end
    if mod.alt and not IsAltKeyDown() then return false end

    return true
end

local function GetNPCIDFromGUID(guid)
    if not guid then return end
    return select(6, strsplit("-", guid))
end

function CopyAnything:TryCopy(key)
    if C_ChallengeMode.IsChallengeModeActive() or InCombatLockdown() then return false end
    local db = self.db
    if not db or not db.key or not db.mod then return false end
    if key ~= strupper(db.key) then return false end
    if not CheckModifiers(db.mod) then return false end

    local now = GetTime()
    if now - lastCopyTime < 0.1 then return true end

    local copyId, copyName

    -- Spell
    if not issecretvalue(GameTooltip:GetSpell()) then
        local spellName, spellId = GameTooltip:GetSpell()
        if spellId then
            copyId = spellId
            copyName = spellName
        end
    end

    -- Item
    if not issecretvalue(GameTooltip:GetItem()) then
        if not copyId then
            local itemName, _, itemId = GameTooltip:GetItem()
            if itemId then
                copyId = itemId
                copyName = itemName
            end
        end
    end

    -- Unit / NPC / Player
    if not issecretvalue(GameTooltip:GetUnit()) then
        if not copyId then
            local unitName, _, unitGUID = GameTooltip:GetUnit()
            local npcId = GetNPCIDFromGUID(unitGUID)

            if npcId then
                copyId = npcId
                copyName = unitName
            elseif unitName then
                copyId = unitName
                copyName = "Player Name"
            end
        end
    end

    -- Aura / Other tooltip data
    if not issecretvalue(GameTooltip:GetTooltipData()) then
        if not copyId then
            local data = GameTooltip:GetTooltipData()
            if data then
                if GameTooltip:IsTooltipType(7) then -- Aura
                    local aura = C_Spell.GetSpellInfo(data.id)
                    if aura then
                        copyId = data.id
                        copyName = aura.name
                    end
                else
                    copyId = data.id
                    copyName = "Other"
                end
            end
        end
    end

    -- ElvUI SpellBook Tooltip
    local addonName = "ElvUI"
    if C_AddOns.IsAddOnLoaded(addonName) then
        if not issecretvalue(ElvUI_SpellBookTooltip) then
            if not copyId and ElvUI_SpellBookTooltip then
                local data = ElvUI_SpellBookTooltip:GetTooltipData()
                if data and ElvUI_SpellBookTooltip:IsTooltipType(1) then
                    copyId = data.id
                    copyName = ElvUI_SpellBookTooltip.TextLeft1:GetText()
                end
            end
        end
    end

    -- Macro handling
    if not issecretvalue(GameTooltip:IsTooltipType()) then
        if not copyId and GameTooltip:IsTooltipType(25) then
            local info = GameTooltip:GetPrimaryTooltipInfo()
            if info and info.getterArgs then
                local actionSlot = info.getterArgs[1]
                local macroName = C_ActionBar.GetActionText(actionSlot)

                if macroName then
                    local macroSlot = GetMacroIndexByName(macroName)
                    local spellId = GetMacroSpell(macroSlot)
                    local _, itemLink = GetMacroItem(macroSlot)

                    if spellId then
                        local spellInfo = C_Spell.GetSpellInfo(spellId)
                        if spellInfo then
                            copyId = spellId
                            copyName = spellInfo.name
                        end
                    elseif itemLink then
                        local itemId = tonumber(itemLink:match("item:(%d+)"))
                        if itemId then
                            local itemName = C_Item.GetItemInfo(itemId)
                            if itemName then
                                copyId = itemId
                                copyName = itemName
                            end
                        end
                    end
                end
            end
        end
    end
    if copyId then
        lastCopyTime = GetTime()
        NRSKNUI:CreateCopyDialog(copyName, tostring(copyId))
        return true
    end
    return false
end

function CopyAnything:ApplySettings() CopyAnything:UpdateDB() end

function CopyAnything:OnEnable()
    if not self.db.Enabled then return end
    if not self.frame then
        self.frame = CreateFrame("Frame", "NRSKNUI_CopyFrame")
        self.frame:SetScript("OnKeyDown", function(frame, key)
            local handled = self:TryCopy(key)
            if not InCombatLockdown() then frame:SetPropagateKeyboardInput(not handled) end
        end)
    end
    self.frame:EnableKeyboard(true)
end

function CopyAnything:OnDisable() if self.frame then self.frame:EnableKeyboard(false) end end
