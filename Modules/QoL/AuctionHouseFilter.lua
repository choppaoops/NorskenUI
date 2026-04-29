---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("AuctionHouseFilter: Addon object not initialized. Check file load order!")
    return
end

---@class AuctionHouseFilter: AceModule, AceEvent-3.0
local AHF = NorskenUI:NewModule("AuctionHouseFilter", "AceEvent-3.0")

local GetExpansionLevel = GetExpansionLevel
local C_Timer = C_Timer
local C_AddOns = C_AddOns

local hooksInstalled = false
local displayModeHooked = false

function AHF:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.AuctionHouseFilter
end

function AHF:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function AHF:ApplyAuctionHouseFilter()
    if not self.db.Enabled then return end
    if not AuctionHouseFrame then return end

    -- Hook needed when using auctionator
    -- Otherwise when you click between blizzard tab and auctionator tab, filter is lost
    if not displayModeHooked and C_AddOns.IsAddOnLoaded("Auctionator") then
        displayModeHooked = true
        if AuctionHouseFrame.BrowseResultsFrame then
            AuctionHouseFrame.BrowseResultsFrame:HookScript("OnShow",
            function() C_Timer.After(0.05, function() self:ApplyFilter() end) end)
        end
    end
    self:ApplyFilter()
end

function AHF:ApplyFilter()
    if not self.db.Enabled then return end

    C_Timer.After(0, function()
        if not AuctionHouseFrame then return end

        if self.db.AuctionHouse.CurrentExpansion then
            local filterButton = AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.FilterButton
            if filterButton and filterButton.filters then
                filterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
            end
        end

        if self.db.AuctionHouse.FocusSearchBar then
            local searchBox = AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox
            if searchBox then searchBox:SetFocus() end
        end
    end)
end

function AHF:ApplyCraftOrdersFilter()
    if not self.db.Enabled then return end

    C_Timer.After(0, function()
        local frame = ProfessionsCustomerOrdersFrame
        if not frame or not frame.BrowseOrders or not frame.BrowseOrders.SearchBar then return end

        if self.db.CraftOrders.CurrentExpansion then
            local filterDropdown = frame.BrowseOrders.SearchBar.FilterDropdown
            if filterDropdown and filterDropdown.filters then
                filterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
            end
        end

        if self.db.CraftOrders.FocusSearchBar then
            local searchBox = frame.BrowseOrders.SearchBar.SearchBox
            if searchBox then searchBox:SetFocus() end
        end
    end)
end

function AHF:ApplyAuctionatorFilter()
    if not self.db.Enabled then return end
    if not C_AddOns.IsAddOnLoaded("Auctionator") then return end

    C_Timer.After(0, function()
        local frame = _G["AuctionatorShoppingTabItemFrame"]
        if not frame then return end

        if self.db.Auctionator.CurrentExpansion then
            local dropdown = frame.ExpansionContainer and frame.ExpansionContainer.DropDown
            if dropdown and dropdown.SetValue then
                local currentExpansion = GetExpansionLevel() or 12
                dropdown:SetValue(currentExpansion)
            end
        end

        if self.db.Auctionator.FocusSearchBar then
            local searchBox = frame.SearchBox or (frame.SearchContainer and frame.SearchContainer.SearchBox)
            if searchBox and searchBox.SetFocus then
                searchBox:SetFocus()
            end
        end
    end)
end

function AHF:SetupHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    self:RegisterEvent("AUCTION_HOUSE_SHOW", "ApplyAuctionHouseFilter")
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER", "ApplyCraftOrdersFilter")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, interactionType)
        if interactionType == Enum.PlayerInteractionType.Auctioneer then
            C_Timer.After(0.1, function()
                self:ApplyAuctionatorFilter()
            end)
        end
    end)
end

function AHF:ApplySettings()
    if not self.db.Enabled then return end
    self:ApplyAuctionHouseFilter()
    self:ApplyCraftOrdersFilter()
    self:ApplyAuctionatorFilter()
end

function AHF:OnEnable()
    if not self.db.Enabled then return end
    self:SetupHooks()
end

function AHF:OnDisable()
    self:UnregisterAllEvents()
    hooksInstalled = false
end
