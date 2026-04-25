---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local CreateFrame = CreateFrame
local ipairs = ipairs

local function CreateTextureSelector(parent, textures, currentTexture, getColorFunc, onSelect)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(60 + Theme.paddingMedium)

    local buttons = {}
    local buttonSize = 60

    for _, texData in ipairs(textures) do
        local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
        btn:SetSize(buttonSize, buttonSize)
        btn:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], 1)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 8, -8)
        tex:SetPoint("BOTTOMRIGHT", -8, 8)
        tex:SetTexture(texData.path)
        btn.tex = tex
        btn.textureKey = texData.key

        local function UpdateVisuals()
            local isSelected = currentTexture == btn.textureKey
            local r, g, b, a = 1, 1, 1, 1
            if getColorFunc then r, g, b, a = getColorFunc() end

            if btn.disabled then
                btn:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 0.6)
                tex:SetVertexColor(r * 0.3, g * 0.3, b * 0.3)
                tex:SetAlpha(0.5)
            elseif isSelected then
                btn:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                tex:SetVertexColor(r, g, b)
                tex:SetAlpha(a)
            elseif btn.hover then
                btn:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                tex:SetVertexColor(r * 0.8, g * 0.8, b * 0.8)
                tex:SetAlpha(a * 0.9)
            else
                btn:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
                tex:SetVertexColor(r * 0.6, g * 0.6, b * 0.6)
                tex:SetAlpha(a * 0.8)
            end
        end
        btn.UpdateVisuals = UpdateVisuals

        btn:SetScript("OnEnter", function(self)
            self.hover = true
            UpdateVisuals()
        end)

        btn:SetScript("OnLeave", function(self)
            self.hover = false
            UpdateVisuals()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function(self)
            if self.disabled then return end
            currentTexture = self.textureKey
            for _, b in ipairs(buttons) do b.UpdateVisuals() end
            if onSelect then onSelect(self.textureKey) end
        end)

        UpdateVisuals()
        table_insert(buttons, btn)
    end

    for i, btn in ipairs(buttons) do
        if i == 1 then
            btn:SetPoint("LEFT", container, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", Theme.paddingMedium, 0)
        end
    end

    function container:SetEnabled(enabled)
        for _, btn in ipairs(buttons) do
            btn.disabled = not enabled
            btn:EnableMouse(enabled)
            btn.UpdateVisuals()
        end
    end

    function container:SetValue(textureKey)
        currentTexture = textureKey
        for _, btn in ipairs(buttons) do btn.UpdateVisuals() end
    end

    function container:RefreshColors()
        for _, btn in ipairs(buttons) do btn.UpdateVisuals() end
    end

    container.buttons = buttons
    return container
end

GUIFrame:RegisterContent("cursorCircle", function(scrollChild, yOffset)
    ---@type CursorCircle?
    local CC = NorskenUI and NorskenUI:GetModule("CursorCircle", true)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.CursorCircle
    if not db or not CC then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local colorModeWidgets = {}
    local throttleWidgets = {}
    local gcdWidgets = {}
    local gcdSeparateWidgets = {}
    local gcdRingColorModeWidgets = {}
    local gcdSwipeColorModeWidgets = {}
    local textureSelector = nil
    local gcdTextureSelector = nil
    local TEXTURE_ROW_HEIGHT = 65

    local gcd = db.GCD

    local function ApplySettings()
        if CC and CC.ApplySettings then CC:ApplySettings() end
        if textureSelector then textureSelector:RefreshColors() end
        if gcdTextureSelector then gcdTextureSelector:RefreshColors() end
    end

    local function GetEffectiveColor()
        return NRSKNUI:GetAccentColor(db.ColorMode, db.Color)
    end

    local function GetGCDEffectiveColor()
        return NRSKNUI:GetAccentColor(gcd.RingColorMode, gcd.RingColor)
    end

    local function UpdateConditionalStates()
        local isCustomColor = db.ColorMode == "custom"
        for _, widget in ipairs(colorModeWidgets) do
            if widget.SetEnabled then widget:SetEnabled(isCustomColor) end
        end

        local throttleEnabled = db.UseUpdateInterval
        for _, widget in ipairs(throttleWidgets) do
            if widget.SetEnabled then widget:SetEnabled(throttleEnabled) end
        end

        local gcdEnabled = gcd.Mode ~= "disabled"
        local isSeparateMode = gcd.Mode == "separate"

        for _, widget in ipairs(gcdWidgets) do
            if widget.SetEnabled then widget:SetEnabled(gcdEnabled) end
        end

        for _, widget in ipairs(gcdSeparateWidgets) do
            if widget.SetEnabled then widget:SetEnabled(gcdEnabled and isSeparateMode) end
        end

        if gcdTextureSelector then
            gcdTextureSelector:SetEnabled(gcdEnabled and isSeparateMode)
        end

        local isGCDRingCustomColor = gcd.RingColorMode == "custom"
        for _, widget in ipairs(gcdRingColorModeWidgets) do
            if widget.SetEnabled then widget:SetEnabled(gcdEnabled and isSeparateMode and isGCDRingCustomColor) end
        end

        local isGCDSwipeCustomColor = gcd.SwipeColorMode == "custom"
        for _, widget in ipairs(gcdSwipeColorModeWidgets) do
            if widget.SetEnabled then widget:SetEnabled(gcdEnabled and isGCDSwipeCustomColor) end
        end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if textureSelector then textureSelector:SetEnabled(db.Enabled) end
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do callback() end
        else
            if gcdTextureSelector then gcdTextureSelector:SetEnabled(false) end
        end
    end

    table_insert(postUpdateCallbacks, UpdateConditionalStates)

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Cursor Circle", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Cursor Circle", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if CC then
                if checked then NorskenUI:EnableModule("CursorCircle") else NorskenUI:DisableModule("CursorCircle") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Cursor Circle",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: General Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "General Settings", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local gcdModeDropdown = GUIFrame:CreateDropdown(row2a, "GCD Mode", {
        options = CC.GCDModeOptions,
        value = gcd.Mode,
        callback = function(key)
            gcd.Mode = key
            ApplySettings()
            UpdateConditionalStates()
        end
    })
    row2a:AddWidget(gcdModeDropdown, 0.5)
    manager:Register(gcdModeDropdown, "all")

    local visModeDropdown = GUIFrame:CreateDropdown(row2a, "Visibility", {
        options = CC.VisibilityModeOptions,
        value = db.VisibilityMode,
        callback = function(key)
            db.VisibilityMode = key
            ApplySettings()
        end
    })
    row2a:AddWidget(visModeDropdown, 0.5)
    manager:Register(visModeDropdown, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local throttleCheck = GUIFrame:CreateCheckbox(row2b, "Limit Update Rate", {
        value = db.UseUpdateInterval,
        callback = function(checked)
            db.UseUpdateInterval = checked
            UpdateConditionalStates()
        end
    })
    row2b:AddWidget(throttleCheck, 0.5)
    manager:Register(throttleCheck, "all")

    local intervalSlider = GUIFrame:CreateSlider(row2b, "Interval (sec)", {
        min = 0.01,
        max = 0.1,
        step = 0.001,
        value = db.UpdateInterval,
        callback = function(val) db.UpdateInterval = val end
    })
    row2b:AddWidget(intervalSlider, 0.5)
    manager:Register(intervalSlider, "all")
    table_insert(throttleWidgets, intervalSlider)
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Main Ring Settings
    local card3 = GUIFrame:CreateCard(scrollChild, "Main Ring Settings", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, TEXTURE_ROW_HEIGHT)
    textureSelector = CreateTextureSelector(row3a, CC.Textures, db.Texture, GetEffectiveColor, function(key)
        db.Texture = key
        ApplySettings()
    end)
    textureSelector:SetPoint("TOPLEFT", row3a, "TOPLEFT", 0, 0)
    textureSelector:SetPoint("TOPRIGHT", row3a, "TOPRIGHT", 0, 0)
    textureSelector:SetEnabled(db.Enabled)
    card3:AddRow(row3a, TEXTURE_ROW_HEIGHT)

    local sep3 = GUIFrame:CreateSeparator(card3.content)
    card3:AddRow(sep3, Theme.rowHeightSeparator)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local sizeSlider = GUIFrame:CreateSlider(row3b, "Size", {
        min = 20,
        max = 150,
        step = 1,
        value = db.Size,
        callback = function(val)
            db.Size = val
            ApplySettings()
        end
    })
    row3b:AddWidget(sizeSlider, 1)
    manager:Register(sizeSlider, "all")
    card3:AddRow(row3b, Theme.rowHeight)

    local row3c = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local colorModeDropdown = GUIFrame:CreateDropdown(row3c, "Color Mode", {
        options = NRSKNUI.ColorModeOptions,
        value = db.ColorMode,
        callback = function(key)
            db.ColorMode = key
            ApplySettings()
            UpdateConditionalStates()
        end
    })
    row3c:AddWidget(colorModeDropdown, 0.5)
    manager:Register(colorModeDropdown, "all")

    local colorPicker = GUIFrame:CreateColorPicker(row3c, "Custom Color", {
        color = db.Color,
        callback = function(r, g, b, a)
            db.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row3c:AddWidget(colorPicker, 0.5)
    manager:Register(colorPicker, "all")
    table_insert(colorModeWidgets, colorPicker)
    card3:AddRow(row3c, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: GCD Settings
    local card4 = GUIFrame:CreateCard(scrollChild, "GCD Settings", yOffset)
    manager:Register(card4, "all")
    table_insert(gcdWidgets, card4)

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local gcdSwipeColorModeDropdown = GUIFrame:CreateDropdown(row4a, "Swipe Color Mode", {
        options = NRSKNUI.ColorModeOptions,
        value = gcd.SwipeColorMode,
        callback = function(key)
            gcd.SwipeColorMode = key
            ApplySettings()
            UpdateConditionalStates()
        end
    })
    row4a:AddWidget(gcdSwipeColorModeDropdown, 0.5)
    manager:Register(gcdSwipeColorModeDropdown, "all")
    table_insert(gcdWidgets, gcdSwipeColorModeDropdown)

    local gcdSwipeColorPicker = GUIFrame:CreateColorPicker(row4a, "Custom Color", {
        color = gcd.SwipeColor,
        callback = function(r, g, b, a)
            gcd.SwipeColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4a:AddWidget(gcdSwipeColorPicker, 0.5)
    manager:Register(gcdSwipeColorPicker, "all")
    table_insert(gcdWidgets, gcdSwipeColorPicker)
    table_insert(gcdSwipeColorModeWidgets, gcdSwipeColorPicker)
    card4:AddRow(row4a, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local reverseCheck = GUIFrame:CreateCheckbox(row4b, "Reverse Swipe", {
        value = gcd.Reverse,
        callback = function(checked)
            gcd.Reverse = checked
            ApplySettings()
        end
    })
    row4b:AddWidget(reverseCheck, 0.5)
    manager:Register(reverseCheck, "all")
    table_insert(gcdWidgets, reverseCheck)

    local hideOOCCheck = GUIFrame:CreateCheckbox(row4b, "Only In Combat", {
        value = gcd.HideOutOfCombat,
        callback = function(checked)
            gcd.HideOutOfCombat = checked
            ApplySettings()
        end
    })
    row4b:AddWidget(hideOOCCheck, 0.5)
    manager:Register(hideOOCCheck, "all")
    table_insert(gcdWidgets, hideOOCCheck)
    card4:AddRow(row4b, Theme.rowHeight)

    local sep4a = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(sep4a, Theme.rowHeightSeparator)

    local row4c = GUIFrame:CreateRow(card4.content, TEXTURE_ROW_HEIGHT)
    gcdTextureSelector = CreateTextureSelector(row4c, CC.Textures, gcd.Texture, GetGCDEffectiveColor, function(key)
        gcd.Texture = key
        ApplySettings()
    end)
    gcdTextureSelector:SetPoint("TOPLEFT", row4c, "TOPLEFT", 0, 0)
    gcdTextureSelector:SetPoint("TOPRIGHT", row4c, "TOPRIGHT", 0, 0)
    table_insert(gcdSeparateWidgets, gcdTextureSelector)
    card4:AddRow(row4c, TEXTURE_ROW_HEIGHT + Theme.paddingSmall)

    local sep4b = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(sep4b, Theme.rowHeightSeparator)

    local row4d = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local gcdSizeSlider = GUIFrame:CreateSlider(row4d, "Ring Size", {
        min = 10,
        max = 150,
        step = 1,
        value = gcd.Size,
        callback = function(val)
            gcd.Size = val
            ApplySettings()
        end
    })
    row4d:AddWidget(gcdSizeSlider, 1)
    manager:Register(gcdSizeSlider, "all")
    table_insert(gcdWidgets, gcdSizeSlider)
    table_insert(gcdSeparateWidgets, gcdSizeSlider)
    card4:AddRow(row4d, Theme.rowHeight)

    local row4e = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local gcdRingColorModeDropdown = GUIFrame:CreateDropdown(row4e, "Ring Color Mode", {
        options = NRSKNUI.ColorModeOptions,
        value = gcd.RingColorMode,
        callback = function(key)
            gcd.RingColorMode = key
            ApplySettings()
            if gcdTextureSelector then gcdTextureSelector:RefreshColors() end
            UpdateConditionalStates()
        end
    })
    row4e:AddWidget(gcdRingColorModeDropdown, 0.5)
    manager:Register(gcdRingColorModeDropdown, "all")
    table_insert(gcdWidgets, gcdRingColorModeDropdown)
    table_insert(gcdSeparateWidgets, gcdRingColorModeDropdown)

    local gcdRingColorPicker = GUIFrame:CreateColorPicker(row4e, "Custom Color", {
        color = gcd.RingColor,
        callback = function(r, g, b, a)
            gcd.RingColor = { r, g, b, a }
            ApplySettings()
            if gcdTextureSelector then gcdTextureSelector:RefreshColors() end
        end
    })
    row4e:AddWidget(gcdRingColorPicker, 0.5)
    manager:Register(gcdRingColorPicker, "all")
    table_insert(gcdWidgets, gcdRingColorPicker)
    table_insert(gcdSeparateWidgets, gcdRingColorPicker)
    table_insert(gcdRingColorModeWidgets, gcdRingColorPicker)
    card4:AddRow(row4e, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
