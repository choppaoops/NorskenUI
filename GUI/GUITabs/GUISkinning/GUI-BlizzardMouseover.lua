-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

--TODO: Update

-- Localization Setup
local table_insert = table.insert
local ipairs = ipairs

-- Helper to get Blizzard Mouseover module
local function GetBlizzardMouseoverModule()
    if NorskenUI then
        return NorskenUI:GetModule("BlizzardMouseover", true)
    end
    return nil
end

-- Combat Message Tab Content
GUIFrame:RegisterContent("BlizzardMouseover", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.BlizzardMouseover
    if not db or not NRSKNUI:ShouldNotLoadModule() then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    -- Get Combat Message module
    local BMO = GetBlizzardMouseoverModule()

    -- Track widgets for enable/disable logic
    local allWidgets = {} -- All widgets (except main toggle)

    -- Helper to apply settings
    local function ApplySettings()
        if BMO then
            BMO:ApplySettings()
        end
    end

    -- Helper to apply new state
    local function ApplyBlizzardMouseoverState(enabled)
        if not BMO then return end
        BMO.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("BlizzardMouseover")
        else
            NorskenUI:DisableModule("BlizzardMouseover")
        end
    end

    -- Comprehensive widget state update
    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false

        -- First: Apply main enable state to ALL widgets
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    ----------------------------------------------------------------
    -- Card 1: Blizzard Mouseover Enable + Non Mouseover Alpha
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Blizzard Mouseover", yOffset)

    -- Enable Checkbox
    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Blizzard Mouseover", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            ApplyBlizzardMouseoverState(checked)
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Blizzard Mouseover",
        msgOn = "On",
        msgOff = "Off",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 40)

    -- Separator
    local row1sep = GUIFrame:CreateRow(card1.content, 8)
    local sepMoverCard = GUIFrame:CreateSeparator(row1sep)
    row1sep:AddWidget(sepMoverCard, 1)
    table_insert(allWidgets, sepMoverCard)
    card1:AddRow(row1sep, 8)

    local textRow1Size = 30
    local row1b = GUIFrame:CreateRow(card1.content, textRow1Size)
    local ttInfoText = GUIFrame:CreateText(row1b, NRSKNUI:ColorTextByTheme("Elements Supported"), {
        text = NRSKNUI:ColorTextByTheme("• ") .. "Bag Bar",
        height = textRow1Size,
        bgMode = "hide"
    })
    row1b:AddWidget(ttInfoText, 1)
    table_insert(allWidgets, ttInfoText)
    card1:AddRow(row1b, textRow1Size)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Mouseover Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Mouseover Settings", yOffset)
    table_insert(allWidgets, card2)

    -- Alpha when non mouseover
    local row2 = GUIFrame:CreateRow(card2.content, 40)
    local nonMouseoverAlpha = GUIFrame:CreateSlider(row2, "Alpha When No Mouseover", {
        min = 0,
        max = 1,
        step = 0.1,
        value = db.Alpha,
        callback = function(val)
            db.Alpha = val
            ApplySettings()
        end
    })
    row2:AddWidget(nonMouseoverAlpha, 1)
    table_insert(allWidgets, nonMouseoverAlpha)
    card2:AddRow(row2, 40)

    -- Fade In Duration
    local row3 = GUIFrame:CreateRow(card2.content, 36)
    local FadeInDuration = GUIFrame:CreateSlider(row3, "Fade In Duration", {
        min = 0,
        max = 10,
        step = 0.1,
        value = db.FadeInDuration,
        callback = function(val)
            db.FadeInDuration = val
        end
    })
    row3:AddWidget(FadeInDuration, 0.5)
    table_insert(allWidgets, FadeInDuration)

    -- Fade Out Duration
    local FadeOutDuration = GUIFrame:CreateSlider(row3, "Fade Out Duration", {
        min = 0,
        max = 10,
        step = 0.1,
        value = db.FadeOutDuration,
        callback = function(val)
            db.FadeOutDuration = val
        end
    })
    row3:AddWidget(FadeOutDuration, 0.5)
    table_insert(allWidgets, FadeOutDuration)

    card2:AddRow(row3, 36)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Blizzard Elements To Mouseover
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Blizzard Elements To Mouseover", yOffset)
    table_insert(allWidgets, card3)

    -- Toggle for bagBar mouseover
    local row4 = GUIFrame:CreateRow(card3.content, 40)
    local bagEnableCheck = GUIFrame:CreateCheckbox(row4, "Enable BagBar Mouseover", {
        value = db.BagMouseover.Enabled ~= false,
        callback = function(checked)
            db.BagMouseover.Enabled = checked
            if BMO then
                BMO:ToggleElement("bags", checked)
                ApplySettings()
            end
        end,
    })
    row4:AddWidget(bagEnableCheck, 1)
    table_insert(allWidgets, bagEnableCheck)

    card3:AddRow(row4, 40)

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end)
