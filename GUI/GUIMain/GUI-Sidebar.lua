---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local math = math
local C_Timer = C_Timer
local ipairs = ipairs
local CreateFrame = CreateFrame
local pairs = pairs
local pcall = pcall
local wipe = wipe

GUIFrame.sidebarHeaderPool = {}
GUIFrame.currentExpandedSection = nil

local headerHeight = 32
local itemHeight = 28
local HOVER_DURATION = 0.12
local ARROW_DURATION = 0.2
local ACCENT_BAR_WIDTH = 2
local SEARCH_BOX_HEIGHT = 30

-- Release section headers
function GUIFrame:ReleaseSectionHeaders()
    for _, header in ipairs(self.sidebarHeaderPool or {}) do
        header.inUse = false
        header.disabled = nil
        if header.hoverBg then
            header.hoverBg:SetAlpha(0)
        end
        if header.label then
            header.label:SetText("")
            header.label:SetAlpha(1)
            header.label:Show()
        end
        header:SetAlpha(1)
        header:EnableMouse(true)
        header:Hide()
        header:ClearAllPoints()
    end
end

-- Search functionality
local PLACEHOLDER_TEXT = "Search..."
GUIFrame.searchText = ""
GUIFrame.searchResults = {}
GUIFrame.widgetRegistry = {}
GUIFrame.currentBuildingPageId = nil

function GUIFrame:RegisterSearchableWidget(widget, labelText)
    if not self.currentBuildingPageId or not labelText or labelText == "" then return end
    if not self.widgetRegistry[self.currentBuildingPageId] then self.widgetRegistry[self.currentBuildingPageId] = {} end
    table.insert(self.widgetRegistry[self.currentBuildingPageId], { widget = widget, label = labelText, })
end

function GUIFrame:ClearWidgetRegistry(pageId)
    if pageId then self.widgetRegistry[pageId] = nil end
end

function GUIFrame:BuildSearchIndex()
    local index = {}
    for tabId, config in pairs(self.SidebarConfig) do
        for _, section in ipairs(config) do
            if section.type == "header" and section.items then
                for _, item in ipairs(section.items) do
                    table.insert(index, {
                        id = item.id,
                        text = item.text,
                        sectionId = section.id,
                        sectionText = section.text,
                        tabId = tabId,
                        elvUIDisabled = item.elvUIDisabled or section.elvUIDisabled,
                        isPage = true,
                    })
                end
            end
        end
    end
    self.searchIndex = index
    return index
end

function GUIFrame:PreBuildAllPagesForSearch()
    if self.searchIndexBuilt then return end

    local dummyFrame = CreateFrame("Frame", nil, UIParent)
    dummyFrame:SetSize(600, 2000)
    dummyFrame:Hide()

    for _, config in pairs(self.SidebarConfig) do
        for _, section in ipairs(config) do
            if section.type == "header" and section.items then
                for _, item in ipairs(section.items) do
                    local pageId = item.id
                    if self.ContentBuilders[pageId] and not self.widgetRegistry[pageId] then
                        self.currentBuildingPageId = pageId
                        pcall(self.ContentBuilders[pageId], dummyFrame, 0)
                        self.currentBuildingPageId = nil

                        for _, child in ipairs({ dummyFrame:GetChildren() }) do
                            child:Hide()
                            child:SetParent(nil)
                        end
                        for _, region in ipairs({ dummyFrame:GetRegions() }) do region:Hide() end
                    end
                end
            end
        end
    end

    dummyFrame:SetParent(nil)
    self.searchIndexBuilt = true
end

function GUIFrame:GetPageInfoById(pageId)
    for tabId, config in pairs(self.SidebarConfig) do
        for _, section in ipairs(config) do
            if section.type == "header" and section.items then
                for _, item in ipairs(section.items) do
                    if item.id == pageId then
                        return {
                            id = item.id,
                            text = item.text,
                            sectionId = section.id,
                            sectionText = section.text,
                            tabId = tabId,
                            elvUIDisabled = item.elvUIDisabled or section.elvUIDisabled,
                        }
                    end
                end
            end
        end
    end
    return nil
end

function GUIFrame:SearchSidebar(searchText)
    wipe(self.searchResults)
    if not searchText or searchText == "" then return self.searchResults end
    if not self.searchIndex then self:BuildSearchIndex() end

    local searchLower = searchText:lower()
    local addedPages = {}

    for _, entry in ipairs(self.searchIndex) do
        local textLower = entry.text:lower()
        local sectionLower = entry.sectionText:lower()
        if textLower:find(searchLower, 1, true) or sectionLower:find(searchLower, 1, true) then
            table.insert(self.searchResults, entry)
            addedPages[entry.id] = true
        end
    end

    for pageId, widgets in pairs(self.widgetRegistry) do
        for _, widgetData in ipairs(widgets) do
            local labelLower = widgetData.label:lower()
            if labelLower:find(searchLower, 1, true) then
                local pageInfo = self:GetPageInfoById(pageId)
                if pageInfo and not addedPages[pageId] then
                    table.insert(self.searchResults, pageInfo)
                    addedPages[pageId] = true
                end
                table.insert(self.searchResults, {
                    id = pageId,
                    text = widgetData.label,
                    sectionId = pageInfo and pageInfo.sectionId,
                    sectionText = pageInfo and pageInfo.text or pageId,
                    tabId = pageInfo and pageInfo.tabId,
                    elvUIDisabled = pageInfo and pageInfo.elvUIDisabled,
                    isWidget = true,
                    widget = widgetData.widget,
                })
            end
        end
    end

    return self.searchResults
end

function GUIFrame:ClearSearch()
    self.searchText = ""
    wipe(self.searchResults)
    if self.searchEditBox then
        self.searchEditBox:SetText(PLACEHOLDER_TEXT)
        self.searchEditBox:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
    end
    if self.searchClearButton then
        self.searchClearButton:Hide()
    end
    self:RefreshSidebar()
end

function GUIFrame:CreateSearchHeader(parent)
    if not parent then return end

    local searchContainerBG = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    searchContainerBG:SetHeight(SEARCH_BOX_HEIGHT)
    searchContainerBG:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -Theme.headerHeight + 1)
    searchContainerBG:SetPoint("RIGHT", parent.content or parent, "LEFT", 0, 0)
    searchContainerBG:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, })
    searchContainerBG:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
    searchContainerBG:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local searchContainer = CreateFrame("Frame", nil, searchContainerBG, "BackdropTemplate")
    searchContainer:SetHeight(SEARCH_BOX_HEIGHT)
    searchContainer:SetPoint("TOPLEFT", searchContainerBG, "TOPLEFT", 4, -4)
    searchContainer:SetPoint("BOTTOMRIGHT", searchContainerBG, "BOTTOMRIGHT", -4, 4)
    searchContainer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, })
    searchContainer:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], 0)
    searchContainer:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 0)

    local clearButton = CreateFrame("Button", nil, searchContainer)
    clearButton:SetSize(16, 16)
    clearButton:SetPoint("RIGHT", searchContainer, "RIGHT", -4, 0)
    clearButton:Hide()

    local clearIcon = clearButton:CreateTexture(nil, "ARTWORK")
    clearIcon:SetAllPoints()
    clearIcon:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\NorskenCustomCrossv3.png")
    clearIcon:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    clearIcon:SetRotation(math.rad(45))

    clearButton:SetScript("OnEnter", function()
        clearIcon:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    end)
    clearButton:SetScript("OnLeave", function()
        clearIcon:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    end)
    clearButton:SetScript("OnClick", function() GUIFrame:ClearSearch() end)
    self.searchClearButton = clearButton

    local searchEditBox = CreateFrame("EditBox", nil, searchContainer)
    searchEditBox:SetPoint("TOPLEFT", searchContainer, "TOPLEFT", 6, -4)
    searchEditBox:SetPoint("BOTTOMRIGHT", clearButton, "BOTTOMLEFT", -4, -4)
    searchEditBox:SetFontObject("GameFontNormal")
    searchEditBox:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetText(PLACEHOLDER_TEXT)
    self.searchEditBox = searchEditBox

    searchEditBox:SetScript("OnTextChanged", function(editBox, userInput)
        if not userInput then return end
        local text = editBox:GetText()
        if text == PLACEHOLDER_TEXT then
            GUIFrame.searchText = ""
        else
            GUIFrame.searchText = text
        end
        if GUIFrame.searchText ~= "" then
            clearButton:Show()
        else
            clearButton:Hide()
        end
        GUIFrame:SearchSidebar(GUIFrame.searchText)
        GUIFrame:RefreshSidebar()
    end)

    searchEditBox:SetScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
        if GUIFrame.searchText ~= "" then GUIFrame:ClearSearch() end
    end)

    searchEditBox:SetScript("OnEnterPressed", function(editBox) editBox:ClearFocus() end)

    searchEditBox:SetScript("OnEditFocusGained", function(editBox)
        editBox:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        if editBox:GetText() == PLACEHOLDER_TEXT then editBox:SetText("") end
    end)

    searchEditBox:SetScript("OnEditFocusLost", function(editBox)
        editBox:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
        if editBox:GetText() == "" then editBox:SetText(PLACEHOLDER_TEXT) end
    end)

    return searchContainer
end

function GUIFrame:CreateSectionHeader()
    local ARROW_SIZE = 14
    local arrowTex = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\collapse.tga"

    local header = CreateFrame("Button", nil, UIParent)
    header:SetHeight(headerHeight)
    header:EnableMouse(true)
    header:RegisterForClicks("LeftButtonUp")

    local hoverBg = header:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(1, 1, 1, 0.04)
    hoverBg:SetAlpha(0)
    header.hoverBg = hoverBg

    local label = header:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", header, "LEFT", Theme.paddingSmall, 0)
    NRSKNUI:ApplyThemeFont(label, "large")
    label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    header.label = label

    local arrow = header:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("RIGHT", header, "RIGHT", -Theme.paddingSmall, 0)
    arrow:SetTexture(arrowTex)
    arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    arrow:SetTexelSnappingBias(0)
    arrow:SetSnapToPixelGrid(false)
    header.arrow = arrow

    local arrowAnimGroup = arrow:CreateAnimationGroup()
    local arrowRotation = arrowAnimGroup:CreateAnimation("Rotation")
    arrowRotation:SetDuration(ARROW_DURATION)
    arrowRotation:SetOrigin("CENTER", 0, 0)
    arrowRotation:SetSmoothing("OUT")
    header.arrowAnimGroup = arrowAnimGroup
    header.arrowRotation = arrowRotation

    header.AnimateArrowOpen = function(self)
        if self.isExpanded then return end
        self.arrowAnimGroup:Stop()
        self.arrowRotation:SetRadians(math.pi / 2)
        self.isExpanded = true
        self.arrowAnimGroup:Play()
    end

    header.AnimateArrowClose = function(self)
        if not self.isExpanded then return end
        self.arrowAnimGroup:Stop()
        self.arrowRotation:SetRadians(-math.pi / 2)
        self.isExpanded = false
        self.arrowAnimGroup:Play()
    end

    arrowAnimGroup:SetScript("OnFinished", function()
        arrow:SetRotation(header.isExpanded and 0 or -math.pi / 2)
    end)

    header.SetArrowState = function(self, expanded)
        self.arrowAnimGroup:Stop()
        self.isExpanded = expanded
        self.arrow:SetRotation(expanded and 0 or -math.pi / 2)
    end

    local hoverTarget = 0
    header:SetScript("OnUpdate", function(self, elapsed)
        local current = hoverBg:GetAlpha()
        if math.abs(current - hoverTarget) > 0.01 then
            local speed = elapsed / HOVER_DURATION
            if hoverTarget > current then
                hoverBg:SetAlpha(math.min(current + speed, hoverTarget))
            else
                hoverBg:SetAlpha(math.max(current - speed, hoverTarget))
            end
        end
    end)

    header:SetScript("OnEnter", function(self)
        if header.disabled then return end
        hoverTarget = 1
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    end)

    header:SetScript("OnLeave", function(self)
        hoverTarget = 0
        if not header.disabled then
            header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
        end
    end)

    header:SetScript("OnClick", function(self)
        if not header.disabled then
            GUIFrame:ToggleSection(self.sectionId)
        end
    end)

    return header
end

function GUIFrame:GetSectionHeader()
    for _, header in ipairs(self.sidebarHeaderPool) do
        if not header.inUse then
            header.inUse = true
            header:Show()
            return header
        end
    end

    local header = self:CreateSectionHeader()
    header.inUse = true
    table.insert(self.sidebarHeaderPool, header)
    return header
end

local initSideBar = false
function GUIFrame:InitializeSidebarExpansion()
    if initSideBar then return end
    wipe(self.sidebarExpanded)

    local config = self.SidebarConfig[self.selectedTab]
    if not config then return end

    for _, section in ipairs(config) do
        if section.type == "header" and section.defaultExpanded then
            self.sidebarExpanded[section.id] = true
        end
    end
    initSideBar = true
end

local arrowInitPos = false
function GUIFrame:ConfigureSectionHeader(header, config, yOffset, isExpanded)
    local scrollChild = self.sidebar.scrollChild
    local horizontalPadding = Theme.paddingSmall

    header:SetParent(scrollChild)
    header:SetFrameLevel(scrollChild:GetFrameLevel() + 2)
    header:SetHeight(headerHeight)
    header:SetAlpha(1)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", horizontalPadding, -yOffset)
    header:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -horizontalPadding, -yOffset)
    header.sectionId = config.id
    header.label:Show()
    header.label:SetAlpha(1)
    NRSKNUI:ApplyThemeFont(header.label, "large")
    header.label:SetText(config.text or "")

    if config.elvUIDisabled and NRSKNUI:ShouldNotLoadModule() then
        header.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
        header.disabled = true
    else
        header.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
        header.disabled = false
    end

    header.isExpanded = isExpanded

    if not arrowInitPos then
        C_Timer.After(0.1, function()
            header:SetArrowState(isExpanded)
            arrowInitPos = true
        end)
    end
    header.hoverBg:SetAlpha(0)
    return header
end

function GUIFrame:GetHeaderBySectionId(sectionId)
    for _, header in ipairs(self.sidebarHeaderPool) do
        if header.inUse and header.sectionId == sectionId then
            return header
        end
    end
end

function GUIFrame:ToggleSection(sectionId)
    local wasExpanded = self.sidebarExpanded[sectionId]

    if wasExpanded then
        local header = self:GetHeaderBySectionId(sectionId)
        if header then
            header:AnimateArrowClose()
        end
        self.sidebarExpanded[sectionId] = nil
    else
        local header = self:GetHeaderBySectionId(sectionId)
        if header then
            header:AnimateArrowOpen()
        end

        self.sidebarExpanded[sectionId] = true
    end
    C_Timer.After(0.01, function()
        self:RefreshSidebar()
        self:RefreshContent()
    end)
end

GUIFrame.staticSidebarItemPool = {}

function GUIFrame:GetStaticSidebarItem()
    for _, item in ipairs(self.staticSidebarItemPool) do
        if not item.inUse then
            item.inUse = true
            item:Show()
            return item
        end
    end

    local item = self:CreateStaticSidebarItem()
    item.inUse = true
    table.insert(self.staticSidebarItemPool, item)
    return item
end

function GUIFrame:ReleaseStaticSidebarItems()
    for _, item in ipairs(self.staticSidebarItemPool) do
        item.inUse = false
        item.hoverTarget = 0
        if item.hoverBg then
            item.hoverBg:SetAlpha(0)
        end
        if item.accentBar then
            item.accentBar:Hide()
        end
        if item.selectedBg then
            item.selectedBg:Hide()
        end
        if item.label then
            item.label:SetText("")
            item.label:SetAlpha(1)
            item.label:Show()
        end
        item:EnableMouse(true)
        item:SetAlpha(1)
        item:Hide()
        item:ClearAllPoints()
        item.id = nil
        item.disabled = nil
        item.searchResult = nil
    end
end

function GUIFrame:CreateStaticSidebarItem()
    local item = CreateFrame("Button", nil, UIParent)
    item:SetHeight(itemHeight)
    item:EnableMouse(true)
    item:RegisterForClicks("LeftButtonUp")

    local hoverBg = item:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(1, 1, 1, 0.05)
    hoverBg:SetAlpha(0)
    item.hoverBg = hoverBg

    local selectedBg = item:CreateTexture(nil, "BACKGROUND", nil, 1)
    selectedBg:SetAllPoints()
    selectedBg:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.08)
    selectedBg:Hide()
    item.selectedBg = selectedBg

    local accentBar = item:CreateTexture(nil, "OVERLAY")
    accentBar:SetWidth(ACCENT_BAR_WIDTH)
    accentBar:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    accentBar:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    accentBar:Hide()
    item.accentBar = accentBar

    local label = item:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", item, "LEFT", 10, 0)
    label:SetPoint("RIGHT", item, "RIGHT", -Theme.paddingSmall, 0)
    NRSKNUI:ApplyThemeFont(label, "normal")
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    item.label = label

    item.hoverTarget = 0
    item:SetScript("OnUpdate", function(sideItem, elapsed)
        local current = hoverBg:GetAlpha()
        if math.abs(current - sideItem.hoverTarget) > 0.01 then
            local speed = elapsed / HOVER_DURATION
            if sideItem.hoverTarget > current then
                hoverBg:SetAlpha(math.min(current + speed, sideItem.hoverTarget))
            else
                hoverBg:SetAlpha(math.max(current - speed, sideItem.hoverTarget))
            end
        end
    end)

    item:SetScript("OnEnter", function(sideItem)
        if sideItem.disabled then return end
        sideItem.hoverTarget = 1
        if sideItem.id ~= GUIFrame.selectedSidebarItem then
            sideItem.label:SetTextColor(Theme.textPrimary[1], Theme.textPrimary[2], Theme.textPrimary[3], 1)
        end
    end)

    item:SetScript("OnLeave", function(sideItem)
        sideItem.hoverTarget = 0
        if sideItem.id ~= GUIFrame.selectedSidebarItem and not sideItem.disabled then
            sideItem.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        end
    end)

    item:SetScript("OnClick", function(sideItem, button)
        if button == "LeftButton" and not sideItem.disabled then
            GUIFrame:SelectSidebarItem(sideItem.id, sideItem.searchResult)
        end
    end)

    return item
end

function GUIFrame:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(Theme.headerHeight + SEARCH_BOX_HEIGHT - 1))
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, Theme.footerHeight)
    sidebar:SetPoint("RIGHT", parent.content or parent, "LEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])

    local rightBorder = sidebar:CreateTexture(nil, "BORDER")
    rightBorder:SetWidth(Theme.borderSize)
    rightBorder:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])

    local scrollbarWidth = Theme.scrollbarWidth or 16

    local scrollFrame = CreateFrame("ScrollFrame", nil, sidebar)
    scrollFrame:SetFrameLevel(sidebar:GetFrameLevel() + 5)
    scrollFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, -Theme.paddingSmall)
    scrollFrame:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -Theme.borderSize, Theme.paddingSmall)
    scrollFrame:SetClipsChildren(true)
    sidebar.scrollFrameDefaultTop = -Theme.paddingSmall

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollChild:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)
    scrollFrame:SetScrollChild(scrollChild)

    local scrollbar = NRSKNUI.GUI.CreateScrollbar(scrollFrame, {
        width = 16,
        thumbHeight = 40,
        padding = { top = -1, bottom = -1, right = 0 },
        scrollStep = 40
    })
    sidebar.scrollbar = scrollbar

    local sidebarScrollbarVisible = false
    local function UpdateSidebarScrollChildWidth()
        local sidebarActualWidth = sidebar:GetWidth()
        if sidebarActualWidth and sidebarActualWidth > 0 then
            if sidebarScrollbarVisible then
                scrollChild:SetWidth(sidebarActualWidth - Theme.borderSize - scrollbarWidth)
            else
                scrollChild:SetWidth(sidebarActualWidth - Theme.borderSize)
            end
        end
    end
    local function UpdateSidebarScrollBarVisibility()
        local contentHeight = scrollChild:GetHeight()
        local frameHeight = scrollFrame:GetHeight()
        sidebarScrollbarVisible = scrollbar:UpdateVisibility(contentHeight, frameHeight)
        UpdateSidebarScrollChildWidth()
    end
    sidebar.UpdateScrollBarVisibility = UpdateSidebarScrollBarVisibility
    scrollChild:HookScript("OnSizeChanged", UpdateSidebarScrollBarVisibility)
    scrollFrame:HookScript("OnSizeChanged", UpdateSidebarScrollBarVisibility)
    scrollFrame:HookScript("OnShow", function() C_Timer.After(0, UpdateSidebarScrollBarVisibility) end)
    sidebar:SetScript("OnSizeChanged", function() UpdateSidebarScrollChildWidth() end)
    scrollChild:SetWidth(Theme.sidebarWidth - Theme.borderSize)
    sidebar.scrollFrame = scrollFrame
    sidebar.scrollChild = scrollChild
    parent.sidebar = sidebar
    self.sidebar = sidebar
    return sidebar
end

function GUIFrame:FlashWidget(widget)
    if not widget then return end

    local flashOverlay = widget._searchFlashOverlay
    if not flashOverlay then
        flashOverlay = CreateFrame("Frame", nil, widget)
        flashOverlay:SetAllPoints()
        flashOverlay:SetFrameLevel(widget:GetFrameLevel() + 10)
        local tex = flashOverlay:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.3)
        flashOverlay.tex = tex
        widget._searchFlashOverlay = flashOverlay
    end

    flashOverlay:Show()
    flashOverlay:SetAlpha(1)

    local fadeOut = flashOverlay:CreateAnimationGroup()
    local fade = fadeOut:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(1.5)
    fade:SetSmoothing("OUT")
    fadeOut:SetScript("OnFinished", function() flashOverlay:Hide() end)
    fadeOut:Play()
end

function GUIFrame:ScrollToWidget(widget)
    if not widget or not self.contentArea or not self.contentArea.scrollFrame then return end

    local scrollFrame = self.contentArea.scrollFrame
    local scrollChild = self.contentArea.scrollChild
    if not scrollChild then return end

    C_Timer.After(0.05, function()
        local widgetTop = widget:GetTop()
        local scrollChildTop = scrollChild:GetTop()
        local scrollFrameHeight = scrollFrame:GetHeight()

        if not widgetTop or not scrollChildTop then return end

        local relativeY = scrollChildTop - widgetTop
        local maxScroll = scrollChild:GetHeight() - scrollFrameHeight
        local targetScroll = math.max(0, math.min(relativeY - 50, maxScroll))

        scrollFrame:SetVerticalScroll(targetScroll)
        self:FlashWidget(widget)
    end)
end

---@param itemId string
---@param searchResult table?
function GUIFrame:SelectSidebarItem(itemId, searchResult)
    local widgetToHighlight = nil

    if searchResult then
        self.sidebarExpanded[searchResult.sectionId] = true
        if searchResult.isWidget and searchResult.widget then widgetToHighlight = searchResult.widget end
    end

    self.selectedSidebarItem = itemId
    for _, item in ipairs(self.staticSidebarItemPool) do
        if item.inUse then
            if item.disabled then
                item.accentBar:Hide()
                item.selectedBg:Hide()
            elseif item.id == itemId then
                item.accentBar:Show()
                item.selectedBg:Show()
                item.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            else
                item.accentBar:Hide()
                item.selectedBg:Hide()
                item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
            end
        end
    end
    self:RefreshContent()

    -- Delay to let layout finish so widget has valid position data
    if widgetToHighlight then C_Timer.After(0.1, function() self:ScrollToWidget(widgetToHighlight) end) end
end

GUIFrame.sidebarExpanded = GUIFrame.sidebarExpanded or {}
GUIFrame.sidebarRefreshPending = false
GUIFrame.SIDEBAR_THROTTLE = 0.05

function GUIFrame:RefreshSidebar()
    if self.sidebarRefreshPending then return end
    self.sidebarRefreshPending = true
    C_Timer.After(self.SIDEBAR_THROTTLE, function()
        self.sidebarRefreshPending = false
        self:RefreshSidebarImmediate()
    end)
end

function GUIFrame:IsItemParentExpanded(itemId)
    if not itemId then return false end
    local config = self.SidebarConfig[self.selectedTab]
    if not config then return false end
    for _, section in ipairs(config) do
        if section.type == "header" and section.items then
            for _, item in ipairs(section.items) do
                if item.id == itemId then
                    return self.sidebarExpanded[section.id] == true
                end
            end
        end
    end
    return false
end

function GUIFrame:EnsureParentSectionExpanded(itemId)
    if not itemId then return end
    local config = self.SidebarConfig[self.selectedTab]
    if not config then return end
    for _, section in ipairs(config) do
        if section.type == "header" and section.items then
            for _, item in ipairs(section.items) do
                if item.id == itemId then
                    self.sidebarExpanded[section.id] = true
                    return
                end
            end
        end
    end
end

function GUIFrame:RefreshSidebarImmediate()
    if not self.sidebar then return end
    self:ReleaseStaticSidebarItems()
    self:ReleaseSectionHeaders()
    local scrollChild = self.sidebar.scrollChild
    local scrollFrame = self.sidebar.scrollFrame
    for _, region in ipairs({ scrollChild:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            region:Hide()
            region:SetText("")
        end
    end

    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.sidebar, "BOTTOMRIGHT", -Theme.borderSize, Theme.paddingSmall)

    local yOffset = Theme.paddingSmall
    local itemSpacing = 1
    local horizontalPadding = Theme.paddingSmall

    if self.sidebarEmptyText then self.sidebarEmptyText:Hide() end

    if self.searchText and self.searchText ~= "" then
        local results = self.searchResults
        if #results == 0 then
            if not self.sidebarEmptyText then
                self.sidebarEmptyText = scrollChild:CreateFontString(nil, "OVERLAY")
                NRSKNUI:ApplyThemeFont(self.sidebarEmptyText, "normal")
                self.sidebarEmptyText:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary
                    [3], 0.6)
            end
            self.sidebarEmptyText:SetText("No results found")
            self.sidebarEmptyText:SetPoint("TOP", scrollChild, "TOP", 0, -yOffset - 10)
            self.sidebarEmptyText:Show()
            scrollChild:SetHeight(yOffset + 40)
            return
        end

        for _, result in ipairs(results) do
            local item = self:GetStaticSidebarItem()
            item:SetParent(scrollChild)
            item:SetFrameLevel(scrollChild:GetFrameLevel() + 2)
            item:SetHeight(itemHeight)
            item:SetAlpha(1)
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", horizontalPadding, -yOffset)
            item:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -horizontalPadding, -yOffset)
            item.id = result.id
            item.searchResult = result
            item.label:Show()
            item.label:SetAlpha(1)
            NRSKNUI:ApplyThemeFont(item.label, "normal")
            local displayText
            if result.isWidget then
                displayText = "|cFFAAAAAA»|r " .. result.text
            else
                displayText = result.text .. " |cFF888888(" .. result.sectionText .. ")|r"
            end
            item.label:SetText(displayText)

            local itemDisabled = result.elvUIDisabled and NRSKNUI:ShouldNotLoadModule()
            if itemDisabled then
                item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
                item.accentBar:Hide()
                item.selectedBg:Hide()
                item:EnableMouse(false)
                item.disabled = true
            else
                item.disabled = false
                item:EnableMouse(true)
                if result.id == self.selectedSidebarItem then
                    item.accentBar:Show()
                    item.selectedBg:Show()
                    item.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                else
                    item.accentBar:Hide()
                    item.selectedBg:Hide()
                    item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
                end
            end
            yOffset = yOffset + itemHeight + itemSpacing
        end
        scrollChild:SetHeight(yOffset + Theme.paddingSmall)
        return
    end

    local config = self.SidebarConfig[self.selectedTab]
    if not config then
        scrollChild:SetHeight(1)
        return
    end

    local sectionSpacing = 4
    local itemIndent = 0

    for _, sectionConfig in ipairs(config) do
        if sectionConfig.type == "header" then
            local isExpanded = self.sidebarExpanded[sectionConfig.id]
            local header = self:GetSectionHeader()
            self:ConfigureSectionHeader(header, sectionConfig, yOffset, isExpanded)
            yOffset = yOffset + headerHeight
            if isExpanded and sectionConfig.items then
                local sectionDisabled = sectionConfig.elvUIDisabled and NRSKNUI:ShouldNotLoadModule()
                for _, itemConfig in ipairs(sectionConfig.items) do
                    local item = self:GetStaticSidebarItem()
                    item:SetParent(scrollChild)
                    item:SetFrameLevel(scrollChild:GetFrameLevel() + 2)
                    item:SetHeight(itemHeight)
                    item:SetAlpha(1)
                    item:ClearAllPoints()
                    item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", horizontalPadding + itemIndent, -yOffset)
                    item:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -horizontalPadding, -yOffset)
                    item.id = itemConfig.id
                    item.label:Show()
                    item.label:SetAlpha(1)
                    NRSKNUI:ApplyThemeFont(item.label, "normal")
                    item.label:SetText(itemConfig.text or "")

                    local itemDisabled = sectionDisabled or (itemConfig.elvUIDisabled and NRSKNUI:ShouldNotLoadModule())
                    if itemDisabled then
                        item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3],
                            0.35)
                        item.accentBar:Hide()
                        item.selectedBg:Hide()
                        item:EnableMouse(false)
                        item.disabled = true
                    else
                        item.disabled = false
                        item:EnableMouse(true)
                        if itemConfig.id == self.selectedSidebarItem then
                            item.accentBar:Show()
                            item.selectedBg:Show()
                            item.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                        else
                            item.accentBar:Hide()
                            item.selectedBg:Hide()
                            item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2],
                                Theme.textSecondary[3], 1)
                        end
                    end
                    yOffset = yOffset + itemHeight + itemSpacing
                end
            end
            yOffset = yOffset + sectionSpacing
        end
    end
    scrollChild:SetHeight(yOffset + Theme.paddingSmall)
end

function GUIFrame:OpenPage(itemId, sectionId, context)
    self:Show()
    if sectionId then
        self.sidebarExpanded[sectionId] = true
        self:RefreshSidebar()
    end
    self.pendingContext = context
    self:SelectSidebarItem(itemId)
end
