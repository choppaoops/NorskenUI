---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local C_Spell = C_Spell

local BuffData = NRSKNUI.MissingBuffsData
local CATEGORY_ICONS = BuffData.CATEGORY_ICONS
local LOAD_CONDITIONS = BuffData.LOAD_CONDITIONS

local SIDEBAR_WIDTH = 180
local ITEM_HEIGHT = 28
local LIST_PADDING = 4

local selectedItem = "General"

local SIDEBAR_ITEMS = {
    { key = "sep_consumables",     name = "Consumables",            order = 9,                       type = "separator" },
    { key = "Flask",               name = "Flask",                  icon = CATEGORY_ICONS.Flask,     order = 10,        type = "consumable" },
    { key = "Food",                name = "Food Buff",              icon = CATEGORY_ICONS.Food,      order = 11,        type = "consumable" },
    { key = "MHEnchant",           name = "Main Hand Enchant",      icon = CATEGORY_ICONS.MHEnchant, order = 12,        type = "consumable" },
    { key = "OHEnchant",           name = "Off Hand Enchant",       icon = CATEGORY_ICONS.OHEnchant, order = 13,        type = "consumable" },
    { key = "Rune",                name = "Augment Rune",           icon = CATEGORY_ICONS.Rune,      order = 14,        type = "consumable" },

    { key = "sep_raidbuffs",       name = "Raid Buffs",             order = 19,                      type = "separator" },
    { key = "MarkOfTheWild",       name = "Mark of the Wild",       icon = 1126,                     order = 20,        type = "raidbuff",  class = "DRUID" },
    { key = "ArcaneIntellect",     name = "Arcane Intellect",       icon = 1459,                     order = 21,        type = "raidbuff",  class = "MAGE" },
    { key = "BattleShout",         name = "Battle Shout",           icon = 6673,                     order = 22,        type = "raidbuff",  class = "WARRIOR" },
    { key = "PowerWordFortitude",  name = "Power Word: Fortitude",  icon = 21562,                    order = 23,        type = "raidbuff",  class = "PRIEST" },
    { key = "Skyfury",             name = "Skyfury",                icon = 462854,                   order = 24,        type = "raidbuff",  class = "SHAMAN" },
    { key = "BlessingOfTheBronze", name = "Blessing of the Bronze", icon = 381748,                   order = 25,        type = "raidbuff",  class = "EVOKER" },

    { key = "sep_presence",        name = "Presence Buffs",         order = 29,                      type = "separator" },
    { key = "DevotionAura",        name = "Devotion Aura",          icon = 465,                      order = 30,        type = "presence",  class = "PALADIN" },
    { key = "Soulstone",           name = "Soulstone",              icon = 20707,                    order = 31,        type = "presence",  class = "WARLOCK" },
    { key = "AtrophicPoison",      name = "Atrophic Poison",        icon = 381637,                   order = 32,        type = "presence",  class = "ROGUE" },

    { key = "sep_selfbuffs",       name = "Self Buffs",             order = 39,                      type = "separator" },
    { key = "ArcaneFamiliar",      name = "Arcane Familiar",        icon = 210126,                   order = 40,        type = "selfbuff",  class = "MAGE" },
    { key = "GrimoireSacrifice",   name = "Grimoire: Sacrifice",    icon = 108503,                   order = 41,        type = "selfbuff",  class = "WARLOCK" },
    { key = "Poisons",             name = "Rogue Poisons",          icon = CATEGORY_ICONS.Poisons,   order = 42,        type = "selfbuff",  class = "ROGUE" },
    { key = "FlametongueWeapon",   name = "Flametongue Weapon",     icon = 318038,                   order = 43,        type = "selfbuff",  class = "SHAMAN" },
    { key = "WindfuryWeapon",      name = "Windfury Weapon",        icon = 33757,                    order = 44,        type = "selfbuff",  class = "SHAMAN" },
    { key = "EarthlivingWeapon",   name = "Earthliving Weapon",     icon = 382021,                   order = 45,        type = "selfbuff",  class = "SHAMAN" },
    { key = "LightningShield",     name = "Lightning Shield",       icon = 192106,                   order = 46,        type = "selfbuff",  class = "SHAMAN" },
    { key = "EarthShieldSelf",     name = "Earth Shield",           icon = 974,                      order = 47,        type = "selfbuff",  class = "SHAMAN" },
    { key = "WaterShield",         name = "Water Shield",           icon = 52127,                    order = 48,        type = "selfbuff",  class = "SHAMAN" },
}

local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("MissingBuffs", true)
    end
    return nil
end

GUIFrame:RegisterPanel("missingBuffs", function(container)
    local db = NRSKNUI.db and NRSKNUI.db.profile.MissingBuffs
    if not db then return nil end

    db.Consumables = db.Consumables or {}
    db.RaidBuffs = db.RaidBuffs or {}
    db.SelfBuffs = db.SelfBuffs or {}
    db.PresenceBuffs = db.PresenceBuffs or {}
    db.RaidBuffDisplay = db.RaidBuffDisplay or {}

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

    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
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
                local alpha = isSelected and 1 or 1
                btn._label:SetTextColor(cc.r, cc.g, cc.b, alpha)
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

    local trackingModeOptions = {
        {
            key = "all",
            text = "Raid Leader",
            tooltip =
            "Track all buffs for all players.\nShows everything - useful for raid leaders who want full group oversight.",
        },
        {
            key = "smart",
            text = "Personal",
            tooltip = "Only shows what matters to you:\n" ..
                NRSKNUI:ColorTextByTheme("• ") ..
                "Buffs you're missing that benefit your spec\n" ..
                NRSKNUI:ColorTextByTheme("• ") .. "Your class buffs missing on group members",
        },
    }

    local itemData = nil
    for _, item in ipairs(SIDEBAR_ITEMS) do
        if item.key == selectedItem then
            itemData = item
            break
        end
    end

    if selectedItem == "General" then
        local card1 = GUIFrame:CreateCard(contentChild, "Missing Buffs", yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Missing Buffs", {
            value = db.Enabled ~= false,
            callback = function(checked)
                db.Enabled = checked
                local mod = GetModule()
                if mod then
                    if checked then NorskenUI:EnableModule("MissingBuffs") else NorskenUI:DisableModule("MissingBuffs") end
                end
            end,
            msgPopup = true,
            msgText = "Missing Buffs",
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
            value = db.RaidBuffDisplay.IconSize or 48,
            callback = function(val)
                db.RaidBuffDisplay.IconSize = val; ApplySettings()
            end
        })
        row2a:AddWidget(iconSizeSlider, 0.5)

        local iconSpacingSlider = GUIFrame:CreateSlider(row2a, "Icon Spacing", {
            min = 0,
            max = 32,
            step = 1,
            value = db.RaidBuffDisplay.IconSpacing or 8,
            callback = function(val)
                db.RaidBuffDisplay.IconSpacing = val; ApplySettings()
            end
        })
        row2a:AddWidget(iconSpacingSlider, 0.5)
        card2:AddRow(row2a, Theme.rowHeight)

        local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
        local growDirectionDropdown = GUIFrame:CreateDropdown(row2b, "Growth Direction", {
            options = growDirectionOptions,
            value = db.RaidBuffDisplay.GrowDirection or "CENTER",
            labelWidth = 120,
            callback = function(key)
                db.RaidBuffDisplay.GrowDirection = key; ApplySettings()
            end
        })
        row2b:AddWidget(growDirectionDropdown, 0.5)

        local trackingModeDropdown = GUIFrame:CreateDropdown(row2b, "Tracking Mode", {
            options = trackingModeOptions,
            value = db.TrackingMode or "all",
            labelWidth = 100,
            callback = function(key)
                db.TrackingMode = key; Refresh()
            end
        })
        row2b:AddWidget(trackingModeDropdown, 0.5)
        card2:AddRow(row2b, Theme.rowHeightLast, 0)

        yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

        db.RaidBuffDisplay.FontShadow = db.RaidBuffDisplay.FontShadow or {}
        local fontCard
        fontCard, yOffset = GUIFrame:CreateFontSettingsCard(contentChild, yOffset, {
            title = "Font Settings",
            db = db.RaidBuffDisplay,
            fontSizeRange = { 8, 32 },
            includeSoftOutline = true,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(fontCard)

        db.RaidBuffDisplay.Position = db.RaidBuffDisplay.Position or {}
        local positionCard
        positionCard, yOffset = GUIFrame:CreatePositionCard(contentChild, yOffset, {
            title = "Position Settings",
            db = db.RaidBuffDisplay,
            defaults = {
                selfPoint = "CENTER",
                anchorPoint = "CENTER",
                xOffset = 0,
                yOffset = 200,
            },
            showAnchorFrameType = false,
            showStrata = false,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(positionCard)
    elseif itemData and itemData.type == "consumable" then
        db.Consumables[itemData.key] = db.Consumables[itemData.key] or {}
        local catDb = db.Consumables[itemData.key]

        manager:SetCondition("consumableLoaded", function() return catDb.Enabled end)

        local card1 = GUIFrame:CreateCard(contentChild, itemData.name, yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
        local enableChk = GUIFrame:CreateCheckbox(row1, "Enable", {
            value = catDb.Enabled ~= false,
            callback = function(checked)
                catDb.Enabled = checked
                Refresh()
                UpdateAllWidgetStates()
            end
        })
        row1:AddWidget(enableChk, 1)
        card1:AddRow(row1, Theme.rowHeight)

        local sep1 = GUIFrame:CreateSeparator(card1.content)
        card1:AddRow(sep1, Theme.rowHeightSeparator)

        local row1b = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local loadDropdown = GUIFrame:CreateDropdown(row1b, "Load Condition", {
            options = LOAD_CONDITIONS,
            value = catDb.LoadCondition or "ALWAYS",
            labelWidth = 120,
            callback = function(key)
                catDb.LoadCondition = key
                Refresh()
            end
        })
        row1b:AddWidget(loadDropdown, 0.5)
        manager:Register(loadDropdown, "all", "consumableLoaded")

        local expSlider = GUIFrame:CreateSlider(row1b, "Warn when under", {
            min = 0,
            max = 30,
            step = 1,
            value = catDb.ExpirationMins or 10,
            suffix = " min",
            callback = function(val)
                catDb.ExpirationMins = val
                Refresh()
            end
        })
        row1b:AddWidget(expSlider, 0.5)
        manager:Register(expSlider, "all", "consumableLoaded")
        card1:AddRow(row1b, Theme.rowHeightLast, 0)

        yOffset = card1:GetNextOffset()

        local glowCard, glowOffset, glowWidgets = GUIFrame:CreateGlowSettingsCard(contentChild, yOffset, {
            db = catDb,
            showGlowMode = true,
            onChangeCallback = Refresh,
            onHeightChange = function()
                miniSidebar.contentArea.SetContentHeight(yOffset)
            end
        })
        miniSidebar.contentArea.RegisterCard(glowCard)
        manager:Register(glowCard, "all", "consumableLoaded")
        manager:RegisterGroup(glowWidgets, "all")
        if glowCard.updateTypeVisibility then table_insert(postUpdateCallbacks, glowCard.updateTypeVisibility) end

        yOffset = glowOffset

        UpdateAllWidgetStates()
    elseif itemData and itemData.type == "raidbuff" then
        db.RaidBuffs[itemData.key] = db.RaidBuffs[itemData.key] or {}
        local buffDb = db.RaidBuffs[itemData.key]

        manager:SetCondition("raidbuffLoaded", function() return buffDb.Enabled end)

        local card1 = GUIFrame:CreateCard(contentChild, itemData.name, yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
        local enableChk = GUIFrame:CreateCheckbox(row1, "Enable", {
            value = buffDb.Enabled ~= false,
            callback = function(checked)
                buffDb.Enabled = checked
                Refresh()
                UpdateAllWidgetStates()
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
        manager:Register(loadDropdown, "all", "raidbuffLoaded")

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
        manager:Register(expSlider, "all", "raidbuffLoaded")
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
        manager:Register(glowCard, "all", "raidbuffLoaded")
        UpdateAllWidgetStates()
    elseif itemData and itemData.type == "presence" then
        db.PresenceBuffs[itemData.key] = db.PresenceBuffs[itemData.key] or {}
        local buffDb = db.PresenceBuffs[itemData.key]

        manager:SetCondition("presenceLoaded", function() return buffDb.Enabled end)

        local card1 = GUIFrame:CreateCard(contentChild, itemData.name, yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
        local enableChk = GUIFrame:CreateCheckbox(row1, "Enable", {
            value = buffDb.Enabled ~= false,
            callback = function(checked)
                buffDb.Enabled = checked
                Refresh()
                UpdateAllWidgetStates()
            end
        })
        row1:AddWidget(enableChk, 1)
        card1:AddRow(row1, Theme.rowHeight)

        local sep1 = GUIFrame:CreateSeparator(card1.content)
        card1:AddRow(sep1, Theme.rowHeightSeparator)

        local infoRow = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Load Information"), {
            text = NRSKNUI:ColorTextByTheme("• ") .. "Presence buffs only track in raid groups",
            height = Theme.rowHeightLast,
            bgMode = "hide"
        })
        infoRow:AddWidget(infoText, 1)
        manager:Register(infoText, "all", "presenceLoaded")
        card1:AddRow(infoRow, Theme.rowHeightLast, 0)

        yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

        local glowCard, glowWidgets
        glowCard, yOffset, glowWidgets = GUIFrame:CreateGlowSettingsCard(contentChild, yOffset, {
            title = "Glow Settings",
            db = buffDb,
            showGlowMode = true,
            onChangeCallback = Refresh,
            onHeightChange = function()
                miniSidebar.contentArea.SetContentHeight(yOffset)
            end
        })
        miniSidebar.contentArea.RegisterCard(glowCard)
        manager:Register(glowCard, "all", "presenceLoaded")
        manager:RegisterGroup(glowWidgets, "all")
        UpdateAllWidgetStates()
    elseif itemData and itemData.type == "selfbuff" then
        db.SelfBuffs[itemData.key] = db.SelfBuffs[itemData.key] or {}
        local buffDb = db.SelfBuffs[itemData.key]

        manager:SetCondition("selfbuffLoaded", function() return buffDb.Enabled end)

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

        local isPoisons = itemData.key == "Poisons"

        local row1b = GUIFrame:CreateRow(card1.content, isPoisons and Theme.rowHeight or Theme.rowHeightLast)
        local loadDropdown = GUIFrame:CreateDropdown(row1b, "Load Condition", {
            options = LOAD_CONDITIONS,
            value = buffDb.LoadCondition or "ALWAYS",
            labelWidth = 120,
            callback = function(key)
                buffDb.LoadCondition = key
                Refresh()
            end
        })
        row1b:AddWidget(loadDropdown, 0.5)
        manager:Register(loadDropdown, "all", "selfbuffLoaded")

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
        manager:Register(expSlider, "all", "selfbuffLoaded")
        card1:AddRow(row1b, isPoisons and Theme.rowHeight or Theme.rowHeightLast, isPoisons and nil or 0)

        if isPoisons then
            local sep2 = GUIFrame:CreateSeparator(card1.content)
            card1:AddRow(sep2, Theme.rowHeightSeparator)

            local row1c = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
            local cripplingChk = GUIFrame:CreateCheckbox(row1c, "Track Crippling Poison", {
                tooltip = "Assassination only, requires Dragon-Tempered Blades talent",
                value = buffDb.EnableCrippling == true,
                callback = function(checked)
                    buffDb.EnableCrippling = checked
                    Refresh()
                end
            })
            row1c:AddWidget(cripplingChk, 1)
            manager:Register(cripplingChk, "all", "selfbuffLoaded")
            card1:AddRow(row1c, Theme.rowHeightLast, 0)
        end

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
        manager:Register(glowCard, "all", "selfbuffLoaded")
        UpdateAllWidgetStates()
    end

    miniSidebar.contentArea.SetContentHeight(yOffset)
    C_Timer.After(0, function()
        miniSidebar.contentArea.UpdateScrollBarVisibility()
        miniSidebar.contentArea.UpdateCardWidths()
    end)

    return miniSidebar.panel
end)
