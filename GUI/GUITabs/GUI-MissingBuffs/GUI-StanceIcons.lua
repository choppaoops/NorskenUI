---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local pairs = pairs
local type = type
local CreateFrame = CreateFrame
local C_Spell = C_Spell

local StanceData = NRSKNUI.StanceData

local SIDEBAR_WIDTH = 180
local ITEM_HEIGHT = 28
local LIST_PADDING = 4

local selectedItem = "General"

local SIDEBAR_ITEMS = {
    { key = "sep_warrior", name = "Warrior",  order = 9,  type = "separator" },
    { key = "WARRIOR",     name = "Stances",  icon = 132349, order = 10, type = "class", class = "WARRIOR" },

    { key = "sep_paladin", name = "Paladin",  order = 19, type = "separator" },
    { key = "PALADIN",     name = "Auras",    icon = 135893, order = 20, type = "class", class = "PALADIN" },

    { key = "sep_druid",   name = "Druid",    order = 29, type = "separator" },
    { key = "DRUID",       name = "Forms",    icon = 136096, order = 30, type = "class", class = "DRUID" },

    { key = "sep_evoker",  name = "Evoker",   order = 39, type = "separator" },
    { key = "EVOKER",      name = "Attunement", icon = 5198700, order = 40, type = "class", class = "EVOKER" },

    { key = "sep_priest",  name = "Priest",   order = 49, type = "separator" },
    { key = "PRIEST",      name = "Shadowform", icon = 136207, order = 50, type = "class", class = "PRIEST" },
}

local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("StanceIcons", true)
    end
    return nil
end

---@param parent Frame
---@param iconData any
---@param size? number
local function CreateIconWidget(parent, iconData, size)
    size = size or 40
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(size + 8, size)
    container.fixedWidth = size + 8

    local iconFrame = CreateFrame("Frame", nil, container)
    iconFrame:SetSize(size, size)
    iconFrame:SetPoint("LEFT", container, "LEFT", 4, 0)

    iconFrame.texture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.texture:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
    iconFrame.texture:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)

    if type(iconData) == "table" then
        if iconData.atlas then
            iconFrame.texture:SetAtlas(iconData.atlas)
        elseif iconData.textureId then
            NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)
            iconFrame.texture:SetTexture(iconData.textureId)
        elseif iconData.spellId then
            NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)
            local texture = C_Spell.GetSpellTexture(iconData.spellId)
            iconFrame.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
    elseif type(iconData) == "number" then
        NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)
        local texture = C_Spell.GetSpellTexture(iconData)
        iconFrame.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    else
        iconFrame.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    local borderTop = iconFrame:CreateTexture(nil, "OVERLAY")
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
    borderTop:SetColorTexture(0, 0, 0, 1)

    local borderBottom = iconFrame:CreateTexture(nil, "OVERLAY")
    borderBottom:SetHeight(1)
    borderBottom:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetColorTexture(0, 0, 0, 1)

    local borderLeft = iconFrame:CreateTexture(nil, "OVERLAY")
    borderLeft:SetWidth(1)
    borderLeft:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 0, 0)
    borderLeft:SetColorTexture(0, 0, 0, 1)

    local borderRight = iconFrame:CreateTexture(nil, "OVERLAY")
    borderRight:SetWidth(1)
    borderRight:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
    borderRight:SetColorTexture(0, 0, 0, 1)

    return container
end

GUIFrame:RegisterPanel("stanceIcons", function(container)
    local db = NRSKNUI.db and NRSKNUI.db.profile.MissingBuffs
    if not db then return nil end

    db.StanceDisplay = db.StanceDisplay or {}
    db.Stances = db.Stances or {}

    local function ApplySettings()
        local mod = GetModule()
        if mod and mod.ApplySettings then mod:ApplySettings() end
    end

    local function Refresh()
        local mod = GetModule()
        if mod and mod.Refresh then mod:Refresh() end
    end

    local function RefreshContent()
        C_Timer.After(0.05, function()
            GUIFrame:RefreshContent()
        end)
    end

    local function GetSidebarItems()
        local items = {}
        for _, item in ipairs(SIDEBAR_ITEMS) do
            table_insert(items, {
                key = item.key,
                name = item.name,
                icon = item.icon,
                order = item.order,
                type = item.type,
                class = item.class,
            })
        end
        table.sort(items, function(a, b) return a.order < b.order end)
        return items
    end

    local miniSidebar = NRSKNUI.GUI.CreateMiniSidebar(container, {
        sidebarWidth = SIDEBAR_WIDTH,
        listPadding = LIST_PADDING,
        itemHeight = ITEM_HEIGHT,

        getItems = GetSidebarItems,
        getItemKey = function(item) return item.key end,

        renderItem = function(btn, item, isSelected)
            local iconTexture = nil
            if item.icon and item.icon > 0 then
                iconTexture = item.icon
            end
            if iconTexture then
                btn._icon:SetTexture(iconTexture)
                NRSKNUI:ApplyZoom(btn._icon, NRSKNUI.GlobalZoom)
            else
                btn._icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end

            btn._label:SetShadowColor(0, 0, 0, 0)
            btn._label:SetText(item.name)

            if item.class and RAID_CLASS_COLORS[item.class] then
                local cc = RAID_CLASS_COLORS[item.class]
                btn._label:SetTextColor(cc.r, cc.g, cc.b, 1)
            elseif isSelected then
                btn._label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            else
                btn._label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
            end
        end,

        onItemSelected = function(item)
            selectedItem = item.key
            RefreshContent()
        end,

        buttonArea = {
            buttonHeight = ITEM_HEIGHT,
            hideSeparator = true,
            listSpacing = 4,
            buttons = {
                {
                    text = "General Settings",
                    onClick = function()
                        selectedItem = "General"
                        RefreshContent()
                    end,
                },
            },
        },
    })

    miniSidebar.SelectItem(selectedItem)
    miniSidebar.RefreshList()

    local contentChild = miniSidebar.contentArea.scrollChild
    local yOffset = Theme.paddingSmall

    local itemData = nil
    for _, item in ipairs(SIDEBAR_ITEMS) do
        if item.key == selectedItem then
            itemData = item
            break
        end
    end

    if selectedItem == "General" then
        local card1 = GUIFrame:CreateCard(contentChild, "Stance Icon Display", yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
        local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Stance Icon", {
            value = db.StanceDisplay.Enabled ~= false,
            callback = function(checked)
                db.StanceDisplay.Enabled = checked
                local mod = GetModule()
                if mod then
                    if checked then NorskenUI:EnableModule("StanceIcons") else NorskenUI:DisableModule("StanceIcons") end
                end
            end,
            msgPopup = true,
            msgText = "Stance Icon",
        })
        row1:AddWidget(enableCheck, 1)
        card1:AddRow(row1, Theme.rowHeightLast, 0)

        yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

        local card2 = GUIFrame:CreateCard(contentChild, "Display Settings", yOffset)
        miniSidebar.contentArea.RegisterCard(card2)

        local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
        local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
            min = 24,
            max = 96,
            step = 1,
            value = db.StanceDisplay.IconSize or 48,
            callback = function(val)
                db.StanceDisplay.IconSize = val; ApplySettings()
            end
        })
        row2a:AddWidget(iconSizeSlider, 1)
        card2:AddRow(row2a, Theme.rowHeight)

        local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
        local showTextCheck = GUIFrame:CreateCheckbox(row2b, "Show Missing Text", {
            value = db.StanceDisplay.ShowMissingText ~= false,
            callback = function(checked)
                db.StanceDisplay.ShowMissingText = checked
                Refresh()
            end
        })
        row2b:AddWidget(showTextCheck, 1)
        card2:AddRow(row2b, Theme.rowHeightLast, 0)

        yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

        db.StanceDisplay.FontShadow = db.StanceDisplay.FontShadow or {}
        local fontCard
        fontCard, yOffset = GUIFrame:CreateFontSettingsCard(contentChild, yOffset, {
            title = "Font Settings",
            db = db.StanceDisplay,
            fontSizeRange = { 8, 32 },
            includeSoftOutline = true,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(fontCard)

        db.StanceDisplay.Position = db.StanceDisplay.Position or {}
        local positionCard
        positionCard, yOffset = GUIFrame:CreatePositionCard(contentChild, yOffset, {
            title = "Position Settings",
            db = db.StanceDisplay,
            defaults = {
                selfPoint = "CENTER",
                anchorPoint = "CENTER",
                xOffset = 0,
                yOffset = 150,
            },
            showAnchorFrameType = false,
            showStrata = false,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(positionCard)

    elseif itemData and itemData.type == "class" then
        local classKey = itemData.key
        db.Stances[classKey] = db.Stances[classKey] or {}

        if classKey == "WARRIOR" or classKey == "PALADIN" then
            local title = classKey == "WARRIOR" and "Warrior Stances" or "Paladin Auras"
            local card = GUIFrame:CreateCard(contentChild, title, yOffset)
            miniSidebar.contentArea.RegisterCard(card)

            local stanceOptions = StanceData:GetStanceOptions(classKey)
            local classData = StanceData[classKey]

            if classData and classData.specs then
                local specWidgets = {}

                local function UpdateSpecWidgetStates()
                    for specName, widgets in pairs(specWidgets) do
                        local specEnabledKey = specName .. "Enabled"
                        local specEnabled = db.Stances[classKey][specEnabledKey] == true

                        if widgets.dropdown and widgets.dropdown.SetEnabled then
                            widgets.dropdown:SetEnabled(specEnabled)
                        end
                        if widgets.reverseIcon and widgets.reverseIcon.SetEnabled then
                            widgets.reverseIcon:SetEnabled(specEnabled)
                        end
                    end
                end

                local isFirst = true
                for specName, specInfo in pairs(classData.specs) do
                    if not isFirst then
                        local sep = GUIFrame:CreateSeparator(card.content)
                        card:AddRow(sep, Theme.rowHeightSeparator)
                    end
                    isFirst = false

                    local specRow = GUIFrame:CreateRow(card.content, 40)

                    local specIconId = specInfo.icon and { textureId = specInfo.icon } or 134400
                    local specIconWidget = CreateIconWidget(specRow, specIconId, 32)
                    specRow:AddWidget(specIconWidget, 0.1)

                    local specEnabledKey = specName .. "Enabled"
                    local specToggle = GUIFrame:CreateCheckbox(specRow, specName, {
                        value = db.Stances[classKey][specEnabledKey] == true,
                        callback = function(checked)
                            db.Stances[classKey][specEnabledKey] = checked
                            UpdateSpecWidgetStates()
                            Refresh()
                        end
                    })
                    specRow:AddWidget(specToggle, 0.35)

                    local reverseIconKey = specName .. "ReverseIcon"
                    local reverseToggle = GUIFrame:CreateCheckbox(specRow, "Reverse Icon", {
                        value = db.Stances[classKey][reverseIconKey] == true,
                        tooltip = "Show current stance icon instead of required stance",
                        callback = function(checked)
                            db.Stances[classKey][reverseIconKey] = checked
                            Refresh()
                        end
                    })
                    specRow:AddWidget(reverseToggle, 0.25)

                    local defaultStance = StanceData:GetDefaultStance(classKey, specName)
                    local specDropdown = GUIFrame:CreateDropdown(specRow, "Required", {
                        options = stanceOptions,
                        value = db.Stances[classKey][specName] or tostring(defaultStance),
                        labelWidth = 80,
                        callback = function(key)
                            db.Stances[classKey][specName] = key
                            Refresh()
                        end
                    })
                    specRow:AddWidget(specDropdown, 0.3)

                    specWidgets[specName] = { toggle = specToggle, dropdown = specDropdown, reverseIcon = reverseToggle }
                    card:AddRow(specRow, 40)
                end

                C_Timer.After(0, UpdateSpecWidgetStates)
            end

            yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall

        elseif classKey == "DRUID" then
            local card = GUIFrame:CreateCard(contentChild, "Druid Forms", yOffset)
            miniSidebar.contentArea.RegisterCard(card)

            local balanceRow = GUIFrame:CreateRow(card.content, 40)
            local balanceIcon = CreateIconWidget(balanceRow, { textureId = StanceData.DRUID.specs[102].icon }, 40)
            balanceRow:AddWidget(balanceIcon, 0.1)

            local balanceToggle = GUIFrame:CreateCheckbox(balanceRow, "Balance: Require Moonkin Form", {
                value = db.Stances.DRUID.BalanceEnabled == true,
                callback = function(checked)
                    db.Stances.DRUID.BalanceEnabled = checked; Refresh()
                end
            })
            balanceRow:AddWidget(balanceToggle, 0.6)

            local balanceCombatToggle = GUIFrame:CreateCheckbox(balanceRow, "Combat Only", {
                value = db.Stances.DRUID.BalanceCombatOnly == true,
                callback = function(checked)
                    db.Stances.DRUID.BalanceCombatOnly = checked; Refresh()
                end
            })
            balanceRow:AddWidget(balanceCombatToggle, 0.3)
            card:AddRow(balanceRow, 40)

            local sep1 = GUIFrame:CreateSeparator(card.content)
            card:AddRow(sep1, Theme.rowHeightSeparator)

            local feralRow = GUIFrame:CreateRow(card.content, 40)
            local feralIcon = CreateIconWidget(feralRow, { textureId = StanceData.DRUID.specs[103].icon }, 40)
            feralRow:AddWidget(feralIcon, 0.1)

            local feralToggle = GUIFrame:CreateCheckbox(feralRow, "Feral: Require Cat Form", {
                value = db.Stances.DRUID.FeralEnabled == true,
                callback = function(checked)
                    db.Stances.DRUID.FeralEnabled = checked; Refresh()
                end
            })
            feralRow:AddWidget(feralToggle, 0.6)

            local feralCombatToggle = GUIFrame:CreateCheckbox(feralRow, "Combat Only", {
                value = db.Stances.DRUID.FeralCombatOnly == true,
                callback = function(checked)
                    db.Stances.DRUID.FeralCombatOnly = checked; Refresh()
                end
            })
            feralRow:AddWidget(feralCombatToggle, 0.3)
            card:AddRow(feralRow, 40)

            local sep2 = GUIFrame:CreateSeparator(card.content)
            card:AddRow(sep2, Theme.rowHeightSeparator)

            local guardianRow = GUIFrame:CreateRow(card.content, 40)
            local guardianIcon = CreateIconWidget(guardianRow, { textureId = StanceData.DRUID.specs[104].icon }, 40)
            guardianRow:AddWidget(guardianIcon, 0.1)

            local guardianToggle = GUIFrame:CreateCheckbox(guardianRow, "Guardian: Require Bear Form", {
                value = db.Stances.DRUID.GuardianEnabled == true,
                callback = function(checked)
                    db.Stances.DRUID.GuardianEnabled = checked; Refresh()
                end
            })
            guardianRow:AddWidget(guardianToggle, 0.6)

            local guardianCombatToggle = GUIFrame:CreateCheckbox(guardianRow, "Combat Only", {
                value = db.Stances.DRUID.GuardianCombatOnly == true,
                callback = function(checked)
                    db.Stances.DRUID.GuardianCombatOnly = checked; Refresh()
                end
            })
            guardianRow:AddWidget(guardianCombatToggle, 0.3)
            card:AddRow(guardianRow, 40)

            yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall

        elseif classKey == "EVOKER" then
            local card = GUIFrame:CreateCard(contentChild, "Augmentation Evoker Attunement", yOffset)
            miniSidebar.contentArea.RegisterCard(card)

            local evokerRow = GUIFrame:CreateRow(card.content, 40)
            local evokerIcon = CreateIconWidget(evokerRow, { textureId = StanceData.EVOKER.specs.Augmentation.icon }, 40)
            evokerRow:AddWidget(evokerIcon, 0.1)

            local evokerToggle = GUIFrame:CreateCheckbox(evokerRow, "Require Attunement", {
                value = db.Stances.EVOKER.AugmentationEnabled == true,
                callback = function(checked)
                    db.Stances.EVOKER.AugmentationEnabled = checked; Refresh()
                end
            })
            evokerRow:AddWidget(evokerToggle, 0.5)

            local attunementOptions = StanceData:GetStanceOptions("EVOKER")
            local evokerDropdown = GUIFrame:CreateDropdown(evokerRow, "Required", {
                options = attunementOptions,
                value = db.Stances.EVOKER.Augmentation or tostring(StanceData.EVOKER.defaultAttunement),
                labelWidth = 100,
                callback = function(key)
                    db.Stances.EVOKER.Augmentation = key; Refresh()
                end
            })
            evokerRow:AddWidget(evokerDropdown, 0.4)
            card:AddRow(evokerRow, 40)

            yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall

        elseif classKey == "PRIEST" then
            local card = GUIFrame:CreateCard(contentChild, "Shadow Priest Shadowform", yOffset)
            miniSidebar.contentArea.RegisterCard(card)

            local priestRow = GUIFrame:CreateRow(card.content, 40)
            local priestIcon = CreateIconWidget(priestRow, { textureId = StanceData.PRIEST.specs.Shadow.icon }, 40)
            priestRow:AddWidget(priestIcon, 0.1)

            local priestToggle = GUIFrame:CreateCheckbox(priestRow, "Require Shadowform", {
                value = db.Stances.PRIEST.ShadowEnabled == true,
                callback = function(checked)
                    db.Stances.PRIEST.ShadowEnabled = checked; Refresh()
                end
            })
            priestRow:AddWidget(priestToggle, 0.9)
            card:AddRow(priestRow, 40)

            yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall
        end
    end

    miniSidebar.contentArea.SetContentHeight(yOffset)
    C_Timer.After(0, function()
        miniSidebar.contentArea.UpdateScrollBarVisibility()
        miniSidebar.contentArea.UpdateCardWidths()
    end)

    return miniSidebar.panel
end)
