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

    local card1 = GUIFrame:CreateCard(scrollChild, "CVars", yOffset)

    if MVAR then
        for i, def in ipairs(MVAR.DEFS) do
            local key = def.key

            local widgetRow = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
            local widget

            local tooltipConfig = def.description and { text = def.description, default = def.default, } or nil

            -- For cvars that simply use 0/1 to disable/enable we use checkboxes
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

                -- For cvars that have a range of values we use sliders
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
            card1:AddRow(widgetRow, Theme.rowHeight)

            if i < #MVAR.DEFS then
                local sepRow = GUIFrame:CreateRow(card1.content, Theme.rowHeightSeparator)
                local sep = GUIFrame:CreateSeparator(sepRow)
                sepRow:AddWidget(sep, 1)
                manager:Register(sep, "all")
                card1:AddRow(sepRow, Theme.rowHeightSeparator)
            end
        end
    end

    yOffset = card1:GetNextOffset()
    UpdateAllWidgetStates()
    return yOffset
end)
