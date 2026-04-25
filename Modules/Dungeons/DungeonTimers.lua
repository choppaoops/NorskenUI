-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("DungeonTimers: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class DungeonTimers: AceModule, AceEvent-3.0, AceTimer-3.0
local DT = NorskenUI:NewModule("DungeonTimers", "AceEvent-3.0", "AceTimer-3.0")

-- Localization
local CreateFrame = CreateFrame
local GetTime = GetTime
local unpack = unpack
local floor = math.floor
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local type = type
local select = select
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo
local CopyTable = CopyTable
local pcall = pcall
local issecretvalue = issecretvalue
local tostring = tostring
local tonumber = tonumber
local math_min = math.min
local table_insert = table.insert
local GetSpecialization = GetSpecialization
local GetSpecializationRole = GetSpecializationRole
local PlaySoundFile = PlaySoundFile
local C_Spell = C_Spell

-- Module state
DT.triggerFrames = {}
DT.triggerBars = {}
DT.barGroupFrame = nil
DT.textGroupFrame = nil
DT.previewsAllowed = false
DT.spellCache = {}
DT.currentDungeonKey = nil
DT.nextExpire = nil
DT.recheckTimer = nil
DT.scheduledScans = {}
DT.visualTicker = nil
DT.positionDirty = false
local instanceIdToDungeonKey = nil
local VISUAL_UPDATE_INTERVAL = 0.033

-- BigWigs events to register
local BIGWIGS_EVENTS = {
    "BigWigs_Timer",
    "BigWigs_TargetTimer",
    "BigWigs_CastTimer",
    "BigWigs_StartBreak",
    "BigWigs_StartPull",
    "BigWigs_StopBar",
    "BigWigs_StopBars",
    "BigWigs_PauseBar",
    "BigWigs_ResumeBar",
    "BigWigs_OnBossDisable",
}

-- Get current player role
local function GetPlayerRole()
    local role = GetSpecializationRole(GetSpecialization())
    return role or "DAMAGER"
end

-- Check if trigger should load based on load conditions
local function CheckLoadConditions(trigger, isPreview)
    if isPreview then return true end
    if not trigger.loadRoleEnabled then return true end
    local role = GetPlayerRole()
    if role == "TANK" and trigger.loadRoleTank then return true end
    if role == "HEALER" and trigger.loadRoleHealer then return true end
    if role == "DAMAGER" and trigger.loadRoleDPS then return true end
    return false
end

-- Play a sound by LSM name
local function PlayTriggerSound(soundName, isPreview)
    if isPreview then return end
    if not soundName or soundName == "" or soundName == "None" then return end
    local LSM = NRSKNUI.LSM
    if not LSM then return end
    local file = LSM:Fetch("sound", soundName)
    if file then
        PlaySoundFile(file, "Master")
    end
end

-- Update db reference
function DT:UpdateDB()
    if NRSKNUI.db and NRSKNUI.db.profile then
        self.db = NRSKNUI.db.profile.DungeonTimers
        if self.db and not self.db.Dungeons then
            self.db.Dungeons = {}
        end
    end
end

-- Build reverse lookup table from instanceId to dungeonKey
local function BuildInstanceIdLookup(dungeons)
    if instanceIdToDungeonKey then return end
    instanceIdToDungeonKey = {}
    for dungeonKey, dungeonData in pairs(dungeons) do
        if dungeonData.instanceId then
            instanceIdToDungeonKey[dungeonData.instanceId] = dungeonKey
        end
    end
end

-- Detect current dungeon based on instance
function DT:UpdateCurrentDungeon()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then
        -- Not in a dungeon/raid, clear current dungeon
        if self.currentDungeonKey then
            self.currentDungeonKey = nil
            self:StopAllBars()
        end
        return
    end

    -- Get instance ID
    local instanceId = select(8, GetInstanceInfo())
    if not instanceId then
        self.currentDungeonKey = nil
        return
    end

    -- Build lookup table if needed
    if self.db and self.db.Dungeons then
        BuildInstanceIdLookup(self.db.Dungeons)
    end

    -- Look up dungeon key from instance ID
    local newDungeonKey = instanceIdToDungeonKey and instanceIdToDungeonKey[instanceId] or nil

    -- If dungeon changed, stop old bars
    if self.currentDungeonKey ~= newDungeonKey then
        self:StopAllBars()
        self.currentDungeonKey = newDungeonKey
    end
end

-- Module init
function DT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Get global display settings for bars
function DT:GetBarDisplaySettings()
    self:UpdateDB()
    return self.db and self.db.BarDisplay or {}
end

-- Get global display settings for texts
function DT:GetTextDisplaySettings()
    self:UpdateDB()
    return self.db and self.db.TextDisplay or {}
end

-- Get group settings
function DT:GetGroupSettings(groupType)
    self:UpdateDB()
    if not self.db then return {} end
    return groupType == "bar" and self.db.BarGroup or self.db.TextGroup
end

-- Create or get the Bar Group container frame
function DT:GetBarGroupFrame()
    if not self.barGroupFrame then
        local frame = CreateFrame("Frame", "NorskenUI_DungeonTimers_BarGroup", UIParent)
        frame:SetSize(1, 1)
        frame:SetFrameStrata("HIGH")
        frame:Show()
        self.barGroupFrame = frame
    end
    return self.barGroupFrame
end

-- Create or get the Text Group container frame
function DT:GetTextGroupFrame()
    if not self.textGroupFrame then
        local frame = CreateFrame("Frame", "NorskenUI_DungeonTimers_TextGroup", UIParent)
        frame:SetSize(1, 1)
        frame:SetFrameStrata("HIGH")
        frame:Show()
        self.textGroupFrame = frame
    end
    return self.textGroupFrame
end

-- Update Bar Group position from settings
function DT:UpdateBarGroupPosition()
    local group = self:GetBarGroupFrame()
    local settings = self:GetGroupSettings("bar")
    local pos = settings.Position

    group:ClearAllPoints()
    group:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
end

-- Update Text Group position from settings
function DT:UpdateTextGroupPosition()
    local group = self:GetTextGroupFrame()
    local settings = self:GetGroupSettings("text")
    local pos = settings.Position

    group:ClearAllPoints()
    group:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
end

-- Position all visible BAR frames within the Bar Group
function DT:PositionAllBars()
    self:UpdateBarGroupPosition()

    local settings = self:GetGroupSettings("bar")
    local pos = settings.Position
    local spacing = settings.Spacing
    local growUp = settings.GrowthDirection == "UP"
    local barDisplay = self:GetBarDisplaySettings()
    local barHeight = barDisplay.barHeight or 20
    local barWidth = barDisplay.barWidth or 200

    -- Collect ALL visible bar frames
    local frames = {}
    for frameKey, frame in pairs(self.triggerFrames) do
        if frame and frame:IsShown() and frame.isBarDisplay == true then
            table_insert(frames, frame)
        end
    end

    -- Sort by dungeon key then trigger ID
    table.sort(frames, function(a, b)
        if a.dungeonKey ~= b.dungeonKey then
            return (a.dungeonKey or "") < (b.dungeonKey or "")
        end
        return (tonumber(a.triggerId) or 0) < (tonumber(b.triggerId) or 0)
    end)

    local anchorFrom = pos.AnchorFrom
    local anchorTo = pos.AnchorTo
    local baseX = pos.XOffset
    local baseY = pos.YOffset

    for i, frame in ipairs(frames) do
        frame:SetSize(barWidth, barHeight)
        frame:ClearAllPoints()

        local offset = (i - 1) * (barHeight + spacing)
        local yPos
        if growUp then
            yPos = baseY + offset
        else
            yPos = baseY - offset
        end

        frame:SetPoint(anchorFrom, UIParent, anchorTo, baseX, yPos)
    end
end

-- Position all visible TEXT frames within the Text Group
function DT:PositionAllTexts()
    self:UpdateTextGroupPosition()

    local settings = self:GetGroupSettings("text")
    local pos = settings.Position
    local spacing = settings.Spacing
    local growUp = settings.GrowthDirection == "UP"
    local textDisplay = self:GetTextDisplaySettings()
    local textFontSize = textDisplay.fontSize or 14
    local textHeight = textFontSize + 4
    local textWidth = 400

    -- Collect ALL visible text frames
    local frames = {}
    for frameKey, frame in pairs(self.triggerFrames) do
        if frame and frame:IsShown() and frame.isBarDisplay == false then
            table_insert(frames, frame)
        end
    end

    -- Sort by dungeon key then trigger ID
    table.sort(frames, function(a, b)
        if a.dungeonKey ~= b.dungeonKey then
            return (a.dungeonKey or "") < (b.dungeonKey or "")
        end
        return (tonumber(a.triggerId) or 0) < (tonumber(b.triggerId) or 0)
    end)

    -- Position frames exactly like the GUI preview does
    -- Each frame's AnchorFrom is placed at UIParent's AnchorTo with offset
    local anchorFrom = pos.AnchorFrom
    local anchorTo = pos.AnchorTo
    local baseX = pos.XOffset
    local baseY = pos.YOffset

    for i, frame in ipairs(frames) do
        frame:SetSize(textWidth, textHeight)
        frame:ClearAllPoints()

        local offset = (i - 1) * (textHeight + spacing)
        local yPos
        if growUp then
            yPos = baseY + offset
        else
            yPos = baseY - offset
        end

        frame:SetPoint(anchorFrom, UIParent, anchorTo, baseX, yPos)
    end
end

-- Position all visible frames
function DT:PositionAllFrames()
    self:PositionAllBars()
    self:PositionAllTexts()
end

-- Create a new trigger for a dungeon
function DT:CreateTrigger(dungeonKey)
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then return nil end

    -- Ensure dungeon entry exists
    if not self.db.Dungeons[dungeonKey] then
        self.db.Dungeons[dungeonKey] = { Enabled = true, Triggers = {} }
    end

    local dungeonDb = self.db.Dungeons[dungeonKey]
    if not dungeonDb.Triggers then
        dungeonDb.Triggers = {}
    end

    -- Find next available ID
    local maxId = 0
    for id in pairs(dungeonDb.Triggers) do
        local numId = tonumber(id)
        if numId and numId > maxId then
            maxId = numId
        end
    end
    local newId = maxId + 1

    -- Copy from TriggerDefaults and set unique values
    local trigger = CopyTable(self.db.TriggerDefaults)
    trigger.id = newId
    trigger.name = "New Timer " .. newId
    dungeonDb.Triggers[newId] = trigger

    return newId
end

-- Get trigger config with global display settings merged
function DT:GetTriggerConfig(trigger)
    local isBar = trigger.displayType == "bar"
    local barDisplay = self:GetBarDisplaySettings()
    local textDisplay = self:GetTextDisplaySettings()

    -- Start with trigger values, overlay global display settings
    return {
        -- Trigger identity
        id = trigger.id,
        name = trigger.name,
        enabled = trigger.enabled ~= false,
        -- Trigger conditions
        triggerType = trigger.triggerType,
        spellId = trigger.spellId,
        message = trigger.message,
        messageOperator = trigger.messageOperator,
        remainingEnabled = trigger.remainingEnabled,
        remainingOperator = trigger.remainingOperator,
        remainingValue = trigger.remainingValue,
        countEnabled = trigger.countEnabled,
        countOperator = trigger.countOperator,
        countValue = trigger.countValue,
        extendTimer = trigger.extendTimer,
        displayType = trigger.displayType,
        -- Global display settings
        barWidth = barDisplay.barWidth,
        barHeight = barDisplay.barHeight,
        barTexture = barDisplay.barTexture,
        fontFace = isBar and barDisplay.fontFace or textDisplay.fontFace,
        fontSize = isBar and barDisplay.fontSize or textDisplay.fontSize,
        fontOutline = isBar and barDisplay.fontOutline or textDisplay.fontOutline,
        iconEnabled = barDisplay.iconEnabled, -- Only for bars
        textJustify = textDisplay.textAlign,
        -- Per-trigger settings
        useBigWigsColors = trigger.useBigWigsColors ~= false,
        barColor = trigger.barColor,
        textColor = trigger.textColor,
        barText1Format = trigger.barText1Format,
        barText1Justify = trigger.barText1Justify,
        barText1XOffset = trigger.barText1XOffset,
        barText1YOffset = trigger.barText1YOffset,
        barText2Format = trigger.barText2Format,
        barText2Justify = trigger.barText2Justify,
        barText2XOffset = trigger.barText2XOffset,
        barText2YOffset = trigger.barText2YOffset,
        textFormat = trigger.textFormat,
        showDecimals = trigger.showDecimals,
        decimalThreshold = trigger.decimalThreshold,
        -- Custom text (Lua code for %c placeholder)
        customText = trigger.customText,
        -- Actions
        actionOnShowSound = trigger.actionOnShowSound,
        actionOnHideSound = trigger.actionOnHideSound,
    }
end

-- Check if BigWigs is loaded
function DT:CheckBigWigs()
    return BigWigsLoader ~= nil
end

-- Alias for backwards compatibility
DT.IsBigWigsAvailable = DT.CheckBigWigs

-- Register BigWigs callbacks
function DT:RegisterBigWigsCallbacks()
    if not self:CheckBigWigs() then return false end
    for _, event in ipairs(BIGWIGS_EVENTS) do
        BigWigsLoader.RegisterMessage(self, event, "EventCallback")
    end
    return true
end

-- Unregister BigWigs callbacks
function DT:UnregisterBigWigsCallbacks()
    if not BigWigsLoader then return end
    for _, event in ipairs(BIGWIGS_EVENTS) do
        BigWigsLoader.UnregisterMessage(self, event)
    end
end

-- Get statusbar texture path
function DT:GetStatusbarPath(textureKey)
    textureKey = textureKey or self:GetBarDisplaySettings().barTexture or "NorskenUI"
    return NRSKNUI:GetStatusbarPath(textureKey) or "Interface\\Buttons\\WHITE8x8"
end

-- Check if format string contains %i (used by bar display for separate icon frame)
function DT:FormatHasIcon(config)
    local format = config.textFormat or "%i %n %p"
    return format:find("%%i") ~= nil
end

-- Check icon position in format (used by bar display for separate icon frame positioning)
function DT:GetIconPosition(config)
    local format = config.textFormat or "%i %n %p"
    local trimmed = format:gsub("^%s+", "")
    if trimmed:sub(1, 2) == "%i" then return "LEFT" end
    local trimmedEnd = format:gsub("%s+$", "")
    if trimmedEnd:sub(-2) == "%i" then return "RIGHT" end
    return "LEFT"
end

-- Format time value
function DT:FormatTime(remaining, showDecimals, decimalThreshold)
    decimalThreshold = decimalThreshold or 3
    if remaining < 1 then return string.format("%.1f", remaining) end
    if showDecimals and remaining <= decimalThreshold then return string.format("%.1f", remaining) end
    return tostring(floor(remaining + 0.5))
end

-- Build replacement values for placeholders
function DT:BuildReplacements(config, barData, remaining)
    local replacements = {}

    -- %i - icon (inline texture)
    if barData.icon then
        replacements["i"] = string.format("|T%s:0:0:0:0:64:64:4:60:4:60|t", barData.icon)
    else
        replacements["i"] = ""
    end

    -- %n - name/text from BigWigs
    replacements["n"] = barData.text or config.name or ""

    -- %p - progress/remaining time
    replacements["p"] = remaining and self:FormatTime(remaining, config.showDecimals, config.decimalThreshold) or ""

    -- %s - stacks/count (WeakAuras convention)
    replacements["s"] = barData.count and tostring(barData.count) or "0"

    -- %d - total duration
    replacements["d"] = barData.duration and tostring(floor(barData.duration + 0.5)) or ""

    -- %c, %c1, %c2, etc. - custom text values
    if barData.customValues then
        -- %c is alias for %c1 (first custom value)
        replacements["c"] = tostring(barData.customValues[1] or "")
        for i, val in ipairs(barData.customValues) do
            replacements["c" .. i] = tostring(val or "")
        end
    else
        replacements["c"] = ""
    end

    return replacements
end

-- State machine parser for format strings
-- Preserves multiple spaces (unlike gsub-based approach)
-- States: 0 = normal, 1 = saw %, 2 = reading placeholder
local STATE_NORMAL = 0
local STATE_PERCENT = 1
local STATE_PLACEHOLDER = 2

-- Format a text string with placeholders using state machine
function DT:FormatText(formatStr, config, barData, remaining)
    if not formatStr or formatStr == "" then return "" end

    -- Precompute replacement values
    local replacements = self:BuildReplacements(config, barData, remaining)

    local result = ""
    local state = STATE_NORMAL
    local placeholderStart = nil
    local pos = 1
    local len = #formatStr

    while pos <= len do
        local char = formatStr:sub(pos, pos)
        local byte = string.byte(char)

        if state == STATE_NORMAL then
            if char == "%" then
                state = STATE_PERCENT
                placeholderStart = pos
            else
                result = result .. char -- Preserves spaces!
            end
        elseif state == STATE_PERCENT then
            if char == "%" then
                -- Escaped %%, output single %
                result = result .. "%"
                state = STATE_NORMAL
            elseif (byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) then
                -- a-z or 0-9: start of placeholder
                state = STATE_PLACEHOLDER
            else
                -- Not a valid placeholder, output literal
                result = result .. "%"
                result = result .. char
                state = STATE_NORMAL
            end
        elseif state == STATE_PLACEHOLDER then
            if (byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) then
                -- Continue reading placeholder (a-z or 0-9)
            else
                -- End of placeholder
                local placeholder = formatStr:sub(placeholderStart + 1, pos - 1)
                local replacement = replacements[placeholder] or ""
                result = result .. replacement
                result = result .. char
                state = STATE_NORMAL
            end
        end
        pos = pos + 1
    end

    -- Handle trailing placeholder
    if state == STATE_PLACEHOLDER then
        local placeholder = formatStr:sub(placeholderStart + 1)
        local replacement = replacements[placeholder] or ""
        result = result .. replacement
    elseif state == STATE_PERCENT then
        result = result .. "%"
    end

    -- Only convert \n escape sequences
    result = result:gsub("\\n", "\n")

    return result
end

-- Load custom text function from Lua code string
function DT:LoadCustomTextFunc(luaCode, triggerId)
    if not luaCode or luaCode == "" then return nil end

    local funcStr = "return " .. luaCode
    local func, err = loadstring(funcStr)
    if not func then
        -- Log error but don't break
        return nil
    end

    -- Execute to get the actual function
    local ok, result = pcall(func)
    if not ok or type(result) ~= "function" then
        return nil
    end

    return result
end

-- Run custom text function with context
function DT:RunCustomTextFunc(customFunc, barData, remaining)
    if not customFunc then return nil end

    local ok, result = pcall(customFunc,
        barData.expirationTime or 0, -- expirationTime
        barData.duration or 0,       -- duration
        remaining or 0,              -- remaining
        barData.text or "",          -- name
        barData.icon or "",          -- icon
        barData.count or 0           -- stacks
    )

    if not ok then return nil end

    -- Wrap single value in table for indexed access
    if type(result) ~= "table" then
        return { result }
    end
    return result
end

-- Get display text for text-only mode
function DT:GetDisplayText(config, barData, remaining)
    local format = config.textFormat or "%i %n %p"
    return self:FormatText(format, config, barData, remaining)
end

-- Get bar text 1
function DT:GetBarText1(config, barData, remaining)
    local format = config.barText1Format or "%n"
    return self:FormatText(format, config, barData, remaining)
end

-- Get bar text 2
function DT:GetBarText2(config, barData, remaining)
    local format = config.barText2Format or "%p"
    return self:FormatText(format, config, barData, remaining)
end

-- Get effective bar duration for remaining time filter
function DT:GetEffectiveBarDuration(config, barData)
    if config.remainingEnabled then
        return config.remainingValue or barData.duration
    end
    return barData.duration
end

-- Compare values with operator
function DT:CompareValue(value, operator, target)
    if operator == "==" then
        return value == target
    elseif operator == ">" then
        return value > target
    elseif operator == "<" then
        return value < target
    elseif operator == ">=" then
        return value >= target
    elseif operator == "<=" then
        return value <= target
    end
    return false
end

-- Check remaining time condition
function DT:CheckRemainingTime(config, remaining)
    if not config.remainingEnabled then return true end
    local target = config.remainingValue or 5
    local operator = config.remainingOperator or "<="
    return self:CompareValue(remaining, operator, target)
end

-- Check message condition
function DT:CheckMessage(trigger, text)
    if not trigger.message or trigger.message == "" then return true end
    if not text then return false end

    -- Check for secret values
    if issecretvalue and issecretvalue(text) then return false end
    if issecretvalue and issecretvalue(trigger.message) then return false end

    local operator = trigger.messageOperator or "find"
    if operator == "==" then
        return text == trigger.message
    elseif operator == "find" then
        return text:find(trigger.message, 1, true) ~= nil
    elseif operator == "match" then
        local ok, result = pcall(function() return text:match(trigger.message) end)
        return ok and result ~= nil
    end
    return false
end

-- Check spell ID condition
function DT:CheckSpellId(trigger, spellId)
    if not trigger.spellId or trigger.spellId == "" then return true end
    return tostring(spellId) == tostring(trigger.spellId)
end

-- Check count condition
function DT:CheckCount(trigger, count)
    if not trigger.countEnabled then return true end
    local target = trigger.countValue or 0
    local operator = trigger.countOperator or "=="
    local countNum = tonumber(count) or 0
    return self:CompareValue(countNum, operator, target)
end

-- Check if trigger matches bar data
function DT:MatchesTrigger(trigger, barData)
    if not CheckLoadConditions(trigger, barData.isPreview) then return false end
    if not self:CheckSpellId(trigger, barData.spellId) then return false end
    if not self:CheckMessage(trigger, barData.text) then return false end
    if not self:CheckCount(trigger, barData.count) then return false end
    return true
end

-- Fetch BigWigs colors for a bar
function DT:GetBigWigsColors(addon, spellId)
    local barColor, textColor, bgColor

    -- Try to get colors from BigWigs Color module
    if BigWigs and BigWigs.GetPlugin then
        local colorModule = BigWigs:GetPlugin("Colors")
        if colorModule and colorModule.GetColorTable then
            barColor = colorModule:GetColorTable("barColor", addon, spellId)
            textColor = colorModule:GetColorTable("barText", addon, spellId)
            bgColor = colorModule:GetColorTable("barBackground", addon, spellId)
        end
    end

    return barColor, textColor, bgColor
end

-- Create bar data from BigWigs event
function DT:CreateBarData(addon, spellId, duration, text, count, icon, event)
    local barColor, textColor, bgColor = self:GetBigWigsColors(addon, spellId)

    -- Cache spell info to avoid repeated API calls
    local spellName, spellIcon
    local spellIdNum = tonumber(spellId)
    if spellIdNum and spellIdNum > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellIdNum)
        if spellInfo then
            spellName = spellInfo.name
            spellIcon = spellInfo.iconID
        end
    end

    return {
        addon = addon,
        spellId = tostring(spellId or ""),
        text = text or "",
        duration = duration or 0,
        expirationTime = GetTime() + (duration or 0),
        icon = icon or spellIcon,
        count = count or 0,
        paused = nil,
        pausedTime = nil,
        -- BigWigs colors
        bwBarColor = barColor,
        bwTextColor = textColor,
        bwBgColor = bgColor,
        -- Cached spell info
        spellName = spellName,
    }
end

-- Create bar frame for a trigger
function DT:CreateBarFrame(dungeonKey, triggerId, trigger)
    local config = self:GetTriggerConfig(trigger)
    local frameKey = dungeonKey .. "_" .. triggerId
    local frameName = "NorskenUI_DungeonTimer_" .. frameKey
    local showIcon = config.iconEnabled
    local iconSize = showIcon and config.barHeight or 0

    -- Create frame
    local group = self:GetBarGroupFrame()
    local frame = CreateFrame("Frame", frameName, group, "BackdropTemplate")
    frame:SetSize(config.barWidth, config.barHeight)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- Bar container
    frame.barContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.barContainer:SetPoint("TOPLEFT", iconSize, 0)
    frame.barContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.barContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.barContainer:SetBackdropColor(0, 0, 0, 0.8)
    frame.barContainer:SetBackdropBorderColor(0, 0, 0, 1)

    -- StatusBar
    frame.bar = CreateFrame("StatusBar", nil, frame.barContainer)
    frame.bar:SetPoint("TOPLEFT", 1, -1)
    frame.bar:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.bar:SetStatusBarTexture(self:GetStatusbarPath())
    frame.bar:SetStatusBarColor(unpack(config.barColor))
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(1)

    -- Icon
    if showIcon then
        frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.iconFrame:SetSize(config.barHeight, config.barHeight)
        frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame.iconFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

        frame.iconFrame.bg = frame.iconFrame:CreateTexture(nil, "BACKGROUND")
        frame.iconFrame.bg:SetAllPoints()
        frame.iconFrame.bg:SetColorTexture(0, 0, 0, 1)

        frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetPoint("TOPLEFT", 1, -1)
        frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        if NRSKNUI.ApplyZoom then
            NRSKNUI:ApplyZoom(frame.icon, 0.1)
        end
    end

    local fontSize = config.fontSize or 12
    local fontOutline = config.fontOutline or "OUTLINE"

    -- Text 1 (left side)
    frame.text1 = frame.bar:CreateFontString(nil, "OVERLAY")
    frame.text1:SetPoint("LEFT", frame.bar, "LEFT", config.barText1XOffset or 4, config.barText1YOffset or 0)
    frame.text1:SetJustifyH(config.barText1Justify or "LEFT")
    NRSKNUI:ApplyFontToText(frame.text1, config.fontFace, fontSize, fontOutline)
    frame.text1:SetTextColor(unpack(config.textColor))

    -- Text 2 (right side)
    frame.text2 = frame.bar:CreateFontString(nil, "OVERLAY")
    frame.text2:SetPoint("RIGHT", frame.bar, "RIGHT", config.barText2XOffset or -4, config.barText2YOffset or 0)
    frame.text2:SetJustifyH(config.barText2Justify or "RIGHT")
    NRSKNUI:ApplyFontToText(frame.text2, config.fontFace, fontSize, fontOutline)
    frame.text2:SetTextColor(unpack(config.textColor))

    frame.config = config
    frame.dungeonKey = dungeonKey
    frame.triggerId = triggerId
    frame.showIcon = showIcon
    frame.isBarDisplay = true

    return frame
end

-- Create text frame for a trigger
function DT:CreateTextFrame(dungeonKey, triggerId, trigger)
    local config = self:GetTriggerConfig(trigger)
    local frameKey = dungeonKey .. "_" .. triggerId
    local frameName = "NorskenUI_DungeonText_" .. frameKey
    local fontSize = config.fontSize or 14

    -- Create frame
    local group = self:GetTextGroupFrame()
    local frame = CreateFrame("Frame", frameName, group)
    frame:SetSize(config.barWidth or 200, fontSize + 4)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    local justify = config.textJustify or "LEFT"
    local fontOutline = config.fontOutline or "OUTLINE"

    -- Text spans full width
    frame.displayText = frame:CreateFontString(nil, "OVERLAY")
    frame.displayText:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.displayText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    frame.displayText:SetJustifyH(justify)
    NRSKNUI:ApplyFontToText(frame.displayText, config.fontFace, fontSize, fontOutline)
    frame.displayText:SetTextColor(unpack(config.textColor))

    frame.config = config
    frame.dungeonKey = dungeonKey
    frame.triggerId = triggerId
    frame.isBarDisplay = false

    return frame
end

-- Get or create frame for trigger
function DT:GetTriggerFrame(dungeonKey, triggerId, trigger)
    local frameKey = dungeonKey .. "_" .. triggerId
    local frame = self.triggerFrames[frameKey]
    local config = self:GetTriggerConfig(trigger)
    local wantBar = config.displayType == "bar"

    -- Check if existing frame has wrong display type and needs to be recreated
    if frame then
        local isBar = frame.isBarDisplay
        if (wantBar and not isBar) or (not wantBar and isBar) then
            frame:Hide()
            self.triggerFrames[frameKey] = nil
            self.triggerBars[frameKey] = nil
            frame = nil
        end
    end

    if not frame then
        if wantBar then
            frame = self:CreateBarFrame(dungeonKey, triggerId, trigger)
        else
            frame = self:CreateTextFrame(dungeonKey, triggerId, trigger)
        end
        if frame then
            self.triggerFrames[frameKey] = frame
        end
    end

    return frame
end

-- Apply BigWigs colors to frame if enabled
function DT:ApplyBarColors(frame, config, barData)
    if not frame.bar then return end

    -- Determine which colors to use
    local barColor = config.barColor
    local textColor = config.textColor

    if config.useBigWigsColors and barData.bwBarColor then
        barColor = barData.bwBarColor
    end
    if config.useBigWigsColors and barData.bwTextColor then
        textColor = barData.bwTextColor
    end

    -- Apply bar color
    if barColor and type(barColor) == "table" then
        frame.bar:SetStatusBarColor(barColor[1] or 1, barColor[2] or 1, barColor[3] or 1, barColor[4] or 1)
    end

    -- Apply text colors
    if textColor and type(textColor) == "table" then
        local r, g, b, a = textColor[1] or 1, textColor[2] or 1, textColor[3] or 1, textColor[4] or 1
        if frame.text1 then frame.text1:SetTextColor(r, g, b, a) end
        if frame.text2 then frame.text2:SetTextColor(r, g, b, a) end
        if frame.displayText then frame.displayText:SetTextColor(r, g, b, a) end
    end
end

-- Show trigger display
function DT:ShowTriggerDisplay(dungeonKey, triggerId, trigger, barData)
    local config = self:GetTriggerConfig(trigger)
    local frame = self:GetTriggerFrame(dungeonKey, triggerId, trigger)
    local frameKey = dungeonKey .. "_" .. triggerId

    if not frame then return end

    -- Always refresh config on frame to ensure latest settings
    frame.config = config

    local now = GetTime()
    local effectiveDuration = self:GetEffectiveBarDuration(config, barData)
    barData.effectiveDuration = effectiveDuration

    -- Set icon if available
    if frame.icon and barData.icon then
        frame.icon:SetTexture(barData.icon)
    end

    -- Apply colors
    self:ApplyBarColors(frame, config, barData)

    -- Initial text update with remaining time
    local remaining = barData.expirationTime - now

    -- Run custom text function if configured
    if config.customText and config.customText ~= "" then
        -- Reload function if code changed
        if frame.customTextCode ~= config.customText then
            frame.customTextFunc = self:LoadCustomTextFunc(config.customText, triggerId)
            frame.customTextCode = config.customText
        end
        if frame.customTextFunc then
            barData.customValues = self:RunCustomTextFunc(frame.customTextFunc, barData, remaining)
        end
    else
        -- Clear cached function if no custom text
        frame.customTextFunc = nil
        frame.customTextCode = nil
    end

    if frame.isBarDisplay then
        -- Bar mode: two separate text elements
        if frame.text1 then
            frame.text1:SetText(self:GetBarText1(config, barData, remaining))
        end
        if frame.text2 then
            frame.text2:SetText(self:GetBarText2(config, barData, remaining))
        end
    else
        -- Text mode: single formatted text
        if frame.displayText then
            frame.displayText:SetText(self:GetDisplayText(config, barData, remaining))
        end
    end

    if frame.bar then
        frame.bar:SetMinMaxValues(0, effectiveDuration)
        frame.bar:SetValue(math_min(remaining, effectiveDuration))
    end

    frame.barData = barData
    self.triggerBars[frameKey] = barData

    -- Schedule expiration check
    self:ScheduleNextExpire(barData.expirationTime)

    -- Check if should show immediately based on remaining time condition
    local shouldShowNow = true
    if config.remainingEnabled and not barData.isPreview then
        shouldShowNow = self:CheckRemainingTime(config, remaining)

        -- If not showing yet, schedule a check for when it should show
        if not shouldShowNow and remaining > 0 then
            local remainingThreshold = config.remainingValue or 5
            local showTime = barData.expirationTime - remainingThreshold
            if showTime > now then
                self:ScheduleCheck(showTime)
            end
        end
    end

    if shouldShowNow then
        -- Play on-show sound
        if not frame:IsShown() then
            PlayTriggerSound(config.actionOnShowSound, barData.isPreview)
        end
        frame:Show()

        -- Position all frames and start visual updates
        self:PositionAllFrames()
        self:StartVisualUpdates()
    else
        frame:Hide()
        self:PositionAllFrames()
    end
end

-- Hide trigger display
function DT:HideTriggerDisplay(frameKey)
    local frame = self.triggerFrames[frameKey]
    if frame then
        local isPreview = frame.barData and frame.barData.isPreview

        -- Play on-hide sound before hiding
        if frame:IsShown() and frame.config then
            PlayTriggerSound(frame.config.actionOnHideSound, isPreview)
        end

        frame:Hide()
        frame.barData = nil
    end

    self.triggerBars[frameKey] = nil
    self.positionDirty = true

    -- Check if any bars remain, if not stop visual updates
    local anyRemaining = false
    for _ in pairs(self.triggerBars) do
        anyRemaining = true
        break
    end

    if anyRemaining then
        -- Reposition remaining frames
        self:PositionAllFrames()
        self.positionDirty = false
    else
        -- No bars left, stop all timers
        self:StopAllTimers()
    end
end

-- Process timer triggers for current dungeon only
function DT:ProcessTimerTriggers(barData)
    if not self.db or not self.db.Dungeons then return end

    -- Only process triggers for the current dungeon
    local dungeonKey = self.currentDungeonKey
    if not dungeonKey then return end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Enabled or not dungeonData.Triggers then return end

    for triggerId, trigger in pairs(dungeonData.Triggers) do
        if trigger.enabled ~= false and trigger.triggerType == "timer" then
            if self:MatchesTrigger(trigger, barData) then
                local adjustedBar = {}
                for k, v in pairs(barData) do adjustedBar[k] = v end
                adjustedBar.expirationTime = adjustedBar.expirationTime + (trigger.extendTimer or 0)
                adjustedBar.duration = adjustedBar.duration + (trigger.extendTimer or 0)
                self:ShowTriggerDisplay(dungeonKey, triggerId, trigger, adjustedBar)
            end
        end
    end
end

-- Process announce triggers for current dungeon only
function DT:ProcessAnnounceTriggers(addon, spellId, text, icon)
    if not self.db or not self.db.Dungeons then return end

    -- Only process triggers for the current dungeon
    local dungeonKey = self.currentDungeonKey
    if not dungeonKey then return end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Enabled or not dungeonData.Triggers then return end

    for triggerId, trigger in pairs(dungeonData.Triggers) do
        if trigger.enabled ~= false and trigger.triggerType == "announce" then
            local data = { spellId = tostring(spellId or ""), text = text, icon = icon }
            if self:MatchesTrigger(trigger, data) then
                local barData = {
                    text = text or "",
                    icon = icon,
                    duration = 3,
                    expirationTime = GetTime() + 3,
                    spellId = tostring(spellId or ""),
                }
                self:ShowTriggerDisplay(dungeonKey, triggerId, trigger, barData)
            end
        end
    end
end

-- Stop bar by text
function DT:StopBar(text)
    for frameKey, barData in pairs(self.triggerBars) do
        if barData and barData.text == text then
            self:HideTriggerDisplay(frameKey)
        end
    end
end

-- Stop all bars
function DT:StopAllBars()
    for frameKey, _ in pairs(self.triggerBars) do
        local frame = self.triggerFrames[frameKey]
        if frame then
            frame:Hide()
            frame.barData = nil
        end
    end
    wipe(self.triggerBars)
    self:StopAllTimers()
end

-- Pause bar
function DT:PauseBar(text)
    local now = GetTime()
    for frameKey, barData in pairs(self.triggerBars) do
        if barData and barData.text == text and not barData.paused then
            barData.paused = true
            barData.pausedTime = now
            barData.remaining = barData.expirationTime - now
        end
    end

    -- Recalculate next expiration
    if self.recheckTimer then
        self:CancelTimer(self.recheckTimer)
        self.recheckTimer = nil
    end
    self:RecheckTimers()
end

-- Resume bar
function DT:ResumeBar(text)
    local now = GetTime()
    local anyResumed = false

    for frameKey, barData in pairs(self.triggerBars) do
        if barData and barData.text == text and barData.paused then
            barData.expirationTime = now + (barData.remaining or 0)
            barData.paused = nil
            barData.pausedTime = nil
            barData.remaining = nil
            anyResumed = true

            -- Schedule expiration for this bar
            self:ScheduleNextExpire(barData.expirationTime)

            -- If there's a remaining time trigger, schedule that check too
            local frame = self.triggerFrames[frameKey]
            if frame and frame.config and frame.config.remainingEnabled then
                local remainingThreshold = frame.config.remainingValue or 5
                local showTime = barData.expirationTime - remainingThreshold
                if showTime > now then
                    self:ScheduleCheck(showTime)
                end
            end
        end
    end

    -- Restart visual updates if bars were resumed
    if anyResumed then
        self:StartVisualUpdates()
    end
end

-- BigWigs event callback
function DT:EventCallback(event, ...)
    if event == "BigWigs_Timer" or event == "BigWigs_TargetTimer" or event == "BigWigs_CastTimer" then
        local addon, spellId, duration, _, text, count, icon = ...
        local barData = self:CreateBarData(addon, spellId, duration, text, count, icon, event)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StartBreak" then
        local addon, duration, _, _, _, text, icon = ...
        local barData = self:CreateBarData(addon, -1, duration, text or "Break", 0, icon, event)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StartPull" then
        local addon, duration, _, text, icon = ...
        local barData = self:CreateBarData(addon, -2, duration, text or "Pull", 0, icon or 136116, event)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StopBar" then
        local _, text = ...
        self:StopBar(text)
    elseif event == "BigWigs_StopBars" or event == "BigWigs_OnBossDisable" then
        self:StopAllBars()
    elseif event == "BigWigs_PauseBar" then
        local _, text = ...
        self:PauseBar(text)
    elseif event == "BigWigs_ResumeBar" then
        local _, text = ...
        self:ResumeBar(text)
    end
end

-- Schedule a check at a specific time
function DT:ScheduleCheck(fireTime)
    if not fireTime or fireTime <= GetTime() then return end

    -- Avoid duplicate schedules for the same time
    if self.scheduledScans[fireTime] then return end

    local delay = fireTime - GetTime()
    if delay > 0 then
        self.scheduledScans[fireTime] = self:ScheduleTimer("DoScheduledScan", delay, fireTime)
    end
end

-- Execute a scheduled scan
function DT:DoScheduledScan(fireTime)
    self.scheduledScans[fireTime] = nil

    local now = GetTime()
    local anyBecameVisible = false

    for frameKey, barData in pairs(self.triggerBars) do
        if barData and not barData.paused then
            local frame = self.triggerFrames[frameKey]
            if frame then
                local config = frame.config
                local remaining = barData.expirationTime - now

                -- Check if this bar should now show due to remaining time trigger
                if config.remainingEnabled and remaining > 0 then
                    local shouldShow = self:CheckRemainingTime(config, remaining)
                    if shouldShow and not frame:IsShown() then
                        -- Play on-show sound
                        PlayTriggerSound(config.actionOnShowSound, barData.isPreview)
                        frame:Show()
                        self.positionDirty = true
                        anyBecameVisible = true
                    end
                end
            end
        end
    end

    -- Apply position updates if needed
    if self.positionDirty then
        self:PositionAllFrames()
        self.positionDirty = false
    end

    -- Restart visual updates if bars became visible
    if anyBecameVisible then
        self:StartVisualUpdates()
    end
end

-- Recheck timers for expiration
function DT:RecheckTimers()
    local now = GetTime()
    self.nextExpire = nil
    local callbacksToRun = {}

    for frameKey, barData in pairs(self.triggerBars) do
        if barData and not barData.paused then
            local expirationTime = barData.expirationTime

            if expirationTime <= now then
                -- Bar has expired
                if barData.isPreview and barData.loopCallback and self.previewsAllowed then
                    table_insert(callbacksToRun, barData.loopCallback)
                end
                self:HideTriggerDisplay(frameKey)
            else
                -- Track next expiration
                if self.nextExpire == nil or expirationTime < self.nextExpire then
                    self.nextExpire = expirationTime
                end
            end
        end
    end

    -- Schedule next expiration check
    if self.nextExpire then
        local delay = self.nextExpire - now
        if delay > 0 then
            self.recheckTimer = self:ScheduleTimer("RecheckTimers", delay)
        end
    end

    -- Run any queued preview callbacks
    for _, callback in ipairs(callbacksToRun) do
        callback()
    end
end

-- Schedule the next expiration check
function DT:ScheduleNextExpire(expirationTime)
    local now = GetTime()

    if self.nextExpire == nil or expirationTime < self.nextExpire then
        -- Cancel existing timer if this one is sooner
        if self.recheckTimer then
            self:CancelTimer(self.recheckTimer)
        end

        self.nextExpire = expirationTime
        local delay = expirationTime - now
        if delay > 0 then
            self.recheckTimer = self:ScheduleTimer("RecheckTimers", delay)
        end
    end
end

-- Visual update ticker callback
function DT:OnVisualUpdate()
    local now = GetTime()
    local anyVisible = false

    for frameKey, barData in pairs(self.triggerBars) do
        if barData then
            local frame = self.triggerFrames[frameKey]
            if frame and frame:IsShown() then
                anyVisible = true
                local remaining = barData.paused
                    and (barData.expirationTime - barData.pausedTime)
                    or (barData.expirationTime - now)

                if remaining > 0 then
                    local config = frame.config

                    -- Update bar progress
                    if frame.bar then
                        local effectiveDuration = barData.effectiveDuration or barData.duration
                        frame.bar:SetValue(math_min(remaining, effectiveDuration))
                    end

                    -- Run custom text function if configured
                    if frame.customTextFunc then
                        barData.customValues = self:RunCustomTextFunc(frame.customTextFunc, barData, remaining)
                    end

                    -- Update text based on display type
                    if frame.isBarDisplay then
                        if frame.text1 then
                            frame.text1:SetText(self:GetBarText1(config, barData, remaining))
                        end
                        if frame.text2 then
                            frame.text2:SetText(self:GetBarText2(config, barData, remaining))
                        end
                    else
                        if frame.displayText then
                            frame.displayText:SetText(self:GetDisplayText(config, barData, remaining))
                        end
                    end
                end
            end
        end
    end

    -- Stop ticker if no visible bars
    if not anyVisible then
        self:StopVisualUpdates()
    end
end

-- Start the visual update ticker
function DT:StartVisualUpdates()
    if not self.visualTicker then
        self.visualTicker = self:ScheduleRepeatingTimer("OnVisualUpdate", VISUAL_UPDATE_INTERVAL)
    end
end

-- Stop the visual update ticker
function DT:StopVisualUpdates()
    if self.visualTicker then
        self:CancelTimer(self.visualTicker)
        self.visualTicker = nil
    end
end

-- Cancel all scheduled scans
function DT:CancelAllScheduledScans()
    for fireTime, handle in pairs(self.scheduledScans) do
        self:CancelTimer(handle)
    end
    wipe(self.scheduledScans)
end

-- Stop all timers
function DT:StopAllTimers()
    self:StopVisualUpdates()
    self:CancelAllScheduledScans()
    if self.recheckTimer then
        self:CancelTimer(self.recheckTimer)
        self.recheckTimer = nil
    end
    self.nextExpire = nil
end

-- Module OnEnable
function DT:OnEnable()
    self:UpdateDB()
    if not self.db or not self.db.Enabled then return end

    -- Register zone change events to detect current dungeon
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateCurrentDungeon")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateCurrentDungeon")

    -- Detect current dungeon immediately
    self:UpdateCurrentDungeon()

    if not self:RegisterBigWigsCallbacks() then
        self:RegisterEvent("ADDON_LOADED", function(_, addonName)
            if addonName == "BigWigs" or addonName == "BigWigs_Core" then
                self:RegisterBigWigsCallbacks()
            end
        end)
    end
end

-- Module OnDisable
function DT:OnDisable()
    self:UnregisterBigWigsCallbacks()
    self:StopAllBars()
    self:StopAllTimers()
    self:UnregisterAllEvents()
    self.currentDungeonKey = nil
    for _, frame in pairs(self.triggerFrames) do
        frame:Hide()
    end
end

-- Public API
function DT:ApplySettings()
    self:UpdateDB()
    if self.db and self.db.Enabled then
        if not self:IsEnabled() then
            NorskenUI:EnableModule("DungeonTimers")
        else
            self:RegisterBigWigsCallbacks()
        end
    else
        if self:IsEnabled() then
            NorskenUI:DisableModule("DungeonTimers")
        end
    end
end

function DT:Refresh()
    -- Stop all timers first
    self:StopAllTimers()

    -- Clear all trigger frames
    for _, frame in pairs(self.triggerFrames) do
        frame:Hide()
    end
    wipe(self.triggerFrames)
    wipe(self.triggerBars)

    -- Clear group frames so they get recreated fresh
    if self.barGroupFrame then
        self.barGroupFrame:Hide()
        self.barGroupFrame = nil
    end
    if self.textGroupFrame then
        self.textGroupFrame:Hide()
        self.textGroupFrame = nil
    end
end

-- Delete trigger from dungeon
function DT:DeleteTrigger(dungeonKey, triggerId)
    if not self.db or not self.db.Dungeons then return end
    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return end

    local frameKey = dungeonKey .. "_" .. triggerId
    self:HideTriggerDisplay(frameKey)
    if self.triggerFrames[frameKey] then
        self.triggerFrames[frameKey]:Hide()
        self.triggerFrames[frameKey] = nil
    end

    dungeonData.Triggers[triggerId] = nil
end

-- Duplicate trigger in dungeon
function DT:DuplicateTrigger(dungeonKey, triggerId)
    if not self.db or not self.db.Dungeons then return nil end
    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return nil end

    local source = dungeonData.Triggers[triggerId]
    if not source then return nil end

    local newId = self:CreateTrigger(dungeonKey)
    if not newId then return nil end

    local target = dungeonData.Triggers[newId]
    for k, v in pairs(source) do
        if k ~= "id" then
            if type(v) == "table" then
                target[k] = {}
                for k2, v2 in pairs(v) do target[k][k2] = v2 end
            else
                target[k] = v
            end
        end
    end
    target.name = (source.name or "Timer") .. " (Copy)"

    return newId
end

-- Get sorted trigger IDs for a dungeon
function DT:GetSortedTriggerIds(dungeonKey)
    if not self.db or not self.db.Dungeons then return {} end
    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return {} end

    local ids = {}
    for id in pairs(dungeonData.Triggers) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
    return ids
end

-- Move trigger up in the list
function DT:MoveTriggerUp(dungeonKey, triggerId)
    if not self.db or not self.db.Dungeons then return false end
    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return false end

    local sortedIds = self:GetSortedTriggerIds(dungeonKey)
    local currentIndex = nil
    for i, id in ipairs(sortedIds) do
        if id == triggerId then
            currentIndex = i
            break
        end
    end

    -- Can't move up if already at top
    if not currentIndex or currentIndex <= 1 then return false end

    local prevId = sortedIds[currentIndex - 1]

    -- Swap the trigger data
    local currentData = dungeonData.Triggers[triggerId]
    local prevData = dungeonData.Triggers[prevId]

    dungeonData.Triggers[triggerId] = prevData
    dungeonData.Triggers[prevId] = currentData

    -- Update their internal IDs
    dungeonData.Triggers[triggerId].id = triggerId
    dungeonData.Triggers[prevId].id = prevId

    -- Hide both frames so they get recreated with correct data
    local frameKey1 = dungeonKey .. "_" .. triggerId
    local frameKey2 = dungeonKey .. "_" .. prevId
    if self.triggerFrames[frameKey1] then
        self.triggerFrames[frameKey1]:Hide()
        self.triggerFrames[frameKey1] = nil
    end
    if self.triggerFrames[frameKey2] then
        self.triggerFrames[frameKey2]:Hide()
        self.triggerFrames[frameKey2] = nil
    end

    return prevId
end

-- Move trigger down in the list
function DT:MoveTriggerDown(dungeonKey, triggerId)
    if not self.db or not self.db.Dungeons then return false end
    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return false end

    local sortedIds = self:GetSortedTriggerIds(dungeonKey)
    local currentIndex = nil
    for i, id in ipairs(sortedIds) do
        if id == triggerId then
            currentIndex = i
            break
        end
    end

    -- Can't move down if already at bottom
    if not currentIndex or currentIndex >= #sortedIds then return false end

    local nextId = sortedIds[currentIndex + 1]

    -- Swap the trigger data
    local currentData = dungeonData.Triggers[triggerId]
    local nextData = dungeonData.Triggers[nextId]

    dungeonData.Triggers[triggerId] = nextData
    dungeonData.Triggers[nextId] = currentData

    -- Update their internal IDs
    dungeonData.Triggers[triggerId].id = triggerId
    dungeonData.Triggers[nextId].id = nextId

    -- Hide both frames so they get recreated with correct data
    local frameKey1 = dungeonKey .. "_" .. triggerId
    local frameKey2 = dungeonKey .. "_" .. nextId
    if self.triggerFrames[frameKey1] then
        self.triggerFrames[frameKey1]:Hide()
        self.triggerFrames[frameKey1] = nil
    end
    if self.triggerFrames[frameKey2] then
        self.triggerFrames[frameKey2]:Hide()
        self.triggerFrames[frameKey2] = nil
    end

    return nextId -- Return the new ID of the moved trigger
end

-- Preview a specific trigger
function DT:PreviewTrigger(dungeonKey, triggerId, loopCallback)
    if not self.previewsAllowed then return end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then return end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return end

    local trigger = dungeonData.Triggers[triggerId]
    if not trigger then return end

    local config = self:GetTriggerConfig(trigger)

    -- Clear existing frame
    local frameKey = dungeonKey .. "_" .. triggerId
    if self.triggerFrames[frameKey] then
        self.triggerFrames[frameKey]:Hide()
        self.triggerFrames[frameKey] = nil
    end

    -- Get spell info for icon and name
    local icon = 136116
    local spellName
    local spellIdNum = tonumber(config.spellId)
    if spellIdNum and spellIdNum > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellIdNum)
        if spellInfo then
            if spellInfo.iconID then icon = spellInfo.iconID end
            spellName = spellInfo.name
        end
    end

    -- Fetch BigWigs colors for preview if enabled
    local bwBarColor, bwTextColor, bwBgColor
    if config.useBigWigsColors and spellIdNum then
        bwBarColor, bwTextColor, bwBgColor = self:GetBigWigsColors(nil, spellIdNum)
    end

    local duration = config.remainingEnabled and (config.remainingValue or 5) or 20

    -- Create individual loop callback for this specific trigger
    -- This ensures each preview restarts independently
    local selfRef = self
    local individualLoopCallback = function()
        if selfRef.previewsAllowed then
            selfRef:PreviewTrigger(dungeonKey, triggerId)
        end
    end

    local barData = {
        text = config.name or "Preview",
        icon = icon,
        duration = duration,
        effectiveDuration = duration,
        expirationTime = GetTime() + duration,
        spellId = config.spellId or "",
        count = 0,
        isPreview = true,
        loopCallback = individualLoopCallback,
        -- BigWigs colors for preview
        bwBarColor = bwBarColor,
        bwTextColor = bwTextColor,
        bwBgColor = bwBgColor,
        -- Cached spell info
        spellName = spellName,
    }

    self:ShowTriggerDisplay(dungeonKey, triggerId, trigger, barData)
end

-- Preview all triggers for a dungeon
function DT:PreviewDungeon(dungeonKey, loopCallback)
    if not self.previewsAllowed then return end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then return end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.Triggers then return end

    -- Clear existing frames for this dungeon first
    for frameKey, frame in pairs(self.triggerFrames) do
        if frame.dungeonKey == dungeonKey then
            frame:Hide()
            self.triggerBars[frameKey] = nil
        end
    end

    -- Create all preview triggers
    for triggerId, trigger in pairs(dungeonData.Triggers) do
        if trigger.enabled ~= false then
            self:PreviewTrigger(dungeonKey, triggerId)
        end
    end

    -- Position all frames
    self:PositionAllFrames()
end

-- Hide all frames and stop timers
function DT:HideAll()
    for _, frame in pairs(self.triggerFrames) do
        frame:Hide()
        frame.barData = nil
    end
    wipe(self.triggerBars)
    self:StopAllTimers()
end

-- Hide only preview frames
function DT:HideAllPreviews()
    local hasRemainingFrames = false
    for frameKey, barData in pairs(self.triggerBars) do
        if barData and barData.isPreview then
            local frame = self.triggerFrames[frameKey]
            if frame then
                frame:Hide()
                frame.barData = nil
            end
            self.triggerBars[frameKey] = nil
        elseif barData then
            hasRemainingFrames = true
        end
    end

    if hasRemainingFrames then
        self:PositionAllFrames()
    else
        self:StopAllTimers()
    end
end

-- Enable previews
function DT:EnablePreviews()
    self.previewsAllowed = true
end

-- Disable previews and hide all preview frames
function DT:DisablePreviews()
    self.previewsAllowed = false
    self:HideAllPreviews()
end

-- Force update group positions and reposition all frames
function DT:RefreshPositions()
    self:UpdateBarGroupPosition()
    self:UpdateTextGroupPosition()
    self:PositionAllFrames()
end

-- Get BigWigs boss modules for a specific instance ID
function DT:GetBigWigsModulesForInstance(instanceId)
    local modules = {}
    if not BigWigs or not BigWigs.IterateBossModules then return modules end

    for name, module in BigWigs:IterateBossModules() do
        if module.instanceId == instanceId then
            table_insert(modules, module)
        end
    end

    return modules
end

-- Force load BigWigs/LittleWigs modules for a zone
function DT:LoadBigWigsZone(instanceId)
    if not instanceId then return false end

    -- Use BigWigsLoader to force-load the zone's modules
    if BigWigsLoader and BigWigsLoader.LoadZone then
        BigWigsLoader:LoadZone(instanceId)
        return true
    end

    return false
end

-- Get all spells from BigWigs modules for a dungeon
function DT:GetSpellsForDungeon(dungeonKey, forceRefresh)
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then return {} end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.instanceId then return {} end

    -- Return cached data if available and not forcing refresh
    if not forceRefresh and self.spellCache[dungeonKey] then
        return self.spellCache[dungeonKey]
    end

    -- Force load the zone's modules first
    self:LoadBigWigsZone(dungeonData.instanceId)

    local spells = {}
    local seenSpells = {}
    local modules = self:GetBigWigsModulesForInstance(dungeonData.instanceId)
    local bossOrder = {}
    local bossNumberMap = {}
    for _, module in ipairs(modules) do
        if module.GetOptions then
            -- Prefer journalId for ordering, fall back to engageId
            local sortKey = module.journalId or module.engageId or 999999
            table_insert(bossOrder, {
                module = module,
                sortKey = sortKey,
                name = module.displayName or module.moduleName,
            })
        end
    end
    table.sort(bossOrder, function(a, b) return a.sortKey < b.sortKey end)

    -- Assign boss numbers
    for i, boss in ipairs(bossOrder) do
        bossNumberMap[boss.name] = i
    end

    -- Now collect spells with boss number info
    for _, module in ipairs(modules) do
        if module.GetOptions then
            local options = module:GetOptions()
            if options then
                local bossName = module.displayName or module.moduleName
                local bossNum = bossNumberMap[bossName] or 0
                local sortKey = module.journalId or module.engageId or 999999

                for _, option in ipairs(options) do
                    local spellId
                    if type(option) == "number" then
                        spellId = option
                    elseif type(option) == "table" and type(option[1]) == "number" then
                        spellId = option[1]
                    end

                    if spellId and spellId > 0 and not seenSpells[spellId] then
                        seenSpells[spellId] = true
                        local spellInfo = C_Spell.GetSpellInfo(spellId)
                        if spellInfo then
                            table_insert(spells, {
                                spellId = spellId,
                                name = spellInfo.name,
                                icon = spellInfo.iconID,
                                bossName = bossName,
                                bossNum = bossNum,
                                sortKey = sortKey,
                            })
                        end
                    end
                end
            end
        end
    end

    -- Sort by boss order
    table.sort(spells, function(a, b)
        if a.sortKey ~= b.sortKey then
            return a.sortKey < b.sortKey
        end
        return a.name < b.name
    end)

    -- Cache the results
    if #spells > 0 then
        self.spellCache[dungeonKey] = spells
    end

    return spells
end

-- Clear spell cache
function DT:ClearSpellCache(dungeonKey)
    if dungeonKey then
        self.spellCache[dungeonKey] = nil
    else
        wipe(self.spellCache)
    end
end

-- Export/Import Functions

-- Libraries for serialization
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

-- Export prefixes
local EXPORT_PREFIX_SINGLE = "!NRSKNUITIMERS1!"
local EXPORT_PREFIX_ALL = "!NRSKNUITIMERSALL1!"

-- Dungeon info for export metadata
local DUNGEON_EXPORT_INFO = {
    MagistersTerrace  = { instanceId = 2811, name = "Magisters' Terrace" },
    MaisaraCaverns    = { instanceId = 2874, name = "Maisara Caverns" },
    NexusPointXenas   = { instanceId = 2915, name = "Nexus-Point Xenas" },
    WindrunnerSpire   = { instanceId = 2805, name = "Windrunner Spire" },
    AlgetharAcademy   = { instanceId = 2526, name = "Algeth'ar Academy" },
    PitOfSaron        = { instanceId = 658, name = "Pit of Saron" },
    SeatOfTriumvirate = { instanceId = 1753, name = "Seat of the Triumvirate" },
    Skyreach          = { instanceId = 1209, name = "Skyreach" },
}

-- Get next available trigger ID for a dungeon
local function GetNextTriggerId(triggers)
    local maxId = 0
    for id in pairs(triggers) do
        local numId = tonumber(id)
        if numId and numId > maxId then
            maxId = numId
        end
    end
    return maxId + 1
end

-- Validate a single trigger structure
local function ValidateTrigger(trigger)
    if type(trigger) ~= "table" then return false end
    -- Must have basic fields
    if trigger.name == nil then return false end
    if trigger.triggerType == nil then return false end
    return true
end

-- Check if a trigger already exists
local function TriggerExists(existingTriggers, newTrigger)
    if not existingTriggers or not newTrigger then return false end
    local newSpellId = tostring(newTrigger.spellId or "")
    local newName = newTrigger.name or ""

    for _, existing in pairs(existingTriggers) do
        local existingSpellId = tostring(existing.spellId or "")
        local existingName = existing.name or ""

        -- Match on spellId + name combo
        if existingSpellId == newSpellId and existingName == newName then
            return true
        end
    end
    return false
end

-- Merge imported trigger with defaults to ensure all fields exist
local function MergeWithDefaults(trigger, defaults)
    if not defaults then return trigger end
    local merged = CopyTable(defaults)
    for k, v in pairs(trigger) do
        if type(v) == "table" and type(merged[k]) == "table" then
            for k2, v2 in pairs(v) do
                merged[k][k2] = v2
            end
        else
            merged[k] = v
        end
    end
    return merged
end

-- Export triggers for a single dungeon
---@param dungeonKey string The dungeon key (e.g., "MagistersTerrace")
---@return string|nil exportString, string|nil error
function DT:ExportDungeonTimers(dungeonKey)
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return nil, "Database not initialized"
    end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData then
        return nil, "Dungeon '" .. dungeonKey .. "' not found"
    end

    local dungeonInfo = DUNGEON_EXPORT_INFO[dungeonKey]
    if not dungeonInfo then
        return nil, "Unknown dungeon key: " .. dungeonKey
    end

    -- Create export package
    local exportData = {
        _v = 1,
        _t = time(),
        _d = dungeonKey,
        _n = dungeonInfo.name,
        _i = dungeonInfo.instanceId,
        triggers = dungeonData.Triggers or {},
    }

    -- Serialize
    local serialized = AceSerializer:Serialize(exportData)
    if not serialized then return nil, "Serialization failed" end

    -- Compress
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    if not compressed then return nil, "Compression failed" end

    -- Encode for copy
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encoding failed" end

    return EXPORT_PREFIX_SINGLE .. encoded
end

-- Import triggers for a single dungeon (merge mode)
---@param importString string The export string
---@param targetDungeonKey string|nil Override target dungeon (uses embedded key if nil)
---@return boolean success, string|nil countOrError
function DT:ImportDungeonTimers(importString, targetDungeonKey)
    if not importString or importString == "" then
        return false, "Import string is empty"
    end

    -- Validate prefix
    if importString:sub(1, #EXPORT_PREFIX_SINGLE) ~= EXPORT_PREFIX_SINGLE then
        return false, "Invalid format (wrong prefix)"
    end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    -- Remove prefix
    local encoded = importString:sub(#EXPORT_PREFIX_SINGLE + 1)

    -- Decode
    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then return false, "Decoding failed" end

    -- Decompress
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return false, "Decompression failed" end

    -- Deserialize
    local success, exportData = AceSerializer:Deserialize(serialized)
    if not success then return false, "Deserialization failed: " .. tostring(exportData) end

    -- Validate structure
    if type(exportData) ~= "table" then return false, "Invalid data structure" end
    if not exportData.triggers then return false, "No triggers in import data" end

    -- Determine target dungeon
    local dungeonKey = targetDungeonKey or exportData._d
    if not dungeonKey then return false, "No dungeon key in import data" end

    -- Ensure dungeon exists in db
    if not self.db.Dungeons[dungeonKey] then
        local info = DUNGEON_EXPORT_INFO[dungeonKey]
        if info then
            self.db.Dungeons[dungeonKey] = { Enabled = true, instanceId = info.instanceId, Triggers = {} }
        else
            return false, "Unknown dungeon key: " .. dungeonKey
        end
    end

    local dungeonDb = self.db.Dungeons[dungeonKey]
    if not dungeonDb.Triggers then
        dungeonDb.Triggers = {}
    end

    -- Import triggers
    local importCount = 0
    local skipCount = 0
    local defaults = self.db and self.db.TriggerDefaults
    for _, trigger in pairs(exportData.triggers) do
        if ValidateTrigger(trigger) then
            if TriggerExists(dungeonDb.Triggers, trigger) then
                skipCount = skipCount + 1
            else
                local newId = GetNextTriggerId(dungeonDb.Triggers)
                local newTrigger = MergeWithDefaults(trigger, defaults)
                newTrigger.id = newId
                dungeonDb.Triggers[newId] = newTrigger
                importCount = importCount + 1
            end
        end
    end

    local result = tostring(importCount) .. " timer(s) imported"
    if skipCount > 0 then
        result = result .. ", " .. tostring(skipCount) .. " duplicate(s) skipped"
    end
    return true, result
end

-- Export all dungeons at once
---@return string|nil exportString, string|nil error
function DT:ExportAllDungeonTimers()
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return nil, "Database not initialized"
    end

    -- Build export data with all dungeons
    local dungeons = {}
    for dungeonKey, info in pairs(DUNGEON_EXPORT_INFO) do
        local dungeonData = self.db.Dungeons[dungeonKey]
        if dungeonData and dungeonData.Triggers then
            dungeons[dungeonKey] = {
                instanceId = info.instanceId,
                triggers = dungeonData.Triggers,
            }
        end
    end

    local exportData = {
        _v = 1,
        _t = time(),
        dungeons = dungeons,
    }

    -- Serialize
    local serialized = AceSerializer:Serialize(exportData)
    if not serialized then return nil, "Serialization failed" end

    -- Compress
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    if not compressed then return nil, "Compression failed" end

    -- Encode for copy
    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encoding failed" end

    return EXPORT_PREFIX_ALL .. encoded
end

-- Import all dungeons at once
---@param importString string The export string
---@return boolean success, string|nil countOrError
function DT:ImportAllDungeonTimers(importString)
    if not importString or importString == "" then
        return false, "Import string is empty"
    end

    -- Validate prefix
    if importString:sub(1, #EXPORT_PREFIX_ALL) ~= EXPORT_PREFIX_ALL then
        return false, "Invalid format (wrong prefix)"
    end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    -- Remove prefix
    local encoded = importString:sub(#EXPORT_PREFIX_ALL + 1)

    -- Decode
    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then return false, "Decoding failed" end

    -- Decompress
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return false, "Decompression failed" end

    -- Deserialize
    local success, exportData = AceSerializer:Deserialize(serialized)
    if not success then return false, "Deserialization failed: " .. tostring(exportData) end

    -- Validate structure
    if type(exportData) ~= "table" then return false, "Invalid data structure" end
    if not exportData.dungeons then return false, "No dungeons in import data" end

    -- Import all dungeons
    local totalImportCount = 0
    local totalSkipCount = 0
    local dungeonCount = 0

    for dungeonKey, dungeonData in pairs(exportData.dungeons) do
        if type(dungeonData) == "table" and dungeonData.triggers then
            -- Ensure dungeon exists
            if not self.db.Dungeons[dungeonKey] then
                local info = DUNGEON_EXPORT_INFO[dungeonKey]
                if info then
                    self.db.Dungeons[dungeonKey] = { Enabled = true, instanceId = info.instanceId, Triggers = {} }
                end
            end

            local dungeonDb = self.db.Dungeons[dungeonKey]
            if dungeonDb then
                if not dungeonDb.Triggers then
                    dungeonDb.Triggers = {}
                end

                -- Import triggers
                local hadImports = false
                local defaults = self.db and self.db.TriggerDefaults
                for _, trigger in pairs(dungeonData.triggers) do
                    if ValidateTrigger(trigger) then
                        if TriggerExists(dungeonDb.Triggers, trigger) then
                            totalSkipCount = totalSkipCount + 1
                        else
                            local newId = GetNextTriggerId(dungeonDb.Triggers)
                            local newTrigger = MergeWithDefaults(trigger, defaults)
                            newTrigger.id = newId
                            dungeonDb.Triggers[newId] = newTrigger
                            totalImportCount = totalImportCount + 1
                            hadImports = true
                        end
                    end
                end
                if hadImports then
                    dungeonCount = dungeonCount + 1
                end
            end
        end
    end

    local result = tostring(totalImportCount) .. " timer(s) imported from " .. tostring(dungeonCount) .. " dungeon(s)"
    if totalSkipCount > 0 then
        result = result .. ", " .. tostring(totalSkipCount) .. " duplicate(s) skipped"
    end
    return true, result
end

-- Import NUI presets for a single dungeon
---@param dungeonKey string The dungeon key
---@return boolean success, string|nil countOrError
function DT:ImportNUIPreset(dungeonKey)
    if not NRSKNUI.DungeonTimerPresets then
        return false, "Presets not loaded"
    end

    local presets = NRSKNUI.DungeonTimerPresets[dungeonKey]
    if not presets or not presets.Triggers or not next(presets.Triggers) then
        return false, "No presets available for this dungeon"
    end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    -- Ensure dungeon exists
    if not self.db.Dungeons[dungeonKey] then
        local info = DUNGEON_EXPORT_INFO[dungeonKey]
        if info then
            self.db.Dungeons[dungeonKey] = { Enabled = true, instanceId = info.instanceId, Triggers = {} }
        else
            return false, "Unknown dungeon key: " .. dungeonKey
        end
    end

    local dungeonDb = self.db.Dungeons[dungeonKey]
    if not dungeonDb.Triggers then
        dungeonDb.Triggers = {}
    end

    -- Import preset triggers
    local importCount = 0
    local skipCount = 0
    local defaults = self.db and self.db.TriggerDefaults
    for _, trigger in pairs(presets.Triggers) do
        if ValidateTrigger(trigger) then
            if TriggerExists(dungeonDb.Triggers, trigger) then
                skipCount = skipCount + 1
            else
                local newId = GetNextTriggerId(dungeonDb.Triggers)
                local newTrigger = MergeWithDefaults(trigger, defaults)
                newTrigger.id = newId
                dungeonDb.Triggers[newId] = newTrigger
                importCount = importCount + 1
            end
        end
    end

    local result = tostring(importCount) .. " timer(s) imported"
    if skipCount > 0 then
        result = result .. ", " .. tostring(skipCount) .. " duplicate(s) skipped"
    end
    return true, result
end

-- Import all NUI presets
---@return boolean success, string|nil countOrError
function DT:ImportAllNUIPresets()
    if not NRSKNUI.DungeonTimerPresets then
        return false, "Presets not loaded"
    end

    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    local totalImportCount = 0
    local totalSkipCount = 0
    local dungeonCount = 0

    for dungeonKey, presets in pairs(NRSKNUI.DungeonTimerPresets) do
        -- Skip version field
        if dungeonKey ~= "_version" and type(presets) == "table" and presets.Triggers then
            -- Ensure dungeon exists
            if not self.db.Dungeons[dungeonKey] then
                local info = DUNGEON_EXPORT_INFO[dungeonKey]
                if info then
                    self.db.Dungeons[dungeonKey] = { Enabled = true, instanceId = info.instanceId, Triggers = {} }
                end
            end

            local dungeonDb = self.db.Dungeons[dungeonKey]
            if dungeonDb then
                if not dungeonDb.Triggers then
                    dungeonDb.Triggers = {}
                end

                local hadImports = false
                local defaults = self.db and self.db.TriggerDefaults
                for _, trigger in pairs(presets.Triggers) do
                    if ValidateTrigger(trigger) then
                        if TriggerExists(dungeonDb.Triggers, trigger) then
                            totalSkipCount = totalSkipCount + 1
                        else
                            local newId = GetNextTriggerId(dungeonDb.Triggers)
                            local newTrigger = MergeWithDefaults(trigger, defaults)
                            newTrigger.id = newId
                            dungeonDb.Triggers[newId] = newTrigger
                            totalImportCount = totalImportCount + 1
                            hadImports = true
                        end
                    end
                end
                if hadImports then
                    dungeonCount = dungeonCount + 1
                end
            end
        end
    end

    if totalImportCount == 0 and totalSkipCount == 0 then
        return false, "No presets available"
    end

    local result = tostring(totalImportCount) .. " timer(s) imported from " .. tostring(dungeonCount) .. " dungeon(s)"
    if totalSkipCount > 0 then
        result = result .. ", " .. tostring(totalSkipCount) .. " duplicate(s) skipped"
    end
    return true, result
end

-- Reset all triggers for a single dungeon
---@param dungeonKey string The dungeon key
---@return boolean success, string|nil countOrError
function DT:ResetDungeonTimers(dungeonKey)
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    local dungeonDb = self.db.Dungeons[dungeonKey]
    if not dungeonDb then
        return false, "Dungeon not found"
    end

    -- Count existing triggers
    local count = 0
    if dungeonDb.Triggers then
        for _ in pairs(dungeonDb.Triggers) do
            count = count + 1
        end
    end

    -- Clear all triggers
    dungeonDb.Triggers = {}

    -- Hide any active frames for this dungeon
    for frameKey, frame in pairs(self.triggerFrames) do
        if frame.dungeonKey == dungeonKey then
            frame:Hide()
            self.triggerFrames[frameKey] = nil
            self.triggerBars[frameKey] = nil
        end
    end

    return true, tostring(count) .. " timer(s) cleared"
end

-- Reset all triggers for all dungeons
---@return boolean success, string|nil countOrError
function DT:ResetAllDungeonTimers()
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        return false, "Database not initialized"
    end

    local totalCount = 0
    local dungeonCount = 0

    for dungeonKey, dungeonDb in pairs(self.db.Dungeons) do
        if dungeonDb.Triggers then
            local count = 0
            for _ in pairs(dungeonDb.Triggers) do
                count = count + 1
            end
            if count > 0 then
                totalCount = totalCount + count
                dungeonCount = dungeonCount + 1
                dungeonDb.Triggers = {}
            end
        end
    end

    -- Hide all active frames
    for frameKey, frame in pairs(self.triggerFrames) do
        frame:Hide()
    end
    wipe(self.triggerFrames)
    wipe(self.triggerBars)

    return true, tostring(totalCount) .. " timer(s) cleared from " .. tostring(dungeonCount) .. " dungeon(s)"
end

-- Helper to serialize a value to Lua string
local function SerializeValue(val, indent)
    indent = indent or ""
    local nextIndent = indent .. "    "
    local valType = type(val)
    if valType == "string" then
        local escaped = val:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("|", "\\124")
        return "\"" .. escaped .. "\""
    elseif valType == "number" then
        return tostring(val)
    elseif valType == "boolean" then
        return val and "true" or "false"
    elseif valType == "table" then
        local parts = {}
        local isArray = true
        local maxIndex = 0

        -- Check if it's an array
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIndex then maxIndex = k end
        end

        if isArray and maxIndex > 0 then
            -- Array format
            for i = 1, maxIndex do
                local v = val[i]
                if v ~= nil then
                    table_insert(parts, nextIndent .. SerializeValue(v, nextIndent))
                end
            end
        else
            -- Dictionary format
            local keys = {}
            for k in pairs(val) do
                table_insert(keys, k)
            end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then
                    return tostring(a) < tostring(b)
                end
                return type(a) < type(b)
            end)

            for _, k in ipairs(keys) do
                local v = val[k]
                local keyStr
                if type(k) == "number" then
                    keyStr = "[" .. k .. "]"
                elseif type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. SerializeValue(k, nextIndent) .. "]"
                end
                table_insert(parts, nextIndent .. keyStr .. " = " .. SerializeValue(v, nextIndent))
            end
        end

        if #parts == 0 then
            return "{}"
        end
        return "{\n" .. table.concat(parts, ",\n") .. ",\n" .. indent .. "}"
    else
        return "nil"
    end
end

-- Generate Lua code for all current timers, for pasting into DungeonTimerPresets.lua, this way i can create and style timers ingame and export
-- Usage: /run NorskenUI:GetModule("DungeonTimers"):GeneratePresetsCode()
function DT:GeneratePresetsCode()
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then
        print("NorskenUI: Database not initialized")
        return
    end

    local output = {}
    table_insert(output, "-- Generated Dungeon Timer Presets")
    table_insert(output, "-- Pasted into DungeonTimerPresets.lua")
    table_insert(output, "")
    table_insert(output, "NRSKNUI.DungeonTimerPresets = {")
    table_insert(output, "    _version = 1,")
    table_insert(output, "")

    for dungeonKey, info in pairs(DUNGEON_EXPORT_INFO) do
        local dungeonData = self.db.Dungeons[dungeonKey]
        local triggers = dungeonData and dungeonData.Triggers

        table_insert(output, "    -- " .. info.name .. " (instanceId " .. info.instanceId .. ")")

        if triggers and next(triggers) then
            table_insert(output, "    " .. dungeonKey .. " = {")
            table_insert(output, "        Triggers = {")

            -- Sort trigger IDs
            local sortedIds = {}
            for id in pairs(triggers) do
                table_insert(sortedIds, id)
            end
            table.sort(sortedIds, function(a, b) return tonumber(a) < tonumber(b) end)

            for _, triggerId in ipairs(sortedIds) do
                local trigger = triggers[triggerId]
                local triggerCode = SerializeValue(trigger, "            ")
                table_insert(output, "            [" .. triggerId .. "] = " .. triggerCode .. ",")
            end

            table_insert(output, "        },")
            table_insert(output, "    },")
        else
            table_insert(output, "    " .. dungeonKey .. " = {},")
        end
        table_insert(output, "")
    end

    table_insert(output, "}")
    local fullCode = table.concat(output, "\n")

    -- Show in a copyable dialog
    NRSKNUI:CreatePrompt(
        "Generated Presets Code",
        fullCode,
        true,
        "Copy this code into DungeonTimerPresets.lua",
        false, nil, nil, nil, nil,
        nil, nil,
        "Close", nil
    )

    print("NorskenUI: Presets code generated! Copy from the dialog.")
end
