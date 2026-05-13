---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("BenchAlert", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.BenchAlert
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type BenchAlert?
    local BA = NorskenUI and NorskenUI:GetModule("BenchAlert", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if BA then BA:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Bench Alert", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Bench Alert", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if BA then
                if checked then NorskenUI:EnableModule("BenchAlert") else NorskenUI:DisableModule("BenchAlert") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Bench Alert",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    local separator = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(separator, Theme.rowHeightSeparator)

    local textRowSize = Theme.rowHeight
    local row1b = GUIFrame:CreateRow(card1.content, textRowSize)
    local infoText = GUIFrame:CreateText(row1b, NRSKNUI:ColorTextByTheme("Functionality Info"), {
        text = NRSKNUI:ColorTextByTheme("• ") ..
            "Shows an alert when you are in a Mythic raid and assigned to group 8 (bench group).",
        height = textRowSize,
        bgMode = "hide",
    })
    row1b:AddWidget(infoText, 1)
    card1:AddRow(row1b, textRowSize)

    yOffset = card1:GetNextOffset()

    -- Card 2: Appearance
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local textInput = GUIFrame:CreateEditBox(row2a, "Alert Text", {
        value = db.Text,
        callback = function(value)
            db.Text = value
            ApplySettings()
            if BA and BA.alertFrame and BA.alertFrame.text then
                BA.alertFrame.text:SetText(value)
            end
        end,
        width = 150,
    })
    row2a:AddWidget(textInput, 0.5)
    manager:Register(textInput, "all")

    local colorPicker = GUIFrame:CreateColorPicker(row2a, "Alert Color", {
        color = db.Color,
        callback = function(r, g, b, a)
            db.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2a:AddWidget(colorPicker, 0.5)
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
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
