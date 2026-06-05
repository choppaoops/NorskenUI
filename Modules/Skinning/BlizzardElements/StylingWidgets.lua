---@class NRSKNUI
local NRSKNUI = select(2, ...)

local hooksecurefunc = hooksecurefunc
local strfind = string.find
local Mixin = Mixin
local CreateFrame = CreateFrame

NRSKNUI.BlizzSkin = NRSKNUI.BlizzSkin or {}
local BSKIN = NRSKNUI.BlizzSkin

-- Collapse button mixins and styling

---@class CollapseButtonMixin: Button
---@field __texture Texture
---@field __highlight Texture
---@field bg Frame
---@field settingTexture boolean?
---@field styled boolean?
local CollapseButtonMixin = {}

function CollapseButtonMixin:DoCollapse(collapsed)
    if collapsed then
        self.__texture:SetAtlas("UI-QuestTrackerButton-Secondary-Expand", true)
    else
        self.__texture:SetAtlas("UI-QuestTrackerButton-Secondary-Collapse", true)
    end
end

function CollapseButtonMixin:ResetTexture(texture)
    if self.settingTexture then return end
    self.settingTexture = true
    self:SetNormalTexture(0)

    if texture and texture ~= "" then
        if strfind(texture, "Plus") or strfind(texture, "[Cc]losed") then
            self:DoCollapse(true)
        elseif strfind(texture, "Minus") or strfind(texture, "[Oo]pen") then
            self:DoCollapse(false)
        end
    end
    self.settingTexture = nil
end

function CollapseButtonMixin:ResetAtlas(atlas)
    if self.settingTexture then return end
    self.settingTexture = true
    self:SetNormalAtlas("")

    if atlas and atlas ~= "" then
        if strfind(atlas, "Plus") or strfind(atlas, "[Cc]losed") or strfind(atlas, "Expand") then
            self:DoCollapse(true)
        elseif strfind(atlas, "Minus") or strfind(atlas, "[Oo]pen") or strfind(atlas, "Collapse") then
            self:DoCollapse(false)
        end
    end
    self.settingTexture = nil
end

function CollapseButtonMixin:OnEnter()
    if self:IsEnabled() and self.__highlight then
        self.__highlight:Show()
    end
end

function CollapseButtonMixin:OnLeave()
    if self.__highlight then
        self.__highlight:Hide()
    end
end

---@param button Button
---@param isAtlas boolean?
function BSKIN:ReskinCollapse(button, isAtlas)
    if not button or button.styled then return end

    Mixin(button, CollapseButtonMixin)

    button:SetNormalTexture(0)
    button:SetHighlightTexture(0)
    button:SetPushedTexture(0)

    local normalTex = button:GetNormalTexture()
    if normalTex then normalTex:SetAlpha(0) end

    local pushedTex = button:GetPushedTexture()
    if pushedTex then pushedTex:SetAlpha(0) end

    local container = CreateFrame("Frame", nil, button)
    container:SetAllPoints(button)
    container:SetFrameLevel(button:GetFrameLevel() + 1)
    button.bg = container

    local texture = container:CreateTexture(nil, "OVERLAY", nil, 6)
    texture:SetPoint("CENTER")
    texture:SetAtlas("UI-QuestTrackerButton-Secondary-Collapse", true)
    button.__texture = texture

    local highlight = container:CreateTexture(nil, "OVERLAY", nil, 7)
    highlight:SetPoint("CENTER")
    highlight:SetAtlas("UI-QuestTrackerButton-Yellow-Highlight", true)
    highlight:Hide()
    button.__highlight = highlight

    button:HookScript("OnEnter", button.OnEnter)
    button:HookScript("OnLeave", button.OnLeave)

    if isAtlas then
        hooksecurefunc(button, "SetNormalAtlas", button.ResetAtlas)
    else
        hooksecurefunc(button, "SetNormalTexture", button.ResetTexture)
    end

    button.styled = true
end
