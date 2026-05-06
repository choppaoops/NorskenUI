---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("Blizzard Mouseover: Addon object not initialized. Check file load order!")
    return
end

---@class BlizzardMouseover: AceModule, AceEvent-3.0
local BMO = NorskenUI:NewModule("BlizzardMouseover", "AceEvent-3.0")

local UIFrameFadeOut = UIFrameFadeOut
local UIFrameFadeIn = UIFrameFadeIn
local ipairs = ipairs
local pairs = pairs
local BagsBar = BagsBar

local appliedHooks = { bags = false, }

function BMO:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.BlizzardMouseover
end

function BMO:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function BMO:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end -- Skip if ElvUI is loaded, to avoid conflicts
    if not self.db.Enabled then return end
    C_Timer.After(0.5, function()
        self:SetupAllHooks()
        self:UpdateAllAlpha()
    end)
end

function BMO:SetupAllHooks()
    self:SetupBagHooks()
end

function BMO:SetupBagHooks()
    if appliedHooks.bags or not BagsBar then return end
    if not self.db.BagMouseover.Enabled then return end

    for _, child in ipairs({ BagsBar:GetChildren() }) do
        if child:IsObjectType("Button") then
            child:HookScript("OnEnter", function()
                if self.db.Enabled and self.db.BagMouseover.Enabled then
                    UIFrameFadeIn(BagsBar, self.db.FadeInDuration, BagsBar:GetAlpha(), 1.0)
                end
            end)
            child:HookScript("OnLeave", function()
                if self.db.Enabled and self.db.BagMouseover.Enabled then
                    C_Timer.After(self.db.FadeOutDuration, function()
                        UIFrameFadeOut(BagsBar, self.db.FadeOutDuration, BagsBar:GetAlpha(), self.db.Alpha)
                    end)
                end
            end)
        end
    end
    appliedHooks.bags = true
end

function BMO:UpdateAllAlpha()
    self:UpdateBagAlpha()
end

function BMO:UpdateBagAlpha()
    if not BagsBar then return end
    if not self.db.Enabled or not self.db.BagMouseover.Enabled then
        BagsBar:SetAlpha(1.0)
    else
        BagsBar:SetAlpha(self.db.Alpha)
    end
end

function BMO:ToggleElement(elementName, enabled)
    if elementName == "bags" then
        self.db.BagMouseover.Enabled = enabled
        if enabled and not appliedHooks.bags then self:SetupBagHooks() end
        self:UpdateBagAlpha()
    end
end

function BMO:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if self.db.Enabled then self:UpdateAllAlpha() end
end

function BMO:Reset()
    if BagsBar then BagsBar:SetAlpha(1.0) end
end

function BMO:OnDisable()
    self:Reset()
    for key in pairs(appliedHooks) do
        appliedHooks[key] = false
    end
end
