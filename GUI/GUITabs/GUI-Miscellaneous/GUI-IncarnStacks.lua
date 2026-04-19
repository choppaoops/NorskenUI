-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM

-- Localization
local table_insert = table.insert
local pairs, ipairs = pairs, ipairs

-- Get IncarnStacks module
local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("IncarnStacks", true)
    end
    return nil
end

-- Register cleanup callback once
if not GUIFrame._incarnStacksCleanupRegistered then
    GUIFrame._incarnStacksCleanupRegistered = true
    GUIFrame:RegisterOnCloseCallback("IncarnStacks", function()
        local INCARN = GetModule()
        if INCARN and INCARN.HidePreview then
            INCARN:HidePreview()
        end
    end)
end

-- Register IncarnStacks tab content
GUIFrame:RegisterContent("IncarnStacks", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.IncarnStacks
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local INCARN = GetModule()
    local allWidgets = {}
    local glowWidgets = {}
    local timerWidgets = {}
    local stackWidgets = {}
    local card2, card3, card4, card5
    local card1EndY
    local calculatedTotalHeight

    local function ApplySettings()
        if INCARN and INCARN.ApplySettings then
            INCARN:ApplySettings()
        end
    end

    local function ApplyModuleState(enabled)
        if not INCARN then return end
        db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("IncarnStacks")
        else
            NorskenUI:DisableModule("IncarnStacks")
        end
    end

    local function UpdateGlowWidgetStates()
        local glowEnabled = db.GlowEnabled ~= false
        for _, widget in ipairs(glowWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(glowEnabled)
            end
        end
    end

    local function UpdateTimerWidgetStates()
        local timerEnabled = db.ShowTimer ~= false
        for _, widget in ipairs(timerWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(timerEnabled)
            end
        end
    end

    local function UpdateStackWidgetStates()
        local stackEnabled = db.ShowStacks ~= false
        for _, widget in ipairs(stackWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(stackEnabled)
            end
        end
    end

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false

        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end

        if mainEnabled then
            UpdateGlowWidgetStates()
            UpdateTimerWidgetStates()
            UpdateStackWidgetStates()
        end
    end

    ----------------------------------------------------------------
    -- Card 1: Enable & Preview
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Incarnation Stack Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Incarn Stack Tracker", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyModuleState(checked)
            UpdateAllWidgetStates()
        end,
        true, "Incarn Stacks", "On", "Off"
    )
    row1:AddWidget(enableCheck, 0.5)

    -- Preview toggle button
    local previewBtn
    previewBtn = GUIFrame:CreateButton(row1, "Show Preview", {
        width = 130,
        height = 28,
        callback = function()
            if INCARN and INCARN.TogglePreview then
                local isActive = INCARN:TogglePreview()
                previewBtn:SetLabel(isActive and "Hide Preview" or "Show Preview")
            end
        end
    })
    row1:AddWidget(previewBtn, 0.5)

    if INCARN and INCARN.IsPreviewActive and INCARN:IsPreviewActive() then
        previewBtn:SetLabel("Hide Preview")
    end

    card1:AddRow(row1, 36)
    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall
    card1EndY = yOffset

    ----------------------------------------------------------------
    -- Card 2: Display & Glow Settings
    ----------------------------------------------------------------
    card2 = GUIFrame:CreateCard(scrollChild, "Display & Glow Settings", yOffset)
    table_insert(allWidgets, card2)

    -- Icon Size Slider
    local row2a = GUIFrame:CreateRow(card2.content, 40)
    local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", 20, 100, 1,
        db.IconSize or 40, nil,
        function(val)
            db.IconSize = val
            ApplySettings()
        end)
    row2a:AddWidget(iconSizeSlider, 1)
    table_insert(allWidgets, iconSizeSlider)
    card2:AddRow(row2a, 40)

    -- Separator
    local rowSep1 = GUIFrame:CreateRow(card2.content, 8)
    local sep1 = GUIFrame:CreateSeparator(rowSep1)
    rowSep1:AddWidget(sep1, 1)
    table_insert(allWidgets, sep1)
    card2:AddRow(rowSep1, 8)

    -- Enable Glow Checkbox
    local row2b = GUIFrame:CreateRow(card2.content, 40)
    local enableGlowCheck = GUIFrame:CreateCheckbox(row2b, "Enable Glow Effect", db.GlowEnabled ~= false,
        function(checked)
            db.GlowEnabled = checked
            UpdateGlowWidgetStates()
            ApplySettings()
        end)
    row2b:AddWidget(enableGlowCheck, 0.5)
    table_insert(allWidgets, enableGlowCheck)
    card2:AddRow(row2b, 40)

    -- Glow Type and Color
    local row2c = GUIFrame:CreateRow(card2.content, 40)
    local glowTypeList = {
        { key = "pixel",    text = "Pixel Border" },
        { key = "autocast", text = "Auto Cast" },
        { key = "button",   text = "Button Glow" },
        { key = "proc",     text = "Proc Glow" },
    }
    local dynamicGlowRows = {}
    local dynamicStartY

    local function UpdateGlowLayout()
        local glowType = db.GlowType or "proc"
        local currentY = dynamicStartY

        for _, rowData in ipairs(dynamicGlowRows) do
            local shouldShow = false
            for _, validType in ipairs(rowData.types) do
                if glowType == validType then
                    shouldShow = true
                    break
                end
            end

            if shouldShow then
                rowData.row:ClearAllPoints()
                rowData.row:SetPoint("TOPLEFT", card2.content, "TOPLEFT", 0, -currentY)
                rowData.row:SetPoint("TOPRIGHT", card2.content, "TOPRIGHT", 0, -currentY)
                rowData.row:Show()
                currentY = currentY + rowData.height + Theme.paddingSmall
            else
                rowData.row:Hide()
            end
        end

        -- Update card2 height
        card2.currentY = currentY
        card2.content:SetHeight(currentY)
        card2:UpdateHeight()

        -- Reposition subsequent cards if they exist
        if card3 and card4 and card5 then
            local nextY = card1EndY + card2:GetContentHeight() + Theme.paddingSmall

            card3:ClearAllPoints()
            card3:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", Theme.paddingSmall, -nextY + Theme.paddingSmall)
            card3:SetPoint("RIGHT", scrollChild, "RIGHT", -Theme.paddingSmall, 0)
            nextY = nextY + card3:GetContentHeight() + Theme.paddingSmall

            card4:ClearAllPoints()
            card4:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", Theme.paddingSmall, -nextY + Theme.paddingSmall)
            card4:SetPoint("RIGHT", scrollChild, "RIGHT", -Theme.paddingSmall, 0)
            nextY = nextY + card4:GetContentHeight() + Theme.paddingSmall

            card5:ClearAllPoints()
            card5:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", Theme.paddingSmall, -nextY + Theme.paddingSmall)
            card5:SetPoint("RIGHT", scrollChild, "RIGHT", -Theme.paddingSmall, 0)
            nextY = nextY + card5:GetContentHeight() + Theme.paddingSmall

            calculatedTotalHeight = nextY - (Theme.paddingSmall * 2)
            scrollChild:SetHeight(calculatedTotalHeight + Theme.paddingLarge)
            if GUIFrame.UpdateScrollbar then
                GUIFrame:UpdateScrollbar()
            end
        end
    end

    local glowTypeDropdown = GUIFrame:CreateDropdown(row2c, "Glow Type", glowTypeList, db.GlowType or "proc", 45,
        function(key)
            db.GlowType = key
            UpdateGlowLayout()
            ApplySettings()
        end)
    row2c:AddWidget(glowTypeDropdown, 0.5)
    table_insert(allWidgets, glowTypeDropdown)
    table_insert(glowWidgets, glowTypeDropdown)

    local glowColorPicker = GUIFrame:CreateColorPicker(row2c, "Glow Color",
        db.GlowColor or { 0, 1, 0, 1 },
        function(r, g, b, a)
            db.GlowColor = { r, g, b, a }
            ApplySettings()
        end)
    row2c:AddWidget(glowColorPicker, 0.5)
    table_insert(allWidgets, glowColorPicker)
    table_insert(glowWidgets, glowColorPicker)
    card2:AddRow(row2c, 40)

    -- Store where dynamic rows start
    dynamicStartY = card2.currentY

    -- X/Y Offset (pixel, autocast, proc)
    local rowGlowOffset = GUIFrame:CreateRow(card2.content, 40)
    local glowXSlider = GUIFrame:CreateSlider(rowGlowOffset, "X Offset", -100, 100, 0.5,
        db.GlowXOffset or 0, nil, function(val)
            db.GlowXOffset = val
            ApplySettings()
        end)
    rowGlowOffset:AddWidget(glowXSlider, 0.5)
    table_insert(allWidgets, glowXSlider)
    table_insert(glowWidgets, glowXSlider)

    local glowYSlider = GUIFrame:CreateSlider(rowGlowOffset, "Y Offset", -100, 100, 0.5,
        db.GlowYOffset or 0, nil, function(val)
            db.GlowYOffset = val
            ApplySettings()
        end)
    rowGlowOffset:AddWidget(glowYSlider, 0.5)
    table_insert(allWidgets, glowYSlider)
    table_insert(glowWidgets, glowYSlider)
    table_insert(dynamicGlowRows, { row = rowGlowOffset, height = 40, types = { "pixel", "autocast", "proc" } })

    -- Lines & Frequency (pixel, autocast)
    local rowGlowLinesFreq = GUIFrame:CreateRow(card2.content, 40)
    local glowLinesSlider = GUIFrame:CreateSlider(rowGlowLinesFreq, "Lines", 1, 30, 1,
        db.GlowLines or 8, nil, function(val)
            db.GlowLines = val
            ApplySettings()
        end)
    rowGlowLinesFreq:AddWidget(glowLinesSlider, 0.5)
    table_insert(allWidgets, glowLinesSlider)
    table_insert(glowWidgets, glowLinesSlider)

    local glowFreqSlider = GUIFrame:CreateSlider(rowGlowLinesFreq, "Frequency", -2, 2, 0.05,
        db.GlowFrequency or 0.25, nil, function(val)
            db.GlowFrequency = val
            ApplySettings()
        end)
    rowGlowLinesFreq:AddWidget(glowFreqSlider, 0.5)
    table_insert(allWidgets, glowFreqSlider)
    table_insert(glowWidgets, glowFreqSlider)
    table_insert(dynamicGlowRows, { row = rowGlowLinesFreq, height = 40, types = { "pixel", "autocast" } })

    -- Pixel only: Length & Thickness
    local rowGlowPixel = GUIFrame:CreateRow(card2.content, 40)
    local glowLengthSlider = GUIFrame:CreateSlider(rowGlowPixel, "Length", 1, 20, 0.5,
        db.GlowLength or 10, nil, function(val)
            db.GlowLength = val
            ApplySettings()
        end)
    rowGlowPixel:AddWidget(glowLengthSlider, 0.5)
    table_insert(allWidgets, glowLengthSlider)
    table_insert(glowWidgets, glowLengthSlider)

    local glowThicknessSlider = GUIFrame:CreateSlider(rowGlowPixel, "Thickness", 0.05, 20, 0.05,
        db.GlowThickness or 1, nil, function(val)
            db.GlowThickness = val
            ApplySettings()
        end)
    rowGlowPixel:AddWidget(glowThicknessSlider, 0.5)
    table_insert(allWidgets, glowThicknessSlider)
    table_insert(glowWidgets, glowThicknessSlider)
    table_insert(dynamicGlowRows, { row = rowGlowPixel, height = 40, types = { "pixel" } })

    -- Pixel only: Border toggle
    local rowGlowBorder = GUIFrame:CreateRow(card2.content, 40)
    local glowBorderCheck = GUIFrame:CreateCheckbox(rowGlowBorder, "Show Border", db.GlowBorder or false,
        function(checked)
            db.GlowBorder = checked
            ApplySettings()
        end)
    rowGlowBorder:AddWidget(glowBorderCheck, 1)
    table_insert(allWidgets, glowBorderCheck)
    table_insert(glowWidgets, glowBorderCheck)
    table_insert(dynamicGlowRows, { row = rowGlowBorder, height = 40, types = { "pixel" } })

    -- AutoCast only: Scale
    local rowGlowScale = GUIFrame:CreateRow(card2.content, 40)
    local glowScaleSlider = GUIFrame:CreateSlider(rowGlowScale, "Scale", 0.05, 10, 0.05,
        db.GlowScale or 1, nil, function(val)
            db.GlowScale = val
            ApplySettings()
        end)
    rowGlowScale:AddWidget(glowScaleSlider, 1)
    table_insert(allWidgets, glowScaleSlider)
    table_insert(glowWidgets, glowScaleSlider)
    table_insert(dynamicGlowRows, { row = rowGlowScale, height = 40, types = { "autocast" } })

    -- Proc only: Duration & Start Animation
    local rowGlowProc = GUIFrame:CreateRow(card2.content, 40)
    local glowDurationSlider = GUIFrame:CreateSlider(rowGlowProc, "Duration", 0.01, 3, 0.05,
        db.GlowDuration or 1, nil, function(val)
            db.GlowDuration = val
            ApplySettings()
        end)
    rowGlowProc:AddWidget(glowDurationSlider, 0.5)
    table_insert(allWidgets, glowDurationSlider)
    table_insert(glowWidgets, glowDurationSlider)

    local glowStartAnimCheck = GUIFrame:CreateCheckbox(rowGlowProc, "Start Animation", db.GlowStartAnim or false,
        function(checked)
            db.GlowStartAnim = checked
            ApplySettings()
        end)
    rowGlowProc:AddWidget(glowStartAnimCheck, 0.5)
    table_insert(allWidgets, glowStartAnimCheck)
    table_insert(glowWidgets, glowStartAnimCheck)
    table_insert(dynamicGlowRows, { row = rowGlowProc, height = 40, types = { "proc" } })

    -- Button only: Frequency
    local rowGlowButtonFreq = GUIFrame:CreateRow(card2.content, 40)
    local glowButtonFreqSlider = GUIFrame:CreateSlider(rowGlowButtonFreq, "Frequency", -2, 2, 0.05,
        db.GlowFrequency or 0.25, nil, function(val)
            db.GlowFrequency = val
            ApplySettings()
        end)
    rowGlowButtonFreq:AddWidget(glowButtonFreqSlider, 1)
    table_insert(allWidgets, glowButtonFreqSlider)
    table_insert(glowWidgets, glowButtonFreqSlider)
    table_insert(dynamicGlowRows, { row = rowGlowButtonFreq, height = 40, types = { "button" } })

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Stack Text Settings
    ----------------------------------------------------------------
    card3 = GUIFrame:CreateCard(scrollChild, "Stack Count Settings", yOffset)
    table_insert(allWidgets, card3)

    -- Show Stacks Checkbox and Color
    local row3a = GUIFrame:CreateRow(card3.content, 40)
    local showStacksCheck = GUIFrame:CreateCheckbox(row3a, "Show Stack Count", db.ShowStacks ~= false,
        function(checked)
            db.ShowStacks = checked
            UpdateStackWidgetStates()
            ApplySettings()
        end)
    row3a:AddWidget(showStacksCheck, 0.5)
    table_insert(allWidgets, showStacksCheck)

    local stackColorPicker = GUIFrame:CreateColorPicker(row3a, "Stack Color",
        db.StackTextColor or { 1, 1, 1, 1 },
        function(r, g, b, a)
            db.StackTextColor = { r, g, b, a }
            ApplySettings()
        end)
    row3a:AddWidget(stackColorPicker, 0.5)
    table_insert(allWidgets, stackColorPicker)
    table_insert(stackWidgets, stackColorPicker)
    card3:AddRow(row3a, 40)

    -- Separator
    local rowSep2 = GUIFrame:CreateRow(card3.content, 8)
    local sep2 = GUIFrame:CreateSeparator(rowSep2)
    rowSep2:AddWidget(sep2, 1)
    table_insert(allWidgets, sep2)
    card3:AddRow(rowSep2, 8)

    -- Font lookup
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    -- Outline list
    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }

    -- Stack Font and Size
    local row3b = GUIFrame:CreateRow(card3.content, 40)
    local stackFontDropdown = GUIFrame:CreateDropdown(row3b, "Font", fontList, db.StackFontFace or "Expressway", 30,
        function(key)
            db.StackFontFace = key
            ApplySettings()
        end, true)
    row3b:AddWidget(stackFontDropdown, 0.5)
    table_insert(allWidgets, stackFontDropdown)
    table_insert(stackWidgets, stackFontDropdown)

    local stackFontSizeSlider = GUIFrame:CreateSlider(card3.content, "Font Size", 8, 36, 1, db.StackFontSize or 18, 60,
        function(val)
            db.StackFontSize = val
            ApplySettings()
        end)
    row3b:AddWidget(stackFontSizeSlider, 0.5)
    table_insert(allWidgets, stackFontSizeSlider)
    table_insert(stackWidgets, stackFontSizeSlider)
    card3:AddRow(row3b, 40)

    -- Stack Font Outline
    local row3c = GUIFrame:CreateRow(card3.content, 36)
    local stackOutlineDropdown = GUIFrame:CreateDropdown(row3c, "Outline", outlineList, db.StackFontOutline or "OUTLINE",
        45,
        function(key)
            db.StackFontOutline = key
            ApplySettings()
        end)
    row3c:AddWidget(stackOutlineDropdown, 1)
    table_insert(allWidgets, stackOutlineDropdown)
    table_insert(stackWidgets, stackOutlineDropdown)
    card3:AddRow(row3c, 36)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Timer Settings
    ----------------------------------------------------------------
    card4 = GUIFrame:CreateCard(scrollChild, "Timer Settings", yOffset)
    table_insert(allWidgets, card4)

    -- Show Timer Checkbox and Color
    local row4a = GUIFrame:CreateRow(card4.content, 40)
    local showTimerCheck = GUIFrame:CreateCheckbox(row4a, "Show Timer Text", db.ShowTimer ~= false,
        function(checked)
            db.ShowTimer = checked
            UpdateTimerWidgetStates()
            ApplySettings()
        end)
    row4a:AddWidget(showTimerCheck, 0.5)
    table_insert(allWidgets, showTimerCheck)

    local timerColorPicker = GUIFrame:CreateColorPicker(row4a, "Timer Color",
        db.TimerTextColor or { 1, 1, 1, 1 },
        function(r, g, b, a)
            db.TimerTextColor = { r, g, b, a }
            ApplySettings()
        end)
    row4a:AddWidget(timerColorPicker, 0.5)
    table_insert(allWidgets, timerColorPicker)
    table_insert(timerWidgets, timerColorPicker)
    card4:AddRow(row4a, 40)

    -- Separator
    local rowSep3 = GUIFrame:CreateRow(card4.content, 8)
    local sep3 = GUIFrame:CreateSeparator(rowSep3)
    rowSep3:AddWidget(sep3, 1)
    table_insert(allWidgets, sep3)
    card4:AddRow(rowSep3, 8)

    -- Timer Font and Size
    local row4b = GUIFrame:CreateRow(card4.content, 40)
    local timerFontDropdown = GUIFrame:CreateDropdown(row4b, "Font", fontList, db.TimerFontFace or "Expressway", 30,
        function(key)
            db.TimerFontFace = key
            ApplySettings()
        end, true)
    row4b:AddWidget(timerFontDropdown, 0.5)
    table_insert(allWidgets, timerFontDropdown)
    table_insert(timerWidgets, timerFontDropdown)

    local timerFontSizeSlider = GUIFrame:CreateSlider(card4.content, "Font Size", 8, 36, 1, db.TimerFontSize or 16, 60,
        function(val)
            db.TimerFontSize = val
            ApplySettings()
        end)
    row4b:AddWidget(timerFontSizeSlider, 0.5)
    table_insert(allWidgets, timerFontSizeSlider)
    table_insert(timerWidgets, timerFontSizeSlider)
    card4:AddRow(row4b, 40)

    -- Timer Font Outline
    local row4c = GUIFrame:CreateRow(card4.content, 36)
    local timerOutlineDropdown = GUIFrame:CreateDropdown(row4c, "Outline", outlineList,
        db.TimerFontOutline or "SOFTOUTLINE", 45,
        function(key)
            db.TimerFontOutline = key
            ApplySettings()
        end)
    row4c:AddWidget(timerOutlineDropdown, 1)
    table_insert(allWidgets, timerOutlineDropdown)
    table_insert(timerWidgets, timerOutlineDropdown)
    card4:AddRow(row4c, 36)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Position Settings
    ----------------------------------------------------------------
    local newOffset
    card5, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        dbKeys = {
            anchorFrameType = "anchorFrameType",
            anchorFrameFrame = "ParentFrame",
            selfPoint = "AnchorFrom",
            anchorPoint = "AnchorTo",
            xOffset = "XOffset",
            yOffset = "YOffset",
            strata = "Strata",
        },
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })

    if card5.positionWidgets then
        for _, widget in ipairs(card5.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, card5)

    yOffset = newOffset

    -- Apply initial glow layout
    UpdateGlowLayout()
    UpdateAllWidgetStates()
    return calculatedTotalHeight or (yOffset - (Theme.paddingSmall * 2))
end)
