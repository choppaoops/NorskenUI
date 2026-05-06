---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local C_Spell = C_Spell

local BuffData = NRSKNUI.MissingBuffsData
local LOAD_CONDITIONS = BuffData.LOAD_CONDITIONS

local SIDEBAR_WIDTH = 180
local ITEM_HEIGHT = 28
local LIST_PADDING = 4

local selectedItem = "General"

local SIDEBAR_ITEMS = {
    { key = "sep_paladin",           name = "Paladin",                order = 9,  type = "separator" },
    { key = "BeaconOfLight",         name = "Beacon of Light",        icon = 53563,  order = 10, type = "targeted", class = "PALADIN" },
    { key = "BeaconOfFaith",         name = "Beacon of Faith",        icon = 156910, order = 11, type = "targeted", class = "PALADIN" },

    { key = "sep_evoker",            name = "Evoker",                 order = 19, type = "separator" },
    { key = "BlisteringScales",      name = "Blistering Scales",      icon = 360827, order = 20, type = "targeted", class = "EVOKER" },
    { key = "Timelessness",          name = "Timelessness",           icon = 412710, order = 21, type = "targeted", class = "EVOKER" },
    { key = "SourceOfMagic",         name = "Source of Magic",        icon = 369459, order = 22, type = "targeted", class = "EVOKER" },

    { key = "sep_shaman",            name = "Shaman",                 order = 29, type = "separator" },
    { key = "EarthShieldOthers",     name = "Earth Shield (Others)",  icon = 974,    order = 30, type = "targeted", class = "SHAMAN" },

    { key = "sep_druid",             name = "Druid",                  order = 39, type = "separator" },
    { key = "SymbioticRelationship", name = "Symbiotic Relationship", icon = 474750, order = 40, type = "targeted", class = "DRUID" },
}

local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("MissingBuffs", true)
    end
    return nil
end

GUIFrame:RegisterPanel("targetedBuffs", function(container)
    local db = NRSKNUI.db and NRSKNUI.db.profile.MissingBuffs
    if not db then return nil end

    db.TargetedBuffs = db.TargetedBuffs or {}
    db.TargetedBuffSettings = db.TargetedBuffSettings or {}
    db.TargetedBuffDisplay = db.TargetedBuffDisplay or {}

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
                iconTexture = C_Spell.GetSpellTexture(item.icon)
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

    local growDirectionOptions = {
        { key = "LEFT",   text = "Left" },
        { key = "CENTER", text = "Center" },
        { key = "RIGHT",  text = "Right" },
    }

    local itemData = nil
    for _, item in ipairs(SIDEBAR_ITEMS) do
        if item.key == selectedItem then
            itemData = item
            break
        end
    end

    if selectedItem == "General" then
        local card1 = GUIFrame:CreateCard(contentChild, "Targeted Buffs", yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Targeted Buffs", {
            value = db.TargetedBuffs.Enabled ~= false,
            callback = function(checked)
                db.TargetedBuffs.Enabled = checked
                Refresh()
            end,
            msgPopup = true,
            msgText = "Targeted Buffs",
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
            value = db.TargetedBuffDisplay.IconSize or 40,
            callback = function(val)
                db.TargetedBuffDisplay.IconSize = val; ApplySettings()
            end
        })
        row2a:AddWidget(iconSizeSlider, 0.5)

        local iconSpacingSlider = GUIFrame:CreateSlider(row2a, "Icon Spacing", {
            min = 0,
            max = 32,
            step = 1,
            value = db.TargetedBuffDisplay.IconSpacing or 1,
            callback = function(val)
                db.TargetedBuffDisplay.IconSpacing = val; ApplySettings()
            end
        })
        row2a:AddWidget(iconSpacingSlider, 0.5)
        card2:AddRow(row2a, Theme.rowHeight)

        local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
        local growDirectionDropdown = GUIFrame:CreateDropdown(row2b, "Growth Direction", {
            options = growDirectionOptions,
            value = db.TargetedBuffDisplay.GrowDirection or "CENTER",
            labelWidth = 120,
            callback = function(key)
                db.TargetedBuffDisplay.GrowDirection = key; ApplySettings()
            end
        })
        row2b:AddWidget(growDirectionDropdown, 1)
        card2:AddRow(row2b, Theme.rowHeightLast, 0)

        yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

        db.TargetedBuffDisplay.Position = db.TargetedBuffDisplay.Position or {}
        local positionCard
        positionCard, yOffset = GUIFrame:CreatePositionCard(contentChild, yOffset, {
            title = "Position Settings",
            db = db.TargetedBuffDisplay,
            defaults = {
                selfPoint = "CENTER",
                anchorPoint = "CENTER",
                xOffset = 0,
                yOffset = -430,
            },
            showAnchorFrameType = false,
            showStrata = false,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(positionCard)
    elseif itemData and itemData.type == "targeted" then
        db.TargetedBuffSettings[itemData.key] = db.TargetedBuffSettings[itemData.key] or {}
        local buffDb = db.TargetedBuffSettings[itemData.key]

        local card1 = GUIFrame:CreateCard(contentChild, itemData.name, yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
        local enableChk = GUIFrame:CreateCheckbox(row1, "Enable", {
            value = buffDb.Enabled ~= false,
            callback = function(checked)
                buffDb.Enabled = checked
                Refresh()
            end
        })
        row1:AddWidget(enableChk, 1)
        card1:AddRow(row1, Theme.rowHeight)

        local sep1 = GUIFrame:CreateSeparator(card1.content)
        card1:AddRow(sep1, Theme.rowHeightSeparator)

        local row1b = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local loadDropdown = GUIFrame:CreateDropdown(row1b, "Load Condition", {
            options = LOAD_CONDITIONS,
            value = buffDb.LoadCondition or "ANYGROUP",
            labelWidth = 120,
            callback = function(key)
                buffDb.LoadCondition = key
                Refresh()
            end
        })
        row1b:AddWidget(loadDropdown, 0.5)

        local expSlider = GUIFrame:CreateSlider(row1b, "Warn when under", {
            min = 0,
            max = 30,
            step = 1,
            value = buffDb.ExpirationMins or 0,
            suffix = " min",
            callback = function(val)
                buffDb.ExpirationMins = val
                Refresh()
            end
        })
        row1b:AddWidget(expSlider, 0.5)
        card1:AddRow(row1b, Theme.rowHeightLast, 0)

        yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

        local glowCard
        glowCard, yOffset = GUIFrame:CreateGlowSettingsCard(contentChild, yOffset, {
            title = "Glow Settings",
            db = buffDb,
            showGlowMode = true,
            onChangeCallback = Refresh,
            onHeightChange = function()
                miniSidebar.contentArea.SetContentHeight(yOffset)
            end
        })
        miniSidebar.contentArea.RegisterCard(glowCard)
    end

    miniSidebar.contentArea.SetContentHeight(yOffset)
    C_Timer.After(0, function()
        miniSidebar.contentArea.UpdateScrollBarVisibility()
        miniSidebar.contentArea.UpdateCardWidths()
    end)

    return miniSidebar.panel
end)
