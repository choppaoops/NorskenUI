---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("tooltips", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return GUIFrame:ShowDBError(scrollChild, yOffset) end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.Tooltips
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end
    local manager = GUIFrame:CreateWidgetStateManager()

    ---@type Tooltips?
    local TT = NRSKNUI:GetModule("Tooltips", true)
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card: Tooltip Skinning
    local card = GUIFrame:CreateCard(scrollChild, "Tooltip Skinning", yOffset)

    local row1 = GUIFrame:CreateRow(card.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Tooltip Skinning", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if TT then
                if checked then
                    NRSKNUI:EnableModule("Tooltips")
                else
                    NRSKNUI:DisableModule("Tooltips")
                    NRSKNUI:CreateReloadPrompt("Enabling Blizzard UI elements requires a reload to take full effect.")
                end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Tooltip Skinning",
    })
    row1:AddWidget(enableCheck, 1)
    card:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
