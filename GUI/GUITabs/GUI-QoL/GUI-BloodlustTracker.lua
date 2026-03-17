-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Localization
local table_insert = table.insert
local ipairs = ipairs

-- Helper to get BloodlustTracker module
local function GetBloodlustTrackerModule()
    if NorskenUI then
        return NorskenUI:GetModule("BloodlustTracker", true)
    end
    return nil
end

-- Register BloodlustTracker tab content
GUIFrame:RegisterContent("BloodlustTracker", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.BloodlustTracker
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local BLT = GetBloodlustTrackerModule()
    local allWidgets = {}

    local function ApplySettings()
        if BLT then
            BLT:ApplySettings()
        end
    end

    local function ApplyModuleState(enabled)
        if not BLT then return end
        db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("BloodlustTracker")
        else
            NorskenUI:DisableModule("BloodlustTracker")
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
    -- Card 1: Bloodlust Tracker (Enable)
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Bloodlust Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Bloodlust Tracker", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyModuleState(checked)
            UpdateAllWidgetStates()
        end,
        true, "Bloodlust Tracker", "On", "Off"
    )
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 40)

    card1:AddLabel("Shows a 40 second countdown when Bloodlust/Heroism is cast.")

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Size & Font Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    table_insert(allWidgets, card2)

    -- Size slider
    local row2 = GUIFrame:CreateRow(card2.content, 40)
    local SizeSlider = GUIFrame:CreateSlider(card2.content, "Icon Size", 16, 100, 1, db.Size or 40, 60,
        function(val)
            db.Size = val
            ApplySettings()
        end)
    row2:AddWidget(SizeSlider, 1)
    table_insert(allWidgets, SizeSlider)
    card2:AddRow(row2, 40)

    -- Font size slider
    local row3 = GUIFrame:CreateRow(card2.content, 40)
    local FontSizeSlider = GUIFrame:CreateSlider(card2.content, "Font Size", 8, 36, 1, db.FontSize or 18, 60,
        function(val)
            db.FontSize = val
            ApplySettings()
        end)
    row3:AddWidget(FontSizeSlider, 1)
    table_insert(allWidgets, FontSizeSlider)
    card2:AddRow(row3, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Position Settings
    ----------------------------------------------------------------
    local card3, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
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
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })

    if card3.positionWidgets then
        for _, widget in ipairs(card3.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, card3)

    yOffset = newOffset

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end)
