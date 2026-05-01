-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("InstanceReset: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class InstanceReset: AceModule, AceHook-3.0
local IR = NorskenUI:NewModule("InstanceReset", "AceHook-3.0")

-- Localization
local SendChatMessage = SendChatMessage
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid

-- Update db reference
function IR:UpdateDB()
    if NRSKNUI.db and NRSKNUI.db.profile then
        self.db = NRSKNUI.db.profile.InstanceReset
    end
end

-- Module init
function IR:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Send party/raid message on instance reset
local function OnInstanceReset()
    if not IR.db or not IR.db.Enabled then return end

    -- Determine chat channel
    local channel
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    end

    -- Only send if in a group
    if channel then
        local message = IR.db.Message or "Instance reset!"
        C_ChatInfo.SendChatMessage(message, channel)
    end
end

-- Apply settings
function IR:ApplySettings()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end

    -- Hook ResetInstances if not already hooked
    if not self:IsHooked("ResetInstances") then
        self:SecureHook("ResetInstances", OnInstanceReset)
    end
end

-- Module OnEnable
function IR:OnEnable()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end
    self:ApplySettings()
end

-- Module OnDisable
function IR:OnDisable()
    self:UnhookAll()
end
