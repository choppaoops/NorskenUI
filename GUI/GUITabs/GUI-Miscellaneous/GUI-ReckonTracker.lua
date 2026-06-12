---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("ReckonTracker", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.ReckonTracker
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type ReckonTracker?
    local RECKON = NorskenUI and NorskenUI:GetModule("ReckonTracker", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if RECKON then RECKON:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable & Preview
    local card1 = GUIFrame:CreateCard(scrollChild, "Reckon Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Reckon Tracker", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if RECKON then
                if checked then NorskenUI:EnableModule("ReckonTracker") else NorskenUI:DisableModule("ReckonTracker") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Reckon Tracker",
    })
    row1:AddWidget(enableCheck, (2 / 3))

    local previewBtn
    previewBtn = GUIFrame:CreateButton(row1, "Show Preview", {
        height = 30,
        callback = function()
            if RECKON and RECKON.TogglePreview then
                local isActive = RECKON:TogglePreview()
                previewBtn:SetLabel(isActive and "Hide Preview" or "Show Preview")
            end
        end
    })
    row1:AddWidget(previewBtn, (1 / 3), nil, 0, -6)
    if RECKON and RECKON.IsPreviewActive and RECKON:IsPreviewActive() then
        previewBtn:SetLabel("Hide Preview")
    end
    card1:AddRow(row1, Theme.rowHeight)

    local sep1 = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(sep1, Theme.rowHeightSeparator)

    local row2 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local iconSizeSlider = GUIFrame:CreateSlider(row2, "Icon Size", {
        min = 20,
        max = 100,
        step = 1,
        value = db.IconSize or 40,
        callback = function(val)
            db.IconSize = val
            ApplySettings()
        end
    })
    row2:AddWidget(iconSizeSlider, 1)
    manager:Register(iconSizeSlider, "all")
    card1:AddRow(row2, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Glow Settings
    local glowCard, glowOffset, glowWidgets = GUIFrame:CreateGlowSettingsCard(scrollChild, yOffset, {
        title = "Glow Settings",
        db = db,
        onChangeCallback = ApplySettings,
    })
    manager:Register(glowCard, "all")
    if glowWidgets then manager:RegisterGroup(glowWidgets, "all") end

    yOffset = glowOffset

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
