---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("CustomSkin_Debuffs", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return yOffset end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.DebuffTracking
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type DebuffTracking?
    local DEBUFFS = NorskenUI and NorskenUI:GetModule("DebuffTracking", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    manager:SetCondition("borderColor", function() return db.BorderColorMode == "custom" end)
    manager:SetCondition("borderTypes", function() return db.BorderColorMode == "dispel" end)
    manager:SetCondition("swipeOn", function() return db.Swipe end)

    local function ApplySettings()
        if DEBUFFS and DEBUFFS:IsEnabled() and DEBUFFS.ApplySettings then
            DEBUFFS:ApplySettings()
        end
    end

    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Custom Debuff Frame", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Custom Debuff Frame", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if DEBUFFS then
                DEBUFFS.db.Enabled = checked
                if checked then
                    NorskenUI:EnableModule("DebuffTracking")
                else
                    NorskenUI:DisableModule("DebuffTracking")
                end
            end
            UpdateAllWidgetStates()
            NRSKNUI:CreateReloadPrompt("Enabling/Disabling this module requires a reload.")
        end,
        msgPopup = true,
        msgText = "Custom Debuff Frame",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Icon Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Icon Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
        min = 16,
        max = 80,
        step = 1,
        value = db.IconSize,
        callback = function(value)
            db.IconSize = value
            ApplySettings()
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
            ApplySettings()
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
            ApplySettings()
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
            ApplySettings()
        end
    })
    row2b:AddWidget(maxRowsSlider, 0.5)
    manager:Register(maxRowsSlider, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local sep2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep2, Theme.rowHeightSeparator)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local growHList = {
        { key = "LEFT",  text = "Left" },
        { key = "RIGHT", text = "Right" },
    }
    local growHDropdown = GUIFrame:CreateDropdown(row2c, "Grow Horizontal", {
        options = growHList,
        value = db.GrowHorizontal or "LEFT",
        callback = function(key)
            db.GrowHorizontal = key
            ApplySettings()
        end
    })
    row2c:AddWidget(growHDropdown, 0.5)
    manager:Register(growHDropdown, "all")

    local growVList = {
        { key = "UP",   text = "Up" },
        { key = "DOWN", text = "Down" },
    }
    local growVDropdown = GUIFrame:CreateDropdown(row2c, "Then Vertical", {
        options = growVList,
        value = db.GrowVertical or "DOWN",
        callback = function(key)
            db.GrowVertical = key
            ApplySettings()
        end
    })
    row2c:AddWidget(growVDropdown, 0.5)
    manager:Register(growVDropdown, "all")
    card2:AddRow(row2c, Theme.rowHeight)

    local separator3b = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(separator3b, Theme.rowHeightSeparator)

    local rowSwipe = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local swipeCheck = GUIFrame:CreateCheckbox(rowSwipe, "Enable Swipe", {
        value = db.Swipe,
        callback = function(checked)
            db.Swipe = checked
            ApplySettings()
            UpdateAllWidgetStates()
            if DEBUFFS then DEBUFFS:TogglePreview() end
        end
    })
    rowSwipe:AddWidget(swipeCheck, 0.5)
    manager:Register(swipeCheck, "all")

    local reverseCheck = GUIFrame:CreateCheckbox(rowSwipe, "Reverse Swipe", {
        value = db.Reverse,
        callback = function(checked)
            db.Reverse = checked
            ApplySettings()
            if DEBUFFS then DEBUFFS:TogglePreview() end
        end
    })
    rowSwipe:AddWidget(reverseCheck, 0.5)
    manager:Register(reverseCheck, "all", "swipeOn")
    card2:AddRow(rowSwipe, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Visual Settings
    local card3 = GUIFrame:CreateCard(scrollChild, "Visual Settings", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local borderModeList = {
        { key = "custom", text = "Custom Color" },
        { key = "dispel", text = "Dispel Type" },
    }
    local borderModeDropdown = GUIFrame:CreateDropdown(row3a, "Border Color Mode", {
        options = borderModeList,
        value = db.BorderColorMode or "custom",
        callback = function(key)
            db.BorderColorMode = key
            ApplySettings()
            UpdateAllWidgetStates()
        end
    })
    row3a:AddWidget(borderModeDropdown, 0.5)
    manager:Register(borderModeDropdown, "all")

    local borderColorPicker = GUIFrame:CreateColorPicker(row3a, "Border Color", {
        color = db.BorderColor,
        callback = function(r, g, b, a)
            db.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(borderColorPicker, 1)
    manager:Register(borderColorPicker, "all", "borderColor")
    card3:AddRow(row3a, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 3b: Dispel Type Colors
    db.DispelColors = db.DispelColors or {}

    local card3b = GUIFrame:CreateCard(scrollChild, "Dispel Type Colors", yOffset)
    manager:Register(card3b, "all")

    local dispelTypes = {
        { name = "None",    label = "None" },
        { name = "Magic",   label = "Magic" },
        { name = "Curse",   label = "Curse" },
        { name = "Disease", label = "Disease" },
        { name = "Poison",  label = "Poison" },
        { name = "Bleed",   label = "Bleed" },
        { name = "Enrage",  label = "Enrage" },
    }

    local function GetDispelColorForPicker(name)
        local custom = db.DispelColors[name]
        if custom and type(custom) == "table" and custom[1] then
            return custom
        end
        local index = NRSKNUI.DispelTypeNameToIndex[name]
        return NRSKNUI:GetDefaultDispelColor(index)
    end

    local function CreateDispelColorRow(parent, type1, type2)
        local row = GUIFrame:CreateRow(parent, Theme.rowHeight)

        local picker1 = GUIFrame:CreateColorPicker(row, type1.label, {
            color = GetDispelColorForPicker(type1.name),
            callback = function(r, g, b, a)
                db.DispelColors[type1.name] = { r, g, b, a }
                NRSKNUI:SetDispelColor(type1.name, r, g, b, a)
                ApplySettings()
            end
        })
        row:AddWidget(picker1, 0.4)
        manager:Register(picker1, "all", "borderTypes")

        local reset1 = GUIFrame:CreateButton(row, "Reset", {
            tooltip = "Reset to Blizzard default color",
            height = 24,
            callback = function()
                db.DispelColors[type1.name] = nil
                NRSKNUI:SetDispelColor(type1.name, nil)
                local defaultColor = NRSKNUI:GetDefaultDispelColor(NRSKNUI.DispelTypeNameToIndex[type1.name])
                picker1:SetColor(unpack(defaultColor))
                ApplySettings()
            end
        })
        row:AddWidget(reset1, 0.1, nil, 0, -14)
        manager:Register(reset1, "all", "borderTypes")

        if type2 then
            local picker2 = GUIFrame:CreateColorPicker(row, type2.label, {
                color = GetDispelColorForPicker(type2.name),
                callback = function(r, g, b, a)
                    db.DispelColors[type2.name] = { r, g, b, a }
                    NRSKNUI:SetDispelColor(type2.name, r, g, b, a)
                    ApplySettings()
                end
            })
            row:AddWidget(picker2, 0.4)
            manager:Register(picker2, "all", "borderTypes")

            local reset2 = GUIFrame:CreateButton(row, "Reset", {
                tooltip = "Reset to Blizzard default color",
                height = 24,
                callback = function()
                    db.DispelColors[type2.name] = nil
                    NRSKNUI:SetDispelColor(type2.name, nil)
                    local defaultColor = NRSKNUI:GetDefaultDispelColor(NRSKNUI.DispelTypeNameToIndex[type2.name])
                    picker2:SetColor(unpack(defaultColor))
                    ApplySettings()
                end
            })
            row:AddWidget(reset2, 0.1, nil, 0, -14)
            manager:Register(reset2, "all", "borderTypes")
        end

        return row
    end

    local dispelRow1 = CreateDispelColorRow(card3b.content, dispelTypes[1], dispelTypes[2])
    card3b:AddRow(dispelRow1, Theme.rowHeight)

    local dispelRow1Sep = GUIFrame:CreateSeparator(card3b.content)
    card3b:AddRow(dispelRow1Sep, Theme.rowHeightSeparator)

    local dispelRow2 = CreateDispelColorRow(card3b.content, dispelTypes[3], dispelTypes[4])
    card3b:AddRow(dispelRow2, Theme.rowHeight)

    local dispelRow2Sep = GUIFrame:CreateSeparator(card3b.content)
    card3b:AddRow(dispelRow2Sep, Theme.rowHeightSeparator)

    local dispelRow3 = CreateDispelColorRow(card3b.content, dispelTypes[5], dispelTypes[6])
    card3b:AddRow(dispelRow3, Theme.rowHeight)

    local dispelRow3Sep = GUIFrame:CreateSeparator(card3b.content)
    card3b:AddRow(dispelRow3Sep, Theme.rowHeightSeparator)

    local dispelRow4 = CreateDispelColorRow(card3b.content, dispelTypes[7], nil)
    card3b:AddRow(dispelRow4, Theme.rowHeightLast, 0)

    yOffset = card3b:GetNextOffset()

    -- Card 4: Filtering Options
    local card4 = GUIFrame:CreateCard(scrollChild, "Filtering Options", yOffset)
    manager:Register(card4, "all")

    db.Filters = db.Filters or {}

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local playerFilterCheck = GUIFrame:CreateCheckbox(row4b, "PLAYER", {
        value = db.Filters.PLAYER == true,
        callback = function(checked)
            db.Filters.PLAYER = checked
            ApplySettings()
        end
    })
    row4b:AddWidget(playerFilterCheck, 0.5)
    manager:Register(playerFilterCheck, "all")

    local raidFilterCheck = GUIFrame:CreateCheckbox(row4b, "RAID", {
        value = db.Filters.RAID == true,
        callback = function(checked)
            db.Filters.RAID = checked
            ApplySettings()
        end
    })
    row4b:AddWidget(raidFilterCheck, 0.5)
    manager:Register(raidFilterCheck, "all")
    card4:AddRow(row4b, Theme.rowHeight)

    local row4d = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local ccCheck = GUIFrame:CreateCheckbox(row4d, "CROWD_CONTROL", {
        value = db.Filters.CROWD_CONTROL == true,
        callback = function(checked)
            db.Filters.CROWD_CONTROL = checked
            ApplySettings()
        end
    })
    row4d:AddWidget(ccCheck, 0.5)
    manager:Register(ccCheck, "all")

    local importantCheck = GUIFrame:CreateCheckbox(row4d, "IMPORTANT", {
        value = db.Filters.IMPORTANT == true,
        callback = function(checked)
            db.Filters.IMPORTANT = checked
            ApplySettings()
        end
    })
    row4d:AddWidget(importantCheck, 0.5)
    manager:Register(importantCheck, "all")
    card4:AddRow(row4d, Theme.rowHeight)

    local row4e = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local dispellableCheck = GUIFrame:CreateCheckbox(row4e, "RAID_PLAYER_DISPELLABLE", {
        value = db.Filters.RAID_PLAYER_DISPELLABLE == true,
        callback = function(checked)
            db.Filters.RAID_PLAYER_DISPELLABLE = checked
            ApplySettings()
        end
    })
    row4e:AddWidget(dispellableCheck, 0.5)
    manager:Register(dispellableCheck, "all")

    local nameplateCheck = GUIFrame:CreateCheckbox(row4e, "INCLUDE_NAME_PLATE_ONLY", {
        value = db.Filters.INCLUDE_NAME_PLATE_ONLY == true,
        callback = function(checked)
            db.Filters.INCLUDE_NAME_PLATE_ONLY = checked
            ApplySettings()
        end
    })
    row4e:AddWidget(nameplateCheck, 0.5)
    manager:Register(nameplateCheck, "all")
    card4:AddRow(row4e, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5: Blocklist
    local card5 = GUIFrame:CreateCard(scrollChild, "Blocklist", yOffset)
    manager:Register(card5, "all")

    db.Blocklist = db.Blocklist or {}

    local function BuildBlocklistOptions()
        local options = {}
        for spellId, label in pairs(db.Blocklist) do
            local text = type(label) == "string" and label or tostring(spellId)
            options[tostring(spellId)] = text .. " (" .. spellId .. ")"
        end
        return options
    end

    local blocklistDropdown
    local spellIdInput
    local labelInput

    local textRowSize = 34
    local infoRow = GUIFrame:CreateRow(card5.content, textRowSize)
    local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Blocklist Filter Info"), {
        text = NRSKNUI:ColorTextByTheme("• ") ..
            "Only possible to add auras that have been made non secret by Blizzard, for example all the Bloodlust ID's.",
        height = textRowSize,
        bgMode = "hide"
    })
    infoRow:AddWidget(infoText, 1)
    manager:Register(infoText, "all")
    card5:AddRow(infoRow, textRowSize)

    local sep1blocklist = GUIFrame:CreateSeparator(card5.content)
    card5:AddRow(sep1blocklist, Theme.rowHeightSeparator)

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    blocklistDropdown = GUIFrame:CreateDropdown(row5a, "Blocked Spells", {
        options = BuildBlocklistOptions(),
        value = nil,
        callback = function(key)
            if key then
                spellIdInput:SetValue(key)
                local lbl = db.Blocklist[tonumber(key)]
                labelInput:SetValue(type(lbl) == "string" and lbl or "")
            end
        end
    })
    row5a:AddWidget(blocklistDropdown, 0.5)
    manager:Register(blocklistDropdown, "all")

    labelInput = GUIFrame:CreateEditBox(row5a, "Label", {
        value = "",
        callback = function() end
    })
    row5a:AddWidget(labelInput, 0.5)
    manager:Register(labelInput, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local row5b = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    spellIdInput = GUIFrame:CreateEditBox(row5b, "Spell ID", {
        value = "",
        callback = function() end
    })
    row5b:AddWidget(spellIdInput, 0.5)
    manager:Register(spellIdInput, "all")

    local addBtn = GUIFrame:CreateButton(row5b, "New", {
        height = 24,
        callback = function()
            local spellId = tonumber(spellIdInput:GetValue())
            if spellId then
                local label = labelInput:GetValue()
                db.Blocklist[spellId] = (label and label ~= "") and label or true
                blocklistDropdown:SetOptions(BuildBlocklistOptions())
                spellIdInput:SetValue("")
                labelInput:SetValue("")
                ApplySettings()
            end
        end
    })
    row5b:AddWidget(addBtn, 0.25, nil, 0, -14)

    local removeBtn = GUIFrame:CreateButton(row5b, "Delete", {
        height = 24,
        callback = function()
            local spellId = tonumber(spellIdInput:GetValue())
            if spellId and db.Blocklist[spellId] then
                db.Blocklist[spellId] = nil
                blocklistDropdown:SetOptions(BuildBlocklistOptions())
                spellIdInput:SetValue("")
                labelInput:SetValue("")
                ApplySettings()
            end
        end
    })
    row5b:AddWidget(removeBtn, 0.25, nil, 0, -14)
    card5:AddRow(row5b, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    -- Card 6: Text Positions
    local card6 = GUIFrame:CreateCard(scrollChild, "Text Positions", yOffset)
    manager:Register(card6, "all")

    local textAnchorOptions = {
        { key = "TOPLEFT",     text = "Top Left" },
        { key = "TOP",         text = "Top" },
        { key = "TOPRIGHT",    text = "Top Right" },
        { key = "LEFT",        text = "Left" },
        { key = "CENTER",      text = "Center" },
        { key = "RIGHT",       text = "Right" },
        { key = "BOTTOMLEFT",  text = "Bottom Left" },
        { key = "BOTTOM",      text = "Bottom" },
        { key = "BOTTOMRIGHT", text = "Bottom Right" },
    }

    db.TimerPosition = db.TimerPosition or {}
    db.StackPosition = db.StackPosition or
        { AnchorFrom = "BOTTOMRIGHT", AnchorTo = "BOTTOMRIGHT", XOffset = -1, YOffset = 1 }

    local row6a = GUIFrame:CreateRow(card6.content, Theme.rowHeight)
    local timerAnchorDropdown = GUIFrame:CreateDropdown(row6a, "Timer Anchor", {
        options = textAnchorOptions,
        value = db.TimerPosition.AnchorFrom or "CENTER",
        callback = function(key)
            db.TimerPosition.AnchorFrom = key
            db.TimerPosition.AnchorTo = key
            ApplySettings()
        end
    })
    row6a:AddWidget(timerAnchorDropdown, 1 / 3)
    manager:Register(timerAnchorDropdown, "all")

    local timerXSlider = GUIFrame:CreateSlider(row6a, "Timer X", {
        min = -50,
        max = 50,
        step = 1,
        value = db.TimerPosition.XOffset or 0,
        callback = function(value)
            db.TimerPosition.XOffset = value
            ApplySettings()
        end
    })
    row6a:AddWidget(timerXSlider, 1 / 3)
    manager:Register(timerXSlider, "all")

    local timerYSlider = GUIFrame:CreateSlider(row6a, "Timer Y", {
        min = -50,
        max = 50,
        step = 1,
        value = db.TimerPosition.YOffset or 0,
        callback = function(value)
            db.TimerPosition.YOffset = value
            ApplySettings()
        end
    })
    row6a:AddWidget(timerYSlider, 1 / 3)
    manager:Register(timerYSlider, "all")
    card6:AddRow(row6a, Theme.rowHeight)

    local textSettingSep = GUIFrame:CreateSeparator(card6.content)
    card6:AddRow(textSettingSep, Theme.rowHeightSeparator)

    local row6b = GUIFrame:CreateRow(card6.content, Theme.rowHeightLast)
    local stackAnchorDropdown = GUIFrame:CreateDropdown(row6b, "Stack Anchor", {
        options = textAnchorOptions,
        value = db.StackPosition.AnchorFrom,
        callback = function(key)
            db.StackPosition.AnchorFrom = key
            db.StackPosition.AnchorTo = key
            ApplySettings()
        end
    })
    row6b:AddWidget(stackAnchorDropdown, 1 / 3)
    manager:Register(stackAnchorDropdown, "all")

    local stackXSlider = GUIFrame:CreateSlider(row6b, "Stack X", {
        min = -50,
        max = 50,
        step = 1,
        value = db.StackPosition.XOffset,
        callback = function(value)
            db.StackPosition.XOffset = value
            ApplySettings()
        end
    })
    row6b:AddWidget(stackXSlider, 1 / 3)
    manager:Register(stackXSlider, "all")

    local stackYSlider = GUIFrame:CreateSlider(row6b, "Stack Y", {
        min = -50,
        max = 50,
        step = 1,
        value = db.StackPosition.YOffset,
        callback = function(value)
            db.StackPosition.YOffset = value
            ApplySettings()
        end
    })
    row6b:AddWidget(stackYSlider, 1 / 3)
    manager:Register(stackYSlider, "all")
    card6:AddRow(row6b, Theme.rowHeightLast, 0)

    yOffset = card6:GetNextOffset()

    -- Card 7: Font Settings
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

    -- Card 8: Position
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function()
            if DEBUFFS and DEBUFFS.ApplyPosition then
                DEBUFFS:ApplyPosition()
            end
        end,
    })
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
