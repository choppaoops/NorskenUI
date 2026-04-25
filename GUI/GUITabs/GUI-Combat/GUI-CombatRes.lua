---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs
local table_insert = table.insert

GUIFrame:RegisterContent("battleRes", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.BattleRes
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatRes?
    local CR = NorskenUI and NorskenUI:GetModule("CombatRes", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local backdropSubWidgets = {}

    local function ApplySettings()
        if CR and CR.ApplySettings then CR:ApplySettings() end
    end

    local function UpdateBackdropState()
        local backdropEnabled = db.Backdrop.Enabled
        for _, widget in ipairs(backdropSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(backdropEnabled) end
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
    local card1 = GUIFrame:CreateCard(scrollChild, "Battle Res Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Res Tracker", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if CR then
                if checked then NorskenUI:EnableModule("CombatRes") else NorskenUI:DisableModule("CombatRes") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Res Tracker",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Text Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Text Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local sepInput = GUIFrame:CreateEditBox(row2a, "Separator", {
        value = db.Separator,
        callback = function(val)
            db.Separator = val
            ApplySettings()
        end
    })
    row2a:AddWidget(sepInput, 0.5)
    manager:Register(sepInput, "all")

    local sepChargeInput = GUIFrame:CreateEditBox(row2a, "Charge Separator", {
        value = db.SeparatorCharges,
        callback = function(val)
            db.SeparatorCharges = val
            ApplySettings()
        end
    })
    row2a:AddWidget(sepChargeInput, 0.5)
    manager:Register(sepChargeInput, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local spacingSlider = GUIFrame:CreateSlider(row2b, "Text Spacing", {
        min = 0, max = 20, step = 1,
        value = db.TextSpacing,
        callback = function(val)
            db.TextSpacing = val
            ApplySettings()
        end
    })
    row2b:AddWidget(spacingSlider, 0.5)
    manager:Register(spacingSlider, "all")

    local growthDropdown = GUIFrame:CreateDropdown(row2b, "Growth Direction", {
        options = {
            { key = "LEFT", text = "Left" },
            { key = "RIGHT", text = "Right" },
        },
        value = db.GrowthDirection,
        callback = function(key)
            db.GrowthDirection = key
            ApplySettings()
        end
    })
    row2b:AddWidget(growthDropdown, 0.5)
    manager:Register(growthDropdown, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local sep2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep2, Theme.rowHeightSeparator)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local sepColor = GUIFrame:CreateColorPicker(row2c, "Separator", {
        color = db.SeparatorColor,
        callback = function(r, g, b, a)
            db.SeparatorColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(sepColor, 0.5)
    manager:Register(sepColor, "all")

    local timerColor = GUIFrame:CreateColorPicker(row2c, "Timer", {
        color = db.TimerColor,
        callback = function(r, g, b, a)
            db.TimerColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(timerColor, 0.5)
    manager:Register(timerColor, "all")
    card2:AddRow(row2c, Theme.rowHeight)

    local row2d = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local chargeAvailColor = GUIFrame:CreateColorPicker(row2d, "Charges Available", {
        color = db.ChargeAvailableColor,
        callback = function(r, g, b, a)
            db.ChargeAvailableColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2d:AddWidget(chargeAvailColor, 0.5)
    manager:Register(chargeAvailColor, "all")

    local chargeUnavailColor = GUIFrame:CreateColorPicker(row2d, "Charges Unavailable", {
        color = db.ChargeUnavailableColor,
        callback = function(r, g, b, a)
            db.ChargeUnavailableColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2d:AddWidget(chargeUnavailColor, 0.5)
    manager:Register(chargeUnavailColor, "all")
    card2:AddRow(row2d, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Backdrop
    local card3 = GUIFrame:CreateCard(scrollChild, "Backdrop", yOffset)
    manager:Register(card3, "all")
    table_insert(postUpdateCallbacks, UpdateBackdropState)

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local backdropCheck = GUIFrame:CreateCheckbox(row3a, "Enable Backdrop", {
        value = db.Backdrop.Enabled,
        callback = function(checked)
            db.Backdrop.Enabled = checked
            ApplySettings()
            UpdateBackdropState()
        end
    })
    row3a:AddWidget(backdropCheck, 0.34)
    manager:Register(backdropCheck, "all")

    local bgColor = GUIFrame:CreateColorPicker(row3a, "Background", {
        color = db.Backdrop.Color,
        callback = function(r, g, b, a)
            db.Backdrop.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(bgColor, 0.33)
    manager:Register(bgColor, "all")
    table_insert(backdropSubWidgets, bgColor)

    local borderColor = GUIFrame:CreateColorPicker(row3a, "Border", {
        color = db.Backdrop.BorderColor,
        callback = function(r, g, b, a)
            db.Backdrop.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(borderColor, 0.33)
    manager:Register(borderColor, "all")
    table_insert(backdropSubWidgets, borderColor)
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local frameWidthSlider = GUIFrame:CreateSlider(row3b, "Width", {
        min = 50, max = 300, step = 1,
        value = db.Backdrop.FrameWidth,
        callback = function(val)
            db.Backdrop.FrameWidth = val
            ApplySettings()
        end
    })
    row3b:AddWidget(frameWidthSlider, 0.5)
    manager:Register(frameWidthSlider, "all")
    table_insert(backdropSubWidgets, frameWidthSlider)

    local frameHeightSlider = GUIFrame:CreateSlider(row3b, "Height", {
        min = 16, max = 100, step = 1,
        value = db.Backdrop.FrameHeight,
        callback = function(val)
            db.Backdrop.FrameHeight = val
            ApplySettings()
        end
    })
    row3b:AddWidget(frameHeightSlider, 0.5)
    manager:Register(frameHeightSlider, "all")
    table_insert(backdropSubWidgets, frameHeightSlider)
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
