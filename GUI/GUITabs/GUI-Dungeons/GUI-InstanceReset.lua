-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Helper to get InstanceReset module
local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("InstanceReset", true)
    end
    return nil
end

-- Register InstanceReset tab content
GUIFrame:RegisterContent("InstanceReset", function(scrollChild, yOffset)
    -- Safety check for database
    local db = NRSKNUI.db and NRSKNUI.db.profile.InstanceReset
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local IR = GetModule()

    -- Apply settings
    local function ApplySettings()
        if IR then
            IR:UpdateDB()
            IR:ApplySettings()
        end
    end

    -- Helper to apply enable state
    local function ApplyEnableState(enabled)
        if not IR then return end
        IR.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("InstanceReset")
        else
            NorskenUI:DisableModule("InstanceReset")
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
    -- Card 1: Instance Reset Settings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Instance Reset Announcer", yOffset)

    -- Enable Checkbox
    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Instance Reset Message", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyEnableState(checked)
            UpdateAllWidgetStates()
        end,
        true,
        "Instance Reset",
        "On",
        "Off"
    )
    row1:AddWidget(enableCheck, 0.5)
    card1:AddRow(row1, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Message Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Message Settings", yOffset)
    table.insert(allWidgets, card2)

    -- Message EditBox
    local row2 = GUIFrame:CreateRow(card2.content, 40)
    local messageBox = GUIFrame:CreateEditBox(row2, "Message", db.Message or "Instance reset!", function(text)
        db.Message = text
        ApplySettings()
    end)
    row2:AddWidget(messageBox, 1)
    table.insert(allWidgets, messageBox)
    card2:AddRow(row2, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - Theme.paddingSmall
    return yOffset
end)
