---@class NRSKNUI
local NRSKNUI = select(2, ...)

local EnumerateFrames = EnumerateFrames
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local UnitExists = UnitExists
local UnitTokenFromGUID = UnitTokenFromGUID
local issecretvalue = issecretvalue
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local UnitIsPlayer = UnitIsPlayer
local UnitTreatAsPlayerForDisplay = UnitTreatAsPlayerForDisplay
local UnitClass = UnitClass
local UnitIsMinion = UnitIsMinion
local UnitSelectionColor = UnitSelectionColor
local UnitLevel = UnitLevel
local UnitRace = UnitRace
local GetMaxPlayerLevel = GetMaxPlayerLevel
local GetGuildInfo = GetGuildInfo
local select = select
local next = next
local pairs = pairs
local UnitNameFromGUID = UnitNameFromGUID
local CreateFrame = CreateFrame

local TooltipContainer = GameTooltipDefaultContainer
local GameTooltip = GameTooltip
local UIParent = UIParent

local WHITE_FONT_COLOR = WHITE_FONT_COLOR
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE

local GetClassColor = C_ClassColor and C_ClassColor.GetClassColor
local GetDisplayedItem = TooltipUtil and TooltipUtil.GetDisplayedItem
local GetItemQualityByID = C_Item and C_Item.GetItemQualityByID
local GetColorDataForItemQuality = ColorManager and ColorManager.GetColorDataForItemQuality
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString

local preCall = TooltipDataProcessor and TooltipDataProcessor.AddLinePreCall
local postCall = TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall

local itemEnum = Enum.TooltipDataType.Item
local unitEnum = Enum.TooltipDataType.Unit
local unitNameEnum = Enum.TooltipDataLineType.UnitName
local unitOwnerEnum = Enum.TooltipDataLineType.UnitOwner
local sellPriceEnum = Enum.TooltipDataLineType.SellPrice
local unitThreatEnum = Enum.TooltipDataLineType.UnitThreat

local tooltipTexts = {
    'GameTooltipHeaderText',
    'GameTooltipText',
    'GameTooltipTextSmall',
}

local levelLineMatch1 = TOOLTIP_UNIT_LEVEL:gsub('%s?%%s%s?%-?', ''):lower()
local levelLineMatch2 = TOOLTIP_UNIT_LEVEL_RACE:gsub('^%%2$s%s?(.-)%s?%%1$s', '%1'):gsub('^%-?г?о?%s?', ''):gsub('%s?%%s%s?%-?', ''):lower()

local factionLineColors = {
    [FACTION_ALLIANCE] = { 0.25, 0.51, 1 },
    [FACTION_HORDE] = { 1, 0.16, 0.16 },
}

local guildNameFormat = '<|cffffa700%s|r>'
local guildRankFormat = '<|cffffa700%s|r> [|cffffa700%s|r]'

---@class Tooltips: AceModule, AceEvent-3.0
local TT = NRSKNUI:NewModule('Tooltips', 'AceEvent-3.0')

function TT:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Tooltips
end

function TT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Hides an already-shown unit tooltip when combat starts, unless Shift is held.
-- Unit tooltips opened during combat are handled by the Unit post call.
local function ToggleTooltipInCombat()
    local db = TT.db
    if not db.HideInCombat then return end
    if GameTooltip:IsForbidden() then return end
    if IsShiftKeyDown() then return end

    if GameTooltip:IsShown() and GameTooltip:IsTooltipType(unitEnum) then
        GameTooltip:Hide()
    end
end

-- Creates the anchor frame on first call, then (re)applies the position
-- from the db, so it can also be used to reposition on settings changes.
local customAnchor
local function CreateTooltipAnchorFrame()
    if not customAnchor then
        customAnchor = CreateFrame('Frame', 'NRSKNUI_ToolTipAnchorFrame', UIParent)
        customAnchor:SetSize(170, 60)
        customAnchor:SetClampedToScreen(true)
        TT.TTAnchor = customAnchor
    end

    local pos = TT.db.Position
    customAnchor:ClearAllPoints()
    customAnchor:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
end

-- Re-points default-anchored tooltips to the custom anchor.
---@param tooltip Tooltip
local function AnchorTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    if not customAnchor or not TT.db.Enabled then return end
    tooltip:ClearAllPoints()
    tooltip:SetPoint('BOTTOMRIGHT', customAnchor, 'BOTTOMRIGHT', 0, 0)
end

-- Shift override, pressing Shift while hovering a unit in combat shows
-- its tooltip immediately, releasing Shift hides it again.
local function OnModifierChanged(_, key, down)
    if key ~= 'LSHIFT' and key ~= 'RSHIFT' then return end
    if not TT.db.HideInCombat or not InCombatLockdown() then return end
    if GameTooltip:IsForbidden() then return end

    if down == 1 then
        if UnitExists('mouseover') and not GameTooltip:IsShown() then
            GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
            AnchorTooltip(GameTooltip)
            GameTooltip:SetUnit('mouseover')
        end
    else
        ToggleTooltipInCombat()
    end
end

-- Runs both on OnShow and whenever item data is set on an already-shown
-- tooltip, so the border always matches the currently displayed item.
---@param tooltip GameTooltip & PublicBackdropMixin
local function UpdateBorderColor(tooltip)
    if tooltip:IsForbidden() then return end
    if not NRSKNUI:BackdropExists(tooltip) then return end

    if GetDisplayedItem and GetColorDataForItemQuality and tooltip.IsTooltipType then
        local _, link = GetDisplayedItem(tooltip)
        local itemQuality = link and GetItemQualityByID(link)
        local colorData = itemQuality and GetColorDataForItemQuality(itemQuality)
        if colorData then
            tooltip:SetBorderColor(colorData.r, colorData.g, colorData.b, 1)
            return
        end
    end

    tooltip:SetBorderColor(0, 0, 0, 1)
end

local function StyleTooltipTexts()
    local db = TT.db
    local outline = NRSKNUI:GetFontOutline(db.FontOutline)
    local font = NRSKNUI:GetFontPath(NRSKNUI:GetEffectiveFont(db))

    -- TODO: Hook up to GUI
    for _, tooltipFontString in next, tooltipTexts do
        if tooltipFontString == 'GameTooltipHeaderText' then
            _G[tooltipFontString]:SetFont(font, db.HeaderTextSize, outline)
        elseif tooltipFontString == 'GameTooltipText' then
            _G[tooltipFontString]:SetFont(font, db.TextSize, outline)
        elseif tooltipFontString == 'GameTooltipTextSmall' then
            _G[tooltipFontString]:SetFont(font, db.TextSmallSize, outline)
        end
        _G[tooltipFontString]:SetShadowOffset(0, 0)
    end
end

---@param tooltip Tooltip
local function GetUnitColor(tooltip)
    local tooltipData = tooltip.processingInfo and tooltip.processingInfo.tooltipData
    local unitGUID = tooltipData and tooltipData.guid
    if unitGUID then
        local unit = UnitTokenFromGUID(unitGUID)
        if issecretvalue(unit) then
            local classToken = select(2, GetPlayerInfoByGUID(unitGUID))
            -- Unit is a player
            if classToken ~= nil then
                return GetClassColor(classToken)
            else
                return tooltipData.lines[1].leftColor
            end
        elseif unit ~= nil then
            if UnitIsPlayer(unit) or UnitTreatAsPlayerForDisplay(unit) then
                local classToken = select(2, UnitClass(unit))
                return GetClassColor(classToken)
            elseif UnitIsMinion(unit) then
                return NRSKNUI:CreateColor(UnitSelectionColor(unit, true))
            else
                return tooltipData.lines[1].leftColor
            end
        end
    end

    return WHITE_FONT_COLOR
end

-- Tooltips with a StatusBar
local statusBarTooltips = {}

local function tooltipHealthChanged(self)
    local tooltip = self:GetParent()
    self:SetStatusBarColor(GetUnitColor(tooltip):GetRGB())
end

--TODO:When mouseovering a unit, then moving mouseover away, the statusbar color is instantly changed to white, fallback.

---@param tooltip Tooltip
local function StyleStatusBar(tooltip)
    if TT.db.ShowStatusBar then
        tooltip.StatusBar:SetAlpha(1)
        tooltip.StatusBar:ClearAllPoints()
        tooltip.StatusBar:SetPoint('BOTTOMLEFT', tooltip, 'BOTTOMLEFT', 2, 2)
        tooltip.StatusBar:SetPoint('BOTTOMRIGHT', tooltip, 'BOTTOMRIGHT', -2, 2)
        tooltip.StatusBar:SetHeight(3)
        tooltip.StatusBar:SetStatusBarTexture(NRSKNUI:GetStatusbarPath('NorskenUI')) --TODO: Proper DB and global statusbar
        tooltip.StatusBar:HookScript('OnValueChanged', tooltipHealthChanged)
    else
        tooltip.StatusBar:Hide()
        tooltip.StatusBar:SetAlpha(0)
    end
end

local function StyleStatusBars()
    for _, tooltip in next, statusBarTooltips do
        StyleStatusBar(tooltip)
    end
end

-- The queue status texts live on pooled entry frames that are created
-- and filled on demand, so this must re-run every time Blizzard updates the frame.
local function StyleQueueStatusFonts()
    local frame = QueueStatusFrame
    if not frame then return end

    local db = TT.db
    local outline = NRSKNUI:GetFontOutline(db.FontOutline)
    local font = NRSKNUI:GetFontPath(NRSKNUI:GetEffectiveFont(db))

    -- Grab frames from GetChildren
    for _, entry in pairs({ frame:GetChildren() }) do
        -- Grab FontStrings regions from each entry
        for _, region in pairs({ entry:GetRegions() }) do
            if region:IsObjectType('FontString') then
                ---@cast region FontString
                local size = region == entry.Title and db.HeaderTextSize or db.TextSize
                region:SetFont(font, size, outline)
                region:SetShadowOffset(0, 0)
            end
        end
    end
end

local function SkinQueueStatus()
    local frame = QueueStatusFrame
    if not frame then return end
    if NRSKNUI:BackdropExists(frame) then return end

    NRSKNUI:Hide(frame, 'NineSlice')
    NRSKNUI:CreateBackdrop(frame)

    -- Restyle whenever entries are (re)built, OnShow covers builds that happen while the frame is hidden.
    if frame.Update then
        hooksecurefunc(frame, 'Update', StyleQueueStatusFonts)
    end
    frame:HookScript('OnShow', StyleQueueStatusFonts)
end

---@param tooltip Tooltip
local function SetupSkinning(tooltip)
    if tooltip:IsForbidden() then return end                       -- Skip forbidden tooltips
    if not tooltip.NineSlice or tooltip.IsEmbedded then return end -- Not skinnable
    if NRSKNUI:BackdropExists(tooltip) then return end             -- Check if we already skinned the tooltip

    NRSKNUI:Hide(tooltip, 'NineSlice')
    NRSKNUI:CreateBackdrop(tooltip)

    tooltip:HookScript('OnShow', UpdateBorderColor)

    if tooltip.CompareHeader then
        tooltip.CompareHeader:SetAlpha(0)
    end

    if tooltip.StatusBar then
        statusBarTooltips[#statusBarTooltips + 1] = tooltip
        hooksecurefunc(tooltip.StatusBar, 'Show', function(bar)
            if not TT.db.ShowStatusBar then bar:Hide() end
        end)
        StyleStatusBar(tooltip)
    end
end

-- Enumerate every single non-forbidden frame.
-- This way you do not need to setup a table with common tooltip types manually.
local CurrentFrame
local function TooltipInit()
    -- Source: https://warcraft.wiki.gg/wiki/API_EnumerateFrames
    local nextFrame = EnumerateFrames(CurrentFrame) -- The current frame. If omitted, returns the first frame.
    while nextFrame do                              -- The frame following currentFrame. Returns nil if there are no more frames.
        if nextFrame:GetObjectType() == 'GameTooltip' then
            SetupSkinning(nextFrame)
        end

        CurrentFrame = nextFrame
        nextFrame = EnumerateFrames(nextFrame)
    end
end


-- Level 1 = red, max level = green, yellow in between.
---@param level number
---@return string hex
local function GetLevelColorHex(level)
    local maxLevel = GetMaxPlayerLevel() or level
    local r, g, b = NRSKNUI:ColorGradient(level - 1, maxLevel - 1,
        1, 0.15, 0.15,
        1, 0.85, 0.1,
        0.2, 0.95, 0.2)
    return NRSKNUI:RGBAToHex(r, g, b)
end

---@param tooltip Tooltip
---@param startLine number First line to consider, skips past the guild line
---@return FontString?
local function GetLevelLine(tooltip, startLine)
    for i = startLine, tooltip:NumLines() do
        local line = _G['GameTooltipTextLeft' .. i]
        local text = line and line:GetText()
        if not issecretvalue(text) and text and text ~= '' then
            local lowerText = text:lower()
            if lowerText:find(levelLineMatch1, 1, true) or lowerText:find(levelLineMatch2, 1, true) then
                return line
            end
        end
    end
end

-- Resolves the unit token from tooltip data, nil for secrets and non-players.
---@param data TooltipData
---@return string? unit
local function GetPlayerUnit(data)
    local unitGUID = data and data.guid
    if not unitGUID or issecretvalue(unitGUID) then return end

    local unit = UnitTokenFromGUID(unitGUID)
    if not unit or issecretvalue(unit) then return end

    local isPlayer = UnitIsPlayer(unit)
    if issecretvalue(isPlayer) or not isPlayer then return end

    return unit
end

---@param tooltip Tooltip
---@param data TooltipData
local function StyleLevelLine(tooltip, data)
    local unit = GetPlayerUnit(data)
    if not unit then return end

    local level = UnitLevel(unit)
    if issecretvalue(level) or not level or level <= 0 then return end

    local race = UnitRace(unit)
    if issecretvalue(race) or not race then return end

    local guildName = GetGuildInfo(unit)
    local startLine = (not issecretvalue(guildName) and guildName) and 3 or 2

    local line = GetLevelLine(tooltip, startLine)
    if not line then return end

    line:SetText(('|cFF%s%d|r %s'):format(GetLevelColorHex(level), level, race))
end

---@param tooltip Tooltip
local function StyleFactionLine(tooltip)
    for i = 2, tooltip:NumLines() do
        local line = _G['GameTooltipTextLeft' .. i]
        local text = line and line:GetText()
        if not issecretvalue(text) and text then
            local color = factionLineColors[text]
            if color then
                line:SetTextColor(color[1], color[2], color[3])
                return
            end
        end
    end
end

---@param data TooltipData
local function StyleGuildLine(data)
    local unit = GetPlayerUnit(data)
    if not unit then return end

    local guildName, guildRank = GetGuildInfo(unit)
    if issecretvalue(guildName) or not guildName then return end

    local line = _G['GameTooltipTextLeft2']
    local text = line and line:GetText()
    if issecretvalue(text) or not text then return end

    -- Only overwrite if line 2 really is the guild line.
    if not text:find(guildName, 1, true) then return end

    if TT.db.ShowGuildRank and not issecretvalue(guildRank) and guildRank then
        line:SetText(guildRankFormat:format(guildName, guildRank))
    else
        line:SetText(guildNameFormat:format(guildName))
    end
end

local tooltipsProcessed = false
local function TooltipProcessor()
    if tooltipsProcessed then return end
    -- Remove unit threat line, very useless xd
    preCall(unitThreatEnum, function(tooltip)
        if not TT.db.Enabled then return end
        if not tooltip:IsForbidden() then return true end
    end)

    -- Add processor for item quality border coloring
    postCall(itemEnum, UpdateBorderColor)

    -- Hide unit tooltips during combat, overwritten by pressing shift
    postCall(unitEnum, function(tooltip, data)
        if not TT.db.Enabled then return end
        if tooltip:IsForbidden() then return end
        if TT.db.HideInCombat and InCombatLockdown() and not IsShiftKeyDown() then
            tooltip:Hide()
            return
        end

        -- Style level and faction lines for units
        if TT.db.StyleLevelLine then
            StyleLevelLine(tooltip, data)
            StyleFactionLine(tooltip)
        end

        -- Style the guild name line for players
        if TT.db.StyleGuildText then
            StyleGuildLine(data)
        end
    end)

    -- Color unit name and style realm name: 'Norsken (TarrenMill)'
    preCall(unitNameEnum, function(tooltip, data)
        if not TT.db.Enabled then return end
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(unitEnum) then
            return
        end

        local unitGUID = select(3, tooltip:GetUnit())
        if not unitGUID then return end

        local r, g, b = GetUnitColor(tooltip):GetRGB()
        if tooltip.StatusBar then
            tooltip.StatusBar:SetStatusBarColor(r, g, b)
        end

        local nameRealmFormat = '%s |cff777777(%s)|r'
        local name, realm = UnitNameFromGUID(unitGUID)
        if realm ~= nil then
            tooltip:AddLine(nameRealmFormat:format(name, realm), r, g, b)
        elseif name ~= nil then
            tooltip:AddLine(name, r, g, b)
        else
            tooltip:AddLine(data.leftText, r, g, b)
        end

        return true
    end)

    -- Color unitOwner name, for example 'Norsken's Pet/Minion/Statue'
    preCall(unitOwnerEnum, function(tooltip, data)
        if not TT.db.Enabled then return end
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(unitEnum) then
            return
        end

        tooltip:AddLine(data.leftText, 0.5, 0.5, 0.5)
        return true
    end)

    -- Fully replace money frame tooltips and add our own styleable line
    preCall(sellPriceEnum, function(tooltip, lineData)
        if not TT.db.Enabled or not GetCoinTextureString then return end
        if tooltip:IsForbidden() then return end
        tooltip:AddLine(SELL_PRICE .. ': ' .. GetCoinTextureString(lineData.price), WHITE_FONT_COLOR:GetRGB())
        return true
    end)

    tooltipsProcessed = true
end

-- Kill tooltip handling in Blizzards editmode, we control it with out custom anchor.
local function KillTooltipEditMode()
    if TooltipContainer then
        TooltipContainer.SetIsInEditMode = nop
        TooltipContainer.OnEditModeEnter = nop
        TooltipContainer.OnEditModeExit = nop
        TooltipContainer.HasActiveChanges = nop
        TooltipContainer.HighlightSystem = nop
        TooltipContainer.SelectSystem = nop
        TooltipContainer.system = nil
    end
end

-- Everything re-appliable lives here, runs on enable, on profile
-- changes and after GUI settings changes.
function TT:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end

    TooltipInit()
    TooltipProcessor()
    CreateTooltipAnchorFrame()
    StyleTooltipTexts()
    StyleStatusBars()
    StyleQueueStatusFonts()
end

local anchorHooked = false
function TT:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end -- Don't enable module if ElvUI is enabled.
    if not self.db.Enabled then return end

    -- One-time setup, everything re-appliable runs through ApplySettings.
    SkinQueueStatus()
    KillTooltipEditMode()
    self:ApplySettings()

    -- Register events.
    self:RegisterEvent('ADDON_LOADED', TooltipInit)
    self:RegisterEvent('PLAYER_REGEN_DISABLED', ToggleTooltipInCombat)
    self:RegisterEvent('MODIFIER_STATE_CHANGED', OnModifierChanged)

    -- Hook when blizzard tries to anchor tooltip and anchor to our custom one instead.
    if not anchorHooked then
        hooksecurefunc('GameTooltip_SetDefaultAnchor', AnchorTooltip)
        anchorHooked = true
    end

    -- Register the custom anchor with addons editmode.
    local config = {
        key = 'TooltipModule',
        displayName = 'Tooltip Anchor',
        frame = self.TTAnchor,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            CreateTooltipAnchorFrame()
        end,
        getParentFrame = function()
            return UIParent
        end,
        guiPath = 'tooltips',
    }
    NRSKNUI.EditMode:RegisterElement(config)
end

function TT:OnDisable()
    self:UnregisterAllEvents()
end
