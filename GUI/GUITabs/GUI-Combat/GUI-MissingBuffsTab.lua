-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

--TODO: Update

-- Locals
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM

-- Localization Setup
local table_insert = table.insert
local table_sort = table.sort
local wipe = wipe
local CreateFrame = CreateFrame
local ipairs, pairs = ipairs, pairs
local type = type

-- Store current sub-tab
local currentSubTab = "raidBuffs"

local allWidgets = {}

-- Sub-tab definitions
local SUB_TABS = {
    { id = "raidBuffs",   text = "Raid & General Buffs" },
    { id = "stances",     text = "Stance & Spec Buffs" },
    { id = "stanceTexts", text = "Stance Texts" },
}

-- Tab bar height constant
local TAB_BAR_HEIGHT = 28

-- Get module reference
local function GetModule()
    return NorskenUI:GetModule("MissingBuffs", true)
end

-- Load database settings
local function GetMissingBuffsDB()
    if not NRSKNUI.db or not NRSKNUI.db.profile then return nil end
    return NRSKNUI.db.profile.MissingBuffs
end

-- Helper to apply settings
local function ApplySettings()
    local mod = GetModule()
    if mod and mod.ApplySettings then
        mod:ApplySettings()
    end
end

-- Helper to refresh module
local function Refresh()
    local mod = GetModule()
    if mod and mod.Refresh then
        mod:Refresh()
    end
end

-- Comprehensive widget state update
local function UpdateAllWidgetStates()
    local db = GetMissingBuffsDB()
    if not db then return end
    local mainEnabled = db.Enabled ~= false

    -- Apply main enable state to ALL widgets
    for _, widget in ipairs(allWidgets) do
        if widget.SetEnabled then
            widget:SetEnabled(mainEnabled)
        end
    end
end

-- Helper to apply new state
local function ApplyMissingBuffsState(enabled)
    local MBUFFS = GetModule()
    if not MBUFFS then return end
    MBUFFS.db.Enabled = enabled
    if enabled then
        NorskenUI:EnableModule("MissingBuffs")
    else
        NorskenUI:DisableModule("MissingBuffs")
    end
end

-- Register cleanup callback once
if not GUIFrame._missingBuffsCleanupRegistered then
    GUIFrame._missingBuffsCleanupRegistered = true

    -- Register callback for when GUI closes
    GUIFrame:RegisterOnCloseCallback("missingBuffs", function()
        Refresh()
    end)
end

-- Category icons
local CATEGORY_ICONS = {
    Flask = 1235110,    -- Alchemical Chaos flask
    Food = 104280,      -- Well Fed (Pandaren food buff for generic food icon)
    MHEnchant = 180608, -- Windfury Weapon
    OHEnchant = 180608, -- Same
    Rune = 1264426,     -- Augment Rune
    RaidBuffs = 1126,   -- Mark of the Wild
    Poisons = 2823,     -- Deadly Poison
}

-- Class icons
local CLASS_ICONS = {
    WARRIOR = { atlas = "classicon-warrior" },
    PALADIN = { atlas = "classicon-paladin" },
    DRUID   = { atlas = "classicon-druid" },
    PRIEST  = { atlas = "classicon-priest" },
    EVOKER  = { atlas = "classicon-evoker" },
}

-- Spec icons (texture IDs for each spec's stance/form)
local SPEC_ICONS = {
    WARRIOR = {
        Arms = { textureId = 132355 },       -- Battle Stance
        Fury = { textureId = 132347 },       -- Berserker Stance
        Protection = { textureId = 132341 }, -- Defensive Stance
    },
    PALADIN = {
        Holy = { textureId = 135920 },        -- Devotion Aura
        Protection = { textureId = 236264 },  -- Devotion Aura
        Retribution = { textureId = 535595 }, -- Crusader Aura
    },
    DRUID = {
        Balance = { textureId = 136096 },  -- Moonkin Form
        Feral = { textureId = 132115 },    -- Cat Form
        Guardian = { textureId = 132276 }, -- Bear Form
    },
    PRIEST = {
        Shadow = { textureId = 136207 }, -- Shadowform
    },
    EVOKER = {
        Augmentation = { textureId = 5198700 }, -- Black Attunement
    },
}

-- Load condition options
local LOAD_CONDITIONS = {
    { key = "ALWAYS",   text = "Always" },
    { key = "ANYGROUP", text = "Any Group" },
    { key = "PARTY",    text = "In Party" },
    { key = "RAID",     text = "In Raid" },
    { key = "NOGROUP",  text = "No Group" },
}

-- Helper to create a fixed-size icon widget
-- TODO: Move into its own file and make re usable
local function CreateIconWidget(parent, iconData, size)
    size = size or 40
    -- Container frame that won't stretch
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(size + 8, size) -- Add small padding
    container.fixedWidth = size + 8   -- Mark as fixed width

    -- Icon frame inside container
    local iconFrame = CreateFrame("Frame", nil, container)
    iconFrame:SetSize(size, size)
    iconFrame:SetPoint("LEFT", container, "LEFT", 4, 0)

    -- Icon texture
    iconFrame.texture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.texture:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
    iconFrame.texture:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)

    -- Determine icon type and set texture
    if type(iconData) == "table" then
        if iconData.atlas then
            iconFrame.texture:SetAtlas(iconData.atlas)
        elseif iconData.textureId then
            -- Direct texture ID with zoom
            NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)
            iconFrame.texture:SetTexture(iconData.textureId)
        elseif iconData.spellId then
            -- Use spell texture with zoom
            NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)

            local texture = C_Spell.GetSpellTexture(iconData.spellId)
            if texture then
                iconFrame.texture:SetTexture(texture)
            else
                iconFrame.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        end
    elseif type(iconData) == "number" then
        NRSKNUI:ApplyZoom(iconFrame.texture, NRSKNUI.GlobalZoom)

        local texture = C_Spell.GetSpellTexture(iconData)
        if texture then
            iconFrame.texture:SetTexture(texture)
        else
            iconFrame.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    else
        iconFrame.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Border stuff
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

-- Helper to create a category row with icon, checkbox, and load dropdown
local function CreateCategoryRow(card, categoryKey, label, iconSpellId, db, isFirst)
    -- Add separator if not first row
    if not isFirst then
        local sepRow = GUIFrame:CreateRow(card.content, 8)
        local sep = GUIFrame:CreateSeparator(sepRow)
        sepRow:AddWidget(sep, 1)
        table_insert(allWidgets, sep)
        card:AddRow(sepRow, 8)
    end

    local row = GUIFrame:CreateRow(card.content, 40)

    -- Icon widget
    local iconWidget = CreateIconWidget(row, iconSpellId, 40)
    row:AddWidget(iconWidget, 0.1)

    -- Enable checkbox
    local enableCheck = GUIFrame:CreateCheckbox(row, label, {
        value = db[categoryKey] and db[categoryKey].Enabled ~= false,
        callback = function(checked)
            db[categoryKey] = db[categoryKey] or {}
            db[categoryKey].Enabled = checked
            Refresh()
        end
    })
    row:AddWidget(enableCheck, 0.5)
    table_insert(allWidgets, enableCheck)

    -- Load condition dropdown
    local loadDropdown = GUIFrame:CreateDropdown(row, "Load", {
        options = LOAD_CONDITIONS,
        value = (db[categoryKey] and db[categoryKey].LoadCondition) or "ALWAYS",
        labelWidth = 60,
        callback = function(key)
            db[categoryKey] = db[categoryKey] or {}
            db[categoryKey].LoadCondition = key
            Refresh()
        end
    })
    row:AddWidget(loadDropdown, 0.4)
    table_insert(allWidgets, loadDropdown)

    card:AddRow(row, 40)
end

----------------------------------------------------------------
-- Sub-Tab 2: Raid & General Buffs
----------------------------------------------------------------
local function RenderRaidBuffsTab(scrollChild, yOffset, activeCards)
    local db = GetMissingBuffsDB()
    if not db then return yOffset end

    ----------------------------------------------------------------
    -- Card 1: Enable + Preview
    ----------------------------------------------------------------
    local card1a = GUIFrame:CreateCard(scrollChild, "Missing Buffs", yOffset)
    table_insert(activeCards, card1a)

    local row1a = GUIFrame:CreateRow(card1a.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1a, "Enable Missing Buffs", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            ApplyMissingBuffsState(checked)
            UpdateAllWidgetStates()
        end,
        msgPopup = true, msgText = "Missing Buffs", msgOn = "On", msgOff = "Off"
    })
    row1a:AddWidget(enableCheck, 0.5)
    card1a:AddRow(row1a, 36)

    yOffset = yOffset + card1a:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 1: Low Duration Warning
    ----------------------------------------------------------------
    --[[
    local card1 = GUIFrame:CreateCard(scrollChild, "Low Duration Warning", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local lowDurCheck = GUIFrame:CreateCheckbox(row1, "Warn Before Expiry", {
        value = db.NotifyLowDuration ~= false,
        callback = function(checked)
            db.NotifyLowDuration = checked
            ApplySettings()
        end
    })
    row1:AddWidget(lowDurCheck, 0.5)
    table_insert(allWidgets, lowDurCheck)

    local thresholdSlider = GUIFrame:CreateSlider(row1, "Minutes Left", {
        min = 1,
        max = 60,
        step = 1,
        value = db.LowDurationThreshold or 5,
        labelWidth = 60,
        callback = function(val)
            db.LowDurationThreshold = val
            ApplySettings()
        end
    })
    row1:AddWidget(thresholdSlider, 0.5)
    table_insert(allWidgets, thresholdSlider)
    card1:AddRow(row1, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall
    --]]

    ----------------------------------------------------------------
    -- Card 2: Consumable & Buff Tracking
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Consumable & Buff Tracking", yOffset)
    table_insert(activeCards, card2)
    table_insert(allWidgets, card2)
    db.Consumables = db.Consumables or {}

    -- Flask row
    CreateCategoryRow(card2, "Flask", "Flask", CATEGORY_ICONS.Flask, db.Consumables, true)

    -- Food row
    CreateCategoryRow(card2, "Food", "Food Buff", CATEGORY_ICONS.Food, db.Consumables, false)

    -- MH Enchant row
    CreateCategoryRow(card2, "MHEnchant", "Main Hand Enchant", CATEGORY_ICONS.MHEnchant, db.Consumables, false)

    -- OH Enchant row
    CreateCategoryRow(card2, "OHEnchant", "Off Hand Enchant", CATEGORY_ICONS.OHEnchant, db.Consumables, false)

    -- Rune row
    CreateCategoryRow(card2, "Rune", "Augment Rune", CATEGORY_ICONS.Rune, db.Consumables, false)

    -- Raid Buffs row
    CreateCategoryRow(card2, "RaidBuffs", "Raid Buffs", CATEGORY_ICONS.RaidBuffs, db.Consumables, false)

    -- Poisons row (Rogue only)
    CreateCategoryRow(card2, "Poisons", "Rogue Poisons", CATEGORY_ICONS.Poisons, db.Consumables, false)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Display Settings
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Display Settings", yOffset)
    table_insert(activeCards, card3)
    table_insert(allWidgets, card3)
    db.RaidBuffDisplay = db.RaidBuffDisplay or {}

    -- Icon Size + Spacing
    local row3a = GUIFrame:CreateRow(card3.content, 36)
    local iconSizeSlider = GUIFrame:CreateSlider(row3a, "Icon Size", {
        min = 24,
        max = 96,
        step = 1,
        value = db.RaidBuffDisplay.IconSize or db.IconSize or 48,
        labelWidth = 60,
        callback = function(val)
            db.RaidBuffDisplay.IconSize = val
            ApplySettings()
        end
    })
    row3a:AddWidget(iconSizeSlider, 0.5)
    table_insert(allWidgets, iconSizeSlider)

    local iconSpacingSlider = GUIFrame:CreateSlider(row3a, "Icon Spacing", {
        min = 0,
        max = 32,
        step = 1,
        value = db.RaidBuffDisplay.IconSpacing or db.IconSpacing or 8,
        labelWidth = 60,
        callback = function(val)
            db.RaidBuffDisplay.IconSpacing = val
            ApplySettings()
        end
    })
    row3a:AddWidget(iconSpacingSlider, 0.5)
    table_insert(allWidgets, iconSpacingSlider)
    card3:AddRow(row3a, 36)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Font Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)
    table_insert(activeCards, card4)
    table_insert(allWidgets, card4)

    -- Build font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            table_insert(fontList, { key = name, text = name })
        end
        table_sort(fontList, function(a, b) return a.text < b.text end)
    else
        table_insert(fontList, { key = "Friz Quadrata TT", text = "Friz Quadrata TT" })
    end

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }

    -- Font and Outline
    local row4a = GUIFrame:CreateRow(card4.content, 36)
    local fontDropdown = GUIFrame:CreateDropdown(row4a, "Font", {
        options = fontList,
        value = db.RaidBuffDisplay.FontFace or "Friz Quadrata TT",
        labelWidth = 120,
        searchable = true,
        isFontPreview = true,
        callback = function(key)
            db.RaidBuffDisplay.FontFace = key
            ApplySettings()
        end
    })
    row4a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineDropdown = GUIFrame:CreateDropdown(row4a, "Outline", {
        options = outlineList,
        value = db.RaidBuffDisplay.FontOutline or "OUTLINE",
        labelWidth = 80,
        callback = function(key)
            db.RaidBuffDisplay.FontOutline = key
            ApplySettings()
        end
    })
    row4a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card4:AddRow(row4a, 36)

    -- Font Size
    local row4b = GUIFrame:CreateRow(card4.content, 36)
    local fontSizeSlider = GUIFrame:CreateSlider(row4b, "Font Size", {
        min = 8,
        max = 32,
        step = 1,
        value = db.RaidBuffDisplay.FontSize or 14,
        labelWidth = 60,
        callback = function(val)
            db.RaidBuffDisplay.FontSize = val
            ApplySettings()
        end
    })
    row4b:AddWidget(fontSizeSlider, 1)
    table_insert(allWidgets, fontSizeSlider)
    card4:AddRow(row4b, 36)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Position Settings
    ----------------------------------------------------------------
    db.RaidBuffDisplay.Position = db.RaidBuffDisplay.Position or {}

    local positionCard
    positionCard, yOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
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
    table_insert(activeCards, positionCard)

    if positionCard.positionWidgets then
        for _, widget in ipairs(positionCard.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, positionCard)

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 4)
    return yOffset
end

-- Stance data for dropdowns
local STANCE_OPTIONS = {
    WARRIOR = {
        Arms = {
            { key = "386164", text = "Battle Stance" },
            { key = "386196", text = "Berserker Stance" },
            { key = "386208", text = "Defensive Stance" },
        },
        Fury = {
            { key = "386164", text = "Battle Stance" },
            { key = "386196", text = "Berserker Stance" },
            { key = "386208", text = "Defensive Stance" },
        },
        Protection = {
            { key = "386164", text = "Battle Stance" },
            { key = "386196", text = "Berserker Stance" },
            { key = "386208", text = "Defensive Stance" },
        },
    },
    PALADIN = {
        Holy = {
            { key = "465",    text = "Devotion Aura" },
            { key = "317920", text = "Concentration Aura" },
            { key = "32223",  text = "Crusader Aura" },
        },
        Protection = {
            { key = "465",    text = "Devotion Aura" },
            { key = "317920", text = "Concentration Aura" },
            { key = "32223",  text = "Crusader Aura" },
        },
        Retribution = {
            { key = "465",    text = "Devotion Aura" },
            { key = "317920", text = "Concentration Aura" },
            { key = "32223",  text = "Crusader Aura" },
        },
    },
    DRUID = {
        Balance = {
            { key = "24858", text = "Moonkin Form" },
            { key = "768",   text = "Cat Form" },
            { key = "5487",  text = "Bear Form" },
        },
        Feral = {
            { key = "768",   text = "Cat Form" },
            { key = "24858", text = "Moonkin Form" },
            { key = "5487",  text = "Bear Form" },
        },
        Guardian = {
            { key = "5487",  text = "Bear Form" },
            { key = "768",   text = "Cat Form" },
            { key = "24858", text = "Moonkin Form" },
        },
    },
    EVOKER = {
        Augmentation = {
            { key = "403264", text = "Black Attunement" },
            { key = "403265", text = "Bronze Attunement" },
        },
    },
    -- PRIEST handled separately
}

-- Helper to create a class stance card with spec-specific options (per-spec toggles only)
local function CreateClassStanceCard(scrollChild, yOffset, classKey, title, iconData, db, activeCards)
    db[classKey] = db[classKey] or {}

    local card = GUIFrame:CreateCard(scrollChild, title, yOffset)
    table_insert(activeCards, card)
    table_insert(allWidgets, card)

    -- Track widgets that need enable/disable updates
    local specWidgets = {}

    -- Function to update spec widget states based on spec toggle
    local function UpdateSpecWidgetStates()
        for specName, widgets in pairs(specWidgets) do
            local specEnabledKey = specName .. "Enabled"
            local specEnabled = db[classKey][specEnabledKey] == true

            -- Dropdown is disabled if spec toggle is off
            if widgets.dropdown and widgets.dropdown.SetEnabled then
                widgets.dropdown:SetEnabled(specEnabled)
            end

            -- Reverse icon toggle is disabled if spec toggle is off
            if widgets.reverseIcon and widgets.reverseIcon.SetEnabled then
                widgets.reverseIcon:SetEnabled(specEnabled)
            end
        end
    end

    -- Get spec options for this class
    local specOptions = STANCE_OPTIONS[classKey]
    local specIcons = SPEC_ICONS[classKey]

    -- Add spec-specific rows
    if specOptions then
        local isFirst = true
        for specName, options in pairs(specOptions) do
            -- Add separator between rows
            if not isFirst then
                local sepRow = GUIFrame:CreateRow(card.content, 8)
                local sep = GUIFrame:CreateSeparator(sepRow)
                sepRow:AddWidget(sep, 1)
                table_insert(allWidgets, sep)
                card:AddRow(sepRow, 8)
            end
            isFirst = false

            local specRow = GUIFrame:CreateRow(card.content, 40)

            -- Spec icon
            local specIconId = specIcons and specIcons[specName]
            local specIconWidget = CreateIconWidget(specRow, specIconId or 134400, 32)
            specRow:AddWidget(specIconWidget, 0.1)

            -- Spec enable toggle
            local specEnabledKey = specName .. "Enabled"
            local specToggle = GUIFrame:CreateCheckbox(specRow, specName, {
                value = db[classKey][specEnabledKey] == true,
                callback = function(checked)
                    db[classKey][specEnabledKey] = checked
                    UpdateSpecWidgetStates()
                    Refresh()
                end
            })
            specRow:AddWidget(specToggle, 0.35)
            table_insert(allWidgets, specToggle)

            -- Reverse icon toggle: show current stance icon and hide missing text
            local reverseIconKey = specName .. "ReverseIcon"
            local reverseToggle = GUIFrame:CreateCheckbox(specRow, "Reverse Icon", {
                value = db[classKey][reverseIconKey] == true,
                callback = function(checked)
                    db[classKey][reverseIconKey] = checked
                    Refresh()
                end
            })
            specRow:AddWidget(reverseToggle, 0.25)
            table_insert(allWidgets, reverseToggle)

            -- Preferred stance dropdown
            local specDropdown = GUIFrame:CreateDropdown(specRow, "Required", {
                options = options,
                value = db[classKey][specName] or options[1].key,
                labelWidth = 80,
                callback = function(key)
                    db[classKey][specName] = key
                    Refresh()
                end
            })
            specRow:AddWidget(specDropdown, 0.3)
            table_insert(allWidgets, specDropdown)

            -- Store widgets for enable/disable management
            specWidgets[specName] = { toggle = specToggle, dropdown = specDropdown, reverseIcon = reverseToggle }

            card:AddRow(specRow, 40)
        end

        -- Apply initial enable states
        C_Timer.After(0, UpdateSpecWidgetStates)
    end

    return yOffset + card:GetContentHeight() + Theme.paddingSmall
end

----------------------------------------------------------------
-- Sub-Tab 3: Stance & Spec Buffs
----------------------------------------------------------------
local function RenderStancesTab(scrollChild, yOffset, activeCards)
    local db = GetMissingBuffsDB()
    if not db then return yOffset end
    db.Stances = db.Stances or {}

    ----------------------------------------------------------------
    -- Card 1: Info Card
    ----------------------------------------------------------------
    local infoCard = GUIFrame:CreateCard(scrollChild, "Stance & Form Tracking", yOffset)
    table_insert(activeCards, infoCard)
    table_insert(allWidgets, infoCard)

    local infoTextHeight = 90
    local infoRow = GUIFrame:CreateRow(infoCard.content, infoTextHeight)
    local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("How it works"), {
        text = (NRSKNUI:ColorTextByTheme("• ") .. "Spec toggles: Enable/disable stance tracking for each spec\n" ..
            NRSKNUI:ColorTextByTheme("• ") .. "Required dropdown: Choose which stance is required for that spec\n" ..
            NRSKNUI:ColorTextByTheme("• ") .. "Reverse Icon: Show current stance icon instead of required stance, hides missing text"),
        height = infoTextHeight,
        bgMode = "hide"
    })
    infoRow:AddWidget(infoText, 1)
    table_insert(allWidgets, infoText)
    infoCard:AddRow(infoRow, infoTextHeight)

    yOffset = yOffset + infoCard:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Class Cards
    ----------------------------------------------------------------

    -- Warrior
    yOffset = CreateClassStanceCard(scrollChild, yOffset, "WARRIOR", "Warrior Stances",
        CLASS_ICONS.WARRIOR, db.Stances, activeCards)

    -- Paladin
    yOffset = CreateClassStanceCard(scrollChild, yOffset, "PALADIN", "Paladin Auras",
        CLASS_ICONS.PALADIN, db.Stances, activeCards)

    -- Druid Forms (simple toggles per spec)
    db.Stances.DRUID = db.Stances.DRUID or {}
    local druidCard = GUIFrame:CreateCard(scrollChild, "Druid Forms", yOffset)
    table_insert(activeCards, druidCard)
    table_insert(allWidgets, druidCard)

    -- Balance - Moonkin Form
    local balanceRow = GUIFrame:CreateRow(druidCard.content, 40)
    local balanceIcon = CreateIconWidget(balanceRow, SPEC_ICONS.DRUID.Balance, 40)
    balanceRow:AddWidget(balanceIcon, 0.1)

    local balanceToggle = GUIFrame:CreateCheckbox(balanceRow, "Balance: Require Moonkin Form", {
        value = db.Stances.DRUID.BalanceEnabled == true,
        callback = function(checked)
            db.Stances.DRUID.BalanceEnabled = checked
            Refresh()
        end
    })
    balanceRow:AddWidget(balanceToggle, 0.6)
    table_insert(allWidgets, balanceToggle)

    local balanceCombatToggle = GUIFrame:CreateCheckbox(balanceRow, "Combat Only", {
        value = db.Stances.DRUID.BalanceCombatOnly == true,
        callback = function(checked)
            db.Stances.DRUID.BalanceCombatOnly = checked
            Refresh()
        end
    })
    balanceRow:AddWidget(balanceCombatToggle, 0.3)
    table_insert(allWidgets, balanceCombatToggle)
    druidCard:AddRow(balanceRow, 40)

    -- Separator
    local druidSep1 = GUIFrame:CreateRow(druidCard.content, 8)
    local druidSep1Widget = GUIFrame:CreateSeparator(druidSep1)
    druidSep1:AddWidget(druidSep1Widget, 1)
    table_insert(allWidgets, druidSep1Widget)
    druidCard:AddRow(druidSep1, 8)

    -- Feral - Cat Form
    local feralRow = GUIFrame:CreateRow(druidCard.content, 40)
    local feralIcon = CreateIconWidget(feralRow, SPEC_ICONS.DRUID.Feral, 40)
    feralRow:AddWidget(feralIcon, 0.1)

    local feralToggle = GUIFrame:CreateCheckbox(feralRow, "Feral: Require Cat Form", {
        value = db.Stances.DRUID.FeralEnabled == true,
        callback = function(checked)
            db.Stances.DRUID.FeralEnabled = checked
            Refresh()
        end
    })
    feralRow:AddWidget(feralToggle, 0.6)
    table_insert(allWidgets, feralToggle)

    local feralCombatToggle = GUIFrame:CreateCheckbox(feralRow, "Combat Only", {
        value = db.Stances.DRUID.FeralCombatOnly == true,
        callback = function(checked)
            db.Stances.DRUID.FeralCombatOnly = checked
            Refresh()
        end
    })
    feralRow:AddWidget(feralCombatToggle, 0.3)
    table_insert(allWidgets, feralCombatToggle)
    druidCard:AddRow(feralRow, 40)

    -- Separator
    local druidSep2 = GUIFrame:CreateRow(druidCard.content, 8)
    local druidSep2Widget = GUIFrame:CreateSeparator(druidSep2)
    druidSep2:AddWidget(druidSep2Widget, 1)
    table_insert(allWidgets, druidSep2Widget)
    druidCard:AddRow(druidSep2, 8)

    -- Guardian - Bear Form
    local guardianRow = GUIFrame:CreateRow(druidCard.content, 40)
    local guardianIcon = CreateIconWidget(guardianRow, SPEC_ICONS.DRUID.Guardian, 40)
    guardianRow:AddWidget(guardianIcon, 0.1)

    local guardianToggle = GUIFrame:CreateCheckbox(guardianRow, "Guardian: Require Bear Form", {
        value = db.Stances.DRUID.GuardianEnabled == true,
        callback = function(checked)
            db.Stances.DRUID.GuardianEnabled = checked
            Refresh()
        end
    })
    guardianRow:AddWidget(guardianToggle, 0.6)
    table_insert(allWidgets, guardianToggle)

    local guardianCombatToggle = GUIFrame:CreateCheckbox(guardianRow, "Combat Only", {
        value = db.Stances.DRUID.GuardianCombatOnly == true,
        callback = function(checked)
            db.Stances.DRUID.GuardianCombatOnly = checked
            Refresh()
        end
    })
    guardianRow:AddWidget(guardianCombatToggle, 0.3)
    table_insert(allWidgets, guardianCombatToggle)
    druidCard:AddRow(guardianRow, 40)

    yOffset = yOffset + druidCard:GetContentHeight() + Theme.paddingSmall

    -- Evoker Attunement (toggle + dropdown)
    db.Stances.EVOKER = db.Stances.EVOKER or {}
    local evokerCard = GUIFrame:CreateCard(scrollChild, "Augmentation Evoker Attunement", yOffset)
    table_insert(activeCards, evokerCard)
    table_insert(allWidgets, evokerCard)

    local evokerRow = GUIFrame:CreateRow(evokerCard.content, 40)
    local evokerIcon = CreateIconWidget(evokerRow, SPEC_ICONS.EVOKER.Augmentation, 40)
    evokerRow:AddWidget(evokerIcon, 0.1)

    local evokerToggle = GUIFrame:CreateCheckbox(evokerRow, "Require Attunement", {
        value = db.Stances.EVOKER.AugmentationEnabled == true,
        callback = function(checked)
            db.Stances.EVOKER.AugmentationEnabled = checked
            Refresh()
        end
    })
    evokerRow:AddWidget(evokerToggle, 0.5)
    table_insert(allWidgets, evokerToggle)

    local attunementOptions = {
        { key = "403264", text = "Black Attunement" },
        { key = "403265", text = "Bronze Attunement" },
    }
    local evokerDropdown = GUIFrame:CreateDropdown(evokerRow, "Required", {
        options = attunementOptions,
        value = db.Stances.EVOKER.Augmentation or "403264",
        labelWidth = 100,
        callback = function(key)
            db.Stances.EVOKER.Augmentation = key
            Refresh()
        end
    })
    evokerRow:AddWidget(evokerDropdown, 0.4)
    table_insert(allWidgets, evokerDropdown)
    evokerCard:AddRow(evokerRow, 40)

    yOffset = yOffset + evokerCard:GetContentHeight() + Theme.paddingSmall

    -- Priest (Shadow only - simple single toggle)
    db.Stances.PRIEST = db.Stances.PRIEST or {}
    local priestCard = GUIFrame:CreateCard(scrollChild, "Shadow Priest Shadowform", yOffset)
    table_insert(activeCards, priestCard)
    table_insert(allWidgets, priestCard)

    local priestRow = GUIFrame:CreateRow(priestCard.content, 40)
    local priestIcon = CreateIconWidget(priestRow, SPEC_ICONS.PRIEST.Shadow, 40)
    priestRow:AddWidget(priestIcon, 0.1)

    local priestToggle = GUIFrame:CreateCheckbox(priestRow, "Require Shadowform", {
        value = db.Stances.PRIEST.ShadowEnabled == true,
        callback = function(checked)
            db.Stances.PRIEST.ShadowEnabled = checked
            Refresh()
        end
    })
    priestRow:AddWidget(priestToggle, 0.9)
    table_insert(allWidgets, priestToggle)
    priestCard:AddRow(priestRow, 40)

    yOffset = yOffset + priestCard:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Display Settings Card
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Display Settings", yOffset)
    table_insert(activeCards, card3)
    table_insert(allWidgets, card3)
    db.StanceDisplay = db.StanceDisplay or {}

    -- Icon Size
    local row3a = GUIFrame:CreateRow(card3.content, 36)
    local iconSizeSlider = GUIFrame:CreateSlider(row3a, "Icon Size", {
        min = 24,
        max = 96,
        step = 1,
        value = db.StanceDisplay.IconSize or 48,
        labelWidth = 60,
        callback = function(val)
            db.StanceDisplay.IconSize = val
            ApplySettings()
        end
    })
    row3a:AddWidget(iconSizeSlider, 1)
    table_insert(allWidgets, iconSizeSlider)
    card3:AddRow(row3a, 36)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Font Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)
    table_insert(activeCards, card4)
    table_insert(allWidgets, card4)

    -- Build font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            table_insert(fontList, { key = name, text = name })
        end
        table_sort(fontList, function(a, b) return a.text < b.text end)
    else
        table_insert(fontList, { key = "Friz Quadrata TT", text = "Friz Quadrata TT" })
    end

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }

    -- Font and Outline
    local row4a = GUIFrame:CreateRow(card4.content, 36)
    local fontDropdown = GUIFrame:CreateDropdown(row4a, "Font", {
        options = fontList,
        value = db.StanceDisplay.FontFace or "Friz Quadrata TT",
        labelWidth = 120,
        searchable = true,
        isFontPreview = true,
        callback = function(key)
            db.StanceDisplay.FontFace = key
            ApplySettings()
        end
    })
    row4a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineDropdown = GUIFrame:CreateDropdown(row4a, "Outline", {
        options = outlineList,
        value = db.StanceDisplay.FontOutline or "OUTLINE",
        labelWidth = 80,
        callback = function(key)
            db.StanceDisplay.FontOutline = key
            ApplySettings()
        end
    })
    row4a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card4:AddRow(row4a, 36)

    -- Font Size
    local row4b = GUIFrame:CreateRow(card4.content, 36)
    local fontSizeSlider = GUIFrame:CreateSlider(row4b, "Font Size", {
        min = 8,
        max = 32,
        step = 1,
        value = db.StanceDisplay.FontSize or 14,
        labelWidth = 60,
        callback = function(val)
            db.StanceDisplay.FontSize = val
            ApplySettings()
        end
    })
    row4b:AddWidget(fontSizeSlider, 1)
    table_insert(allWidgets, fontSizeSlider)
    card4:AddRow(row4b, 36)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Position Settings
    ----------------------------------------------------------------
    db.StanceDisplay.Position = db.StanceDisplay.Position or {}
    local positionCard
    positionCard, yOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
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
    table_insert(activeCards, positionCard)

    if positionCard.positionWidgets then
        for _, widget in ipairs(positionCard.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, positionCard)

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 4)
    return yOffset
end

----------------------------------------------------------------
-- Sub-Tab 4: Stance Texts
----------------------------------------------------------------

-- Stance text data
local STANCE_TEXT_DATA = {
    WARRIOR = {
        { key = "386164", text = "Battle Stance",    textureId = 132349 },
        { key = "386196", text = "Berserker Stance", textureId = 132275 },
        { key = "386208", text = "Defensive Stance", textureId = 132341 },
    },
    PALADIN = {
        { key = "465",    text = "Devotion Aura",      textureId = 135893 },
        { key = "317920", text = "Concentration Aura", textureId = 135933 },
        { key = "32223",  text = "Crusader Aura",      textureId = 135890 },
    },
}

-- Helper to create a stance text card with per-stance settings
local function CreateStanceTextCard(scrollChild, yOffset, classKey, title, iconData, db, activeCards)
    db[classKey] = db[classKey] or {}

    local card = GUIFrame:CreateCard(scrollChild, title, yOffset)
    table_insert(activeCards, card)
    table_insert(allWidgets, card)

    local stances = STANCE_TEXT_DATA[classKey]
    if not stances then
        return yOffset + card:GetContentHeight() + Theme.paddingSmall
    end

    local isFirst = true
    for _, stance in ipairs(stances) do
        -- Add separator if not first row
        if not isFirst then
            local sepRow = GUIFrame:CreateRow(card.content, 8)
            local sep = GUIFrame:CreateSeparator(sepRow)
            sepRow:AddWidget(sep, 1)
            table_insert(allWidgets, sep)
            card:AddRow(sepRow, 8)
        end
        isFirst = false

        db[classKey][stance.key] = db[classKey][stance.key] or {}
        if not db[classKey][stance.key].Text then
            db[classKey][stance.key].Text = stance.text
        end

        local row = GUIFrame:CreateRow(card.content, 40)

        -- Stance icon
        local iconWidget = CreateIconWidget(row, { textureId = stance.textureId }, 36)
        row:AddWidget(iconWidget, 0.1)

        -- Enable toggle
        local enableToggle = GUIFrame:CreateCheckbox(row, "Show", {
            value = db[classKey][stance.key].Enabled == true,
            callback = function(checked)
                db[classKey][stance.key].Enabled = checked
                Refresh()
            end
        })
        row:AddWidget(enableToggle, 0.15)
        table_insert(allWidgets, enableToggle)

        -- Color picker
        local colorPicker = GUIFrame:CreateColorPicker(row, "Color", {
            color = db[classKey][stance.key].Color or { 1, 1, 1, 1 },
            callback = function(r, g, b, a)
                db[classKey][stance.key].Color = { r, g, b, a }
                ApplySettings()
            end
        })
        row:AddWidget(colorPicker, 0.25)
        table_insert(allWidgets, colorPicker)

        -- Text input
        local textInput = GUIFrame:CreateEditBox(row, "Text", {
            value = db[classKey][stance.key].Text or stance.text,
            callback = function(text)
                db[classKey][stance.key].Text = text
                ApplySettings()
            end
        })
        row:AddWidget(textInput, 0.5)
        table_insert(allWidgets, textInput)

        card:AddRow(row, 40)
    end

    return yOffset + card:GetContentHeight() + Theme.paddingSmall
end

local function RenderStanceTextsTab(scrollChild, yOffset, activeCards)
    local db = GetMissingBuffsDB()
    if not db then return yOffset end
    db.StanceText = db.StanceText or {}

    -- Build font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            table_insert(fontList, { key = name, text = name })
        end
        table_sort(fontList, function(a, b) return a.text < b.text end)
    else
        table_insert(fontList, { key = "Friz Quadrata TT", text = "Friz Quadrata TT" })
    end

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }

    ----------------------------------------------------------------
    -- Card 1: Enable
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Stance Text Display", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Stance Text", {
        value = db.StanceText.Enabled == true,
        callback = function(checked)
            db.StanceText.Enabled = checked
            Refresh()
            UpdateAllWidgetStates()
        end
    })
    row1:AddWidget(enableCheck, 1)
    table_insert(allWidgets, enableCheck)
    card1:AddRow(row1, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Warrior Stances
    ----------------------------------------------------------------
    yOffset = CreateStanceTextCard(scrollChild, yOffset, "WARRIOR", "Warrior Stance Texts",
        CLASS_ICONS.WARRIOR, db.StanceText, activeCards)

    ----------------------------------------------------------------
    -- Card 3: Paladin Auras
    ----------------------------------------------------------------
    yOffset = CreateStanceTextCard(scrollChild, yOffset, "PALADIN", "Paladin Aura Texts",
        CLASS_ICONS.PALADIN, db.StanceText, activeCards)

    ----------------------------------------------------------------
    -- Card 4: Font Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)
    table_insert(activeCards, card4)
    table_insert(allWidgets, card4)

    -- Font and Outline
    local row4a = GUIFrame:CreateRow(card4.content, 36)
    local fontDropdown = GUIFrame:CreateDropdown(row4a, "Font", {
        options = fontList,
        value = db.StanceText.FontFace or "Friz Quadrata TT",
        labelWidth = 120,
        searchable = true,
        isFontPreview = true,
        callback = function(key)
            db.StanceText.FontFace = key
            ApplySettings()
        end
    })
    row4a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineDropdown = GUIFrame:CreateDropdown(row4a, "Outline", {
        options = outlineList,
        value = db.StanceText.FontOutline or "OUTLINE",
        labelWidth = 80,
        callback = function(key)
            db.StanceText.FontOutline = key
            ApplySettings()
        end
    })
    row4a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card4:AddRow(row4a, 36)

    -- Font Size
    local row4b = GUIFrame:CreateRow(card4.content, 36)
    local fontSizeSlider = GUIFrame:CreateSlider(row4b, "Font Size", {
        min = 8,
        max = 32,
        step = 1,
        value = db.StanceText.FontSize or 14,
        labelWidth = 60,
        callback = function(val)
            db.StanceText.FontSize = val
            ApplySettings()
        end
    })
    row4b:AddWidget(fontSizeSlider, 1)
    table_insert(allWidgets, fontSizeSlider)
    card4:AddRow(row4b, 36)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Position Settings
    ----------------------------------------------------------------
    db.StanceText.Position = db.StanceText.Position or {}
    local positionCard
    positionCard, yOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Position Settings",
        db = db.StanceText,
        defaults = {
            anchorFrameType = "UIPARENT",
            selfPoint = "CENTER",
            anchorPoint = "CENTER",
            xOffset = 0,
            yOffset = 100,
            strata = "HIGH",
        },
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    table_insert(activeCards, positionCard)

    if positionCard.positionWidgets then
        for _, widget in ipairs(positionCard.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, positionCard)

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 4)
    return yOffset
end

----------------------------------------------------------------
-- Create Missing Buffs Panel
----------------------------------------------------------------
local function CreateMissingBuffsPanel(container)
    -- Forward reference for tabPanel
    local tabPanel

    -- Render content for selected tab
    local function RenderContent(tabId)
        if not tabPanel then return end

        -- Clear widget tracking
        wipe(allWidgets)

        -- Clear panel content
        tabPanel:ClearContent()

        local scrollChild = tabPanel.scrollChild
        local yOffset = Theme.paddingMedium

        -- Collect cards for width updates
        local activeCards = {}

        -- Render selected tab content
        if tabId == "raidBuffs" then
            yOffset = RenderRaidBuffsTab(scrollChild, yOffset, activeCards)
        elseif tabId == "stances" then
            yOffset = RenderStancesTab(scrollChild, yOffset, activeCards)
        elseif tabId == "stanceTexts" then
            yOffset = RenderStanceTextsTab(scrollChild, yOffset, activeCards)
        end

        -- Register cards for width updates
        for _, card in ipairs(activeCards) do
            tabPanel:RegisterCard(card)
        end

        -- Update scroll child height
        tabPanel:SetContentHeight(yOffset + Theme.paddingLarge)

        UpdateAllWidgetStates()
    end

    -- Create sub-tab panel using the widget
    tabPanel = NRSKNUI.GUI.CreateSubTabPanel(container, SUB_TABS, {
        tabBarHeight = TAB_BAR_HEIGHT,
        defaultTab = currentSubTab,
        onTabChanged = function(tabId)
            currentSubTab = tabId
            RenderContent(tabId)
        end
    })

    -- Render initial content
    RenderContent(currentSubTab)

    return tabPanel.panel
end

----------------------------------------------------------------
-- Register Panel (full control of content area)
----------------------------------------------------------------
GUIFrame:RegisterPanel("missingBuffs", CreateMissingBuffsPanel)
