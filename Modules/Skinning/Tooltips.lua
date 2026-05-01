---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("Tooltips: Addon object not initialized. Check file load order!")
    return
end

---@class Tooltips: AceModule, AceEvent-3.0
local TT = NorskenUI:NewModule("Tooltips", "AceEvent-3.0")

local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local pairs = pairs
local Mixin = Mixin
local _G = _G
local GetCoinTextureString = GetCoinTextureString
local issecretvalue = issecretvalue
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitTreatAsPlayerForDisplay = UnitTreatAsPlayerForDisplay
local UnitNameFromGUID = UnitNameFromGUID
local UnitTokenFromGUID = UnitTokenFromGUID
local C_ClassColor = C_ClassColor
local UnitIsMinion = UnitIsMinion
local UnitSelectionColor = UnitSelectionColor
local CreateColor = CreateColor

local isInitialized = false
local tooltipBackdrops = {}

local TOOLTIPS_TO_SKIN = {
    "GameTooltip",
    "ItemRefTooltip",
    "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "EmbeddedItemTooltip",
    "FriendsTooltip",
    "GameSmallHeaderTooltip",
    "QuickKeybindTooltip",
    "ReputationParagonTooltip",
    "WarCampaignTooltip",
    "LibDBIconTooltip",
    "SettingsTooltip",
}

-- Prevents errors when frame width/height become secret values
local backdropMixin = {}
function backdropMixin:SetBackgroundColor(r, g, b, a)
    if self.backdropBackground then
        self.backdropBackground:SetColorTexture(r, g, b, a)
    end
end

function backdropMixin:SetBorderColor(r, g, b, a)
    if self.backdropEdges then
        for _, edge in pairs(self.backdropEdges) do
            edge:SetColorTexture(r, g, b, a or 1)
        end
    end
end

function TT:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Tooltips
end

function TT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

local cachedColor

local function GetOrCreateBackdrop(tooltip)
    if not tooltip or tooltip:IsForbidden() or tooltipBackdrops[tooltip] then return end

    Mixin(tooltip, backdropMixin)
    tooltip.backdropEdges = {}

    local function CreateBorder(p1, r1, x1, y1, p2, r2, x2, y2, size, isWidth)
        local tex = tooltip:CreateTexture(nil, "BORDER")
        tex:SetPoint(p1, tooltip, r1, x1, y1)
        tex:SetPoint(p2, tooltip, r2, x2, y2)
        if isWidth then tex:SetWidth(size) else tex:SetHeight(size) end
        NRSKNUI:PixelPerfect(tex)
        return tex
    end

    tooltip.backdropEdges.left = CreateBorder("TOPLEFT", "TOPLEFT", -1, 1, "BOTTOMLEFT", "BOTTOMLEFT", -1, -1, 1, true)
    tooltip.backdropEdges.top = CreateBorder("TOPLEFT", "TOPLEFT", -1, 1, "TOPRIGHT", "TOPRIGHT", 1, 1, 1, false)
    tooltip.backdropEdges.right = CreateBorder("TOPRIGHT", "TOPRIGHT", 1, 1, "BOTTOMRIGHT", "BOTTOMRIGHT", 1, -1, 1, true)
    tooltip.backdropEdges.bottom = CreateBorder("BOTTOMLEFT", "BOTTOMLEFT", -1, -1, "BOTTOMRIGHT", "BOTTOMRIGHT", 1, -1,
        1, false)

    tooltip.backdropBackground = tooltip:CreateTexture(nil, "BACKGROUND")
    tooltip.backdropBackground:SetAllPoints()
    NRSKNUI:PixelPerfect(tooltip.backdropBackground)

    tooltip:SetBackgroundColor(0, 0, 0, 0.8)
    tooltip:SetBorderColor(0, 0, 0, 1)

    tooltipBackdrops[tooltip] = true
end

local skinnedTooltips = {}

local function SkinTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end

    if tooltip.NineSlice then
        tooltip.NineSlice:SetAlpha(0)
        tooltip.NineSlice:Hide()
    end
    if tooltip.SetBackdrop then
        tooltip:SetBackdrop(nil)
        tooltip:SetBackdropColor(0, 0, 0, 0)
        tooltip:SetBackdropBorderColor(0, 0, 0, 0)
    end

    GetOrCreateBackdrop(tooltip)

    if skinnedTooltips[tooltip] then return end
    skinnedTooltips[tooltip] = true

    tooltip:HookScript("OnShow", function(self)
        if self:IsForbidden() then return end
        if self.NineSlice then
            self.NineSlice:SetAlpha(0)
            self.NineSlice:Hide()
        end
        if self.SetBackdrop then
            self:SetBackdrop(nil)
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(0, 0, 0, 0)
        end
        GetOrCreateBackdrop(self)
    end)

    if tooltip.StatusBar then
        tooltip.StatusBar:Hide()
        tooltip.StatusBar:SetAlpha(0)
        hooksecurefunc(tooltip.StatusBar, "Show", function(self) self:Hide() end)
    end
end

local function RegisterTooltipProcessors()
    local NAME_REALM_FORMAT = "%s |cff777777(%s)|r"

    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitName, function(tooltip, data)
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(Enum.TooltipDataType.Unit) then return end

        local tooltipData = tooltip:GetTooltipData()
        if not tooltipData or not tooltipData.guid then return end

        local guid = tooltipData.guid
        if issecretvalue(guid) then return end

        local unit = UnitTokenFromGUID(guid)
        if not unit or issecretvalue(unit) then return end

        local name, realm

        if UnitIsPlayer(unit) or UnitTreatAsPlayerForDisplay(unit) then
            local _, classToken = UnitClass(unit)
            cachedColor = C_ClassColor.GetClassColor(classToken)
            name, realm = UnitNameFromGUID(guid)
        elseif UnitIsMinion(unit) then
            cachedColor = CreateColor(UnitSelectionColor(unit, true))
        else
            cachedColor = data.leftColor
        end

        if realm ~= nil then
            tooltip:AddLine(NAME_REALM_FORMAT:format(name, realm), cachedColor:GetRGB())
        elseif name ~= nil then
            tooltip:AddLine(name, cachedColor:GetRGB())
        else
            tooltip:AddLine(data.leftText, (cachedColor or data.leftColor):GetRGB())
        end

        return true
    end)

    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitOwner, function(tooltip, data)
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(Enum.TooltipDataType.Unit) then
            return
        end

        tooltip:AddLine(data.leftText, 0.5, 0.5, 0.5)
        return true
    end)

    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitThreat, function(tooltip)
        return not tooltip:IsForbidden()
    end)
end

local function SetTooltipFonts()
    local font = NRSKNUI.FONT or "Fonts\\FRIZQT__.TTF"

    for _, fontStringName in pairs({
        "GameTooltipHeaderText",
        "GameTooltipText",
        "GameTooltipTextSmall",
    }) do
        local fontString = _G[fontStringName]
        if fontString then
            fontString:SetShadowOffset(0, 0)

            if fontStringName ~= "GameTooltipHeaderText" then
                fontString:SetFont(font, 13, "OUTLINE")
            else
                fontString:SetFont(font, 16, "OUTLINE")
            end
        end
    end
end

function TT:CreateTooltipAnchorFrame()
    local TTAnchor = CreateFrame("Frame", "NRSKNUI_ToolTipAnchorFrame", UIParent)
    TTAnchor:SetSize(170, 60)
    TTAnchor:ClearAllPoints()
    TTAnchor:SetPoint(
        self.db.Position.AnchorFrom,
        UIParent,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    TTAnchor:SetClampedToScreen(true)

    self.TTAnchor = TTAnchor
    return TTAnchor
end

function TT:AnchorTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    tooltip:ClearAllPoints()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetPoint("BOTTOMRIGHT", self.TTAnchor, "BOTTOMRIGHT", 0, 0)
end

local function DisableTooltipEditMode()
    if GameTooltipDefaultContainer then
        GameTooltipDefaultContainer.SetIsInEditMode = nop
        GameTooltipDefaultContainer.OnEditModeEnter = nop
        GameTooltipDefaultContainer.OnEditModeExit = nop
        GameTooltipDefaultContainer.HasActiveChanges = nop
        GameTooltipDefaultContainer.HighlightSystem = nop
        GameTooltipDefaultContainer.SelectSystem = nop
        GameTooltipDefaultContainer.system = nil
    end
end

local function SkinQueueStatus()
    local frame = QueueStatusFrame
    if not frame then return end

    local children = { frame:GetChildren() }
    local borderFrame = children[1]

    if borderFrame then
        for _, region in pairs({ borderFrame:GetRegions() }) do
            region:SetAlpha(0)
            region:Hide()
        end
        hooksecurefunc(borderFrame, "Show", function(self)
            for _, region in pairs({ self:GetRegions() }) do
                region:SetAlpha(0)
                region:Hide()
            end
        end)
    end

    GetOrCreateBackdrop(frame)

    frame:HookScript("OnShow", function(self)
        if borderFrame then
            for _, region in pairs({ borderFrame:GetRegions() }) do
                region:SetAlpha(0)
                region:Hide()
            end
        end
        GetOrCreateBackdrop(self)
    end)
end

function TT:Refresh()
    for _, tooltipName in pairs(TOOLTIPS_TO_SKIN) do
        local tooltip = _G[tooltipName]
        if tooltip then SkinTooltip(tooltip) end
    end
end

function TT:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    self:Refresh()
end

function TT:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end
    if isInitialized then return end

    -- Override SetTooltipMoney to fix frame errors
    function SetTooltipMoney(frame, money, type, prefixText, suffixText)
        frame:AddLine((prefixText or "") .. "  " .. C_CurrencyInfo.GetCoinTextureString(money) .. " " .. (suffixText or ""), 0, 1, 1)
    end

    TT:CreateTooltipAnchorFrame()
    TT:Refresh()
    SkinQueueStatus()
    RegisterTooltipProcessors()
    SetTooltipFonts()

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip) TT:AnchorTooltip(tooltip) end)

    C_Timer.After(0.5, DisableTooltipEditMode)

    local config = {
        key = "TooltipModule",
        displayName = "Tooltip Anchor",
        frame = self.TTAnchor,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset

            self.TTAnchor:ClearAllPoints()
            self.TTAnchor:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
        end,
        getParentFrame = function()
            return UIParent
        end,
        guiPath = "tooltips",
    }
    NRSKNUI.EditMode:RegisterElement(config)

    isInitialized = true
end
