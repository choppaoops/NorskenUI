---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs
local table_insert = table.insert

GUIFrame:RegisterContent("combatCross", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.CombatCross
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatCross?
    local CC = NorskenUI and NorskenUI:GetModule("CombatCross", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local colorModeWidgets = {}
    local rangeColorWidgets = {}

    local function ApplySettings()
        if CC and CC.ApplySettings then CC:ApplySettings() end
    end

    local function UpdateColorModeState()
        local isCustomColor = db.ColorMode == "custom"
        for _, widget in ipairs(colorModeWidgets) do
            if widget.SetEnabled then widget:SetEnabled(isCustomColor) end
        end
    end

    local function UpdateRangeState()
        local isRangeEnabled = db.RangeColorMeleeEnabled or db.RangeColorRangedEnabled
        for _, widget in ipairs(rangeColorWidgets) do
            if widget.SetEnabled then widget:SetEnabled(isRangeEnabled) end
        end
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
    local card1 = GUIFrame:CreateCard(scrollChild, "Combat Cross", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Cross", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if CC then
                if checked then NorskenUI:EnableModule("CombatCross") else NorskenUI:DisableModule("CombatCross") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Cross",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Appearance
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local sizeSlider = GUIFrame:CreateSlider(row2a, "Size", {
        min = 8, max = 72, step = 1,
        value = db.Thickness,
        callback = function(val)
            db.Thickness = val
            ApplySettings()
        end
    })
    row2a:AddWidget(sizeSlider, 0.5)
    manager:Register(sizeSlider, "all")

    local outlineCheck = GUIFrame:CreateCheckbox(row2a, "Font Outline", {
        value = db.Outline,
        callback = function(checked)
            db.Outline = checked
            ApplySettings()
        end
    })
    row2a:AddWidget(outlineCheck, 0.5)
    manager:Register(outlineCheck, "all")
    card2:AddRow(row2a, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Color
    local card3 = GUIFrame:CreateCard(scrollChild, "Color", yOffset)
    manager:Register(card3, "all")
    table_insert(postUpdateCallbacks, UpdateColorModeState)

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local colorModeDropdown = GUIFrame:CreateDropdown(row3a, "Color Mode", {
        options = NRSKNUI.ColorModeOptions,
        value = db.ColorMode,
        callback = function(key)
            db.ColorMode = key
            ApplySettings()
            UpdateColorModeState()
        end
    })
    row3a:AddWidget(colorModeDropdown, 0.5)
    manager:Register(colorModeDropdown, "all")

    local colorPicker = GUIFrame:CreateColorPicker(row3a, "Custom Color", {
        color = db.Color,
        callback = function(r, g, b, a)
            db.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(colorPicker, 0.5)
    manager:Register(colorPicker, "all")
    table_insert(colorModeWidgets, colorPicker)
    card3:AddRow(row3a, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: Range Warning
    local card4 = GUIFrame:CreateCard(scrollChild, "Range Warning", yOffset)
    manager:Register(card4, "all")
    table_insert(postUpdateCallbacks, UpdateRangeState)

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local meleeRangeCheck = GUIFrame:CreateCheckbox(row4a, "Enable for melee specs", {
        value = db.RangeColorMeleeEnabled,
        callback = function(checked)
            db.RangeColorMeleeEnabled = checked
            ApplySettings()
            UpdateRangeState()
        end
    })
    row4a:AddWidget(meleeRangeCheck, 0.5)
    manager:Register(meleeRangeCheck, "all")

    local rangedRangeCheck = GUIFrame:CreateCheckbox(row4a, "Enable for ranged specs", {
        value = db.RangeColorRangedEnabled,
        callback = function(checked)
            db.RangeColorRangedEnabled = checked
            ApplySettings()
            UpdateRangeState()
        end
    })
    row4a:AddWidget(rangedRangeCheck, 0.5)
    manager:Register(rangedRangeCheck, "all")
    card4:AddRow(row4a, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local outOfRangeColorPicker = GUIFrame:CreateColorPicker(row4b, "Out of Range Color", {
        color = db.OutOfRangeColor,
        callback = function(r, g, b, a)
            db.OutOfRangeColor = { r, g, b, a }
            if CC then CC.lastInRange = nil end
        end
    })
    row4b:AddWidget(outOfRangeColorPicker, 1)
    manager:Register(outOfRangeColorPicker, "all")
    table_insert(rangeColorWidgets, outOfRangeColorPicker)
    card4:AddRow(row4b, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5: Position
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
