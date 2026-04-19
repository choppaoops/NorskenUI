-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM or LibStub("LibSharedMedia-3.0", true)

-- Localization
local table_insert = table.insert
local ipairs = ipairs

-- Helper to get HealerMana module
local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("HealerMana", true)
    end
    return nil
end

-- Register HealerMana tab content
GUIFrame:RegisterContent("HealerMana", function(scrollChild, yOffset)
    -- Safety check for database
    local db = NRSKNUI.db and NRSKNUI.db.profile.HealerMana
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local HM = GetModule()

    -- Apply settings
    local function ApplySettings()
        if HM then
            HM:UpdateDB()
            HM:ApplySettings()
        end
    end

    -- Refresh (recreate frames)
    local function Refresh()
        if HM then
            HM:Refresh()
        end
    end

    -- Helper to apply enable state
    local function ApplyEnableState(enabled)
        if not HM then return end
        HM.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("HealerMana")
        else
            NorskenUI:DisableModule("HealerMana")
        end
    end

    -- Track widgets for enable/disable logic
    local allWidgets = {}

    -- Update all widget states based on main toggle
    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    ----------------------------------------------------------------
    -- Card 1: General Settings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Healer Mana Tracker", yOffset)

    -- Enable Checkbox
    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Healer Mana Tracker", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyEnableState(checked)
            UpdateAllWidgetStates()
        end,
        true,
        "Healer Mana",
        "On",
        "Off"
    )
    row1:AddWidget(enableCheck, 0.5)
    card1:AddRow(row1, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Size Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Size Settings", yOffset)
    table_insert(allWidgets, card2)

    -- Icon Size
    local rowIcon = GUIFrame:CreateRow(card2.content, 36)
    local iconSlider = GUIFrame:CreateSlider(rowIcon, "Icon Size", 16, 64, 1, db.IconSize, 30, function(value)
        db.IconSize = value
        Refresh()
    end)
    rowIcon:AddWidget(iconSlider, 1)
    table_insert(allWidgets, iconSlider)
    card2:AddRow(rowIcon, 36)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Name Text Settings
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Name Text", yOffset)
    table_insert(allWidgets, card3)

    -- Name Font Size + X Offset
    local rowName1 = GUIFrame:CreateRow(card3.content, 36)
    local nameSizeSlider = GUIFrame:CreateSlider(rowName1, "Font Size", 8, 44, 1, db.NameFontSize, 30, function(value)
        db.NameFontSize = value
        Refresh()
    end)
    rowName1:AddWidget(nameSizeSlider, 1)
    table_insert(allWidgets, nameSizeSlider)
    card3:AddRow(rowName1, 36)

    -- Separator
    local sepRow = GUIFrame:CreateRow(card3.content, 8)
    local sep = GUIFrame:CreateSeparator(sepRow)
    sepRow:AddWidget(sep, 1)
    card3:AddRow(sepRow, 8)

    local rowName3 = GUIFrame:CreateRow(card3.content, 36)
    local nameXSlider = GUIFrame:CreateSlider(rowName3, "X Offset", -40, 40, 1, db.NameXOffset, 30, function(value)
        db.NameXOffset = value
        Refresh()
    end)
    rowName3:AddWidget(nameXSlider, 0.5)
    table_insert(allWidgets, nameXSlider)

    -- Name Y Offset
    local nameYSlider = GUIFrame:CreateSlider(rowName3, "Y Offset", -40, 40, 1, db.NameYOffset, 30, function(value)
        db.NameYOffset = value
        Refresh()
    end)
    rowName3:AddWidget(nameYSlider, 0.5)
    table_insert(allWidgets, nameYSlider)
    card3:AddRow(rowName3, 36)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Mana Text Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Mana Text", yOffset)
    table_insert(allWidgets, card4)

    -- Mana Font Size + X Offset
    local rowMana1 = GUIFrame:CreateRow(card4.content, 36)
    local manaSizeSlider = GUIFrame:CreateSlider(rowMana1, "Font Size", 8, 44, 1, db.ManaFontSize, 30, function(value)
        db.ManaFontSize = value
        Refresh()
    end)
    rowMana1:AddWidget(manaSizeSlider, 1)
    table_insert(allWidgets, manaSizeSlider)
    card4:AddRow(rowMana1, 36)

    -- Separator
    local sepRow2 = GUIFrame:CreateRow(card4.content, 8)
    local sep2 = GUIFrame:CreateSeparator(sepRow2)
    sepRow2:AddWidget(sep2, 1)
    card4:AddRow(sepRow2, 8)

    local rowMana2 = GUIFrame:CreateRow(card4.content, 36)
    local manaXSlider = GUIFrame:CreateSlider(rowMana2, "X Offset", -40, 40, 1, db.ManaXOffset, 30, function(value)
        db.ManaXOffset = value
        Refresh()
    end)
    rowMana2:AddWidget(manaXSlider, 0.5)
    table_insert(allWidgets, manaXSlider)

    -- Mana Y Offset
    local manaYSlider = GUIFrame:CreateSlider(rowMana2, "Y Offset", -40, 40, 1, db.ManaYOffset, 30, function(value)
        db.ManaYOffset = value
        Refresh()
    end)
    rowMana2:AddWidget(manaYSlider, 0.5)
    table_insert(allWidgets, manaYSlider)
    card4:AddRow(rowMana2, 36)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Mana Text Color
    ----------------------------------------------------------------
    local card5 = GUIFrame:CreateCard(scrollChild, "Mana Text Color", yOffset)
    table_insert(allWidgets, card5)

    -- Mana Color
    local rowColor = GUIFrame:CreateRow(card5.content, 37)
    local manaColorPicker = GUIFrame:CreateColorPicker(rowColor, "Mana Text Color", db.HighManaColor,
        function(r, g, b, a)
            db.HighManaColor = { r, g, b, a }
            ApplySettings()
        end)
    rowColor:AddWidget(manaColorPicker, 0.5)
    table_insert(allWidgets, manaColorPicker)
    card5:AddRow(rowColor, 37)

    yOffset = yOffset + card5:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 6: Font Settings
    ----------------------------------------------------------------
    local card6 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)
    table_insert(allWidgets, card6)

    -- Font Face + Outline
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    local rowFont = GUIFrame:CreateRow(card6.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(rowFont, "Font", fontList, db.FontFace or "Expressway", 30,
        function(value)
            db.FontFace = value
            Refresh()
        end, { searchable = true })
    rowFont:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }
    local outlineDropdown = GUIFrame:CreateDropdown(rowFont, "Outline", outlineList, db.FontOutline or "SOFTOUTLINE", 30,
        function(value)
            db.FontOutline = value
            Refresh()
        end)
    rowFont:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card6:AddRow(rowFont, 40)

    yOffset = yOffset + card6:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 7: Position
    ----------------------------------------------------------------
    local card7, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
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

    if card7.positionWidgets then
        for _, widget in ipairs(card7.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, card7)

    yOffset = newOffset

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - Theme.paddingSmall
    return yOffset
end)
