---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("WayFinder", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.WayFinder
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type WayFinder?
    local WF = NorskenUI and NorskenUI:GetModule("WayFinder", true)

    local card1 = GUIFrame:CreateCard(scrollChild, "Waypoint Finder", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Waypoint Finder", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if WF then
                if checked then NorskenUI:EnableModule("WayFinder") else NorskenUI:DisableModule("WayFinder") end
            end
        end,
        msgPopup = true,
        msgText = "Waypoint Finder",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    local separator = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(separator, Theme.rowHeightSeparator)

    local textRowSize = 50
    local row2 = GUIFrame:CreateRow(card1.content, textRowSize)
    local infoText = GUIFrame:CreateText(row2, NRSKNUI:ColorTextByTheme("How to Use"), {
        text = NRSKNUI:ColorTextByTheme("• ") ..
            "Converts /way <x> <y> to a blizzard waypoint on your current map.\n" ..
            NRSKNUI:ColorTextByTheme("• ") ..
            "For example, type |cffffffff/way 29.7 78.2|r and it will set a blizzard waypoint at those coordinates",
        height = textRowSize,
        bgMode = "hide",
    })
    row2:AddWidget(infoText, 1)
    card1:AddRow(row2, textRowSize)

    yOffset = card1:GetNextOffset()

    return yOffset
end)
