---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs

GUIFrame:RegisterContent("Automation", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Automation
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type Automation?
    local AUTO = NorskenUI and NorskenUI:GetModule("Automation", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings()
        if AUTO and AUTO.ApplySettings then AUTO:ApplySettings() end
    end

    local postUpdateCallbacks = {}

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Automation", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Automation", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if AUTO then
                if checked then NorskenUI:EnableModule("Automation") else NorskenUI:DisableModule("Automation") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Automation",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Cinematics & Dialogs
    local card2 = GUIFrame:CreateCard(scrollChild, "Cinematics & Dialogs", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local skipCinematicsCheck = GUIFrame:CreateCheckbox(row2a, "Skip Cinematics & Movies", {
        value = db.SkipCinematics,
        callback = function(checked)
            db.SkipCinematics = checked
            ApplySettings()
        end
    })
    row2a:AddWidget(skipCinematicsCheck, 1)
    manager:Register(skipCinematicsCheck, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local hideTalkingHeadCheck = GUIFrame:CreateCheckbox(row2b, "Hide Talking Head Frame", {
        value = db.HideTalkingHead,
        callback = function(checked)
            db.HideTalkingHead = checked
            ApplySettings()
        end
    })
    row2b:AddWidget(hideTalkingHeadCheck, 1)
    manager:Register(hideTalkingHeadCheck, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local hideHelptipsCheck = GUIFrame:CreateCheckbox(row2c, "Hide Spammy Tutorial Helptips", {
        value = db.HideHelptips,
        callback = function(checked)
            db.HideHelptips = checked
            ApplySettings()
        end
    })
    row2c:AddWidget(hideHelptipsCheck, 1)
    manager:Register(hideHelptipsCheck, "all")
    card2:AddRow(row2c, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Merchant Automation
    local card3 = GUIFrame:CreateCard(scrollChild, "Merchant Automation", yOffset)
    manager:Register(card3, "all")
    local useGuildCheck

    local shiftTooltip = "Hold " .. "|cffffffffShift|r" .. " when opening a merchant to skip this action."

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local autoSellCheck = GUIFrame:CreateCheckbox(row3a, "Auto Sell Junk (Grey Items)", {
        value = db.AutoSellJunk,
        tooltip = shiftTooltip,
        callback = function(checked)
            db.AutoSellJunk = checked
            ApplySettings()
        end
    })
    row3a:AddWidget(autoSellCheck, 1)
    manager:Register(autoSellCheck, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local autoRepairCheck = GUIFrame:CreateCheckbox(row3b, "Auto Repair Gear", {
        value = db.AutoRepair,
        tooltip = shiftTooltip,
        callback = function(checked)
            db.AutoRepair = checked
            if useGuildCheck and useGuildCheck.SetEnabled then
                useGuildCheck:SetEnabled(db.Enabled and checked)
            end
            ApplySettings()
        end
    })
    row3b:AddWidget(autoRepairCheck, 1)
    manager:Register(autoRepairCheck, "all")
    card3:AddRow(row3b, Theme.rowHeight)

    local row3c = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    useGuildCheck = GUIFrame:CreateCheckbox(row3c, "Use Guild Funds for Repair", {
        value = db.UseGuildFunds,
        callback = function(checked)
            db.UseGuildFunds = checked
            ApplySettings()
        end
    })
    row3c:AddWidget(useGuildCheck, 1)
    manager:Register(useGuildCheck, "all")
    card3:AddRow(row3c, Theme.rowHeightLast, 0)

    local function UpdateGuildFundsState()
        if useGuildCheck and useGuildCheck.SetEnabled then
            useGuildCheck:SetEnabled(db.Enabled and db.AutoRepair)
        end
    end
    table.insert(postUpdateCallbacks, UpdateGuildFundsState)

    yOffset = card3:GetNextOffset()

    -- Card 4: Group Finder
    local card4 = GUIFrame:CreateCard(scrollChild, "Group Finder", yOffset)
    manager:Register(card4, "all")

    local row4 = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local autoRoleCheck = GUIFrame:CreateCheckbox(row4, "Auto Accept Role Check", {
        value = db.AutoRoleCheck,
        tooltip = "Hold " .. "|cffffffffShift|r" .. " to skip auto-accepting role checks. Role based on selected roles in the Group Finder.",
        callback = function(checked)
            db.AutoRoleCheck = checked
            ApplySettings()
        end
    })
    row4:AddWidget(autoRoleCheck, 1)
    manager:Register(autoRoleCheck, "all")
    card4:AddRow(row4, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5: Convenience
    local card5 = GUIFrame:CreateCard(scrollChild, "Convenience", yOffset)
    manager:Register(card5, "all")

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local autoFillDeleteCheck = GUIFrame:CreateCheckbox(row5a, "Auto-Fill DELETE Text", {
        value = db.AutoFillDelete,
        callback = function(checked)
            db.AutoFillDelete = checked
            ApplySettings()
        end
    })
    row5a:AddWidget(autoFillDeleteCheck, 1)
    manager:Register(autoFillDeleteCheck, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local row5b = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local autoLootCheck = GUIFrame:CreateCheckbox(row5b, "Auto Loot", {
        value = db.AutoLoot,
        callback = function(checked)
            db.AutoLoot = checked
            ApplySettings()
        end
    })
    row5b:AddWidget(autoLootCheck, 1)
    manager:Register(autoLootCheck, "all")
    card5:AddRow(row5b, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
