---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs

GUIFrame:RegisterContent("InstanceReset", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.InstanceReset
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type HealerMana?
    local IR = NorskenUI and NorskenUI:GetModule("InstanceReset", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function ApplySettings()
        if IR then IR:ApplySettings() end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Instance Reset Announcer", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Instance Reset Message", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if IR then
                if checked then NorskenUI:EnableModule("InstanceReset") else NorskenUI:DisableModule("InstanceReset") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Instance Reset",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Message Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Message Settings", yOffset)
    manager:Register(card2, "all")

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local messageBox = GUIFrame:CreateEditBox(row2, "Chat Message", {
        value = db.Message,
        callback = function(text)
            db.Message = text
            ApplySettings()
        end
    })
    row2:AddWidget(messageBox, 1)
    manager:Register(messageBox, "all")
    card2:AddRow(row2, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
