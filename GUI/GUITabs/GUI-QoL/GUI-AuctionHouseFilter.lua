---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local C_AddOns = C_AddOns

GUIFrame:RegisterContent("AuctionHouseFilter", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.AuctionHouseFilter
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type AuctionHouseFilter?
    local AHF = NorskenUI and NorskenUI:GetModule("AuctionHouseFilter", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local auctionatorLoaded = C_AddOns.IsAddOnLoaded("Auctionator")

    manager:SetCondition("auctionator", function() return auctionatorLoaded end)
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Auction House Filter", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Auction House Filter", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if AHF then
                if checked then
                    NorskenUI:EnableModule("AuctionHouseFilter")
                else
                    NorskenUI:DisableModule(
                        "AuctionHouseFilter")
                end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Auction House Filter",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Blizzard Auction House
    local card2 = GUIFrame:CreateCard(scrollChild, "Blizzard Auction House", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local ahExpansionCheck = GUIFrame:CreateCheckbox(row2a, "Current Expansion Only", {
        value = db.AuctionHouse.CurrentExpansion,
        callback = function(checked)
            db.AuctionHouse.CurrentExpansion = checked
        end
    })
    row2a:AddWidget(ahExpansionCheck, 1)
    manager:Register(ahExpansionCheck, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local sepRow1 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sepRow1, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local ahFocusCheck = GUIFrame:CreateCheckbox(row2b, "Auto Focus Search Bar", {
        value = db.AuctionHouse.FocusSearchBar,
        callback = function(checked)
            db.AuctionHouse.FocusSearchBar = checked
        end
    })
    row2b:AddWidget(ahFocusCheck, 1)
    manager:Register(ahFocusCheck, "all")
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Crafting Orders
    local card3 = GUIFrame:CreateCard(scrollChild, "Crafting Orders", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local coExpansionCheck = GUIFrame:CreateCheckbox(row3a, "Current Expansion Only", {
        value = db.CraftOrders.CurrentExpansion,
        callback = function(checked)
            db.CraftOrders.CurrentExpansion = checked
        end
    })
    row3a:AddWidget(coExpansionCheck, 1)
    manager:Register(coExpansionCheck, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local sepRow2 = GUIFrame:CreateSeparator(card3.content)
    card3:AddRow(sepRow2, Theme.rowHeightSeparator)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local coFocusCheck = GUIFrame:CreateCheckbox(row3b, "Auto Focus Search Bar", {
        value = db.CraftOrders.FocusSearchBar,
        callback = function(checked)
            db.CraftOrders.FocusSearchBar = checked
        end
    })
    row3b:AddWidget(coFocusCheck, 1)
    manager:Register(coFocusCheck, "all")
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: Auctionator
    local auctionatorLoaded = C_AddOns.IsAddOnLoaded("Auctionator")
    local auctionatorTitle = auctionatorLoaded and "Auctionator, |cff00FF00Loaded|r" or
        "Auctionator, |cffFF0000Not Loaded|r"

    local card4 = GUIFrame:CreateCard(scrollChild, auctionatorTitle, yOffset)
    manager:Register(card4, "all")

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local atrExpansionCheck = GUIFrame:CreateCheckbox(row4a, "Current Expansion Only", {
        value = db.Auctionator.CurrentExpansion,
        callback = function(checked)
            db.Auctionator.CurrentExpansion = checked
        end
    })
    row4a:AddWidget(atrExpansionCheck, 1)
    manager:Register(atrExpansionCheck, "all", "auctionator")
    card4:AddRow(row4a, Theme.rowHeight)

    local sepRow3 = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(sepRow3, Theme.rowHeightSeparator)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local atrFocusCheck = GUIFrame:CreateCheckbox(row4b, "Auto Focus Search Bar", {
        value = db.Auctionator.FocusSearchBar,
        callback = function(checked)
            db.Auctionator.FocusSearchBar = checked
        end
    })
    row4b:AddWidget(atrFocusCheck, 1)
    manager:Register(atrFocusCheck, "all", "auctionator")
    card4:AddRow(row4b, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
