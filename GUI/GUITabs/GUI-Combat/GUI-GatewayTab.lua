---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("gateway", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Gateway
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type Gateway?
    local GATE = NorskenUI and NorskenUI:GetModule("Gateway", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function ApplySettings()
        if GATE and GATE.ApplySettings then GATE:ApplySettings() end
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
    local card1 = GUIFrame:CreateCard(scrollChild, "Gateway Usable Alert", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Gateway Alert", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if GATE then
                if checked then NorskenUI:EnableModule("Gateway") else NorskenUI:DisableModule("Gateway") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Gateway Alert",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Appearance
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local TextInput = GUIFrame:CreateEditBox(row2a, "Alert Text", {
        value = db.Text,
        callback = function(val)
            db.Text = val
            ApplySettings()
        end
    })
    row2a:AddWidget(TextInput, 0.5)
    manager:Register(TextInput, "all")

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
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

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
