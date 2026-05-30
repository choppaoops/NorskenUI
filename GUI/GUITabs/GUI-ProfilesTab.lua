---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local pairs = pairs
local ipairs = ipairs
local GetNumSpecializations = GetNumSpecializations
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecialization = GetSpecialization

local function BuildProfileOptions()
    local PM = NRSKNUI.ProfileManager
    if not PM then return {} end

    local profiles = PM:GetProfiles()
    local options = {}
    for _, name in pairs(profiles) do
        options[name] = name
    end
    return options
end

local function GetSpecInfo()
    local specs = {}
    local numSpecs = GetNumSpecializations()
    local currentSpec = GetSpecialization()
    for i = 1, numSpecs do
        local _, name = GetSpecializationInfo(i)
        specs[i] = { index = i, name = name, isCurrent = (i == currentSpec) }
    end
    return specs, currentSpec
end

GUIFrame:RegisterContent("ProfileSelector", function(scrollChild, yOffset)
    local PM = NRSKNUI.ProfileManager
    if not PM then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local db = NRSKNUI.db
    local useGlobal = PM:GetUseGlobalProfile()
    local currentProfile = PM:GetCurrentProfile()
    local profileOptions = BuildProfileOptions()
    local manager = GUIFrame:CreateWidgetStateManager()
    local specEnabled = db and db.IsDualSpecEnabled and db:IsDualSpecEnabled() or false

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Current Profile", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local profileDropdown = GUIFrame:CreateDropdown(row1, "Active Profile", {
        options = profileOptions,
        value = currentProfile,
        callback = function(key)
            if key == currentProfile then return end
            local success, err = PM:SetProfile(key)
            if not success then
                NRSKNUI:Print("Failed to switch profile: " .. (err or "Unknown error"))
            else
                NRSKNUI:CreatePrompt({
                    title = "Profile Changed",
                    text = "Profile switched to '" ..
                        key .. "'.\n\nA UI reload is recommended to fully apply all settings.",
                    onAccept = function() ReloadUI() end,
                    acceptText = "Reload Now",
                    cancelText = "Later",
                })
            end
        end
    })
    row1:AddWidget(profileDropdown, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    profileDropdown:SetEnabled(not useGlobal and not specEnabled)

    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2 = GUIFrame:CreateCard(scrollChild, "Global Profile", yOffset)

    local globalProfile = PM:GetGlobalProfile()

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local globalToggle = GUIFrame:CreateCheckbox(row2a, "Use Global Profile", {
        value = useGlobal,
        callback = function(newState)
            local success = PM:SetUseGlobalProfile(newState)
            if success then
                if newState then
                    NRSKNUI:CreatePrompt({
                        title = "Global Profile Enabled",
                        text = "Global profile mode enabled.\n\nA UI reload is recommended to fully apply all settings.",
                        onAccept = function() ReloadUI() end,
                        onCancel = function()
                            C_Timer.After(0.1, function()
                                if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                                    GUIFrame:RefreshContent()
                                end
                            end)
                        end,
                        acceptText = "Reload Now",
                        cancelText = "Later",
                    })
                else
                    NRSKNUI:Print("Global profile mode disabled")
                    C_Timer.After(0.1, function()
                        if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                            GUIFrame:RefreshContent()
                        end
                    end)
                end
            end
        end
    })
    row2a:AddWidget(globalToggle, 0.5)

    local globalDropdown = GUIFrame:CreateDropdown(row2a, "Global Profile", {
        options = profileOptions,
        value = globalProfile,
        callback = function(key)
            local success, err = PM:SetGlobalProfile(key)
            if not success then
                NRSKNUI:Print("Failed to set global profile: " .. (err or "Unknown error"))
            else
                if useGlobal then
                    NRSKNUI:CreatePrompt({
                        title = "Global Profile Changed",
                        text = "Global profile switched to '" ..
                            key .. "'.\n\nA UI reload is recommended to fully apply all settings.",
                        onAccept = function() ReloadUI() end,
                        acceptText = "Reload Now",
                        cancelText = "Later",
                    })
                else
                    NRSKNUI:Print("Global profile set to: " .. key)
                end
            end
        end
    })
    row2a:AddWidget(globalDropdown, 0.5)
    manager:Register(globalDropdown, "all")
    card2:AddRow(row2a, Theme.rowHeightLast, 0)

    manager:UpdateAll(useGlobal)

    yOffset = card2:GetNextOffset()

    -- Card 3: Specialization Profiles
    local specProfilesAvailable = db and db.IsDualSpecEnabled

    if specProfilesAvailable then
        local card3 = GUIFrame:CreateCard(scrollChild, "Specialization Profiles", yOffset)
        local specs = GetSpecInfo()
        local specWidgets = {}

        local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
        local specToggle = GUIFrame:CreateCheckbox(row3a, "Enable Spec Profiles", {
            value = specEnabled,
            callback = function(newState)
                db:SetDualSpecEnabled(newState)
                profileDropdown:SetEnabled(not useGlobal and not newState)
                for _, widget in ipairs(specWidgets) do
                    widget:SetEnabled(newState)
                end
            end
        })
        row3a:AddWidget(specToggle, 0.5)
        card3:AddRow(row3a, Theme.rowHeight)

        specToggle:SetEnabled(not useGlobal)

        local sepSpec = GUIFrame:CreateSeparator(card3.content)
        card3:AddRow(sepSpec, Theme.rowHeightSeparator)

        local numSpecs = #specs
        local widthPerSpec = numSpecs == 2 and 0.5 or (numSpecs == 3 and 0.33 or 0.25)

        local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
        for _, spec in ipairs(specs) do
            local label = spec.isCurrent and (spec.name .. " (Active)") or spec.name
            local specDropdown = GUIFrame:CreateDropdown(row3b, label, {
                options = profileOptions,
                value = db:GetDualSpecProfile(spec.index),
                callback = function(key)
                    db:SetDualSpecProfile(key, spec.index)
                end
            })
            row3b:AddWidget(specDropdown, widthPerSpec)
            specDropdown:SetEnabled(specEnabled and not useGlobal)
            specWidgets[#specWidgets + 1] = specDropdown
        end
        card3:AddRow(row3b, Theme.rowHeightLast, 0)

        yOffset = card3:GetNextOffset()
    end

    return yOffset
end)

GUIFrame:RegisterContent("ProfileActions", function(scrollChild, yOffset)
    local PM = NRSKNUI.ProfileManager
    if not PM then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local profileOptions = BuildProfileOptions()
    local currentProfile = PM:GetCurrentProfile()

    -- Card 1: Reset Profile
    local card1 = GUIFrame:CreateCard(scrollChild, "Reset Profile", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast - 9)

    local profileLabel = GUIFrame:CreateText(row1, "Current Profile: " .. NRSKNUI:ColorTextByTheme(currentProfile), {
        height = Theme.rowHeightLast - 9,
        bgMode = "hide",
    })
    row1:AddWidget(profileLabel, 0.5, nil, 0, -6)

    local resetBtn = GUIFrame:CreateButton(row1, "Reset to Defaults", {
        height = 30,
        callback = function()
            NRSKNUI:CreatePrompt({
                title = "Reset Profile",
                text = "Reset all settings in current profile to defaults?\nThis cannot be undone.",
                onAccept = function()
                    local success = PM:ResetProfile()
                    if not success then
                        NRSKNUI:Print("Failed to reset profile")
                    end
                end,
                acceptText = "Reset",
                cancelText = "Cancel",
            })
        end
    })
    row1:AddWidget(resetBtn, 0.5, nil, 0, -2)
    card1:AddRow(row1, Theme.rowHeightLast - 9, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Create New Profile
    local card2 = GUIFrame:CreateCard(scrollChild, "Create New Profile", yOffset)

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local newProfileInput = GUIFrame:CreateEditBox(row2, "Profile Name", { value = "" })
    row2:AddWidget(newProfileInput, 0.5)

    local createBtn = GUIFrame:CreateButton(row2, "Create", {
        width = 80,
        height = 24,
        callback = function()
            local name = newProfileInput:GetValue()
            if name and name ~= "" then
                local success, err = PM:CreateProfile(name)
                if success then
                    NRSKNUI:Print("Created profile: " .. name)
                    newProfileInput:SetValue("")
                    C_Timer.After(0.1, function()
                        if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                            GUIFrame:RefreshContent()
                        end
                    end)
                else
                    NRSKNUI:Print("Failed to create profile: " .. (err or "Unknown error"))
                end
            else
                NRSKNUI:Print("Please enter a profile name")
            end
        end
    })
    row2:AddWidget(createBtn, 0.5, nil, 0, -14)
    card2:AddRow(row2, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 2a
    local card2a = GUIFrame:CreateCard(scrollChild, "Copy Profile", yOffset)

    local row2a = GUIFrame:CreateRow(card2a.content, Theme.rowHeightLast)
    local copyDropdown = GUIFrame:CreateDropdown(row2a, "Source Profile", {
        options = profileOptions,
        value = ""
    })
    row2a:AddWidget(copyDropdown, 0.5)

    local copyBtn = GUIFrame:CreateButton(row2a, "Copy", {
        width = 80,
        height = 24,
        callback = function()
            local source = copyDropdown:GetValue()
            if source and source ~= "" then
                NRSKNUI:CreatePrompt({
                    title = "Copy Profile",
                    text = "Copy all settings from '" ..
                        source .. "' to current profile?\nThis will overwrite your current settings.",
                    onAccept = function()
                        local success, err = PM:CopyProfile(source)
                        if not success then
                            NRSKNUI:Print("Failed to copy profile: " .. (err or "Unknown error"))
                        end
                    end,
                    acceptText = "Copy",
                    cancelText = "Cancel",
                })
            else
                NRSKNUI:Print("Please select a source profile")
            end
        end
    })
    row2a:AddWidget(copyBtn, 0.5, nil, 0, -14)
    card2a:AddRow(row2a, Theme.rowHeightLast, 0)

    yOffset = card2a:GetNextOffset()

    -- Card 3
    local card3 = GUIFrame:CreateCard(scrollChild, "Rename Profile", yOffset)

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local renameDropdown = GUIFrame:CreateDropdown(row3a, "Profile to Rename", {
        options = profileOptions,
        value = ""
    })
    row3a:AddWidget(renameDropdown, 1)
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local newNameInput = GUIFrame:CreateEditBox(row3b, "New Name", { value = "" })
    row3b:AddWidget(newNameInput, 0.5)

    local renameBtn = GUIFrame:CreateButton(row3b, "Rename", {
        width = 80,
        height = 24,
        callback = function()
            local oldName = renameDropdown:GetValue()
            local newName = newNameInput:GetValue()

            if not oldName or oldName == "" then
                NRSKNUI:Print("Please select a profile to rename")
                return
            end

            if not newName or newName == "" then
                NRSKNUI:Print("Please enter a new name")
                return
            end

            local success, err = PM:RenameProfile(oldName, newName)
            if success then
                NRSKNUI:Print("Renamed '" .. oldName .. "' to '" .. newName .. "'")
                newNameInput:SetValue("")
                C_Timer.After(0.1, function()
                    if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                        GUIFrame:RefreshContent()
                    end
                end)
            else
                NRSKNUI:Print("Failed to rename: " .. (err or "Unknown error"))
            end
        end
    })
    row3b:AddWidget(renameBtn, 0.5, nil, 0, -14)
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4
    local card4 = GUIFrame:CreateCard(scrollChild, "Delete Profile", yOffset)

    local row4 = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local deleteDropdown = GUIFrame:CreateDropdown(row4, "Profile to Delete", {
        options = profileOptions,
        value = ""
    })
    row4:AddWidget(deleteDropdown, 0.5)

    local deleteBtn = GUIFrame:CreateButton(row4, "Delete", {
        width = 80,
        height = 24,
        callback = function()
            local toDelete = deleteDropdown:GetValue()
            if toDelete and toDelete ~= "" then
                if toDelete == PM:GetCurrentProfile() then
                    NRSKNUI:Print("Cannot delete the active profile")
                    return
                end
                NRSKNUI:CreatePrompt({
                    title = "Delete Profile",
                    text = "Are you sure you want to delete '" .. toDelete .. "'?\nThis cannot be undone.",
                    onAccept = function()
                        local success, err = PM:DeleteProfile(toDelete)
                        if success then
                            NRSKNUI:Print("Deleted profile: " .. toDelete)
                            C_Timer.After(0.1, function()
                                if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                                    GUIFrame:RefreshContent()
                                end
                            end)
                        else
                            NRSKNUI:Print("Failed to delete profile: " .. (err or "Unknown error"))
                        end
                    end,
                    acceptText = "Delete",
                    cancelText = "Cancel",
                })
            else
                NRSKNUI:Print("Please select a profile to delete")
            end
        end
    })
    row4:AddWidget(deleteBtn, 0.5, nil, 0, -14)
    card4:AddRow(row4, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    return yOffset
end)

GUIFrame:RegisterContent("ProfileImportExport", function(scrollChild, yOffset)
    local PM = NRSKNUI.ProfileManager
    if not PM then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Export Profile", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast - 9)
    local exportBtn = GUIFrame:CreateButton(row1, "Export Current Profile", {
        height = 30,
        callback = function()
            local exportString, err = PM:ExportProfile()
            if exportString then
                NRSKNUI:CreateCopyDialog("Export Profile", exportString, "Copy the string above (Ctrl+C)")
                NRSKNUI:Print("Export Success")
            else
                NRSKNUI:Print("Export failed: " .. (err or "Unknown error"))
            end
        end
    })
    row1:AddWidget(exportBtn, 1, nil, 0, -2)
    card1:AddRow(row1, Theme.rowHeightLast - 9, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2 = GUIFrame:CreateCard(scrollChild, "Import Profile", yOffset)

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast - 9)
    local importBtn = GUIFrame:CreateButton(row2, "Import from String", {
        height = 30,
        callback = function()
            NRSKNUI:CreatePrompt({
                title = "Import Profile",
                text = "",
                editBox = true,
                editBoxLabel = "Paste import string",
                onAccept = function(importString)
                    if not importString or importString == "" then return end

                    C_Timer.After(0.1, function()
                        NRSKNUI:CreatePrompt({
                            title = "Profile Name",
                            text = "",
                            editBox = true,
                            editBoxLabel = "Enter profile name (leave empty for original)",
                            onAccept = function(profileName)
                                local targetName = (profileName and profileName ~= "") and profileName or nil

                                local success, nameOrErr = PM:ImportProfile(importString, targetName)
                                if success then
                                    NRSKNUI:Print("Imported profile: " .. nameOrErr)
                                    C_Timer.After(0.1, function()
                                        if GUIFrame.mainFrame and GUIFrame.mainFrame:IsShown() then
                                            GUIFrame:RefreshContent()
                                        end
                                    end)
                                else
                                    NRSKNUI:Print("Import failed: " .. (nameOrErr or "Unknown error"))
                                end
                            end,
                            acceptText = "Import",
                            cancelText = "Cancel",
                        })
                    end)
                end,
                acceptText = "Next",
                cancelText = "Cancel",
            })
        end
    })
    row2:AddWidget(importBtn, 1, nil, 0, -2)
    card2:AddRow(row2, Theme.rowHeightLast - 9, 0)

    yOffset = card2:GetNextOffset()

    return yOffset
end)
