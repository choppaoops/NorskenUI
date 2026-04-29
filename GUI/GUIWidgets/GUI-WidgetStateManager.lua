---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame

local ipairs = ipairs
local pairs = pairs
local type = type

---@class NUIWidgetStateManagerMixin
---@field groups table<string, Frame[]>
---@field conditions table<string, function>
---@field widgetGroups table<Frame, table<string, boolean>>
local NUIWidgetStateManagerMixin = {}

---@param widget Frame
---@param ... string
function NUIWidgetStateManagerMixin:Register(widget, ...)
    if not widget then return end
    local groupNames = { ... }

    self.widgetGroups[widget] = self.widgetGroups[widget] or {}

    for _, groupName in ipairs(groupNames) do
        self.groups[groupName] = self.groups[groupName] or {}
        self.groups[groupName][#self.groups[groupName] + 1] = widget
        self.widgetGroups[widget][groupName] = true
    end
end

---@param widgets Frame[]
---@param groupName string
function NUIWidgetStateManagerMixin:RegisterGroup(widgets, groupName)
    if not widgets or not groupName then return end
    self.groups[groupName] = self.groups[groupName] or {}
    for _, widget in ipairs(widgets) do
        self.groups[groupName][#self.groups[groupName] + 1] = widget
        self.widgetGroups[widget] = self.widgetGroups[widget] or {}
        self.widgetGroups[widget][groupName] = true
    end
end

---@param groupName string
---@param conditionFn fun(): boolean
function NUIWidgetStateManagerMixin:SetCondition(groupName, conditionFn)
    self.conditions[groupName] = conditionFn
end

---@param mainEnabled boolean
function NUIWidgetStateManagerMixin:UpdateAll(mainEnabled)
    for widget, groups in pairs(self.widgetGroups) do
        local enabled = mainEnabled

        if enabled then
            for groupName in pairs(groups) do
                local condition = self.conditions[groupName]
                if condition and type(condition) == "function" then
                    if not condition() then
                        enabled = false
                        break
                    end
                end
            end
        end

        if widget.SetEnabled then
            widget:SetEnabled(enabled)
        elseif widget.SetDisabled then
            widget:SetDisabled(not enabled)
        end
    end
end

---@param groupName string
---@param enabled boolean
function NUIWidgetStateManagerMixin:UpdateGroup(groupName, enabled)
    local widgets = self.groups[groupName]
    if not widgets then return end

    for _, widget in ipairs(widgets) do
        if widget.SetEnabled then
            widget:SetEnabled(enabled)
        elseif widget.SetDisabled then
            widget:SetDisabled(not enabled)
        end
    end
end

---@param groupName string
---@return Frame[]
function NUIWidgetStateManagerMixin:GetGroup(groupName)
    return self.groups[groupName] or {}
end

function NUIWidgetStateManagerMixin:Clear()
    self.groups = {}
    self.conditions = {}
    self.widgetGroups = {}
end

---@return NUIWidgetStateManager
function GUIFrame:CreateWidgetStateManager()
    local manager = {
        groups = {},
        conditions = {},
        widgetGroups = {},
    }

    Mixin(manager, NUIWidgetStateManagerMixin)

    return manager
end
