---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs

local GLOW_TYPES = {
    { key = "pixel",    text = "Pixel" },
    { key = "autocast", text = "Autocast" },
    { key = "button",   text = "Button" },
    { key = "proc",     text = "Proc" },
}

local GLOW_MODES = {
    { key = "always",     text = "Always Glow" },
    { key = "expiration", text = "Expiration Glow" },
}

---@class NUIGlowSettingsCard : NUICard
---@field glowWidgets table
---@field typeOnlyRows table
---@field frequencyRow Frame
---@field updateTypeVisibility fun()
---@field _initialized boolean

---@param scrollChild Frame
---@param yOffset number
---@param config table
---@return NUIGlowSettingsCard card
---@return number newYOffset
---@return table widgets
function GUIFrame:CreateGlowSettingsCard(scrollChild, yOffset, config)
    config = config or {}
    local title = config.title or "Glow Settings"
    local db = config.db
    local dbKeys = config.dbKeys or {}
    local onChange = config.onChangeCallback
    local onHeightChange = config.onHeightChange
    local allowedTypes = config.glowTypes

    local glowTypeOptions = GLOW_TYPES
    if allowedTypes then
        glowTypeOptions = {}
        for _, glowType in ipairs(GLOW_TYPES) do
            for _, allowed in ipairs(allowedTypes) do
                if glowType.key == allowed then
                    table_insert(glowTypeOptions, glowType)
                    break
                end
            end
        end
    end

    local keys = {
        enabled = dbKeys.enabled or "GlowEnabled",
        type = dbKeys.type or "GlowType",
        color = dbKeys.color or "GlowColor",
        lines = dbKeys.lines or "GlowLines",
        frequency = dbKeys.frequency or "GlowFrequency",
        length = dbKeys.length or "GlowLength",
        thickness = dbKeys.thickness or "GlowThickness",
        border = dbKeys.border or "GlowBorder",
        scale = dbKeys.scale or "GlowScale",
        startAnim = dbKeys.startAnim or "GlowStartAnim",
        duration = dbKeys.duration or "GlowDuration",
        glowMode = dbKeys.glowMode or "GlowMode",
    }

    local showGlowMode = config.showGlowMode

    local widgets = {}
    local typeOnlyRows = {
        pixel = {},
        autocast = {},
        proc = {},
    }
    local frequencyRow

    local function setValue(key, val)
        db[key] = val
        if onChange then onChange() end
    end

    local card = GUIFrame:CreateCard(scrollChild, title, yOffset)

    -- Row 1: Enable Glow + When to Glow (if showGlowMode) or Enable Glow + Type
    local row1 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Glow", {
        value = db[keys.enabled],
        callback = function(checked)
            setValue(keys.enabled, checked)
            card.updateTypeVisibility()
        end
    })
    row1:AddWidget(enableCheck, 0.5)
    table_insert(widgets, enableCheck)

    if showGlowMode then
        local storedGlowMode = db[keys.glowMode]
        local validGlowMode = (storedGlowMode == "always" or storedGlowMode == "expiration") and storedGlowMode or
            "always"

        local glowModeDropdown = GUIFrame:CreateDropdown(row1, "When to Glow", {
            options = GLOW_MODES,
            value = validGlowMode,
            labelWidth = 100,
            callback = function(key)
                setValue(keys.glowMode, key)
            end
        })
        row1:AddWidget(glowModeDropdown, 0.5)
        table_insert(widgets, glowModeDropdown)
    else
        local typeDropdown = GUIFrame:CreateDropdown(row1, "Type", {
            options = glowTypeOptions,
            value = db[keys.type],
            callback = function(val)
                setValue(keys.type, val)
                C_Timer.After(0.2, function()
                    card.updateTypeVisibility()
                    GUIFrame:RefreshContent()
                end)
            end
        })
        row1:AddWidget(typeDropdown, 0.5)
        table_insert(widgets, typeDropdown)
    end
    card:AddRow(row1, Theme.rowHeight)

    local separator = GUIFrame:CreateSeparator(card.content)
    card:AddRow(separator, Theme.rowHeightSeparator)

    -- Row 2: Type + Color (if showGlowMode) or Speed + Color
    local row2 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    if showGlowMode then
        local typeDropdown = GUIFrame:CreateDropdown(row2, "Type", {
            options = glowTypeOptions,
            value = db[keys.type],
            callback = function(val)
                setValue(keys.type, val)
                C_Timer.After(0.2, function()
                    card.updateTypeVisibility()
                    GUIFrame:RefreshContent()
                end)
            end
        })
        row2:AddWidget(typeDropdown, 0.5)
        table_insert(widgets, typeDropdown)
    else
        local freqSlider = GUIFrame:CreateSlider(row2, "Speed", {
            min = 0.05,
            max = 1,
            step = 0.05,
            value = db[keys.frequency],
            callback = function(val) setValue(keys.frequency, val) end
        })
        row2:AddWidget(freqSlider, 0.5)
        table_insert(widgets, freqSlider)
    end

    local colorPicker = GUIFrame:CreateColorPicker(row2, "Color", {
        color = db[keys.color],
        callback = function(r, g, b, a)
            db[keys.color] = { r, g, b, a }
            if onChange then onChange() end
        end
    })
    row2:AddWidget(colorPicker, 0.5)
    table_insert(widgets, colorPicker)
    card:AddRow(row2, Theme.rowHeight)

    -- Row 3: Speed (full width) - only if showGlowMode
    if showGlowMode then
        local rowFreq = GUIFrame:CreateRow(card.content, Theme.rowHeight)
        local freqSlider = GUIFrame:CreateSlider(rowFreq, "Speed", {
            min = 0.05,
            max = 1,
            step = 0.05,
            value = db[keys.frequency],
            callback = function(val) setValue(keys.frequency, val) end
        })
        rowFreq:AddWidget(freqSlider, 1)
        table_insert(widgets, freqSlider)
        card:AddRow(rowFreq, Theme.rowHeight)
        frequencyRow = rowFreq
    else
        frequencyRow = row2
    end

    local rowPixel1 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local linesSlider = GUIFrame:CreateSlider(rowPixel1, "Lines", {
        min = 1,
        max = 16,
        step = 1,
        value = db[keys.lines],
        callback = function(val) setValue(keys.lines, val) end
    })
    rowPixel1:AddWidget(linesSlider, 0.5)
    table_insert(widgets, linesSlider)

    local lengthSlider = GUIFrame:CreateSlider(rowPixel1, "Length", {
        min = 1,
        max = 20,
        step = 1,
        value = db[keys.length],
        callback = function(val) setValue(keys.length, val) end
    })
    rowPixel1:AddWidget(lengthSlider, 0.5)
    table_insert(widgets, lengthSlider)
    card:AddRow(rowPixel1, Theme.rowHeight)
    table_insert(typeOnlyRows.pixel, rowPixel1)

    local rowPixel2 = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local thicknessSlider = GUIFrame:CreateSlider(rowPixel2, "Thickness", {
        min = 1,
        max = 8,
        step = 1,
        value = db[keys.thickness],
        callback = function(val) setValue(keys.thickness, val) end
    })
    rowPixel2:AddWidget(thicknessSlider, 0.5)
    table_insert(widgets, thicknessSlider)

    local borderCheck = GUIFrame:CreateCheckbox(rowPixel2, "Border", {
        value = db[keys.border],
        callback = function(checked) setValue(keys.border, checked) end
    })
    rowPixel2:AddWidget(borderCheck, 0.5)
    table_insert(widgets, borderCheck)
    card:AddRow(rowPixel2, Theme.rowHeight)
    table_insert(typeOnlyRows.pixel, rowPixel2)

    local rowAutocast = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local particlesSlider = GUIFrame:CreateSlider(rowAutocast, "Particles", {
        min = 1,
        max = 16,
        step = 1,
        value = db[keys.lines],
        callback = function(val) setValue(keys.lines, val) end
    })
    rowAutocast:AddWidget(particlesSlider, 0.5)
    table_insert(widgets, particlesSlider)

    local scaleSlider = GUIFrame:CreateSlider(rowAutocast, "Scale", {
        min = 0.5,
        max = 3,
        step = 0.1,
        value = db[keys.scale],
        callback = function(val) setValue(keys.scale, val) end
    })
    rowAutocast:AddWidget(scaleSlider, 0.5)
    table_insert(widgets, scaleSlider)
    card:AddRow(rowAutocast, Theme.rowHeight)
    table_insert(typeOnlyRows.autocast, rowAutocast)

    local rowProc = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local startAnimCheck = GUIFrame:CreateCheckbox(rowProc, "Start Animation", {
        value = db[keys.startAnim],
        callback = function(checked) setValue(keys.startAnim, checked) end
    })
    rowProc:AddWidget(startAnimCheck, 0.5)
    table_insert(widgets, startAnimCheck)

    local durationSlider = GUIFrame:CreateSlider(rowProc, "Duration", {
        min = 0.5,
        max = 5,
        step = 0.1,
        value = db[keys.duration],
        callback = function(val) setValue(keys.duration, val) end
    })
    rowProc:AddWidget(durationSlider, 0.5)
    table_insert(widgets, durationSlider)
    card:AddRow(rowProc, Theme.rowHeight)
    table_insert(typeOnlyRows.proc, rowProc)

    card.glowWidgets = widgets
    card.typeOnlyRows = typeOnlyRows
    card.frequencyRow = frequencyRow
    card._initialized = false
    card._hasInternalWidgetState = true

    function card.updateTypeVisibility()
        local glowType = db[keys.type]
        local enabled = db[keys.enabled]

        local baseHeight = card.headerHeight + Theme.paddingSmall * 2
        local currentY = (Theme.rowHeight + Theme.paddingSmall) * 2 + Theme.rowHeightSeparator + Theme.paddingSmall

        if showGlowMode then
            local showFrequency = (glowType == "pixel" or glowType == "autocast" or glowType == "button")
            frequencyRow:SetShown(showFrequency)
            if showFrequency then
                frequencyRow:ClearAllPoints()
                frequencyRow:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, -currentY)
                frequencyRow:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, -currentY)
                currentY = currentY + Theme.rowHeight + Theme.paddingSmall
            end
        end

        for typeName, rows in pairs(typeOnlyRows) do
            local show = (typeName == glowType)
            for _, row in ipairs(rows) do
                row:SetShown(show)
                if show then
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, -currentY)
                    row:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0, -currentY)
                    currentY = currentY + Theme.rowHeight + Theme.paddingSmall
                end
            end
        end

        card.content:SetHeight(currentY)
        local newHeight = baseHeight + currentY
        local heightChanged = card.contentHeight ~= newHeight
        card.contentHeight = newHeight
        card:SetHeight(newHeight)

        for _, widget in ipairs(widgets) do
            if widget ~= enableCheck and widget.SetEnabled then
                widget:SetEnabled(enabled)
            end
        end

        if heightChanged and onHeightChange and card._initialized then
            onHeightChange()
        end
    end

    function card:SetEnabled(cardEnabled)
        self:SetAlpha(cardEnabled and 1 or 0.5)
        if cardEnabled then
            self.updateTypeVisibility()
        else
            for _, widget in ipairs(self.glowWidgets) do
                if widget.SetEnabled then widget:SetEnabled(false) end
            end
        end
    end

    card.updateTypeVisibility()
    card._initialized = true

    ---@cast card NUIGlowSettingsCard
    return card, card:GetNextOffset(), widgets
end
