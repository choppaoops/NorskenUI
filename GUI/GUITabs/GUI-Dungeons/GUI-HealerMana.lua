---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local IsInRaid = IsInRaid

GUIFrame:RegisterContent("HealerMana", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.HealerMana
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type HealerMana?
    local HM = NorskenUI and NorskenUI:GetModule("HealerMana", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end
    manager:SetCondition("RaidLoad", function() return db.EnableInRaid end)
    manager:SetCondition("SplitPos", function() return db.SplitPositioning end)
    local function ApplySettings() if HM then HM:ApplySettings() end end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Healer Mana Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Healer Mana Tracker", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if HM then
                if checked then
                    NorskenUI:EnableModule("HealerMana")
                    HM:ShowPreview()
                else
                    NorskenUI:DisableModule("HealerMana")
                    HM:HidePreview()
                end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Healer Mana",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    local sep0 = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(sep0, Theme.rowHeightSeparator)

    local row1b = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local raidCheck = GUIFrame:CreateCheckbox(row1b, "Enable in Raids", {
        value = db.EnableInRaid,
        callback = function(checked)
            db.EnableInRaid = checked
            ApplySettings()
            UpdateAllWidgetStates()
        end,
    })
    row1b:AddWidget(raidCheck, 0.5)
    manager:Register(raidCheck, "all")

    local maxHealersSlider = GUIFrame:CreateSlider(row1b, "Max Healers", {
        min = 1,
        max = 8,
        step = 1,
        value = db.MaxHealers,
        callback = function(value)
            db.MaxHealers = value
            ApplySettings()
        end,
    })
    row1b:AddWidget(maxHealersSlider, 0.5)
    manager:Register(maxHealersSlider, "all", "RaidLoad")
    card1:AddRow(row1b, Theme.rowHeight)

    local row1c = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local spacingSlider = GUIFrame:CreateSlider(row1c, "Frame Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.FrameSpacing,
        callback = function(value)
            db.FrameSpacing = value
            ApplySettings()
        end,
    })
    row1c:AddWidget(spacingSlider, 0.5)
    manager:Register(spacingSlider, "all", "RaidLoad")

    local growthOptions = { { key = "DOWN", text = "Down" }, { key = "UP", text = "Up" } }
    local growDropdown = GUIFrame:CreateDropdown(row1c, "Grow Direction", {
        options = growthOptions,
        value = db.GrowDirection,
        callback = function(value)
            db.GrowDirection = value
            ApplySettings()
        end,
    })
    row1c:AddWidget(growDropdown, 0.5)
    manager:Register(growDropdown, "all", "RaidLoad")
    card1:AddRow(row1c, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Appearance
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local iconSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
        min = 16,
        max = 64,
        step = 1,
        value = db.IconSize,
        callback = function(value)
            db.IconSize = value
            ApplySettings()
        end
    })
    row2a:AddWidget(iconSlider, 1)
    manager:Register(iconSlider, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local sep1 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep1, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local nameYSlider = GUIFrame:CreateSlider(row2b, "Name Y Offset", {
        min = -30,
        max = 30,
        step = 1,
        value = db.NameYOffset,
        callback = function(value)
            db.NameYOffset = value
            ApplySettings()
        end
    })
    row2b:AddWidget(nameYSlider, 0.5)
    manager:Register(nameYSlider, "all")

    local manaYSlider = GUIFrame:CreateSlider(row2b, "Mana Y Offset", {
        min = -30,
        max = 30,
        step = 1,
        value = db.ManaYOffset,
        callback = function(value)
            db.ManaYOffset = value
            ApplySettings()
        end
    })
    row2b:AddWidget(manaYSlider, 0.5)
    manager:Register(manaYSlider, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local sep2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep2, Theme.rowHeightSeparator)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local manaColorPicker = GUIFrame:CreateColorPicker(row2c, "Mana Text Color", {
        color = db.HighManaColor,
        callback = function(r, g, b, a)
            db.HighManaColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(manaColorPicker, 1)
    manager:Register(manaColorPicker, "all")
    card2:AddRow(row2c, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        fontSizes = {
            { label = "Name Size", dbKey = "NameFontSize" },
            { label = "Mana Size", dbKey = "ManaFontSize" },
        },
        fontSizeRange = { 8, 44 },
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")

    yOffset = fontOffset

    -- Card 4: Position
    local defaultContext = (HM and IsInRaid() and db.SplitPositioning) and "raid" or "party"
    if HM then HM:SetPreviewContext(defaultContext) end
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function()
            if HM then HM:ApplyPosition() end
            UpdateAllWidgetStates()
        end,
        onContextChange = function(context)
            if HM then HM:SetPreviewContext(context) end
        end,
        contextOptions = {
            { key = "party", text = "Party", positionKey = "PartyPosition" },
            { key = "raid", text = "Raid", positionKey = "RaidPosition" },
        },
        defaultContext = defaultContext,
        splitToggleKey = "SplitPositioning",
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end
    if posCard.splitToggle then manager:Register(posCard.splitToggle, "all", "RaidLoad") end
    if posCard.contextDropdown then manager:Register(posCard.contextDropdown, "all", "RaidLoad", "SplitPos") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
