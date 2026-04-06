local internal = RunDirectorBiomeControl_Internal

local DEFAULT_FIELD_MEDIUM = internal.DEFAULT_FIELD_MEDIUM
local REGION_UNDERWORLD = internal.REGION_UNDERWORLD
-- local REGION_SURFACE = internal.REGION_SURFACE
local REGION_OPTIONS = internal.REGION_OPTIONS
local GetPackedModeValue = internal.GetPackedModeValue
local SetPackedModeValue = internal.SetPackedModeValue
local GetPackedModeDisplay = internal.GetPackedModeDisplay

local TYPE_ORDER = { "Story", "Trial", "Shop", "Fountain", "MiniBoss" }
local NON_MINIBOSS_TYPE_ORDER = { "Story", "Trial", "Shop", "Fountain" }

local function IsBiomeVisible(biome)
    local isUnderworld = biome == "F" or biome == "G" or biome == "H" or biome == "I"
    if internal.regionFilter == REGION_UNDERWORLD then
        return isUnderworld
    end
    return not isUnderworld
end

local function IsPackedOptionChecked(uiState, configKey, bit)
    local packed = uiState.get(configKey) or 0
    return bit32.band(packed, bit32.lshift(1, bit)) ~= 0
end

local function SetPackedOptionChecked(uiState, configKey, bit, enabled)
    local packed = uiState.get(configKey) or 0
    local mask = bit32.lshift(1, bit)
    local newValue
    if enabled then
        newValue = bit32.bor(packed, mask)
    else
        newValue = bit32.band(packed, bit32.bnot(mask))
    end
    if newValue ~= packed then
        uiState.set(configKey, newValue)
    end
end

local function DrawManagedField(ui, uiState, alias, width)
    local node = internal.uiNodes[alias]
    if not node then return end
    lib.drawUiNode(ui, node, uiState, width)
end

local function GetChoiceDisplay(node, value)
    if node and node.displayValues and node.displayValues[value] ~= nil then
        return tostring(node.displayValues[value])
    end
    return tostring(value)
end

local function DrawChoiceValuesAsRadio(ui, currentValue, values, displayValues, onSelect)
    if not values then return end
    for index, value in ipairs(values) do
        if index > 1 then
            ui.SameLine()
        end
        local label = displayValues and displayValues[value] or tostring(value)
        if ui.RadioButton(label, currentValue == value) then
            onSelect(value)
            currentValue = value
        end
    end
end

local function IsBiomeRoomEntryVisible(uiState, entry)
    if not entry.visibleIfConfigKey then
        return true
    end

    local value = uiState.view[entry.visibleIfConfigKey]
    if entry.visibleIfValue ~= nil then
        return value == entry.visibleIfValue
    end
    if entry.visibleIfValues then
        for _, expected in ipairs(entry.visibleIfValues) do
            if value == expected then
                return true
            end
        end
        return false
    end
    return value == true
end

local function GetDefinitionEditorKey(def)
    return def.modeKey
end

local function GetDefinitionMode(uiState, def)
    return GetPackedModeValue(function(configKey)
        return uiState.view[configKey]
    end, def)
end

local function GetDefinitionSummary(uiState, def)
    local mode = GetDefinitionMode(uiState, def)
    if mode == "forced" then
        local currentMin = uiState.view[def.configKeyMin]
        local currentMax = uiState.view[def.configKeyMax]
        return string.format("%s %d-%d", GetPackedModeDisplay(def, mode), currentMin, currentMax)
    end
    return GetPackedModeDisplay(def, mode)
end

local function DrawDefinitionEntry(ui, uiState, def, depthWidth)
    local editorKey = GetDefinitionEditorKey(def)
    local isEditing = internal.activeRoomEditorKey == editorKey
    local mode = GetDefinitionMode(uiState, def)

    ui.PushID(editorKey)
    ui.Text(def.label)
    ui.SameLine()
    ui.TextDisabled(GetDefinitionSummary(uiState, def))
    ui.SameLine()
    if isEditing then
        if ui.Button("Done") then
            internal.activeRoomEditorKey = nil
            isEditing = false
        end
    else
        if ui.Button("Edit") then
            internal.activeRoomEditorKey = editorKey
            isEditing = true
        end
    end

    if isEditing then
        ui.Indent()
        DrawChoiceValuesAsRadio(ui, mode, def.modeValues, def.modeDisplayValues, function(value)
            SetPackedModeValue(uiState, def, value)
        end)
        mode = GetDefinitionMode(uiState, def)
        if mode == "forced" then
            DrawManagedField(ui, uiState, def.configKeyMin, depthWidth)
        end
        ui.Unindent()
    end
    ui.PopID()
end

local function FindNPCDefinition(group, biomeCode)
    return group.lookup and group.lookup[biomeCode]
end

local function GetNPCGroupSummary(uiState, group)
    local mode = GetPackedModeValue(function(configKey)
        return uiState.view[configKey]
    end, group)
    local summary = GetPackedModeDisplay(group, mode)
    local def = FindNPCDefinition(group, mode)
    if def then
        local currentMin = uiState.view[def.configKeyMin]
        local currentMax = uiState.view[def.configKeyMax]
        summary = string.format("%s %d-%d", summary, currentMin, currentMax)
    end
    return summary
end

local function DrawNPCGroupEntry(ui, uiState, group, depthWidth)
    local editorKey = group.modeKey
    local isEditing = internal.activeNPCEditorKey == editorKey
    local mode = GetPackedModeValue(function(configKey)
        return uiState.view[configKey]
    end, group)

    ui.PushID(editorKey)
    ui.Text(group.label)
    ui.SameLine()
    ui.TextDisabled(GetNPCGroupSummary(uiState, group))
    ui.SameLine()
    if isEditing then
        if ui.Button("Done") then
            internal.activeNPCEditorKey = nil
            isEditing = false
        end
    else
        if ui.Button("Edit") then
            internal.activeNPCEditorKey = editorKey
            isEditing = true
        end
    end

    if isEditing then
        ui.Indent()
        DrawChoiceValuesAsRadio(ui, mode, group.modeValues, group.modeDisplayValues, function(value)
            SetPackedModeValue(uiState, group, value)
        end)
        mode = GetPackedModeValue(function(configKey)
            return uiState.view[configKey]
        end, group)
        local def = FindNPCDefinition(group, mode)
        if def then
            DrawManagedField(ui, uiState, def.configKeyMin, depthWidth)
        end
        ui.Unindent()
    end
    ui.PopID()
end

local function GetRoomEntryEditorKey(entry)
    return entry.modeKey or entry.configKey
end

local function IsRoomEntryRangeVisible(uiState, entry)
    if not entry.rangeConfigKeys then
        return false
    end
    local value
    if entry.kind == "modeField" then
        value = GetPackedModeValue(function(configKey)
            return uiState.view[configKey]
        end, entry)
    else
        value = uiState.view[entry.configKey]
    end
    for _, expected in ipairs(entry.rangeVisibleValues or {}) do
        if value == expected then
            return true
        end
    end
    return false
end

local function GetRoomEntrySummary(uiState, entry)
    local summary
    if entry.kind == "modeField" then
        local value = GetPackedModeValue(function(configKey)
            return uiState.view[configKey]
        end, entry)
        summary = GetPackedModeDisplay(entry, value)
    else
        local node = internal.uiNodes[entry.configKey]
        if not node then return "" end
        local value = uiState.view[entry.configKey]
        summary = GetChoiceDisplay(node, value)
    end
    if IsRoomEntryRangeVisible(uiState, entry) then
        local minValue = uiState.view[entry.rangeConfigKeys.min]
        local maxValue = uiState.view[entry.rangeConfigKeys.max]
        summary = string.format("%s %d-%d", summary, minValue, maxValue)
    end
    return summary
end

local function DrawRoomEntry(ui, uiState, entry, depthWidth)
    local node = entry.kind ~= "modeField" and internal.uiNodes[entry.configKey] or nil

    local editorKey = GetRoomEntryEditorKey(entry)
    local isEditing = internal.activeRoomEditorKey == editorKey

    ui.PushID(editorKey)
    ui.Text(entry.label or (node and node.label) or entry.configKey)
    ui.SameLine()
    ui.TextDisabled(GetRoomEntrySummary(uiState, entry))
    ui.SameLine()
    if isEditing then
        if ui.Button("Done") then
            internal.activeRoomEditorKey = nil
            isEditing = false
        end
    else
        if ui.Button("Edit") then
            internal.activeRoomEditorKey = editorKey
            isEditing = true
        end
    end

    if isEditing then
        ui.Indent()
        if entry.kind == "modeField" then
            local value = GetPackedModeValue(function(configKey)
                return uiState.view[configKey]
            end, entry)
            DrawChoiceValuesAsRadio(ui, value, entry.modeValues, entry.modeDisplayValues, function(modeValue)
                SetPackedModeValue(uiState, entry, modeValue)
            end)
        elseif node then
            DrawChoiceValuesAsRadio(ui, uiState.view[entry.configKey], node.values, node.displayValues, function(value)
                uiState.set(entry.configKey, value)
            end)
        end
        if IsRoomEntryRangeVisible(uiState, entry) then
            DrawManagedField(ui, uiState, entry.rangeConfigKeys.min, depthWidth)
        end
        if entry.helpText and entry.helpText ~= "" then
            ui.TextDisabled(entry.helpText)
        end
        ui.Unindent()
    end
    ui.PopID()
end

local function DrawRegionFilter(ui)
    ui.Text("View Region:")
    for _, option in ipairs(REGION_OPTIONS) do
        ui.SameLine()
        if ui.RadioButton(option.label, internal.regionFilter == option.value) then
            internal.regionFilter = option.value
            store.write("ViewRegion", internal.regionFilter)
        end
    end
end

local function IsNPCGroupVisible(group)
    if not group or not group.definitions or #group.definitions == 0 then
        return true
    end

    local wantsUnderworld = internal.regionFilter == REGION_UNDERWORLD
    for _, def in ipairs(group.definitions) do
        local isUnderworldBiome = def.biome == "F" or def.biome == "G" or def.biome == "H" or def.biome == "I"
        if wantsUnderworld == isUnderworldBiome then
            return true
        end
    end
    return false
end

local function DrawBiomeSections(ui, uiState, biome, depthWidth)
    local biomeDefs = internal.biomeDefinitions[biome] or {}
    local biomeRoomEntries = internal.biomeRoomEntries[biome] or {}
    local biomeRewards = internal.biomeRewards[biome] or {}
    local biomeSpecials = internal.biomeSpecials[biome] or {}
    local drewAnything = false

    local hasRooms = false
    for _, typeKey in ipairs(TYPE_ORDER) do
        local defs = biomeDefs[typeKey]
        if defs and #defs > 0 then
            hasRooms = true
            break
        end
    end
    if not hasRooms then
        for _, entry in ipairs(biomeRoomEntries) do
            if IsBiomeRoomEntryVisible(uiState, entry) then
                hasRooms = true
                break
            end
        end
    end

    if hasRooms then
        drewAnything = true
        if ui.CollapsingHeader("Rooms", 32) then
            ui.Indent()
            for _, typeKey in ipairs(NON_MINIBOSS_TYPE_ORDER) do
                local defs = biomeDefs[typeKey]
                if defs and #defs > 0 then
                    for _, def in ipairs(defs) do
                        DrawDefinitionEntry(ui, uiState, def, depthWidth)
                    end
                end
                for _, entry in ipairs(biomeRoomEntries) do
                    if entry.roomGroup == typeKey and IsBiomeRoomEntryVisible(uiState, entry) then
                        DrawRoomEntry(ui, uiState, entry, depthWidth)
                    end
                end
            end

            local minibossDefs = biomeDefs.MiniBoss
            local hasMiniBossEntries = false
            for _, entry in ipairs(biomeRoomEntries) do
                if entry.roomGroup == "MiniBoss" and IsBiomeRoomEntryVisible(uiState, entry) then
                    hasMiniBossEntries = true
                    break
                end
            end
            if (minibossDefs and #minibossDefs > 0) or hasMiniBossEntries then
                ui.Spacing()
                ui.Separator()
                ui.TextDisabled("Minibosses")
                if minibossDefs and #minibossDefs > 0 then
                    for _, def in ipairs(minibossDefs) do
                        DrawDefinitionEntry(ui, uiState, def, depthWidth)
                    end
                end
                for _, entry in ipairs(biomeRoomEntries) do
                    if entry.roomGroup == "MiniBoss" and IsBiomeRoomEntryVisible(uiState, entry) then
                        DrawRoomEntry(ui, uiState, entry, depthWidth)
                    end
                end
            end
            ui.Unindent()
        end
        ui.Spacing()
    end

    if #biomeRewards > 0 then
        drewAnything = true
        if ui.CollapsingHeader("Rewards") then
            ui.Indent()
            for _, reward in ipairs(biomeRewards) do
                if reward.kind == "field" then
                    DrawManagedField(ui, uiState, reward.configKey, depthWidth * 2)
                    if reward.helpText and reward.helpText ~= "" then
                        ui.TextDisabled(reward.helpText)
                    end
                elseif reward.kind == "packedCheckboxes" then
                    ui.Text(reward.label)
                    ui.Indent()
                    for _, option in ipairs(reward.options or {}) do
                        local checked = IsPackedOptionChecked(uiState, reward.configKey, option.bit)
                        local value, changed = ui.Checkbox(option.label, checked)
                        if changed then
                            SetPackedOptionChecked(uiState, reward.configKey, option.bit, value)
                        end
                    end
                    if reward.helpText and reward.helpText ~= "" then
                        ui.TextDisabled(reward.helpText)
                    end
                    ui.Unindent()
                end
            end
            ui.Unindent()
        end
        ui.Spacing()
    end

    if #biomeSpecials > 0 then
        drewAnything = true
        if ui.CollapsingHeader("Special") then
            ui.Indent()
            for _, special in ipairs(biomeSpecials) do
                if special.kind == "checkbox" then
                    local value, changed = ui.Checkbox(special.label, uiState.view[special.configKey] == true)
                    if changed then
                        uiState.set(special.configKey, value)
                    end
                    if special.helpText and special.helpText ~= "" then
                        ui.TextDisabled(special.helpText)
                    end
                end
            end
            ui.Unindent()
        end
        ui.Spacing()
    end

    if not drewAnything then
        ui.TextDisabled("No biome controls yet.")
    end
end

local function DrawSettingsTab(ui, uiState, width)
    ui.Text("Biome tabs are filtered by route.")
    ui.TextDisabled("(Switch between Underworld and Surface above to reduce tab clutter)")
    ui.Spacing()
    ui.Separator()
    ui.Spacing()

    ui.Text("Route Reward Priorities")
    local biomeToggle, biomeToggleChanged =
        ui.Checkbox("Choose First Boon in Each Biome", uiState.view.PrioritizeSpecificRewardEnabled == true)
    if biomeToggleChanged then
        uiState.set("PrioritizeSpecificRewardEnabled", biomeToggle)
    end
    ui.TextDisabled("(Uses route order: Biome 1 through Biome 4)")
    if uiState.view.PrioritizeSpecificRewardEnabled then
        ui.Indent()
        DrawManagedField(ui, uiState, "PriorityBiome1", width)
        DrawManagedField(ui, uiState, "PriorityBiome2", width)
        DrawManagedField(ui, uiState, "PriorityBiome3", width)
        DrawManagedField(ui, uiState, "PriorityBiome4", width)
        ui.Unindent()
    end

    ui.Spacing()
    ui.Separator()
    ui.Spacing()

    ui.Text("Trial Reward Priorities")
    local trialToggle, trialToggleChanged =
        ui.Checkbox("Choose Boon Priorities in Trial Rooms", uiState.view.PrioritizeTrialRewardEnabled == true)
    if trialToggleChanged then
        uiState.set("PrioritizeTrialRewardEnabled", trialToggle)
    end
    if uiState.view.PrioritizeTrialRewardEnabled then
        ui.Indent()
        DrawManagedField(ui, uiState, "PriorityTrial1", width)
        DrawManagedField(ui, uiState, "PriorityTrial2", width)
        ui.Unindent()
    end
end

local function DrawNPCTab(ui, uiState, width, depthWidth)
    ui.Text("NPC Encounter Rules")
    ui.Spacing()

    local visibleGroups = {}
    for _, npcId in ipairs(internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[npcId]
        if IsNPCGroupVisible(group) then
            table.insert(visibleGroups, group)
        end
    end

    if #visibleGroups > 0 and ui.CollapsingHeader("NPCs", 32) then
        ui.Indent()
        for index, group in ipairs(visibleGroups) do
            DrawNPCGroupEntry(ui, uiState, group, depthWidth)
            if index < #visibleGroups then
                ui.Spacing()
                ui.Separator()
                ui.Spacing()
            end
        end
        ui.Unindent()
        ui.Spacing()
    end

    if ui.CollapsingHeader("Settings") then
        ui.Indent()

        local strictVal, strictChanged =
            ui.Checkbox("Only Allow Forced NPC Encounters", uiState.view.OnlyAllowForcedEncounters == true)
        if strictChanged then
            uiState.set("OnlyAllowForcedEncounters", strictVal)
        end
        ui.TextDisabled("(Blocks NPC encounters left on Default. Only Forced entries can appear.)")

        ui.Spacing()
        ui.Separator()
        ui.Spacing()

        local ignoreVal, ignoreChanged =
            ui.Checkbox("Ignore NPC Max Depth Requirements", uiState.view.IgnoreMaxDepth == true)
        if ignoreChanged then
            uiState.set("IgnoreMaxDepth", ignoreVal)
        end
        ui.TextDisabled("(Forced NPC encounters can still appear after max depth)")

        ui.Spacing()
        ui.Separator()
        ui.Spacing()

        DrawManagedField(ui, uiState, "NPCSpacing", width)
        ui.TextDisabled("(Minimum rooms between field NPC encounters)")

        ui.Unindent()
    end
end

function internal.DrawTab(ui, uiState, theme)
    local colors = theme and theme.colors
    local fieldMedium = (theme and theme.FIELD_MEDIUM) or DEFAULT_FIELD_MEDIUM
    local winW = ui.GetWindowWidth()
    local stepperWidth = winW * fieldMedium
    local depthWidth = stepperWidth * 0.5

    ui.Spacing()
    if colors and colors.info then
        ui.TextColored(colors.info[1], colors.info[2], colors.info[3], colors.info[4],
            "Configure biome rooms, assist NPC encounters, rewards, and biome-specific tweaks.")
    else
        ui.Text("Configure biome rooms, assist NPC encounters, rewards, and biome-specific tweaks.")
    end
    ui.Spacing()
    DrawRegionFilter(ui)
    ui.Separator()
    ui.Spacing()

    if ui.BeginTabBar("BiomeControlTabs") then
        if ui.BeginTabItem("Settings") then
            DrawSettingsTab(ui, uiState, stepperWidth)
            ui.EndTabItem()
        end

        if ui.BeginTabItem("NPCs") then
            DrawNPCTab(ui, uiState, stepperWidth, depthWidth)
            ui.EndTabItem()
        end

        for _, biome in ipairs(internal.biomeTabs) do
            if IsBiomeVisible(biome.key) and ui.BeginTabItem(biome.label) then
                DrawBiomeSections(ui, uiState, biome.key, depthWidth)
                ui.EndTabItem()
            end
        end

        ui.EndTabBar()
    end
end

function internal.DrawQuickContent(ui, uiState, theme)
    local colors = theme and theme.colors
    local enabledCount = 0
    for _, def in ipairs(internal.roomDefinitions) do
        if GetDefinitionMode(uiState, def) ~= def.defaultMode then
            enabledCount = enabledCount + 1
        end
    end
    for _, npcId in ipairs(internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[npcId]
        local value = GetPackedModeValue(function(configKey)
            return uiState.view[configKey]
        end, group)
        if value ~= group.defaultMode then
            enabledCount = enabledCount + 1
        end
    end
    local seenEntries = {}
    for _, entries in pairs(internal.biomeRoomEntries or {}) do
        for _, entry in ipairs(entries) do
            local entryKey = entry.modeKey or entry.configKey
            if entryKey and not seenEntries[entryKey] then
                seenEntries[entryKey] = true
                if entry.kind == "modeField" then
                    local value = GetPackedModeValue(function(configKey)
                        return uiState.view[configKey]
                    end, entry)
                    if value and value ~= entry.defaultMode then
                        enabledCount = enabledCount + 1
                    end
                else
                    local node = internal.uiNodes[entry.configKey]
                    local value = node and (uiState.view[entry.configKey] or node.default)
                    if value and value ~= "default" then
                        enabledCount = enabledCount + 1
                    end
                end
            end
        end
    end

    if colors and colors.info then
        ui.TextColored(colors.info[1], colors.info[2], colors.info[3], colors.info[4], "Biome Control")
    else
        ui.Text("Biome Control")
    end
    ui.Text(string.format("%d biome control rules enabled", enabledCount))
end
