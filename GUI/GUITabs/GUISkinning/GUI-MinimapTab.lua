---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("Minimap", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.Minimap
    if not db or NRSKNUI:ShouldNotLoadModule() then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local MAP = NorskenUI:GetModule("Minimap", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    manager:SetCondition("bugWidgets", function() return db.BugSack.Enabled end)

    local function ApplySettings() if MAP then MAP:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Toggle
    local card1 = GUIFrame:CreateCard(scrollChild, "Minimap", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Minimap", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if checked then
                NorskenUI:EnableModule("Minimap")
            else
                NorskenUI:DisableModule("Minimap")
            end
            UpdateAllWidgetStates()
            NRSKNUI:CreateReloadPrompt("Enabling/Disabling this UI element requires a reload to take full effect.")
        end,
        msgPopup = true,
        msgText = "Minimap",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Minimap Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Minimap Settings", yOffset)
    manager:Register(card2, "all")

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local MinimapSize = GUIFrame:CreateSlider(row2, "Minimap Size", {
        min = 50,
        max = 500,
        step = 1,
        value = db.Size,
        callback = function(val)
            db.Size = val
            if MAP then MAP:UpdateSize() end
        end
    })
    row2:AddWidget(MinimapSize, 1)
    manager:Register(MinimapSize, "all")
    card2:AddRow(row2, Theme.rowHeight)

    local sepRow1 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sepRow1, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local BorderColor = GUIFrame:CreateColorPicker(row2b, "Border Color", {
        color = db.Border.Color,
        callback = function(r, g, b, a)
            db.Border.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(BorderColor, 1)
    manager:Register(BorderColor, "all")
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3
    local card3 = GUIFrame:CreateCard(scrollChild, "Mail Icon Settings", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local MailScale = GUIFrame:CreateSlider(row3a, "Scale", {
        min = 0.5,
        max = 2,
        step = 0.1,
        value = db.Mail.Scale,
        callback = function(val)
            db.Mail.Scale = val
            ApplySettings()
        end
    })
    row3a:AddWidget(MailScale, 1)
    manager:Register(MailScale, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local MailX = GUIFrame:CreateSlider(row3b, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.Mail.X,
        callback = function(val)
            db.Mail.X = val
            ApplySettings()
        end
    })
    row3b:AddWidget(MailX, 0.5)
    manager:Register(MailX, "all")

    local MailY = GUIFrame:CreateSlider(row3b, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.Mail.Y,
        callback = function(val)
            db.Mail.Y = val
            ApplySettings()
        end
    })
    row3b:AddWidget(MailY, 0.5)
    manager:Register(MailY, "all")
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4
    local card4 = GUIFrame:CreateCard(scrollChild, "BugSack Settings", yOffset)
    manager:Register(card4, "all")

    local row4 = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local BugSackEnbl = GUIFrame:CreateCheckbox(row4, "Toggle BugSack Frame", {
        value = db.BugSack.Enabled ~= false,
        callback = function(checked)
            db.BugSack.Enabled = checked
            if MAP then MAP:CreateBugSackButton() end
            UpdateAllWidgetStates()
        end
    })
    row4:AddWidget(BugSackEnbl, 0.5)
    manager:Register(BugSackEnbl, "all")

    local BugSackSize = GUIFrame:CreateSlider(row4, "BugSack Size", {
        min = 5,
        max = 50,
        step = 1,
        value = db.BugSack.Size,
        callback = function(val)
            db.BugSack.Size = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4:AddWidget(BugSackSize, 0.5)
    manager:Register(BugSackSize, "all", "bugWidgets")
    card4:AddRow(row4, Theme.rowHeight)

    local sepRow2 = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(sepRow2, Theme.rowHeightSeparator)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local BugSackX = GUIFrame:CreateSlider(row4b, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.BugSack.X,
        callback = function(val)
            db.BugSack.X = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4b:AddWidget(BugSackX, 0.5)
    manager:Register(BugSackX, "all", "bugWidgets")

    local BugSackY = GUIFrame:CreateSlider(row4b, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.BugSack.Y,
        callback = function(val)
            db.BugSack.Y = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4b:AddWidget(BugSackY, 0.5)
    manager:Register(BugSackY, "all", "bugWidgets")
    card4:AddRow(row4b, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5
    local card5 = GUIFrame:CreateCard(scrollChild, "AddOn Compartment Settings", yOffset)
    manager:Register(card5, "all")

    local row5 = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local HideAddOn = GUIFrame:CreateCheckbox(row5, "Hide AddOn Compartment", {
        value = db.HideAddOnComp,
        callback = function(checked)
            db.HideAddOnComp = checked
            ApplySettings()
        end
    })
    row5:AddWidget(HideAddOn, 0.5)
    manager:Register(HideAddOn, "all")
    card5:AddRow(row5, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    -- Card 6
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        dbKeys = {
            xOffset = "X",
            yOffset = "Y",
        },
        showAnchorFrameType = false,
        showStrata = false,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
