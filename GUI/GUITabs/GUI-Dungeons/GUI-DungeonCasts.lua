-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme or {}
local LSM = NRSKNUI.LSM

-- Localization
local pairs = pairs
local table_insert = table.insert

-- Get module reference
local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("DungeonCasts", true)
    end
    return nil
end

-- Preview state
local previewActive = false

-- Start preview
local function StartPreview()
    if previewActive then return end
    if not GUIFrame or not GUIFrame:IsShown() then return end

    previewActive = true
    local mod = GetModule()
    if mod and mod.ShowPreview then
        mod:ShowPreview()
    end
end

-- Stop preview
local function StopPreview()
    if not previewActive then return end

    previewActive = false
    local mod = GetModule()
    if mod and mod.HidePreview then
        mod:HidePreview()
    end
end

-- Register cleanup callbacks
GUIFrame.contentCleanupCallbacks = GUIFrame.contentCleanupCallbacks or {}
GUIFrame.contentCleanupCallbacks["DungeonCasts"] = StopPreview

GUIFrame.onCloseCallbacks = GUIFrame.onCloseCallbacks or {}
GUIFrame.onCloseCallbacks["DungeonCasts"] = StopPreview

-- DungeonCasts settings panel
GUIFrame:RegisterContent("DungeonCasts", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.DungeonCasts
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + (Theme.paddingMedium or 10)
    end

    local DC = GetModule()

    -- Track widgets for enable/disable logic
    local allWidgets = {}

    -- Build statusbar list from LSM
    local statusbarList = {}
    if LSM then
        for name in pairs(LSM:HashTable("statusbar")) do
            statusbarList[name] = name
        end
    else
        statusbarList["Blizzard"] = "Blizzard"
    end

    -- Build font list from LSM
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            fontList[name] = name
        end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    -- Helper to apply settings changes
    local function ApplySettings()
        if DC and DC.ApplySettings then
            DC:ApplySettings()
        end
    end

    -- Helper to apply position changes
    local function ApplyPosition()
        if DC and DC.ApplyPosition then
            DC:ApplyPosition()
        end
    end

    -- Helper to apply new state
    local function ApplyDungeonCastsState(enabled)
        if not DC then return end
        db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("DungeonCasts")
        else
            NorskenUI:DisableModule("DungeonCasts")
        end
    end

    -- Widget state update
    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    ----------------------------------------------------------------
    -- Card 1: Main Settings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Dungeon Casts", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Dungeon Casts", db.Enabled ~= false, function(checked)
        ApplyDungeonCastsState(checked)
        UpdateAllWidgetStates()
        ApplySettings()
    end)
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 40)

    yOffset = yOffset + card1:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 2: Frame Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Frame Settings", yOffset)

    local row2a = GUIFrame:CreateRow(card2.content, 40)
    local maxBarsSlider = GUIFrame:CreateSlider(row2a, "Max Bars", 1, 10, 1,
        db.Frame.MaxBars or 5, nil,
        function(value)
            db.Frame.MaxBars = value
            ApplySettings()
        end)
    row2a:AddWidget(maxBarsSlider, 0.5)
    table_insert(allWidgets, maxBarsSlider)

    local widthSlider = GUIFrame:CreateSlider(row2a, "Bar Width", 100, 400, 1,
        db.Frame.Width or 220, nil,
        function(value)
            db.Frame.Width = value
            ApplySettings()
        end)
    row2a:AddWidget(widthSlider, 0.5)
    table_insert(allWidgets, widthSlider)
    card2:AddRow(row2a, 40)

    local row2b = GUIFrame:CreateRow(card2.content, 40)
    local heightSlider = GUIFrame:CreateSlider(row2b, "Bar Height", 16, 40, 1,
        db.Frame.Height or 24, nil,
        function(value)
            db.Frame.Height = value
            ApplySettings()
        end)
    row2b:AddWidget(heightSlider, 0.5)
    table_insert(allWidgets, heightSlider)

    local spacingSlider = GUIFrame:CreateSlider(row2b, "Spacing", 0, 10, 1,
        db.Frame.Spacing or 2, nil,
        function(value)
            db.Frame.Spacing = value
            ApplySettings()
        end)
    row2b:AddWidget(spacingSlider, 0.5)
    table_insert(allWidgets, spacingSlider)
    card2:AddRow(row2b, 40)

    local row2c = GUIFrame:CreateRow(card2.content, 40)
    local growthOptions = { DOWN = "Down", UP = "Up" }
    local growthDropdown = GUIFrame:CreateDropdown(row2c, "Growth Direction", growthOptions,
        db.Frame.GrowthDirection or "DOWN", 70,
        function(selected)
            db.Frame.GrowthDirection = selected
            ApplySettings()
        end)
    row2c:AddWidget(growthDropdown, 1)
    table_insert(allWidgets, growthDropdown)
    card2:AddRow(row2c, 40)

    yOffset = yOffset + card2:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 3: Bar Appearance
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Bar Appearance", yOffset)

    local row3a = GUIFrame:CreateRow(card3.content, 40)
    local textureDropdown = GUIFrame:CreateDropdown(row3a, "Bar Texture", statusbarList,
        db.BarDisplay.StatusBarTexture or "NorskenUI", 70,
        function(selected)
            db.BarDisplay.StatusBarTexture = selected
            ApplySettings()
        end, { searchable = true })
    row3a:AddWidget(textureDropdown, 1)
    table_insert(allWidgets, textureDropdown)
    card3:AddRow(row3a, 40)

    local row3b = GUIFrame:CreateRow(card3.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(row3b, "Font", fontList,
        db.BarDisplay.FontFace or "Expressway", 70,
        function(selected)
            db.BarDisplay.FontFace = selected
            ApplySettings()
        end, { searchable = true })
    row3b:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local fontSizeSlider = GUIFrame:CreateSlider(row3b, "Font Size", 8, 24, 1,
        db.BarDisplay.FontSize or 12, nil,
        function(value)
            db.BarDisplay.FontSize = value
            ApplySettings()
        end)
    row3b:AddWidget(fontSizeSlider, 0.5)
    table_insert(allWidgets, fontSizeSlider)
    card3:AddRow(row3b, 40)

    local row3c = GUIFrame:CreateRow(card3.content, 40)
    local outlineOptions = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }
    local outlineDropdown = GUIFrame:CreateDropdown(row3c, "Font Outline", outlineOptions,
        db.BarDisplay.FontOutline or "OUTLINE", 70,
        function(selected)
            db.BarDisplay.FontOutline = selected
            ApplySettings()
        end)
    row3c:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)

    local sparkCheck = GUIFrame:CreateCheckbox(row3c, "Show Spark", db.BarDisplay.SparkEnabled ~= false,
        function(checked)
            db.BarDisplay.SparkEnabled = checked
            ApplySettings()
        end)
    row3c:AddWidget(sparkCheck, 0.5)
    table_insert(allWidgets, sparkCheck)
    card3:AddRow(row3c, 40)

    yOffset = yOffset + card3:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 4: Icon Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Icon Settings", yOffset)

    local row4a = GUIFrame:CreateRow(card4.content, 40)
    local iconCheck = GUIFrame:CreateCheckbox(row4a, "Show Spell Icon", db.Icon.Enabled ~= false, function(checked)
        db.Icon.Enabled = checked
        ApplySettings()
    end)
    row4a:AddWidget(iconCheck, 0.5)
    table_insert(allWidgets, iconCheck)

    local iconSizeSlider = GUIFrame:CreateSlider(row4a, "Icon Size", 16, 48, 1,
        db.Icon.Size or 24, nil,
        function(value)
            db.Icon.Size = value
            ApplySettings()
        end)
    row4a:AddWidget(iconSizeSlider, 0.5)
    table_insert(allWidgets, iconSizeSlider)
    card4:AddRow(row4a, 40)

    local row4b = GUIFrame:CreateRow(card4.content, 40)
    local raidIconCheck = GUIFrame:CreateCheckbox(row4b, "Show Raid Target Icon", db.RaidIcon.Enabled ~= false,
        function(checked)
            db.RaidIcon.Enabled = checked
            ApplySettings()
        end)
    row4b:AddWidget(raidIconCheck, 0.5)
    table_insert(allWidgets, raidIconCheck)

    local raidIconSizeSlider = GUIFrame:CreateSlider(row4b, "Raid Icon Size", 12, 40, 1,
        db.RaidIcon.Size or 20, nil,
        function(value)
            db.RaidIcon.Size = value
            ApplySettings()
        end)
    row4b:AddWidget(raidIconSizeSlider, 0.5)
    table_insert(allWidgets, raidIconSizeSlider)
    card4:AddRow(row4b, 40)

    yOffset = yOffset + card4:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 5: Colors
    ----------------------------------------------------------------
    local card5 = GUIFrame:CreateCard(scrollChild, "Colors", yOffset)

    local row5a = GUIFrame:CreateRow(card5.content, 40)
    local castingColorPicker = GUIFrame:CreateColorPicker(row5a, "Casting", db.CastingColor, function(r, g, b, a)
        db.CastingColor = { r, g, b, a }
        ApplySettings()
    end)
    row5a:AddWidget(castingColorPicker, 0.33)
    table_insert(allWidgets, castingColorPicker)

    local channelingColorPicker = GUIFrame:CreateColorPicker(row5a, "Channeling", db.ChannelingColor,
        function(r, g, b, a)
            db.ChannelingColor = { r, g, b, a }
            ApplySettings()
        end)
    row5a:AddWidget(channelingColorPicker, 0.33)
    table_insert(allWidgets, channelingColorPicker)

    local shieldedColorPicker = GUIFrame:CreateColorPicker(row5a, "Shielded", db.NotInterruptibleColor,
        function(r, g, b, a)
            db.NotInterruptibleColor = { r, g, b, a }
            ApplySettings()
        end)
    row5a:AddWidget(shieldedColorPicker, 0.34)
    table_insert(allWidgets, shieldedColorPicker)
    card5:AddRow(row5a, 40)

    local row5b = GUIFrame:CreateRow(card5.content, 40)
    local bgColorPicker = GUIFrame:CreateColorPicker(row5b, "Background", db.BackgroundColor, function(r, g, b, a)
        db.BackgroundColor = { r, g, b, a }
        ApplySettings()
    end)
    row5b:AddWidget(bgColorPicker, 0.33)
    table_insert(allWidgets, bgColorPicker)

    local borderColorPicker = GUIFrame:CreateColorPicker(row5b, "Border", db.BorderColor, function(r, g, b, a)
        db.BorderColor = { r, g, b, a }
        ApplySettings()
    end)
    row5b:AddWidget(borderColorPicker, 0.33)
    table_insert(allWidgets, borderColorPicker)

    local textColorPicker = GUIFrame:CreateColorPicker(row5b, "Text", db.Text.TextColor, function(r, g, b, a)
        db.Text.TextColor = { r, g, b, a }
        ApplySettings()
    end)
    row5b:AddWidget(textColorPicker, 0.34)
    table_insert(allWidgets, textColorPicker)
    card5:AddRow(row5b, 40)

    yOffset = yOffset + card5:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 6: Text Settings
    ----------------------------------------------------------------
    local card6 = GUIFrame:CreateCard(scrollChild, "Text Settings", yOffset)

    local row6a = GUIFrame:CreateRow(card6.content, 40)
    local showTimeCheck = GUIFrame:CreateCheckbox(row6a, "Show Cast Time", db.Text.ShowTime ~= false, function(checked)
        db.Text.ShowTime = checked
        ApplySettings()
    end)
    row6a:AddWidget(showTimeCheck, 1)
    table_insert(allWidgets, showTimeCheck)
    card6:AddRow(row6a, 40)

    yOffset = yOffset + card6:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 6b: Target Settings
    ----------------------------------------------------------------
    local card6b = GUIFrame:CreateCard(scrollChild, "Target Settings", yOffset)

    local row6b1 = GUIFrame:CreateRow(card6b.content, 40)
    local targetCheck = GUIFrame:CreateCheckbox(row6b1, "Show Cast Target", db.Target and db.Target.Enabled ~= false,
        function(checked)
            db.Target = db.Target or {}
            db.Target.Enabled = checked
            ApplySettings()
        end)
    row6b1:AddWidget(targetCheck, 0.5)
    table_insert(allWidgets, targetCheck)

    local classColorCheck = GUIFrame:CreateCheckbox(row6b1, "Use Class Colors",
        db.Target and db.Target.ShowClassColor ~= false, function(checked)
        db.Target = db.Target or {}
        db.Target.ShowClassColor = checked
        ApplySettings()
    end)
    row6b1:AddWidget(classColorCheck, 0.5)
    table_insert(allWidgets, classColorCheck)
    card6b:AddRow(row6b1, 40)

    local row6b2 = GUIFrame:CreateRow(card6b.content, 40)
    local positionOptions = { LEFT = "Left", RIGHT = "Right" }
    local positionDropdown = GUIFrame:CreateDropdown(row6b2, "Target Position", positionOptions,
        (db.Target and db.Target.Position) or "RIGHT", 70,
        function(selected)
            db.Target = db.Target or {}
            db.Target.Position = selected
            ApplySettings()
        end)
    row6b2:AddWidget(positionDropdown, 0.5)
    table_insert(allWidgets, positionDropdown)

    local separatorOptions = {
        ["»"] = "»",
        ["-"] = "-",
        [">"] = ">",
        [">>"] = ">>",
        ["•"] = "•",
        ["None"] = "None",
    }
    local separatorDropdown = GUIFrame:CreateDropdown(row6b2, "Separator", separatorOptions,
        (db.Target and db.Target.Separator) or "»", 70,
        function(selected)
            db.Target = db.Target or {}
            db.Target.Separator = selected
            ApplySettings()
        end)
    row6b2:AddWidget(separatorDropdown, 0.5)
    table_insert(allWidgets, separatorDropdown)
    card6b:AddRow(row6b2, 40)

    yOffset = yOffset + card6b:GetContentHeight() + (Theme.paddingMedium or 10)

    ----------------------------------------------------------------
    -- Card 7: Position
    ----------------------------------------------------------------
    local card7, newYOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db.Frame,
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
        onChangeCallback = ApplyPosition,
    })
    yOffset = newYOffset

    -- Apply initial widget states
    UpdateAllWidgetStates()

    -- Start preview when panel is shown
    StartPreview()

    return yOffset
end)
