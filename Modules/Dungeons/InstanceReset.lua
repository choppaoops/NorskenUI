---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("InstanceReset: Addon object not initialized. Check file load order!")
    return
end

---@class InstanceReset: AceModule, AceHook-3.0
local IR = NorskenUI:NewModule("InstanceReset", "AceHook-3.0")

local IsInGroup = IsInGroup
local IsInRaid = IsInRaid

function IR:UpdateDB()
    if NRSKNUI.db and NRSKNUI.db.profile then self.db = NRSKNUI.db.profile.InstanceReset end
end

function IR:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local function OnInstanceReset()
    if not IR.db or not IR.db.Enabled then return end
    local channel
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    end
    if channel then C_ChatInfo.SendChatMessage(IR.db.Message, channel) end
end

function IR:ApplySettings()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end
    if not self:IsHooked("ResetInstances") then self:SecureHook("ResetInstances", OnInstanceReset) end
end

function IR:OnEnable()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end
    self:ApplySettings()
end

function IR:OnDisable() self:UnhookAll() end
