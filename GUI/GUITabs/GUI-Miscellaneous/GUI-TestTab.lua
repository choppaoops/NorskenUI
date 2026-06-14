---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("TestTab", function(scrollChild, yOffset)
    local db = {
        Enabled = true,
    }
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local manager = GUIFrame:CreateWidgetStateManager()

    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Test Tab", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Test Tab", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Test Tab",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    yOffset = card1:GetNextOffset()

    return yOffset
end)
