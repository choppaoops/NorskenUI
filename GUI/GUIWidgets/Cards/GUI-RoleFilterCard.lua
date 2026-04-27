---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs
local table_insert = table.insert

---Role filter card with enable toggle and Tank/Healer/DPS checkboxes
---@param scrollChild Frame
---@param yOffset number
---@param config table
---@return table card
---@return number newYOffset
function GUIFrame:CreateRoleFilterCard(scrollChild, yOffset, config)
    config = config or {}
    local title = config.title or "Role"
    local db = config.db
    local dbKeys = config.dbKeys or {}
    local onChange = config.onChangeCallback
    local onRefresh = config.onRefreshCallback

    local keys = {
        enabled = dbKeys.enabled or "loadRoleEnabled",
        tank = dbKeys.tank or "loadRoleTank",
        healer = dbKeys.healer or "loadRoleHealer",
        dps = dbKeys.dps or "loadRoleDPS",
    }

    local widgets = {}
    local card = GUIFrame:CreateCard(scrollChild, title, yOffset)

    local isEnabled = db[keys.enabled] or false
    local row1Height = isEnabled and 40 or 36

    local row1 = GUIFrame:CreateRow(card.content, row1Height)
    local roleToggle = GUIFrame:CreateCheckbox(row1, "Filter by Role", {
        value = isEnabled,
        callback = function(checked)
            db[keys.enabled] = checked
            if onChange then onChange() end
            if onRefresh then onRefresh() end
        end
    })
    row1:AddWidget(roleToggle, 1)
    table_insert(widgets, roleToggle)
    card:AddRow(row1, row1Height)

    if isEnabled then
        local separator = GUIFrame:CreateSeparator(card.content)
        card:AddRow(separator, Theme.rowHeightSeparator)

        local row2 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
        local tankCheck = GUIFrame:CreateCheckbox(row2, "Tank", {
            value = db[keys.tank] ~= false,
            callback = function(checked)
                db[keys.tank] = checked
                if onChange then onChange() end
            end
        })
        row2:AddWidget(tankCheck, 1)
        table_insert(widgets, tankCheck)
        card:AddRow(row2, Theme.rowHeight)

        local row3 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
        local healerCheck = GUIFrame:CreateCheckbox(row3, "Healer", {
            value = db[keys.healer] ~= false,
            callback = function(checked)
                db[keys.healer] = checked
                if onChange then onChange() end
            end
        })
        row3:AddWidget(healerCheck, 1)
        table_insert(widgets, healerCheck)
        card:AddRow(row3, Theme.rowHeight)

        local row4 = GUIFrame:CreateRow(card.content, Theme.rowHeightLast)
        local dpsCheck = GUIFrame:CreateCheckbox(row4, "DPS", {
            value = db[keys.dps] ~= false,
            callback = function(checked)
                db[keys.dps] = checked
                if onChange then onChange() end
            end
        })
        row4:AddWidget(dpsCheck, 1)
        table_insert(widgets, dpsCheck)
        card:AddRow(row4, Theme.rowHeightLast, 0)
    end

    card.roleWidgets = widgets

    function card:SetEnabled(enabled)
        if enabled then
            self:SetAlpha(1)
        else
            self:SetAlpha(0.5)
        end
        for _, widget in ipairs(self.roleWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(enabled)
            end
        end
    end

    return card, card:GetNextOffset()
end
