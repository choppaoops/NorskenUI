---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("HuntersMark", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.HuntersMark
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type HuntersMark?
    local HUNTMARK = NorskenUI and NorskenUI:GetModule("HuntersMark", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings()
        if HUNTMARK and HUNTMARK.ApplySettings then HUNTMARK:ApplySettings() end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Hunters Mark Tracking", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Hunters Mark Tracking", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if HUNTMARK then
                if checked then NorskenUI:EnableModule("HuntersMark") else NorskenUI:DisableModule("HuntersMark") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Hunters Mark Tracking",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    local sep1 = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(sep1, Theme.rowHeightSeparator)

    local textRowSize = 55
    local infoRow = GUIFrame:CreateRow(card1.content, textRowSize)
    local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Functionality Info"), {
        text = NRSKNUI:ColorTextByTheme("• ") ..
            "Loads in raid instances when out of combat.\n" ..
            NRSKNUI:ColorTextByTheme("• ") ..
            "Scans for nameplates that belong to bosses and checks if they have a mark on them or not from the player",
        height = textRowSize,
        bgMode = "hide"
    })
    infoRow:AddWidget(infoText, 1)
    manager:Register(infoText, "all")
    card1:AddRow(infoRow, textRowSize, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Text Color
    local card2 = GUIFrame:CreateCard(scrollChild, "Text Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local colorPicker = GUIFrame:CreateColorPicker(row2a, "Alert Color", {
        color = db.Color,
        callback = function(r, g, b, a)
            db.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2a:AddWidget(colorPicker, 1)
    manager:Register(colorPicker, "all")
    card2:AddRow(row2a, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")

    yOffset = fontOffset

    -- Card 4: Position
    local card4, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(card4, "all")
    if card4.positionWidgets then manager:RegisterGroup(card4.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
