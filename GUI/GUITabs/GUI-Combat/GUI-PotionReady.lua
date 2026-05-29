---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("PotionReady", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.PotionReady
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type PotionReady?
    local POT = NorskenUI and NorskenUI:GetModule("PotionReady", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if POT then POT:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Potion Ready", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Potion Ready", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if POT then
                if checked then NorskenUI:EnableModule("PotionReady") else NorskenUI:DisableModule("PotionReady") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Potion Ready",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

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
            if POT and POT.alertFrame and POT.alertFrame.text then
                POT.alertFrame.text:SetText(value)
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
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
