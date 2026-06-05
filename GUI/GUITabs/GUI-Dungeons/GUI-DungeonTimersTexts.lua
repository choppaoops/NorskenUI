---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local SETTINGS_GROWTH_OPTIONS = {
    { key = "DOWN", text = "Down" },
    { key = "UP",   text = "Up" },
}

local SETTINGS_TEXT_ALIGN_OPTIONS = {
    { key = "LEFT",   text = "Left" },
    { key = "CENTER", text = "Center" },
    { key = "RIGHT",  text = "Right" },
}

GUIFrame:RegisterContent("DT_Texts", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.DungeonTimers
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type DungeonTimers?
    local DT = NorskenUI and NorskenUI:GetModule("DungeonTimers", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings()
        if DT and DT.UpdateFrameVisuals then DT:UpdateFrameVisuals() end
    end

    local function RefreshTextPreviews()
        if DT and DT.RefreshSettingsTextPreviews then DT:RefreshSettingsTextPreviews() end
    end

    local function ApplyAndUpdate()
        ApplySettings()
        RefreshTextPreviews()
    end

    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    if NRSKNUI.GUI and NRSKNUI.GUI.DungeonTimers and NRSKNUI.GUI.DungeonTimers.HideBarPreviews then
        NRSKNUI.GUI.DungeonTimers.HideBarPreviews()
    end

    if GUIFrame.selectedSidebarItem == "DT_Texts" and DT and DT.ShowSettingsTextPreviews then
        DT:ShowSettingsTextPreviews()
    end

    local displayCard = GUIFrame:CreateCard(scrollChild, "Text Display Settings", yOffset)
    manager:Register(displayCard, "all")

    local row1 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeightLast)
    local alignDropdown = GUIFrame:CreateDropdown(row1, "Text Align", {
        options = SETTINGS_TEXT_ALIGN_OPTIONS,
        value = db.TextDisplay.textAlign or "LEFT",
        callback = function(key)
            db.TextDisplay.textAlign = key
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(alignDropdown, (1 / 3))

    local textGrowthDropdown = GUIFrame:CreateDropdown(row1, "Growth Direction", {
        options = SETTINGS_GROWTH_OPTIONS,
        value = db.TextGroup.GrowthDirection or "DOWN",
        callback = function(key)
            db.TextGroup.GrowthDirection = key
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(textGrowthDropdown, (1 / 3))

    local textSpacingSlider = GUIFrame:CreateSlider(row1, "Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.TextGroup.Spacing or 2,
        labelWidth = 50,
        callback = function(val)
            db.TextGroup.Spacing = val
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(textSpacingSlider, (1 / 3))
    displayCard:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = displayCard:GetNextOffset()

    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db.TextDisplay,
        includeSoftOutline = true,
        globalOverride = {},
        onChangeCallback = ApplyAndUpdate,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")

    yOffset = fontOffset

    local textPosCard, textPosYOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db.TextGroup.Position,
        onChangeCallback = ApplyAndUpdate,
    })
    manager:Register(textPosCard, "all")
    if textPosCard.positionWidgets then manager:RegisterGroup(textPosCard.positionWidgets, "all") end

    yOffset = textPosYOffset

    UpdateAllWidgetStates()

    return yOffset
end)

NRSKNUI.GUI = NRSKNUI.GUI or {}
NRSKNUI.GUI.DungeonTimers = NRSKNUI.GUI.DungeonTimers or {}

NRSKNUI.GUI.DungeonTimers.HideTextPreviews = function()
    local DT = NorskenUI and NorskenUI:GetModule("DungeonTimers", true)
    if DT and DT.HideSettingsTextPreviews then DT:HideSettingsTextPreviews() end
end

GUIFrame.onCloseCallbacks["DT_Texts"] = NRSKNUI.GUI.DungeonTimers.HideTextPreviews
