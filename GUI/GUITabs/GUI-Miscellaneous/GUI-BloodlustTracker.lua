---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("BloodlustTracker", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.BloodlustTracker
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type BloodlustTracker?
    local BLT = NorskenUI:GetModule("BloodlustTracker", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if BLT then BLT:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Bloodlust Tracker
    local card1 = GUIFrame:CreateCard(scrollChild, "Bloodlust Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Bloodlust Tracker", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if checked then
                NorskenUI:EnableModule("BloodlustTracker")
            else
                NorskenUI:DisableModule("BloodlustTracker")
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Bloodlust Tracker",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Size & Font Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local SizeSlider = GUIFrame:CreateSlider(card2.content, "Icon Size", {
        min = 16,
        max = 100,
        step = 1,
        value = db.Size or 40,
        labelWidth = 60,
        callback = function(val)
            db.Size = val
            ApplySettings()
        end
    })
    row2:AddWidget(SizeSlider, 1)
    manager:Register(SizeSlider, "all")
    card2:AddRow(row2, Theme.rowHeight)

    local row3 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local FontSizeSlider = GUIFrame:CreateSlider(card2.content, "Font Size", {
        min = 8,
        max = 36,
        step = 1,
        value = db.FontSize or 18,
        labelWidth = 60,
        callback = function(val)
            db.FontSize = val
            ApplySettings()
        end
    })
    row3:AddWidget(FontSizeSlider, 1)
    manager:Register(FontSizeSlider, "all")
    card2:AddRow(row3, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Position Settings
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
