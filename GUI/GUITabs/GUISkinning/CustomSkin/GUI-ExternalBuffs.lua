-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM

-- Localization Setup
local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs

-- Helper to get ExternalBuffTracking module
local function GetExternalBuffTrackingModule()
    if NorskenUI then
        return NorskenUI:GetModule("ExternalBuffTracking", true)
    end
    return nil
end

----------------------------------------------------------------
-- EXTERNAL BUFFS TAB
----------------------------------------------------------------
GUIFrame:RegisterContent("CustomSkin_Externals", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return yOffset end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.ExternalBuffTracking
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local EXTERNALS = GetExternalBuffTrackingModule()
    local allWidgets = {}

    local function ApplySettings()
        if not EXTERNALS or not EXTERNALS:IsEnabled() then return end
        if EXTERNALS.ApplySettings then
            EXTERNALS:ApplySettings()
        end
    end

    local function ApplyExternalsState(enabled)
        if not EXTERNALS then return end
        EXTERNALS.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("ExternalBuffTracking")
        else
            NorskenUI:DisableModule("ExternalBuffTracking")
        end
    end

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    ----------------------------------------------------------------
    -- Card 1: Enable
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "External Buff Frame", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable External Buff Frame", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyExternalsState(checked)
            UpdateAllWidgetStates()
        end,
        true,
        "External Buff Frame",
        "On",
        "Off"
    )
    row1:AddWidget(enableCheck, 0.5)

    -- Preview toggle button
    local previewBtn
    previewBtn = GUIFrame:CreateButton(row1, "Show Preview", {
        width = 130,
        height = 28,
        callback = function()
            if EXTERNALS and EXTERNALS.TogglePreview then
                local isActive = EXTERNALS:TogglePreview()
                previewBtn:SetLabel(isActive and "Hide Preview" or "Show Preview")
            end
        end
    })
    row1:AddWidget(previewBtn, 0.5)

    -- Update button text based on current state
    if EXTERNALS and EXTERNALS:IsPreviewActive() then
        previewBtn:SetLabel("Hide Preview")
    end

    card1:AddRow(row1, 36)

    card1:AddLabel("Tracks external defensive buffs like Pain Suppression, Ironbark, etc.")

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Icon Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Icon Settings", yOffset)

    -- Icon Size slider
    local row2a = GUIFrame:CreateRow(card2.content, 40)
    local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", 16, 100, 1, db.IconSize or 50, nil,
        function(value)
            db.IconSize = value
            ApplySettings()
        end)
    row2a:AddWidget(iconSizeSlider, 0.5)
    table_insert(allWidgets, iconSizeSlider)

    -- Icon Spacing slider
    local iconSpacingSlider = GUIFrame:CreateSlider(row2a, "Icon Spacing", 0, 10, 1, db.IconSpacing or 2, nil,
        function(value)
            db.IconSpacing = value
            ApplySettings()
        end)
    row2a:AddWidget(iconSpacingSlider, 0.5)
    table_insert(allWidgets, iconSpacingSlider)
    card2:AddRow(row2a, 40)

    -- Icons Per Row slider
    local row2b = GUIFrame:CreateRow(card2.content, 40)
    local iconsPerRowSlider = GUIFrame:CreateSlider(row2b, "Icons Per Row", 1, 20, 1, db.IconsPerRow or 6, nil,
        function(value)
            db.IconsPerRow = value
            ApplySettings()
        end)
    row2b:AddWidget(iconsPerRowSlider, 0.5)
    table_insert(allWidgets, iconsPerRowSlider)

    -- Max Rows slider
    local maxRowsSlider = GUIFrame:CreateSlider(row2b, "Max Rows", 1, 5, 1, db.MaxRows or 1, nil,
        function(value)
            db.MaxRows = value
            ApplySettings()
        end)
    row2b:AddWidget(maxRowsSlider, 0.5)
    table_insert(allWidgets, maxRowsSlider)
    card2:AddRow(row2b, 40)

    -- Icon Zoom slider
    local row2c = GUIFrame:CreateRow(card2.content, 40)
    local iconZoomSlider = GUIFrame:CreateSlider(row2c, "Icon Zoom", 0, 0.5, 0.01, db.IconZoom or 0.32, nil,
        function(value)
            db.IconZoom = value
            ApplySettings()
        end)
    row2c:AddWidget(iconZoomSlider, 0.5)
    table_insert(allWidgets, iconZoomSlider)
    card2:AddRow(row2c, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Visual Settings
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Visual Settings", yOffset)

    -- Border Color
    local row3a = GUIFrame:CreateRow(card3.content, 40)
    local borderColorPicker = GUIFrame:CreateColorPicker(row3a, "Border Color", db.BorderColor,
        function(r, g, b, a)
            db.BorderColor = { r, g, b, a }
            ApplySettings()
        end)
    row3a:AddWidget(borderColorPicker, 0.5)
    table_insert(allWidgets, borderColorPicker)

    -- Background Color
    local bgColorPicker = GUIFrame:CreateColorPicker(row3a, "Background Color", db.BackgroundColor,
        function(r, g, b, a)
            db.BackgroundColor = { r, g, b, a }
            ApplySettings()
        end)
    row3a:AddWidget(bgColorPicker, 0.5)
    table_insert(allWidgets, bgColorPicker)
    card3:AddRow(row3a, 40)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Font Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)

    -- Font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    -- Font Face and Outline
    local row4a = GUIFrame:CreateRow(card4.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(row4a, "Font", fontList, db.FontFace, 30,
        function(key)
            db.FontFace = key
            ApplySettings()
        end, { searchable = true })
    row4a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineList = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick" }
    local outlineDropdown = GUIFrame:CreateDropdown(row4a, "Outline", outlineList, db.FontOutline or "OUTLINE", 45,
        function(key)
            db.FontOutline = key
            ApplySettings()
        end)
    row4a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card4:AddRow(row4a, 40)

    -- Font Size
    local row4b = GUIFrame:CreateRow(card4.content, 40)
    local fontSizeSlider = GUIFrame:CreateSlider(row4b, "Count Font Size", 8, 24, 1, db.FontSize or 14, nil,
        function(value)
            db.FontSize = value
            ApplySettings()
        end)
    row4b:AddWidget(fontSizeSlider, 0.5)
    table_insert(allWidgets, fontSizeSlider)

    -- Timer Font Size
    local timerFontSizeSlider = GUIFrame:CreateSlider(row4b, "Timer Font Size", 8, 32, 1, db.TimerFontSize or 16, nil,
        function(value)
            db.TimerFontSize = value
            ApplySettings()
        end)
    row4b:AddWidget(timerFontSizeSlider, 0.5)
    table_insert(allWidgets, timerFontSizeSlider)
    card4:AddRow(row4b, 40)

    -- Timer Position Offsets
    local timerPos = db.TimerPosition or {}
    local row4c = GUIFrame:CreateRow(card4.content, 40)
    local timerXSlider = GUIFrame:CreateSlider(row4c, "Timer X Offset", -50, 50, 1, timerPos.XOffset or 0, nil,
        function(value)
            db.TimerPosition = db.TimerPosition or {}
            db.TimerPosition.XOffset = value
            ApplySettings()
        end)
    row4c:AddWidget(timerXSlider, 0.5)
    table_insert(allWidgets, timerXSlider)

    local timerYSlider = GUIFrame:CreateSlider(row4c, "Timer Y Offset", -50, 50, 1, timerPos.YOffset or 0, nil,
        function(value)
            db.TimerPosition = db.TimerPosition or {}
            db.TimerPosition.YOffset = value
            ApplySettings()
        end)
    row4c:AddWidget(timerYSlider, 0.5)
    table_insert(allWidgets, timerYSlider)
    card4:AddRow(row4c, 40)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Sorting Options
    ----------------------------------------------------------------
    local card5 = GUIFrame:CreateCard(scrollChild, "Sorting Options", yOffset)

    -- Sort Method and Direction
    local row5a = GUIFrame:CreateRow(card5.content, 40)
    local sortMethodList = { ["TIME"] = "Time", ["NAME"] = "Name", ["INDEX"] = "Index" }
    local sortMethodDropdown = GUIFrame:CreateDropdown(row5a, "Sort Method", sortMethodList, db.SortMethod, 30,
        function(key)
            db.SortMethod = key
            if EXTERNALS and EXTERNALS:IsEnabled() and EXTERNALS.UpdateAuras then
                EXTERNALS:UpdateAuras()
            end
        end)
    row5a:AddWidget(sortMethodDropdown, 0.5)
    table_insert(allWidgets, sortMethodDropdown)

    local sortDirList = { ["-"] = "Descending", ["+"] = "Ascending" }
    local sortDirDropdown = GUIFrame:CreateDropdown(row5a, "Sort Direction", sortDirList, db.SortDirection, 30,
        function(key)
            db.SortDirection = key
            if EXTERNALS and EXTERNALS:IsEnabled() and EXTERNALS.UpdateAuras then
                EXTERNALS:UpdateAuras()
            end
        end)
    row5a:AddWidget(sortDirDropdown, 0.5)
    table_insert(allWidgets, sortDirDropdown)
    card5:AddRow(row5a, 40)

    yOffset = yOffset + card5:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 6: Position
    ----------------------------------------------------------------
    local card6 = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Position",
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
        onChangeCallback = function()
            local EXTERNALS = GetExternalBuffTrackingModule()
            if EXTERNALS and EXTERNALS.ApplyPosition then
                EXTERNALS:ApplyPosition()
            end
        end,
    })
    yOffset = yOffset + card6:GetContentHeight() + Theme.paddingSmall

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 3)
    return yOffset
end)
