---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("CustomSkin_Buffs", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return yOffset end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.BuffTracking
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type BuffTracking?
    local BUFFS = NorskenUI and NorskenUI:GetModule("BuffTracking", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings()
        if BUFFS and BUFFS:IsEnabled() and BUFFS.ApplySettings then
            BUFFS:ApplySettings()
        end
    end

    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Custom Buff Frame", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Custom Buff Frame", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if BUFFS then
                BUFFS.db.Enabled = checked
                if checked then
                    NorskenUI:EnableModule("BuffTracking")
                else
                    NorskenUI:DisableModule("BuffTracking")
                end
            end
            UpdateAllWidgetStates()
            NRSKNUI:CreateReloadPrompt("Enabling/Disabling this module requires a reload.")
        end,
        msgPopup = true,
        msgText = "Custom Buff Frame",
    })
    row1:AddWidget(enableCheck, (2 / 3))

    local previewBtn
    previewBtn = GUIFrame:CreateButton(row1, "Show Preview", {
        height = 30,
        callback = function()
            if BUFFS and BUFFS.TogglePreview then
                local isActive = BUFFS:TogglePreview()
                previewBtn:SetLabel(isActive and "Hide Preview" or "Show Preview")
            end
        end
    })
    row1:AddWidget(previewBtn, (1 / 3), nil, 0, -6)
    if BUFFS and BUFFS:IsPreviewActive() then previewBtn:SetLabel("Hide Preview") end
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2 = GUIFrame:CreateCard(scrollChild, "Icon Settings", yOffset)
    manager:Register(card2, "all")

    local row2ab = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local includeEnchantsCheck = GUIFrame:CreateCheckbox(row2ab, "Include Weapon Enchants", {
        value = db.IncludeWeaponEnchants,
        callback = function(checked)
            db.IncludeWeaponEnchants = checked
            NRSKNUI:CreateReloadPrompt("Changing this setting requires a reload.")
        end
    })
    row2ab:AddWidget(includeEnchantsCheck, 1)
    manager:Register(includeEnchantsCheck, "all")
    card2:AddRow(row2ab, Theme.rowHeight)

    local separator67 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(separator67, Theme.rowHeightSeparator)

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
        min = 16,
        max = 80,
        step = 1,
        value = db.IconSize,
        callback = function(value)
            db.IconSize = value
            NRSKNUI:CreateReloadPrompt("Changing icon size requires a reload.")
        end
    })
    row2a:AddWidget(iconSizeSlider, 0.5)
    manager:Register(iconSizeSlider, "all")

    local iconSpacingSlider = GUIFrame:CreateSlider(row2a, "Icon Spacing", {
        min = 0,
        max = 10,
        step = 1,
        value = db.IconSpacing,
        callback = function(value)
            db.IconSpacing = value
            NRSKNUI:CreateReloadPrompt("Changing icon spacing requires a reload.")
        end
    })
    row2a:AddWidget(iconSpacingSlider, 0.5)
    manager:Register(iconSpacingSlider, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local iconsPerRowSlider = GUIFrame:CreateSlider(row2b, "Icons Per Row", {
        min = 1,
        max = 20,
        step = 1,
        value = db.IconsPerRow,
        callback = function(value)
            db.IconsPerRow = value
            NRSKNUI:CreateReloadPrompt("Changing icons per row requires a reload.")
        end
    })
    row2b:AddWidget(iconsPerRowSlider, 0.5)
    manager:Register(iconsPerRowSlider, "all")

    local maxRowsSlider = GUIFrame:CreateSlider(row2b, "Max Rows", {
        min = 1,
        max = 10,
        step = 1,
        value = db.MaxRows,
        callback = function(value)
            db.MaxRows = value
            NRSKNUI:CreateReloadPrompt("Changing max rows requires a reload.")
        end
    })
    row2b:AddWidget(maxRowsSlider, 0.5)
    manager:Register(maxRowsSlider, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local separator6 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(separator6, Theme.rowHeightSeparator)

    local growthOptions = {
        { key = "LEFT_DOWN",  text = "Left, then Down" },
        { key = "LEFT_UP",    text = "Left, then Up" },
        { key = "RIGHT_DOWN", text = "Right, then Down" },
        { key = "RIGHT_UP",   text = "Right, then Up" },
        { key = "DOWN_LEFT",  text = "Down, then Left" },
        { key = "DOWN_RIGHT", text = "Down, then Right" },
        { key = "UP_LEFT",    text = "Up, then Left" },
        { key = "UP_RIGHT",   text = "Up, then Right" },
    }

    local row6b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local growthDropdown = GUIFrame:CreateDropdown(row6b, "Growth Direction", {
        options = growthOptions,
        value = db.GrowthDirection,
        callback = function(key)
            db.GrowthDirection = key
            NRSKNUI:CreateReloadPrompt("Changing growth direction requires a reload.")
        end
    })
    row6b:AddWidget(growthDropdown, (1 / 3))
    manager:Register(growthDropdown, "all")

    local sortMethodList = {
        { key = "TIME",  text = "Time" },
        { key = "NAME",  text = "Name" },
        { key = "INDEX", text = "Index" },
    }
    local sortMethodDropdown = GUIFrame:CreateDropdown(row6b, "Sort Method", {
        options = sortMethodList,
        value = db.SortMethod,
        callback = function(key)
            db.SortMethod = key
            NRSKNUI:CreateReloadPrompt("Changing sort method requires a reload.")
        end
    })
    row6b:AddWidget(sortMethodDropdown, (1 / 3))
    manager:Register(sortMethodDropdown, "all")

    local sortDirList = {
        { key = "-", text = "Descending" },
        { key = "+", text = "Ascending" },
    }
    local sortDirDropdown = GUIFrame:CreateDropdown(row6b, "Sort Direction", {
        options = sortDirList,
        value = db.SortDirection,
        callback = function(key)
            db.SortDirection = key
            NRSKNUI:CreateReloadPrompt("Changing sort direction requires a reload.")
        end
    })
    row6b:AddWidget(sortDirDropdown, (1 / 3))
    manager:Register(sortDirDropdown, "all")
    card2:AddRow(row6b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3
    local card3 = GUIFrame:CreateCard(scrollChild, "Color Settings", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local borderColorPicker = GUIFrame:CreateColorPicker(row3a, "Border Color", {
        color = db.BorderColor,
        callback = function(r, g, b, a)
            db.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(borderColorPicker, 0.5)
    manager:Register(borderColorPicker, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local enchantColorPicker = GUIFrame:CreateColorPicker(row3b, "Weapon Enchant Border", {
        color = db.EnchantBorderColor,
        callback = function(r, g, b, a)
            db.EnchantBorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3b:AddWidget(enchantColorPicker, 0.5)
    manager:Register(enchantColorPicker, "all")
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 5
    local card5 = GUIFrame:CreateCard(scrollChild, "Text Positions", yOffset)
    manager:Register(card5, "all")

    local textAnchorOptions = {
        { key = "TOPLEFT", text = "Top Left" },
        { key = "TOP", text = "Top" },
        { key = "TOPRIGHT", text = "Top Right" },
        { key = "LEFT", text = "Left" },
        { key = "CENTER", text = "Center" },
        { key = "RIGHT", text = "Right" },
        { key = "BOTTOMLEFT", text = "Bottom Left" },
        { key = "BOTTOM", text = "Bottom" },
        { key = "BOTTOMRIGHT", text = "Bottom Right" },
    }

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local timerAnchorDropdown = GUIFrame:CreateDropdown(row5a, "Timer Anchor", {
        options = textAnchorOptions,
        value = db.TimerPosition.AnchorFrom,
        callback = function(key)
            db.TimerPosition.AnchorFrom = key
            db.TimerPosition.AnchorTo = key
            ApplySettings()
        end
    })
    row5a:AddWidget(timerAnchorDropdown, 1 / 3)
    manager:Register(timerAnchorDropdown, "all")

    local timerXSlider = GUIFrame:CreateSlider(row5a, "Timer X", {
        min = -50,
        max = 50,
        step = 1,
        value = db.TimerPosition.XOffset,
        callback = function(value)
            db.TimerPosition.XOffset = value
            ApplySettings()
        end
    })
    row5a:AddWidget(timerXSlider, 1 / 3)
    manager:Register(timerXSlider, "all")

    local timerYSlider = GUIFrame:CreateSlider(row5a, "Timer Y", {
        min = -50,
        max = 50,
        step = 1,
        value = db.TimerPosition.YOffset,
        callback = function(value)
            db.TimerPosition.YOffset = value
            ApplySettings()
        end
    })
    row5a:AddWidget(timerYSlider, 1 / 3)
    manager:Register(timerYSlider, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local sep6a = GUIFrame:CreateSeparator(card5.content)
    card5:AddRow(sep6a, Theme.rowHeightSeparator)

    local row5stack = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local stackAnchorDropdown = GUIFrame:CreateDropdown(row5stack, "Stack Anchor", {
        options = textAnchorOptions,
        value = db.StackPosition.AnchorFrom,
        callback = function(key)
            db.StackPosition.AnchorFrom = key
            db.StackPosition.AnchorTo = key
            ApplySettings()
        end
    })
    row5stack:AddWidget(stackAnchorDropdown, 1 / 3)
    manager:Register(stackAnchorDropdown, "all")

    local stackXSlider = GUIFrame:CreateSlider(row5stack, "Stack X", {
        min = -50,
        max = 50,
        step = 1,
        value = db.StackPosition.XOffset,
        callback = function(value)
            db.StackPosition.XOffset = value
            ApplySettings()
        end
    })
    row5stack:AddWidget(stackXSlider, 1 / 3)
    manager:Register(stackXSlider, "all")

    local stackYSlider = GUIFrame:CreateSlider(row5stack, "Stack Y", {
        min = -50,
        max = 50,
        step = 1,
        value = db.StackPosition.YOffset,
        callback = function(value)
            db.StackPosition.YOffset = value
            ApplySettings()
        end
    })
    row5stack:AddWidget(stackYSlider, 1 / 3)
    manager:Register(stackYSlider, "all")
    card5:AddRow(row5stack, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    -- Card 4
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        title = "Font Settings",
        db = db,
        dbKeys = { fontFace = "FontFace", fontOutline = "FontOutline" },
        fontSizes = {
            { label = "Count Size", dbKey = "FontSize" },
            { label = "Timer Size", dbKey = "TimerFontSize" },
        },
        fontSizeRange = { 8, 32 },
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")

    yOffset = fontOffset

    -- Card 7
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function()
            if BUFFS and BUFFS.ApplyPosition then
                BUFFS:ApplyPosition()
            end
        end,
    })
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
