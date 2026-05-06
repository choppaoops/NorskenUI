---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("HealerMana", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.HealerMana
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type HealerMana?
    local HM = NorskenUI and NorskenUI:GetModule("HealerMana", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function ApplySettings()
        if HM then HM:ApplySettings() end
    end

    local function Refresh()
        if HM then HM:Refresh() end
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
    local card1 = GUIFrame:CreateCard(scrollChild, "Healer Mana Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
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
    card1:AddRow(row1, Theme.rowHeightLast, 0)

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
            Refresh()
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
            Refresh()
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
            Refresh()
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
        onChangeCallback = Refresh,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 4: Position
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function() if HM then HM:ApplyPosition() end end,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
