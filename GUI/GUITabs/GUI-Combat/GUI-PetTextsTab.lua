---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("PetTexts", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.PetTexts
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type PetTexts?
    local PET = NorskenUI and NorskenUI:GetModule("PetTexts", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function ApplySettings()
        if PET and PET.ApplySettings then PET:ApplySettings() end
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
    local card1 = GUIFrame:CreateCard(scrollChild, "Pet Status Texts", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Pet Status Texts", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if PET then
                if checked then NorskenUI:EnableModule("PetTexts") else NorskenUI:DisableModule("PetTexts") end
            end
            UpdateAllWidgetStates()
            if checked and PET then PET:ShowPreview() end
        end,
        msgPopup = true,
        msgText = "Pet Status Texts",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: State Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "State Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local petMissingInput = GUIFrame:CreateEditBox(row2a, "Pet Missing Text", {
        value = db.PetMissing,
        callback = function(val)
            db.PetMissing = val
            ApplySettings()
        end
    })
    row2a:AddWidget(petMissingInput, 0.5)
    manager:Register(petMissingInput, "all")

    local missingColorPicker = GUIFrame:CreateColorPicker(row2a, "Missing Color", {
        color = db.MissingColor,
        callback = function(r, g, b, a)
            db.MissingColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2a:AddWidget(missingColorPicker, 0.5)
    manager:Register(missingColorPicker, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local petDeadInput = GUIFrame:CreateEditBox(row2b, "Pet Dead Text", {
        value = db.PetDead,
        callback = function(val)
            db.PetDead = val
            ApplySettings()
        end
    })
    row2b:AddWidget(petDeadInput, 0.5)
    manager:Register(petDeadInput, "all")

    local deadColorPicker = GUIFrame:CreateColorPicker(row2b, "Dead Color", {
        color = db.DeadColor,
        callback = function(r, g, b, a)
            db.DeadColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(deadColorPicker, 0.5)
    manager:Register(deadColorPicker, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local petPassiveInput = GUIFrame:CreateEditBox(row2c, "Pet Passive Text", {
        value = db.PetPassive,
        callback = function(val)
            db.PetPassive = val
            ApplySettings()
        end
    })
    row2c:AddWidget(petPassiveInput, 0.5)
    manager:Register(petPassiveInput, "all")

    local passiveColorPicker = GUIFrame:CreateColorPicker(row2c, "Passive Color", {
        color = db.PassiveColor,
        callback = function(r, g, b, a)
            db.PassiveColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(passiveColorPicker, 0.5)
    manager:Register(passiveColorPicker, "all")
    card2:AddRow(row2c, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 4: Position
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
