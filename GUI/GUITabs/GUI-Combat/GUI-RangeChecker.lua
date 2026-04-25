---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("RangeChecker", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.RangeChecker
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type RangeChecker?
    local RANGE = NorskenUI and NorskenUI:GetModule("RangeChecker", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function ApplySettings()
        if RANGE and RANGE.ApplySettings then RANGE:ApplySettings() end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do callback() end
        end
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Range Checker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Range Checker", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if RANGE then
                if checked then NorskenUI:EnableModule("RangeChecker") else NorskenUI:DisableModule("RangeChecker") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Range Checker",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: General Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "General Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local combatOnlyCheck = GUIFrame:CreateCheckbox(row2a, "Show In Combat Only", {
        value = db.CombatOnly,
        callback = function(checked)
            db.CombatOnly = checked
            ApplySettings()
        end
    })
    row2a:AddWidget(combatOnlyCheck, 1)
    manager:Register(combatOnlyCheck, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local throttleSlider = GUIFrame:CreateSlider(row2b, "Update Throttle", {
        min = 0,
        max = 1,
        step = 0.05,
        value = db.UpdateThrottle,
        callback = function(val)
            db.UpdateThrottle = val
        end
    })
    row2b:AddWidget(throttleSlider, 1)
    manager:Register(throttleSlider, "all")
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Color Settings
    local card3 = GUIFrame:CreateCard(scrollChild, "Color Gradient", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local colorOnePicker = GUIFrame:CreateColorPicker(row3a, "Far (40+ yards)", {
        color = db.ColorOne,
        callback = function(r, g, b, a)
            db.ColorOne = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(colorOnePicker, 0.5)
    manager:Register(colorOnePicker, "all")

    local colorTwoPicker = GUIFrame:CreateColorPicker(row3a, "Mid-Far (20-40)", {
        color = db.ColorTwo,
        callback = function(r, g, b, a)
            db.ColorTwo = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(colorTwoPicker, 0.5)
    manager:Register(colorTwoPicker, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local colorThreePicker = GUIFrame:CreateColorPicker(row3b, "Mid-Close (10-20)", {
        color = db.ColorThree,
        callback = function(r, g, b, a)
            db.ColorThree = { r, g, b, a }
            ApplySettings()
        end
    })
    row3b:AddWidget(colorThreePicker, 0.5)
    manager:Register(colorThreePicker, "all")

    local colorFourPicker = GUIFrame:CreateColorPicker(row3b, "Close (0-10)", {
        color = db.ColorFour,
        callback = function(r, g, b, a)
            db.ColorFour = { r, g, b, a }
            ApplySettings()
        end
    })
    row3b:AddWidget(colorFourPicker, 0.5)
    manager:Register(colorFourPicker, "all")
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 5: Position
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
