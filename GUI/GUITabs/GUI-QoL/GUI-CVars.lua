---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local ipairs = ipairs

GUIFrame:RegisterContent("MiscVars", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.MiscVars
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type MiscVars?
    local MVAR = NorskenUI and NorskenUI:GetModule("MiscVars", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled ~= false) end

    local function CreateCVarWidget(card, def)
        local key = def.key
        local widgetRow = GUIFrame:CreateRow(card.content, Theme.rowHeight)
        local widget
        local tooltipConfig = def.description and { text = def.description, default = def.default, } or nil

        if def.type == "boolean" then
            widget = GUIFrame:CreateCheckbox(widgetRow, def.label, {
                value = db[key],
                tooltip = tooltipConfig,
                cvartooltip = true,
                callback = function(checked)
                    db[key] = checked
                    MVAR._suppressCVarUpdate = true
                    MVAR:ApplySettings()
                    MVAR._suppressCVarUpdate = false
                end
            })
            widgetRow:AddWidget(widget, 1)
        elseif def.type == "number" then
            widget = GUIFrame:CreateSlider(widgetRow, def.label, {
                min = def.min,
                max = def.max,
                step = def.step,
                value = db[key],
                tooltip = tooltipConfig,
                cvartooltip = true,
                callback = function(value)
                    db[key] = value
                    MVAR._suppressCVarUpdate = true
                    MVAR:ApplySettings()
                    MVAR._suppressCVarUpdate = false
                end
            })
            widgetRow:AddWidget(widget, 1)
        end

        manager:Register(widget, "all")
        card:AddRow(widgetRow, Theme.rowHeight)
        return widget
    end

    local function AddSeparator(card)
        local sepRow = GUIFrame:CreateRow(card.content, Theme.rowHeightSeparator)
        local sep = GUIFrame:CreateSeparator(sepRow)
        sepRow:AddWidget(sep, 1)
        manager:Register(sep, "all")
        card:AddRow(sepRow, Theme.rowHeightSeparator)
    end

    if MVAR then
        local generalDefs, spellqueueDefs, devDefs = {}, {}, {}
        for _, def in ipairs(MVAR.DEFS) do
            if def.category == "spellqueue" then
                spellqueueDefs[#spellqueueDefs + 1] = def
            elseif def.category == "dev" then
                devDefs[#devDefs + 1] = def
            else
                generalDefs[#generalDefs + 1] = def
            end
        end

        local card1 = GUIFrame:CreateCard(scrollChild, "CVar Browser", yOffset)
        for i, def in ipairs(generalDefs) do
            CreateCVarWidget(card1, def)
            if i < #generalDefs then AddSeparator(card1) end
        end
        yOffset = card1:GetNextOffset()

        local card2 = GUIFrame:CreateCard(scrollChild, "Spell Queue Window", yOffset)
        for i, def in ipairs(spellqueueDefs) do
            CreateCVarWidget(card2, def)
            if i < #spellqueueDefs then AddSeparator(card2) end
        end

        AddSeparator(card2)

        local infoHeight = 70
        local infoRow = GUIFrame:CreateRow(card2.content, infoHeight)
        local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Learn More"), {
            text =
            "The spell queue window determines how early you can\nqueue your next ability before your current cast finishes.\nVisit |cff8788EEXerwo|r's maxroll guide for more information.",
            height = infoHeight,
            bgMode = "hide"
        })
        infoRow:AddWidget(infoText, 0.65)
        manager:Register(infoText, "all")

        local linkBtn = GUIFrame:CreateButton(infoRow, "Open Guide", {
            callback = function()
                NRSKNUI:CreateCopyDialog(
                    "Spell Queue Window Guide",
                    "https://maxroll.gg/wow/resources/spell-queue-window",
                    "Copy to clipboard by pressing CTRL + C"
                )
            end,
            width = 100,
            height = 36,
        })
        infoRow:AddWidget(linkBtn, 0.35)
        manager:Register(linkBtn, "all")
        card2:AddRow(infoRow, infoHeight, 0)

        yOffset = card2:GetNextOffset()

        local card3 = GUIFrame:CreateCard(scrollChild, "Dev CVars", yOffset)
        for i, def in ipairs(devDefs) do
            CreateCVarWidget(card3, def)
            if i < #devDefs then AddSeparator(card3) end
        end
        yOffset = card3:GetNextOffset()
    end

    UpdateAllWidgetStates()
    return yOffset
end)
