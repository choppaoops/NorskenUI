-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local Theme = NRSKNUI.Theme

-- Check for addon object
if not NorskenUI then
    error("Chat: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class Chat: AceModule, AceEvent-3.0
local CHAT = NorskenUI:NewModule("Chat", "AceEvent-3.0")

-- Localization
local next = next
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local hooksecurefunc = hooksecurefunc
local UIFrameFadeOut = UIFrameFadeOut
local UIFrameFadeIn = UIFrameFadeIn
local strsub = strsub
local pairs, ipairs = pairs, ipairs
local tContains = tContains
local CreateFrame = CreateFrame
local _G = _G
local C_Timer = C_Timer

-- Constants
local TAB_INACTIVE_ALPHA = 0.6
local TAB_ACTIVE_ALPHA = 1
local TAB_AREA_HEIGHT = 25
local DEFAULT_CHAT_FONT_SIZE = 12
local DEFAULT_EDITBOX_FONT_SIZE = 13
local DEFAULT_TAB_FONT_SIZE = 12

-- Tab color lookup table
local TAB_COLOR_DEFAULTS = {
    alert = { 1, 0, 0, 1 },
    active = { 1, 1, 1, 1 },
    whisper = { 1, 0.5, 0.8, 1 },
    inactive = { 0.898, 0.063, 0.224, 1 },
}

-- Helper to get tab colors
local function GetTabColor(colorType)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.Chat
    local tabColors = db and db.TabColors or {}

    if colorType == "inactive" then
        local colorMode = tabColors.InactiveColorMode or "custom"
        local customColor = tabColors.InactiveColor or TAB_COLOR_DEFAULTS.inactive
        if NRSKNUI.GetAccentColor then
            return NRSKNUI:GetAccentColor(colorMode, customColor)
        else
            return customColor[1], customColor[2], customColor[3], customColor[4] or 1
        end
    end

    local colorKey = colorType == "alert" and "AlertColor"
        or colorType == "active" and "ActiveColor"
        or colorType == "whisper" and "WhisperColor"
        or nil

    if colorKey then
        local c = tabColors[colorKey] or TAB_COLOR_DEFAULTS[colorType]
        return c[1], c[2], c[3], c[4] or 1
    end

    return 1, 1, 1, 1
end

-- Tab tracking
local chatTabAlerts = {}
local chatTabIndices = NRSKNUI:T()
local updateTabColor

-- Debounce tracking for DeferredReskin
local deferredReskinPending = false

-- Update db, used for profile changes
function CHAT:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Chat
end

-- Module init
function CHAT:OnInitialize()
    self:UpdateDB()
    self.backdrops = {}
    self:SetEnabledState(false)
end

-- Backdrop for editbox using BackdropTemplate with edge
local editBoxBackdropInfo = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Create backdrop for editbox
function CHAT:CreateEditBoxBackdrop(parent, alpha, xOffset, yOffset)
    local backdrop = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local parentLevel = parent:GetFrameLevel()
    backdrop:SetFrameLevel(math.max(0, parentLevel - 1))
    backdrop:SetPoint("TOPLEFT", xOffset or 0, -(yOffset or 0))
    backdrop:SetPoint("BOTTOMRIGHT", -(xOffset or 0), yOffset or 0)
    backdrop:SetBackdrop(editBoxBackdropInfo)
    backdrop:SetBackdropColor(0, 0, 0, alpha or 0.6)
    backdrop:SetBackdropBorderColor(0, 0, 0, alpha or 0.6)

    self.backdrops[parent] = backdrop
    return backdrop
end

-- Create main chat backdrop with pixel-perfect borders
function CHAT:CreateChatBackDrop()
    local db = self.db
    local bgColor = db.Backdrop and db.Backdrop.Color or { 0, 0, 0, 0.8 }
    local borderColor = db.Backdrop and db.Backdrop.BorderColor or { 0, 0, 0, 1 }
    local backdropEnabled = db.Backdrop and db.Backdrop.Enabled ~= false

    local backdrop = CreateFrame("Frame", "NRSKNUI_ChatBackdrop", UIParent, "BackdropTemplate")
    backdrop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    backdrop:SetFrameStrata("BACKGROUND")
    backdrop:SetFrameLevel(0)
    backdrop:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -2, TAB_AREA_HEIGHT)
    backdrop:SetPoint("BOTTOMRIGHT", ChatFrame1, "BOTTOMRIGHT", 10, -2)

    if backdropEnabled then
        backdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    else
        backdrop:SetBackdropColor(0, 0, 0, 0)
    end

    local borderFrame = CreateFrame("Frame", nil, backdrop)
    borderFrame:SetAllPoints(backdrop)
    borderFrame:SetFrameLevel(backdrop:GetFrameLevel() + 1)

    local borderAlpha = backdropEnabled and borderColor[4] or 0
    NRSKNUI:AddBorders(backdrop, { borderColor[1], borderColor[2], borderColor[3], borderAlpha }, borderFrame)

    self.backdrop = backdrop
end

-- Update backdrop colors from DB
function CHAT:UpdateBackdrop()
    if not self.backdrop then return end
    local db = self.db
    local bgColor = db.Backdrop and db.Backdrop.Color or { 0, 0, 0, 0.8 }
    local borderColor = db.Backdrop and db.Backdrop.BorderColor or { 0, 0, 0, 1 }
    local backdropEnabled = db.Backdrop and db.Backdrop.Enabled ~= false

    if backdropEnabled then
        self.backdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    else
        self.backdrop:SetBackdropColor(0, 0, 0, 0)
    end

    local borderAlpha = backdropEnabled and borderColor[4] or 0
    if self.backdrop.borders then
        self.backdrop:SetBorderColor(borderColor[1], borderColor[2], borderColor[3], borderAlpha)
    end
end

-- Update editbox backdrops from DB
function CHAT:UpdateEditBox()
    local editBoxDB = self.db.EditBox or {}
    local bgColor = editBoxDB.BackdropColor or { 0, 0, 0, 0.8 }
    local borderColor = editBoxDB.BorderColor or { 0, 0, 0, 1 }

    for i = 1, 12 do
        local editBox = _G['ChatFrame' .. i .. 'EditBox']
        if editBox and self.backdrops[editBox] then
            self.backdrops[editBox]:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
            self.backdrops[editBox]:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor
                [4])
        end
    end
end

-- Update tab colors from DB
function CHAT:UpdateTabColors()
    for _, tabIndex in next, chatTabIndices do
        updateTabColor(tabIndex)
    end
end

-- Get tab font settings from DB
function CHAT:GetTabFontSettings()
    local db = self.db
    local font = NRSKNUI:GetFontPath(db.FontFace) or NRSKNUI.FONT
    local outline = db.FontOutline or "OUTLINE"
    if outline == "NONE" then outline = "" end
    local size = db.TabFontSize or DEFAULT_TAB_FONT_SIZE
    return font, size, outline
end

-- Apply font to a single tab
local function ApplyTabFont(tab)
    if not tab or not tab.Text then return end
    local font, size, outline = CHAT:GetTabFontSettings()
    tab.Text:SetFont(font, size, outline)
    tab.Text:SetShadowColor(0, 0, 0, 0)
end

-- Apply font to all chat tabs
local function ApplyAllTabFonts()
    for i = 1, NUM_CHAT_WINDOWS do
        ApplyTabFont(_G["ChatFrame" .. i .. "Tab"])
    end
    if CHAT_FRAMES then
        for _, name in pairs(CHAT_FRAMES) do
            ApplyTabFont(_G[name .. "Tab"])
        end
    end
end

-- Update fonts from DB
function CHAT:UpdateFonts()
    local db = self.db
    local font = NRSKNUI:GetFontPath(db.FontFace) or NRSKNUI.FONT
    local outline = db.FontOutline or "OUTLINE"
    if outline == "NONE" then outline = "" end
    local editBoxSize = db.EditBoxFontSize or DEFAULT_EDITBOX_FONT_SIZE
    local chatSize = db.ChatFontSize or DEFAULT_CHAT_FONT_SIZE

    -- Update editbox fonts
    if ChatFrame1EditBox then
        ChatFrame1EditBox:SetFont(font, editBoxSize, outline)
        ChatFrame1EditBox:SetShadowOffset(0, 0)
    end
    if ChatFrame1EditBoxHeader then
        ChatFrame1EditBoxHeader:SetFont(font, editBoxSize, outline)
        ChatFrame1EditBoxHeader:SetShadowOffset(0, 0)
    end

    -- Update chat frame fonts
    for i = 1, 20 do
        local chatFrame = _G["ChatFrame" .. i]
        if not chatFrame then break end
        if chatFrame._nrsknSkinned then
            chatFrame:SetFont(font, chatSize, outline)
            chatFrame:SetShadowOffset(0, 0)
        end
    end

    -- Update tab fonts
    ApplyAllTabFonts()
end

-- Main update function
function CHAT:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    self:UpdateBackdrop()
    self:UpdateFonts()
    self:UpdateEditBox()
    self:UpdateTabColors()
end

-- Function to modify scrolling
local function onChatScroll(chatFrame, direction)
    if direction > 0 then
        if IsShiftKeyDown() then
            chatFrame:ScrollToTop()
        elseif IsControlKeyDown() then
            chatFrame:PageUp()
        else
            chatFrame:ScrollUp()
        end
    else
        if IsShiftKeyDown() then
            chatFrame:ScrollToBottom()
        elseif IsControlKeyDown() then
            chatFrame:PageDown()
        else
            chatFrame:ScrollDown()
        end
    end
end

-- Tab color update
updateTabColor = function(tabIndex)
    local tab = _G['ChatFrame' .. tabIndex .. 'Tab']
    local chatFrame = _G['ChatFrame' .. tabIndex]
    if not tab or not tab.Text then return end

    local isSelected = tabIndex == SELECTED_CHAT_FRAME:GetID()

    -- Check if this is a whisper tab
    local isWhisper = false
    if chatFrame then
        local chatType = chatFrame.chatType
        if chatType and NRSKNUI:NotSecretValue(chatType) then
            isWhisper = (chatType == "WHISPER" or chatType == "BN_WHISPER")
        end
    end

    -- Set tab alpha
    tab:SetAlpha(isSelected and TAB_ACTIVE_ALPHA or TAB_INACTIVE_ALPHA)

    if chatTabAlerts[tabIndex] then
        tab.Text:SetTextColor(GetTabColor("alert"))
    elseif isSelected then
        tab.Text:SetTextColor(GetTabColor("active"))
    elseif isWhisper then
        tab.Text:SetTextColor(GetTabColor("whisper"))
    else
        tab.Text:SetTextColor(GetTabColor("inactive"))
    end
end

-- Setup custom chat friend button
local function SetupChatButtons()
    local friendButton = NRSKNUI:CreateButtonFrame(CHAT.backdrop, 25, 30, "NRSKNUI_ChatFriendButton", {
        text = true,
        btnPoint = "TOPLEFT",
        btnOffset = { 0, 31 },
    })
    friendButton:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    friendButton:SetAlpha(0)

    local function UpdateFriendText()
        friendButton:SetButtonText(QuickJoinToastButton.FriendCount:GetText())
    end

    UpdateFriendText()
    hooksecurefunc(QuickJoinToastButton.FriendCount, "SetText", UpdateFriendText)
    friendButton:SetScript("OnClick", function()
        QuickJoinToastButton:Click()
    end)

    friendButton:SetScript("OnEnter", function()
        UIFrameFadeIn(friendButton, 0.2, friendButton:GetAlpha(), 1)
    end)

    friendButton:SetScript("OnLeave", function(self)
        if not self:IsMouseOver() then
            C_Timer.After(3, function()
                UIFrameFadeOut(friendButton, 3, friendButton:GetAlpha(), 0)
            end)
        end
    end)

    CHAT.friendButton = friendButton
end

-- On tab click function
local function onTabClick(chatTab)
    if chatTabAlerts[chatTab:GetID()] then
        chatTabAlerts[chatTab:GetID()] = false
    end

    for _, tabIndex in next, chatTabIndices do
        updateTabColor(tabIndex)
    end
end

function NRSKNUI:AlertChatTab(tabIndex)
    chatTabAlerts[tabIndex] = true
    updateTabColor(tabIndex)
end

local function SkinChatTab(chatTab, chatIndex, isSpecialTab)
    if chatTab._nrsknSkinned then return end

    if not isSpecialTab then
        chatTab:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        chatTab:RegisterForDrag()
    end

    -- Hook events for tabs
    chatTab:HookScript('OnEnter', GenerateClosure(updateTabColor, chatIndex))
    chatTab:HookScript('OnLeave', GenerateClosure(updateTabColor, chatIndex))
    chatTab:HookScript('PostClick', onTabClick)

    -- Track modified tabs
    if not tContains(chatTabIndices, chatIndex) then
        chatTabIndices:insert(chatIndex)
    end

    -- Update tab color and font
    updateTabColor(chatIndex)
    ApplyTabFont(chatTab)

    chatTab._nrsknSkinned = true
end

-- Hide editbox textures
local function HideEditBoxTextures(editBox)
    local frameName = editBox:GetName()
    local textures = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }
    for _, textureName in ipairs(textures) do
        local texture = editBox[textureName] or (frameName and _G[frameName .. textureName])
        if texture then
            texture:SetTexture(0)
        end
    end
end

local setupPending = false
local function SetupAndSkinChat()
    if setupPending then return end
    setupPending = true
    C_Timer.After(0, function()
        setupPending = false
    end)

    local db = CHAT.db

    -- Hide chat background textures
    if not CHAT._texturesHidden then
        for _, value in ipairs(CHAT_FRAME_TEXTURES) do
            for i = 1, NUM_CHAT_WINDOWS do
                local tex = _G["ChatFrame" .. i .. value]
                if tex then
                    tex:Hide()
                    tex:SetAlpha(0)
                end
            end
        end

        local function SafeHide(name)
            local obj = _G[name]
            if obj then
                obj:Hide()
                obj:SetAlpha(0)
                if obj.EnableMouse then obj:EnableMouse(false) end
            end
        end
        SafeHide('QuickJoinToastButton')
        SafeHide('ChatFrameChannelButton')
        SafeHide('ChatFrameMenuButton')
        SafeHide('ChatFrame1EditBoxMid')
        SafeHide('ChatFrame1EditBoxLeft')
        SafeHide('ChatFrame1EditBoxRight')

        CHAT._texturesHidden = true
    end

    -- Chat frame element hiding and skinning
    for chatIndex = 1, 12 do
        local chatFrame = _G['ChatFrame' .. chatIndex]
        local chatTab = _G['ChatFrame' .. chatIndex .. 'Tab']
        local editBox = _G['ChatFrame' .. chatIndex .. 'EditBox']

        if not chatFrame then break end

        -- Hide scroll to bottom button
        local btn = chatFrame.ScrollToBottomButton
        if btn and not btn._nrsknHidden then
            btn:Hide()
            btn:SetAlpha(0)
            btn:EnableMouse(false)
            btn._nrsknHidden = true
        end

        -- One-time element setup per chat frame
        if not chatFrame._nrsknElementsHidden then
            if chatFrame.buttonFrame then
                chatFrame.buttonFrame:Hide()
                chatFrame.buttonFrame:SetAlpha(0)
                chatFrame.buttonFrame:EnableMouse(false)
            end

            if chatFrame.ScrollBar and not chatFrame.ScrollBar._nrsknDisabled then
                -- Hide scrollbar completely
                local scrollBar = chatFrame.ScrollBar
                scrollBar:Hide()
                scrollBar:SetAlpha(0)
                scrollBar:EnableMouse(false)
                scrollBar._nrsknDisabled = true
            end

            HideEditBoxTextures(editBox)

            for _, region in next, { chatFrame:GetRegions() } do
                region:Hide()
                region:SetAlpha(0)
            end

            chatFrame._nrsknElementsHidden = true
        end

        -- Hide tab textures
        if chatTab and not chatTab._nrsknTexturesHidden then
            for _, region in next, { chatTab:GetRegions() } do
                if region:GetObjectType() == 'Texture' then
                    region:Hide()
                    region:SetAlpha(0)
                end
            end
            chatTab._nrsknTexturesHidden = true
        end

        -- Editbox backdrop
        if not CHAT.backdrops[editBox] then
            local editBoxDB = db.EditBox or {}
            local bgColor = editBoxDB.BackdropColor or { 0, 0, 0, 0.8 }
            local borderColor = editBoxDB.BorderColor or { 0, 0, 0, 1 }
            local backdrop = CHAT:CreateEditBoxBackdrop(editBox, bgColor[4], 0, 5)
            backdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
            backdrop:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
        end

        -- Editbox font
        if chatIndex == 1 and not CHAT._editBoxFontSet then
            local font = NRSKNUI:GetFontPath(db.FontFace) or NRSKNUI.FONT
            local outline = db.FontOutline or "OUTLINE"
            if outline == "NONE" then outline = "" end
            local editBoxSize = db.EditBoxFontSize or DEFAULT_EDITBOX_FONT_SIZE
            ChatFrame1EditBox:SetFont(font, editBoxSize, outline)
            ChatFrame1EditBox:SetShadowOffset(0, 0)
            ChatFrame1EditBoxHeader:SetFont(font, editBoxSize, outline)
            ChatFrame1EditBoxHeader:SetShadowOffset(0, 0)
            CHAT._editBoxFontSet = true
        end

        -- Disable screen clamping
        if not chatFrame._nrsknUnclampSet then
            chatFrame:SetClampedToScreen(false)
            chatFrame:SetScript('OnMouseWheel', onChatScroll)
            chatFrame._nrsknUnclampSet = true
        end

        -- Position editbox
        if not editBox._nrsknPositioned then
            editBox:ClearAllPoints()
            editBox:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -1, 4)
            editBox:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 10, 4)
            editBox._nrsknPositioned = true
        end

        -- Skin chat tabs
        local isSpecialTab = (chatIndex == 2 or chatIndex == 3)
        SkinChatTab(chatTab, chatIndex, isSpecialTab)
    end

    -- Also apply tab fonts to any temporary tabs
    ApplyAllTabFonts()
end

-- Create theme colored clickable links in chat
local function SetupChatLinks()
    hooksecurefunc(_G.ItemRefTooltip, "SetHyperlink", function(self, link)
        if link and (strsub(link, 1, 3) == "url") then
            local editbox = ChatEdit_ChooseBoxForSend()
            ChatEdit_ActivateChat(editbox)
            editbox:Insert(string.sub(link, 5))
            editbox:HighlightText()
        end
    end)
end

local function DeferredReskin()
    if deferredReskinPending then return end
    deferredReskinPending = true
    C_Timer.After(0.1, function()
        deferredReskinPending = false
        SetupAndSkinChat()
        ApplyAllTabFonts()
        CHAT:UpdateTabColors()
    end)
end

-- Module OnEnable
function CHAT:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    FCF_FadeInChatFrame = function(chatFrame)
        if chatFrame then
            chatFrame:SetAlpha(1)
            chatFrame.oldAlpha = nil
        end
    end
    FCF_FadeOutChatFrame = function(chatFrame)
        if chatFrame then
            chatFrame:SetAlpha(1)
            chatFrame.oldAlpha = nil
        end
    end
    FCF_FadeInScrollbar = function() end
    FCF_FadeOutScrollbar = function() end

    -- Also disable the OnUpdate fade handler
    if FCF_OnUpdate then
        FCF_OnUpdate = function() end
    end

    self:CreateChatBackDrop()

    -- Initial setup with delay
    C_Timer.After(0.1, function()
        SetupAndSkinChat()
        SetupChatLinks()
        SetupChatButtons()
        C_Timer.After(0.2, function()
            SetupAndSkinChat()
            ApplyAllTabFonts()
        end)
        C_Timer.After(0.5, ApplyAllTabFonts)
    end)

    -- Setup hooks
    hooksecurefunc("FCF_Tab_OnClick", DeferredReskin)
    hooksecurefunc("FCFTab_UpdateColors", DeferredReskin)
    hooksecurefunc("FCF_OpenTemporaryWindow", DeferredReskin)
    hooksecurefunc("FCF_OpenNewWindow", DeferredReskin)
    hooksecurefunc("FCF_DockFrame", DeferredReskin)
    hooksecurefunc("FCF_UnDockFrame", DeferredReskin)
    hooksecurefunc("FCFDock_AddChatFrame", DeferredReskin)
    hooksecurefunc("FCF_RestorePositionAndDimensions", DeferredReskin)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(0.1, function()
            SetupAndSkinChat()
            ApplyAllTabFonts()
        end)
    end)
end
