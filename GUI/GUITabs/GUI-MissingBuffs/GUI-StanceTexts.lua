---@class NRSKNUI
local NRSKNUI = select(2, ...)

local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs
local type = type
local CreateFrame = CreateFrame

local StanceData = NRSKNUI.StanceData

local SIDEBAR_WIDTH = 180
local ITEM_HEIGHT = 28
local LIST_PADDING = 4

local selectedItem = "General"

local SIDEBAR_ITEMS = {
    { key = "sep_warrior", name = "Warrior", order = 9,  type = "separator" },
    { key = "WARRIOR",     name = "Stances", icon = 132349, order = 10, type = "class", class = "WARRIOR" },

    { key = "sep_paladin", name = "Paladin", order = 19, type = "separator" },
    { key = "PALADIN",     name = "Auras",   icon = 135893, order = 20, type = "class", class = "PALADIN" },
}

local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("StanceTexts", true)
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

GUIFrame:RegisterPanel("stanceTexts", function(container)
    local db = NRSKNUI.db and NRSKNUI.db.profile.MissingBuffs
    if not db then return nil end

    db.StanceText = db.StanceText or {}

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
        local card1 = GUIFrame:CreateCard(contentChild, "Stance Text Display", yOffset)
        miniSidebar.contentArea.RegisterCard(card1)

        local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
        local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Stance Text", {
            value = db.StanceText.Enabled == true,
            callback = function(checked)
                db.StanceText.Enabled = checked
                local mod = GetModule()
                if mod then
                    if checked then NorskenUI:EnableModule("StanceTexts") else NorskenUI:DisableModule("StanceTexts") end
                end
            end,
            msgPopup = true,
            msgText = "Stance Text",
        })
        row1:AddWidget(enableCheck, 1)
        card1:AddRow(row1, Theme.rowHeightLast, 0)

        yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

        db.StanceText.FontShadow = db.StanceText.FontShadow or {}
        local fontCard
        fontCard, yOffset = GUIFrame:CreateFontSettingsCard(contentChild, yOffset, {
            title = "Font Settings",
            db = db.StanceText,
            fontSizeRange = { 8, 32 },
            includeSoftOutline = true,
            onChangeCallback = ApplySettings,
        })
        miniSidebar.contentArea.RegisterCard(fontCard)

        db.StanceText.Position = db.StanceText.Position or {}
        local positionCard
        positionCard, yOffset = GUIFrame:CreatePositionCard(contentChild, yOffset, {
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
        miniSidebar.contentArea.RegisterCard(positionCard)

    elseif itemData and itemData.type == "class" then
        local classKey = itemData.key
        db.StanceText[classKey] = db.StanceText[classKey] or {}

        local title = classKey == "WARRIOR" and "Warrior Stance Texts" or "Paladin Aura Texts"
        local card = GUIFrame:CreateCard(contentChild, title, yOffset)
        miniSidebar.contentArea.RegisterCard(card)

        local stances = StanceData:GetStanceTextData(classKey)
        if stances and #stances > 0 then
            local isFirst = true
            for _, stance in ipairs(stances) do
                if not isFirst then
                    local sep = GUIFrame:CreateSeparator(card.content)
                    card:AddRow(sep, Theme.rowHeightSeparator)
                end
                isFirst = false

                db.StanceText[classKey][stance.key] = db.StanceText[classKey][stance.key] or {}
                if not db.StanceText[classKey][stance.key].Text then
                    db.StanceText[classKey][stance.key].Text = stance.text
                end

                local row = GUIFrame:CreateRow(card.content, 40)

                local iconWidget = CreateIconWidget(row, { textureId = stance.textureId }, 36)
                row:AddWidget(iconWidget, 0.1)

                local enableToggle = GUIFrame:CreateCheckbox(row, "Show", {
                    value = db.StanceText[classKey][stance.key].Enabled == true,
                    callback = function(checked)
                        db.StanceText[classKey][stance.key].Enabled = checked
                        Refresh()
                    end
                })
                row:AddWidget(enableToggle, 0.15)

                local colorPicker = GUIFrame:CreateColorPicker(row, "Color", {
                    color = db.StanceText[classKey][stance.key].Color or { 1, 1, 1, 1 },
                    callback = function(r, g, b, a)
                        db.StanceText[classKey][stance.key].Color = { r, g, b, a }
                        ApplySettings()
                    end
                })
                row:AddWidget(colorPicker, 0.25)

                local textInput = GUIFrame:CreateEditBox(row, "Text", {
                    value = db.StanceText[classKey][stance.key].Text or stance.text,
                    callback = function(text)
                        db.StanceText[classKey][stance.key].Text = text
                        ApplySettings()
                    end
                })
                row:AddWidget(textInput, 0.5)

                card:AddRow(row, 40)
            end
        end

        yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall
    end

    miniSidebar.contentArea.SetContentHeight(yOffset)
    C_Timer.After(0, function()
        miniSidebar.contentArea.UpdateScrollBarVisibility()
        miniSidebar.contentArea.UpdateCardWidths()
    end)

    return miniSidebar.panel
end)
