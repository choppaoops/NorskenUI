-- NorskenUI namespace
---@diagnostic disable: undefined-field
---@class NRSKNUI
local NRSKNUI = select(2, ...)
NRSKNUI.GUIFrame = NRSKNUI.GUIFrame or {}
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local addonVersion = NRSKNUI.Version

NRSKNUI.GUIOpen = false

local pcall = pcall
local select = select
local ShowUIPanel = ShowUIPanel
local table_insert = table.insert
local IsMouseButtonDown = IsMouseButtonDown
local tostring = tostring
local CreateFrame = CreateFrame
local pairs = pairs
local ipairs = ipairs
local ReloadUI = ReloadUI
local CreateColor = CreateColor
local InCombatLockdown = InCombatLockdown
local _G = _G
local C_AddOns = C_AddOns

GUIFrame.selectedTab = "systems"
GUIFrame.selectedSidebarItem = nil
GUIFrame.sidebarExpanded = GUIFrame.sidebarExpanded or {}

local function RefreshAllFontStrings(frame)
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text then
                region:SetText("")
                region:SetText(text)
            end
        end
    end

    for i = 1, frame:GetNumChildren() do
        local child = select(i, frame:GetChildren())
        if child then
            RefreshAllFontStrings(child)
        end
    end
end

function GUIFrame:CreateMainFrame()
    if self.mainFrame then
        return self.mainFrame
    end

    local frame = CreateFrame("Frame", "NorskenUIGUIFrame", UIParent, "BackdropTemplate")
    frame:SetSize(950, 700)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(950, 700)
    frame:EnableMouse(true)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = Theme.borderSize,
    })
    frame:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], Theme.bgDark[4])
    frame:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    NRSKNUI.GUIOverlay = CreateFrame("Frame", nil, UIParent)
    NRSKNUI.GUIOverlay:SetAllPoints(UIParent)
    NRSKNUI.GUIOverlay:SetFrameStrata("TOOLTIP")
    NRSKNUI.GUIOverlay:SetFrameLevel(1)
    NRSKNUI.GUIOverlay:EnableMouse(false)

    self:CreateHeader(frame)
    self:CreateFooter(frame)
    self:CreateContentArea(frame)
    self:CreateSidebar(frame)
    self:CreateShortcutFrame(frame)

    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints(frame)
    borderFrame:SetFrameStrata("TOOLTIP")
    borderFrame:SetFrameLevel(frame:GetFrameLevel() + 100)

    local borderTop = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    borderTop:SetHeight(Theme.borderSize)
    borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borderTop:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local borderBottom = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    borderBottom:SetHeight(Theme.borderSize)
    borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local borderLeft = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    borderLeft:SetWidth(Theme.borderSize)
    borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borderLeft:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    local borderRight = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    borderRight:SetWidth(Theme.borderSize)
    borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borderRight:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            GUIFrame:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    frame:EnableKeyboard(true)

    frame:SetToplevel(true)

    frame:SetScript("OnHide", function()
        if NRSKNUI.GUIOpen then
            GUIFrame:SaveFramePosition()
            GUIFrame:SaveSessionState()
            if GUIFrame.contentCleanupCallbacks then
                for _, callback in pairs(GUIFrame.contentCleanupCallbacks) do
                    pcall(callback)
                end
            end
            GUIFrame:FireOnCloseCallbacks()
            NRSKNUI.GUIOpen = false
            if NRSKNUI.PreviewManager then
                NRSKNUI.PreviewManager:SetGUIOpen(false)
            end
        end
    end)
    frame:Hide()

    self.mainFrame = frame
    return frame
end

function GUIFrame:ApplyThemeColors()
    if not self.mainFrame then return end
    local frame = self.mainFrame
    local selBg = Theme.selectedBg or Theme.accent
    local selText = Theme.selectedText or Theme.accent

    frame:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], Theme.bgDark[4])
    frame:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    if frame.header then
        frame.header:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
        if frame.header.logoN then
            frame.header.logoN:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
        end
        if frame.header.logoUI then
            frame.header.logoUI:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3],
                1)
        end
    end

    if self.sidebar then
        self.sidebar:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
        if self.sidebar.scrollbar and self.sidebar.scrollbar.ApplyThemeColors then
            self.sidebar.scrollbar:ApplyThemeColors()
        end
    end

    if self.sidebarHeaderPool then
        local r, g, b = Theme.accent[1], Theme.accent[2], Theme.accent[3]
        for _, header in ipairs(self.sidebarHeaderPool) do
            if header.inUse then
                if header.disabled then
                    if header.label then
                        header.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3],
                            0.35)
                    end
                    if header.arrow then
                        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2],
                            Theme.textSecondary[3], 0.35)
                    end
                else
                    if header.label then
                        header.label:SetTextColor(r, g, b, 1)
                    end
                    if header.arrow then
                        header.arrow:SetVertexColor(r, g, b, 1)
                    end
                end
                if header.background then
                    header.background:SetGradient("HORIZONTAL", CreateColor(0.3, 0.3, 0.3, 0.25),
                        CreateColor(0.3, 0.3, 0.3, 0))
                end
                if header.selectedOverlay then
                    header.selectedOverlay:SetVertexColor(selBg[1], selBg[2], selBg[3], selBg[4] or 0.25)
                end
                if header.selectedBar then
                    header.selectedBar:SetColorTexture(r, g, b, 1)
                end
            end
        end
    end

    if self.staticSidebarItemPool then
        local r, g, b = Theme.accent[1], Theme.accent[2], Theme.accent[3]
        for _, item in ipairs(self.staticSidebarItemPool) do
            if item.selectedOverlay then
                item.selectedOverlay:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.25), CreateColor(r, g, b, 0))
            end
            if item.background then
                item.background:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.25), CreateColor(r, g, b, 0))
            end
            if item.selectedBar then
                item.selectedBar:SetColorTexture(selText[1], selText[2], selText[3], selText[4] or 1)
            end
            if item.inUse then
                if item.disabled then
                    item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
                elseif item.id == self.selectedSidebarItem then
                    item.label:SetTextColor(selText[1], selText[2], selText[3], selText[4] or 1)
                else
                    item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
                end
            end
        end
    end

    if frame.content then
        frame.content:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], Theme.bgDark[4])
        if frame.content.scrollbar and frame.content.scrollbar.ApplyThemeColors then
            frame.content.scrollbar:ApplyThemeColors()
        end
    end

    if frame.footer then
        frame.footer:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])
        if frame.footer.logoTwitchTexture then
            frame.footer.logoTwitchTexture:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
        end
        if frame.footer.logoTwitchText then
            frame.footer.logoTwitchText:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2],
                Theme.textSecondary[3], 0.7)
        end
        if frame.footer.logoDiscordTexture then
            frame.footer.logoDiscordTexture:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
        end
        if frame.footer.logoDiscordText then
            frame.footer.logoDiscordText:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2],
                Theme.textSecondary[3], 0.7)
        end
    end

    if self.shortcutContent then
        self.shortcutContent:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], 1)
        self.shortcutContent:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    end
    if self.shortcutBtn then
        local tex = self.shortcutBtn:GetNormalTexture()
        if tex then
            tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        end
    end
    if self.shortcutItemButtons then
        for _, btn in ipairs(self.shortcutItemButtons) do
            for i = 1, btn:GetNumRegions() do
                local region = select(i, btn:GetRegions())
                if region and region:GetObjectType() == "FontString" then
                    region:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                    break
                end
            end
        end
    end
    if self.shortcutScrollbarThumb then
        self.shortcutScrollbarThumb:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.8)
    end
    if self.shortcutScrollbarBorder then
        self.shortcutScrollbarBorder:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    end
end

function GUIFrame:CreateShortcutFrame(parent)
    local ITEM_HEIGHT = 24
    local MAX_DROPDOWN_HEIGHT = 400
    local ANIMATION_DURATION = 0.18

    local shortcutBtn = CreateFrame("Button", nil, parent)
    shortcutBtn:SetSize(18, 22)
    shortcutBtn:SetPoint("TOPLEFT", parent, "TOPRIGHT", -50, -6)
    shortcutBtn:SetFrameStrata("TOOLTIP")

    local shortcutBtnTex = shortcutBtn:CreateTexture(nil, "ARTWORK")
    shortcutBtnTex:SetAllPoints()
    shortcutBtnTex:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\NorskenCustomBurger.png")
    shortcutBtnTex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    shortcutBtn:SetNormalTexture(shortcutBtnTex)
    shortcutBtnTex:SetTexelSnappingBias(0)
    shortcutBtnTex:SetSnapToPixelGrid(true)

    local dropdownList = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdownList:SetHeight(1)
    dropdownList:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dropdownList:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], 1)
    dropdownList:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
    dropdownList:SetFrameStrata("TOOLTIP")
    dropdownList:SetClipsChildren(true)
    dropdownList:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, dropdownList)
    scrollFrame:SetPoint("TOPLEFT", dropdownList, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", dropdownList, "BOTTOMRIGHT", -12, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)

    local scrollbar = NRSKNUI.GUI.CreateScrollbar(scrollFrame, {
        anchorToScrollFrame = false,
    })
    scrollbar:SetParent(dropdownList)
    scrollbar:ClearAllPoints()
    scrollbar:SetPoint("TOPRIGHT", dropdownList, "TOPRIGHT", 0, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", dropdownList, "BOTTOMRIGHT", 0, 0)

    local scrollHold = false
    scrollbar:HookScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            scrollHold = true
        end
    end)
    scrollbar:HookScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            C_Timer.After(0.1, function()
                scrollHold = false
            end)
        end
    end)

    local isOpen = false
    local itemButtons = {}
    local startHeight = 0
    local targetHeight = 0
    local btnTextR, btnTextG, btnTextB = Theme.accent[1], Theme.accent[2], Theme.accent[3]

    local mouseChecker = CreateFrame("Frame", nil, UIParent)
    mouseChecker:Hide()

    local animGroup = dropdownList:CreateAnimationGroup()
    animGroup:CreateAnimation("Animation"):SetDuration(ANIMATION_DURATION)

    local hoverAnimGroup = shortcutBtn:CreateAnimationGroup()
    local hoverAnim = hoverAnimGroup:CreateAnimation("Animation")
    hoverAnim:SetDuration(0.15)

    local borderColorFrom = {}
    local borderColorTo = {}

    hoverAnimGroup:SetScript("OnUpdate", function(self)
        local progress = self:GetProgress() or 0
        local r = borderColorFrom.btnTextR + (borderColorTo.btnTextR - borderColorFrom.btnTextR) * progress
        local g = borderColorFrom.btnTextG + (borderColorTo.btnTextG - borderColorFrom.btnTextG) * progress
        local b = borderColorFrom.btnTextB + (borderColorTo.btnTextB - borderColorFrom.btnTextB) * progress

        shortcutBtnTex:SetVertexColor(r, g, b, 1)
        btnTextR, btnTextG, btnTextB = r, g, b
    end)

    hoverAnimGroup:SetScript("OnFinished", function()
        shortcutBtnTex:SetVertexColor(borderColorTo.btnTextR, borderColorTo.btnTextG, borderColorTo.btnTextB, 1)
        btnTextR, btnTextG, btnTextB = borderColorTo.btnTextR, borderColorTo.btnTextG, borderColorTo.btnTextB
    end)

    local function AnimateBorderColor(toAccent)
        hoverAnimGroup:Stop()

        btnTextR, btnTextG, btnTextB = shortcutBtnTex:GetVertexColor()
        borderColorFrom.btnTextR = btnTextR
        borderColorFrom.btnTextG = btnTextG
        borderColorFrom.btnTextB = btnTextB

        if toAccent then
            borderColorTo.btnTextR = Theme.accent[1]
            borderColorTo.btnTextG = Theme.accent[2]
            borderColorTo.btnTextB = Theme.accent[3]
        else
            borderColorTo.btnTextR = Theme.textSecondary[1]
            borderColorTo.btnTextG = Theme.textSecondary[2]
            borderColorTo.btnTextB = Theme.textSecondary[3]
        end

        hoverAnimGroup:Play()
    end

    local function CloseDropdown(instant)
        if scrollHold then return end
        if not isOpen then return end

        isOpen = false

        if instant then
            dropdownList:SetHeight(1)
            dropdownList:Hide()
            animGroup:Stop()
        else
            startHeight = dropdownList:GetHeight()
            targetHeight = 1
            animGroup:Stop()
            animGroup:Play()
        end

        mouseChecker:SetScript("OnUpdate", nil)
        mouseChecker:Hide()
    end

    local function UpdateScroll()
        local contentHeight = scrollChild:GetHeight()
        local scrollFrameHeight = scrollFrame:GetHeight()
        local needsScrollbar = scrollbar:UpdateVisibility(contentHeight, scrollFrameHeight)

        if needsScrollbar then
            scrollbar:SetValue(0)
            scrollFrame:SetPoint("BOTTOMRIGHT", dropdownList, "BOTTOMRIGHT", -12, 0)
        else
            scrollFrame:SetPoint("BOTTOMRIGHT", dropdownList, "BOTTOMRIGHT", 0, 0)
        end

        scrollChild:SetWidth(scrollFrame:GetWidth())

        for i, btn in ipairs(itemButtons) do
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ITEM_HEIGHT)
            btn:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        end
    end

    animGroup:SetScript("OnUpdate", function(self)
        local progress = self:GetProgress() or 0
        local smoothProgress = progress * progress * (3 - 2 * progress)
        local newHeight = startHeight + (targetHeight - startHeight) * smoothProgress
        dropdownList:SetHeight(newHeight)

        if isOpen and newHeight < targetHeight then
            dropdownList:SetClipsChildren(false)
        end
    end)

    animGroup:SetScript("OnFinished", function()
        dropdownList:SetHeight(targetHeight)

        if not isOpen then
            dropdownList:Hide()
        else
            dropdownList:SetClipsChildren(true)
        end
    end)

    local function CreateItemButtons()
        for _, btn in ipairs(itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        itemButtons     = {}
        local BCDMLogo  = "|TInterface\\AddOns\\NorskenUI\\Media\\AddonLogos\\Logo.png:16:16|t"
        local UUFLogo   = "|TInterface\\AddOns\\NorskenUI\\Media\\AddonLogos\\Logo:11:12|t"
        local MSLogo    = "|TInterface\\AddOns\\NorskenUI\\Media\\AddonLogos\\MinimapStats.png:16:16|t"

        local shortcuts = {
            { text = "Reload UI", onClick = function() ReloadUI() end },
            {
                text = "Edit Mode",
                onClick = function()
                    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
                        return
                    end
                    ShowUIPanel(EditModeManagerFrame)
                end
            },
            {
                text = "Cooldown Manager",
                onClick = function()
                    local frame = _G["CooldownViewerSettings"]
                    if frame then
                        frame:Show()
                        frame:Raise()
                    else
                        NRSKNUI:Print(
                            "CooldownViewerSettings not found. Make sure Cooldown Manager is enabled in Edit Mode.")
                    end
                end
            },
            {
                text = UUFLogo .. " " .. "|cFF8080FFUnhalted|r" .. "|cFFFFFFFFUnitFrames|r",
                onClick = function()
                    local addonName = "UnhaltedUnitFrames"
                    if not C_AddOns.IsAddOnLoaded(addonName) then
                        local loaded = C_AddOns.LoadAddOn(addonName)
                        if not loaded then
                            NRSKNUI:Print("UnhaltedUnitFrames is disabled/missing")
                            return
                        end
                    end
                    if SlashCmdList["UUF"] then
                        SlashCmdList["UUF"]("")
                    else
                        NRSKNUI:Print("UUF command not available.")
                    end
                end
            },
            {
                text = BCDMLogo .. " " .. "|cFF8080FFBetter|r" .. "|cFFFFFFFFCooldownManager|r",
                onClick = function()
                    local addonName = "BetterCooldownManager"
                    if not C_AddOns.IsAddOnLoaded(addonName) then
                        local loaded = C_AddOns.LoadAddOn(addonName)
                        if not loaded then
                            NRSKNUI:Print("BetterCooldownManager is disabled/missing")
                            return
                        end
                    end
                    if SlashCmdList["BCDM"] then
                        SlashCmdList["BCDM"]("")
                    else
                        NRSKNUI:Print("BCDM command not available.")
                    end
                end
            },
            {
                text = MSLogo .. " " .. "|cFF8080FFMinimap|r" .. "|cFFFFFFFFStats|r",
                onClick = function()
                    local addonName = "MinimapStats"
                    if not C_AddOns.IsAddOnLoaded(addonName) then
                        local loaded = C_AddOns.LoadAddOn(addonName)
                        if not loaded then
                            NRSKNUI:Print("MinimapStats is disabled/missing")
                            return
                        end
                    end
                    if SlashCmdList["MINIMAPSTATS"] then
                        SlashCmdList["MINIMAPSTATS"]("")
                    else
                        NRSKNUI:Print("MS command not available.")
                    end
                end
            },
        }

        for i, item in ipairs(shortcuts) do
            local btn = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            btn:SetHeight(ITEM_HEIGHT)
            btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ITEM_HEIGHT)
            btn:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

            local btnText = btn:CreateFontString(nil, "OVERLAY")
            btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
            btnText:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
            btnText:SetJustifyH("LEFT")
            NRSKNUI:ApplyThemeFont(btnText, "normal")
            btnText:SetText(item.text)
            btnText:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3])

            btn:SetScript("OnClick", function()
                item.onClick()
                CloseDropdown()
            end)

            btn:SetScript("OnEnter", function()
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                btn:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
                btn:SetBackdropColor(Theme.accentHover[1], Theme.accentHover[2], Theme.accentHover[3],
                    Theme.accentHover[4] or 0.25)
                btnText:SetTextColor(Theme.textPrimary[1], Theme.textPrimary[2], Theme.textPrimary[3], 1)
            end)

            btn:SetScript("OnLeave", function()
                btn:SetBackdrop(nil)
                btnText:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3])
            end)

            table_insert(itemButtons, btn)
        end

        scrollChild:SetHeight(#shortcuts * ITEM_HEIGHT)

        for _, btn in ipairs(itemButtons) do
            btn:Show()
        end
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        if scrollbar:IsShown() then
            local current = scrollbar:GetValue()
            local minVal, maxVal = scrollbar:GetMinMaxValues()
            local newValue = current - (delta * ITEM_HEIGHT)
            newValue = math.max(minVal, math.min(maxVal, newValue))
            scrollbar:SetValue(newValue)
        end
    end)

    local function ToggleDropdown()
        if isOpen then
            CloseDropdown()
        else
            dropdownList:ClearAllPoints()
            dropdownList:SetPoint("TOP", shortcutBtn, "BOTTOM", 132, 28)
            dropdownList:SetWidth(180)

            local contentHeight = #itemButtons * ITEM_HEIGHT
            local maxHeight = math.min(contentHeight, MAX_DROPDOWN_HEIGHT)

            startHeight = 1
            targetHeight = maxHeight

            dropdownList:SetHeight(targetHeight)
            scrollChild:SetWidth(scrollFrame:GetWidth())
            UpdateScroll()
            dropdownList:Show()
            dropdownList:SetHeight(startHeight)

            isOpen = true

            animGroup:Play()

            shortcutBtnTex:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)

            local wasMouseDown = false
            mouseChecker:SetScript("OnUpdate", function()
                local isDown = IsMouseButtonDown("LeftButton")
                if wasMouseDown and not isDown then
                    if not dropdownList:IsMouseOver() and not shortcutBtn:IsMouseOver() then
                        CloseDropdown()
                    end
                end
                wasMouseDown = isDown
            end)
            mouseChecker:Show()
        end
    end

    shortcutBtn:SetScript("OnEnter", function()
        AnimateBorderColor(true)
        if not isOpen then
            ToggleDropdown()
        end
    end)

    shortcutBtn:SetScript("OnLeave", function()
        AnimateBorderColor(false)
        C_Timer.After(0.1, function()
            if not dropdownList:IsMouseOver() and not shortcutBtn:IsMouseOver() then
                CloseDropdown()
            end
        end)
    end)

    dropdownList:SetScript("OnLeave", function()
        C_Timer.After(0.1, function()
            if not dropdownList:IsMouseOver() then
                CloseDropdown()
            end
        end)
    end)

    dropdownList:SetScript("OnHide", function()
        if isOpen then
            isOpen = false
        end
    end)

    shortcutBtn:SetScript("OnHide", function()
        CloseDropdown(true)
    end)

    dropdownList:Show()
    dropdownList:SetHeight(MAX_DROPDOWN_HEIGHT)
    CreateItemButtons()
    dropdownList:SetHeight(1)
    dropdownList:Hide()

    self.shortcutBtn = shortcutBtn
    self.shortcutContent = dropdownList
    self.shortcutItemButtons = itemButtons
    self.shortcutScrollbarThumb = scrollbar.thumb
    self.shortcutScrollbarBorder = scrollbar.thumbBorder

    return shortcutBtn
end

function GUIFrame:CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetHeight(Theme.headerHeight)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    header:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])

    local bottomBorder = header:CreateTexture(nil, "BORDER")
    bottomBorder:SetHeight(Theme.borderSize)
    bottomBorder:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])

    local logoContainer = CreateFrame("Frame", nil, header)
    logoContainer:SetSize(180, 32)
    logoContainer:SetPoint("LEFT", header, "LEFT", Theme.paddingLarge, -1)

    local logoN = logoContainer:CreateTexture(nil, "ARTWORK")
    logoN:SetSize(64, 64)
    logoN:SetPoint("LEFT", logoContainer, "LEFT", -10, 1)
    logoN:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\Logo\\logocookingsPT1128x128OT.png")
    logoN:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
    logoN:SetTexelSnappingBias(0)
    logoN:SetSnapToPixelGrid(false)

    local logoUI = logoContainer:CreateTexture(nil, "ARTWORK")
    logoUI:SetSize(128, 128)
    logoUI:SetPoint("LEFT", logoN, "RIGHT", -62, -4)
    logoUI:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\Logo\\logocookingsPT3128x128OT.png")
    logoUI:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    logoUI:SetTexelSnappingBias(0)
    logoUI:SetSnapToPixelGrid(false)

    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = Theme.fontSizeSmall or 10
    local currentVersionText = header:CreateFontString(nil, "OVERLAY")
    currentVersionText:SetPoint("LEFT", logoUI, "RIGHT", -45, -3)
    currentVersionText:SetFont(fontPath, fontSize, "")
    currentVersionText:SetText(addonVersion)
    currentVersionText:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    currentVersionText:SetJustifyH("LEFT")
    currentVersionText:SetShadowColor(0, 0, 0, 0)
    NRSKNUI:CreateSoftOutline(currentVersionText, {
        thickness = 1,
        color = { 0, 0, 0 },
        alpha = 0.9,
    })

    header.logoN = logoN
    header.logoUI = logoUI

    local function CreateHeaderButton(config)
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(config.size, config.size)
        btn:SetPoint("RIGHT", header, "RIGHT", config.xOffset, config.yOffset or 0)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(config.texture)
        tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        btn:SetNormalTexture(tex)
        if config.rotation then
            tex:SetRotation(math.rad(config.rotation))
        end
        tex:SetTexelSnappingBias(0)
        tex:SetSnapToPixelGrid(true)

        btn:SetScript("OnEnter", function()
            tex:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], Theme.accent[4])
        end)
        btn:SetScript("OnLeave", function()
            tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        end)
        btn:SetScript("OnClick", config.onClick)
        return btn
    end

    CreateHeaderButton({
        size = 22,
        xOffset = -6,
        texture = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\NorskenCustomCrossv3.png",
        rotation = 45,
        onClick = function() GUIFrame:Hide() end,
    })

    CreateHeaderButton({
        size = 18,
        xOffset = -81,
        texture = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\fill.png",
        onClick = function() GUIFrame:OpenPage("ThemePage") end,
    })

    CreateHeaderButton({
        size = 18,
        xOffset = -56,
        texture = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\HomeButtonv2.png",
        onClick = function() GUIFrame:OpenPage("HomePage") end,
    })

    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        parent:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        NRSKNUI:SnapFrameToPixels(parent)
        GUIFrame:SaveFramePosition()
    end)

    parent.header = header
    return header
end

function GUIFrame:CreateContentArea(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(Theme.contentWidth)
    container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -Theme.headerHeight)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, Theme.footerHeight)

    local area = NRSKNUI.GUI.CreateBasicContentArea(container, {
        contentWidth = Theme.contentWidth,
        noScrollbarOffset = 1,
        scrollbarOptions = {
            width = 16,
            thumbHeight = 40,
            padding = { top = -1, bottom = -1, right = 0 },
            scrollStep = 40,
        },
    })

    local content = area.frame
    content.scrollFrame = area.scrollFrame
    content.scrollChild = area.scrollChild
    content.scrollbar = area.scrollbar

    local baseUpdateVisibility = area.UpdateScrollBarVisibility
    content.UpdateScrollBarVisibility = function()
        if content._customPanel then
            area.scrollbar:Hide()
            return
        end
        baseUpdateVisibility()
    end

    local lastValue = 0
    area.scrollbar.onValueChanged = function(_, value)
        if math.abs(value - lastValue) > 0.1 then
            C_Timer.After(0, function()
                RefreshAllFontStrings(area.scrollChild)
            end)
            lastValue = value
        end
    end

    parent.content = content
    self.contentArea = content
    return content
end

local function CreateSocialButton(parent, config)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(config.width, 21)
    btn:SetPoint(config.point, config.anchor, config.relativePoint, config.offsetX or 0, config.offsetY or 0)

    local texture = btn:CreateTexture(nil, "ARTWORK")
    texture:SetSize(21, 21)
    texture:SetPoint("LEFT", btn, "LEFT", 0, 0)
    texture:SetTexture(config.texturePath)
    texture:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
    texture:SetTexelSnappingBias(0)
    texture:SetSnapToPixelGrid(false)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", texture, "RIGHT", Theme.paddingSmall, 1)
    if NRSKNUI.ApplyThemeFont then
        NRSKNUI:ApplyThemeFont(text, "normal")
    else
        text:SetFontObject("GameFontNormal")
    end
    text:SetText(config.text)
    text:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    text:SetShadowColor(0, 0, 0, 0)

    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnClick", function()
        NRSKNUI:CreatePrompt(
            config.promptTitle,
            config.link,
            true,
            "Copy to clipboard by pressing CTRL + C",
            true,
            config.texturePath,
            21, 21,
            { r = Theme.accent[1], g = Theme.accent[2], b = Theme.accent[3] }
        )
    end)

    btn:SetScript("OnEnter", function()
        texture:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        text:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    end)
    btn:SetScript("OnLeave", function()
        texture:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.7)
        text:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    end)

    return btn, texture, text
end

function GUIFrame:CreateFooter(parent)
    local footer = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    footer:SetHeight(Theme.footerHeight)
    footer:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    footer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    footer:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])

    local topBorder = footer:CreateTexture(nil, "BORDER")
    topBorder:SetHeight(Theme.borderSize)
    topBorder:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, 0)
    topBorder:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])

    local supportLogoContainer = CreateFrame("Frame", nil, footer)
    supportLogoContainer:SetSize(180, 32)
    supportLogoContainer:SetPoint("LEFT", footer, "LEFT", 0, 0)

    local logoTwitch, logoTwitchTexture, logoTwitchText = CreateSocialButton(supportLogoContainer, {
        text = "Twitch",
        width = 62,
        texturePath = "Interface\\AddOns\\NorskenUI\\Media\\SupportLogos\\twitchv2W.png",
        promptTitle = "Support My |cff9146FFTwitch|r",
        link = "www.twitch.tv/norskenwow",
        point = "LEFT",
        anchor = supportLogoContainer,
        relativePoint = "LEFT",
        offsetX = Theme.paddingMedium,
    })
    footer.logoTwitchTexture = logoTwitchTexture
    footer.logoTwitchText = logoTwitchText

    local logoDiscord, logoDiscordTexture, logoDiscordText = CreateSocialButton(supportLogoContainer, {
        text = "Discord",
        width = 68,
        texturePath = "Interface\\AddOns\\NorskenUI\\Media\\SupportLogos\\discordv2W.png",
        promptTitle = "Join My |cff5865F2Discord|r",
        link = "https://discord.com/invite/23bS8pHfuX",
        point = "LEFT",
        anchor = logoTwitch,
        relativePoint = "RIGHT",
        offsetX = Theme.paddingMedium,
    })
    footer.logoDiscordTexture = logoDiscordTexture
    footer.logoDiscordText = logoDiscordText

    local logoGitHub, logoGitHubTexture, logoGitHubText = CreateSocialButton(supportLogoContainer, {
        text = "GitHub",
        width = 68,
        texturePath = "Interface\\AddOns\\NorskenUI\\Media\\SupportLogos\\github2W.png",
        promptTitle = "Support My |cffffffffGitHub|r",
        link = "https://github.com/Nrsken/NorskenUI",
        point = "LEFT",
        anchor = logoDiscord,
        relativePoint = "RIGHT",
        offsetX = Theme.paddingMedium,
    })
    footer.logoGitHubTexture = logoGitHubTexture
    footer.logoGitHubText = logoGitHubText

    local handle = CreateFrame("Button", nil, footer)
    handle:SetSize(23, 23)
    handle:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", -2, 2)
    handle:EnableMouse(true)

    local tex = handle:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\NorskenCustomResizeHandle23px.png")
    tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
    tex:SetTexelSnappingBias(0)
    tex:SetSnapToPixelGrid(false)

    handle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            tex:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            parent:StartSizing("BOTTOMRIGHT")
        end
    end)
    handle:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
            parent:StopMovingOrSizing()
            if GUIFrame.contentArea and GUIFrame.contentArea.UpdateScrollBarVisibility then
                C_Timer.After(0.05, GUIFrame.contentArea.UpdateScrollBarVisibility)
            end
            if GUIFrame.sidebar and GUIFrame.sidebar.UpdateScrollBarVisibility then
                C_Timer.After(0.05, GUIFrame.sidebar.UpdateScrollBarVisibility)
            end
            NRSKNUI:SnapFrame(parent)
            GUIFrame:SaveFramePosition()
        end
    end)

    handle:SetScript("OnEnter", function()
        tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    end)
    handle:SetScript("OnLeave", function()
        tex:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.6)
    end)

    footer:EnableMouse(true)
    footer:RegisterForDrag("LeftButton")
    footer:SetScript("OnDragStart", function()
        parent:StartMoving()
    end)
    footer:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        NRSKNUI:SnapFrameToPixels(parent)
        GUIFrame:SaveFramePosition()
    end)

    parent.footer = footer
    self.footer = footer
    return footer
end

function GUIFrame:RefreshContent()
    if not self.contentArea then return end

    if self.contentArea._customPanel then
        self.contentArea._customPanel:Hide()
        self.contentArea._customPanel:SetParent(nil)
        self.contentArea._customPanel = nil
    end

    local itemId = self.selectedSidebarItem
    if not itemId then
        itemId = "HomePage"
    end

    if itemId and self.PanelBuilders and self.PanelBuilders[itemId] then
        if self.contentArea.scrollFrame then
            self.contentArea.scrollFrame:Hide()
        end
        if self.contentArea.scrollbar then
            self.contentArea.scrollbar:Hide()
        end

        local ok, panel = pcall(self.PanelBuilders[itemId], self.contentArea)
        if ok and panel then
            self.contentArea._customPanel = panel
        elseif not ok then
            if self.contentArea.scrollFrame then
                self.contentArea.scrollFrame:Show()
            end
            if self.contentArea.scrollbar then
                self.contentArea.scrollbar:Show()
            end
            local scrollChild = self.contentArea.scrollChild
            local errorCard = self:CreateCard(scrollChild, "Error", Theme.paddingMedium)
            local errorMsg = errorCard:AddLabel("Panel builder failed: " .. tostring(panel))
            errorMsg:SetTextColor(Theme.error[1], Theme.error[2], Theme.error[3], 1)
            scrollChild:SetHeight(errorCard:GetContentHeight() + Theme.paddingLarge)
        end
        return
    end

    if self.contentArea.scrollFrame then
        self.contentArea.scrollFrame:Show()
    end
    if self.contentArea.UpdateScrollBarVisibility then
        self.contentArea.UpdateScrollBarVisibility()
    end

    local scrollChild = self.contentArea.scrollChild

    for _, region in ipairs({ scrollChild:GetRegions() }) do
        if region:GetObjectType() == "FontString" or region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end

    for _, child in ipairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = Theme.paddingSmall

    if itemId and self.ContentBuilders[itemId] then
        local ok, result = pcall(self.ContentBuilders[itemId], scrollChild, yOffset)
        if ok then
            if result then
                yOffset = result
            end
        else
            local errorCard = self:CreateCard(scrollChild, "Error", yOffset)
            local errorMsg = errorCard:AddLabel("Content builder failed: " .. tostring(result))
            errorMsg:SetTextColor(Theme.error[1], Theme.error[2], Theme.error[3], 1)
            errorCard:AddSpacing(Theme.paddingSmall)
            yOffset = errorCard:GetNextOffset()
        end
    else
        local card = self:CreateCard(scrollChild, "Coming Soon", yOffset)
        card:AddLabel("This section is under construction.")
        card:AddSpacing(Theme.paddingSmall)
        yOffset = card:GetNextOffset()
    end

    scrollChild:SetHeight(yOffset)
    if self.contentArea.UpdateScrollbar then
        self.contentArea.UpdateScrollbar()
    end
end

function GUIFrame:Show()
    if self._isShowing then return end
    self._isShowing = true

    if InCombatLockdown() then
        NRSKNUI:Print("Options will open after combat ends.")
        self.reopenAfterCombat = true
        self._isShowing = false
        return
    end

    local isFirstCreate = not self.mainFrame
    if isFirstCreate then
        self:CreateMainFrame()
        GUIFrame:InitializeSidebarExpansion()
    end

    self:RestoreFramePosition()
    self.mainFrame:Show()
    self.mainFrame:Raise()
    NRSKNUI.GUIOpen = true

    if NRSKNUI.PreviewManager then
        NRSKNUI.PreviewManager:SetGUIOpen(true)
    end

    self:RefreshSidebar()

    if self.shortcutBtn then
        self.shortcutBtn:Show()
    end

    self._isShowing = false

    C_Timer.After(0, function()
        if self.mainFrame and self.mainFrame:IsShown() then
            if self.sidebar then
                local sidebarWidth = self.sidebar:GetWidth()
                if sidebarWidth and sidebarWidth > 0 and self.sidebar.scrollChild then
                    local newWidth = sidebarWidth - Theme.paddingSmall * 2 - 16
                    self.sidebar.scrollChild:SetWidth(newWidth)
                end
            end
            self:RefreshSidebar()
            self:RefreshContent()
            if self.contentArea and self.contentArea.scrollChild then
                RefreshAllFontStrings(self.contentArea.scrollChild)
            end
        end
    end)
end

function GUIFrame:Hide()
    if self.mainFrame then
        if self.shortcutBtn then
            self.shortcutBtn:Hide()
        end
        self.mainFrame:Hide()
    else
        NRSKNUI.GUIOpen = false
        if NRSKNUI.PreviewManager then
            NRSKNUI.PreviewManager:SetGUIOpen(false)
        end
    end
end

function GUIFrame:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function GUIFrame:IsShown()
    return self.mainFrame and self.mainFrame:IsShown()
end

GUIFrame.sessionState = GUIFrame.sessionState or {
    scrollPositions = {},
    selectedTab = "systems",
    selectedSidebarItem = nil,
}

function GUIFrame:SaveSessionState()
    if not self.mainFrame then return end

    if self.sidebar and self.sidebar.scrollFrame and self.selectedTab then
        local scrollValue = self.sidebar.scrollFrame:GetVerticalScroll()
        self.sessionState.scrollPositions[self.selectedTab] = scrollValue
    end

    self.sessionState.selectedTab = self.selectedTab
    self.sessionState.selectedSidebarItem = self.selectedSidebarItem
end

function GUIFrame:RestoreSessionState()
    if not self.sessionState then return end

    if self.sessionState.selectedTab then
        self.selectedTab = self.sessionState.selectedTab
    end

    if self.sessionState.selectedSidebarItem then
        self.selectedSidebarItem = self.sessionState.selectedSidebarItem
    end

    C_Timer.After(0.01, function()
        if self.sidebar and self.sidebar.scrollFrame and self.selectedTab then
            local scrollValue = self.sessionState.scrollPositions[self.selectedTab]
            if scrollValue then
                self.sidebar.scrollFrame:SetVerticalScroll(scrollValue)
            end
        end
    end)
end

function GUIFrame:SaveFramePosition()
    if not self.mainFrame then return end
    if not NRSKNUI.db or not NRSKNUI.db.global then return end

    local point, _, relPoint, x, y = self.mainFrame:GetPoint()

    NRSKNUI.db.global.GUIState = NRSKNUI.db.global.GUIState or {}
    NRSKNUI.db.global.GUIState.frame = {
        point = point,
        relativePoint = relPoint,
        xOffset = x,
        yOffset = y,
        width = self.mainFrame:GetWidth(),
        height = self.mainFrame:GetHeight(),
    }
    self:SaveSessionState()
end

function GUIFrame:RestoreFramePosition()
    if not self.mainFrame then return end

    local pos = NRSKNUI.db and NRSKNUI.db.global and NRSKNUI.db.global.GUIState and NRSKNUI.db.global.GUIState.frame
    if pos then
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.xOffset or 0,
            pos.yOffset or 50)
        if pos.width and pos.height then
            self.mainFrame:SetSize(pos.width, pos.height)
        end
    end

    self:RestoreSessionState()
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if GUIFrame:IsShown() then
            GUIFrame.reopenAfterCombat = true
            GUIFrame:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if GUIFrame.reopenAfterCombat then
            GUIFrame.reopenAfterCombat = nil
            GUIFrame:Show()
        end
    end
end)
