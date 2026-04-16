local internal = RunDirectorBiomeControl_Internal

local UNDERWORLD_REGION = "Underworld"
local SURFACE_REGION = "Surface"
local NPC_MODE_DEFAULT = 0
local NPC_MODE_DISABLED = 1
local NPC_MODE_FORCED = 2

local NPC_MODE_VALUES = {
    NPC_MODE_DEFAULT,
    NPC_MODE_DISABLED,
    NPC_MODE_FORCED,
}

local NPC_MODE_DISPLAY_VALUES = {
    [NPC_MODE_DEFAULT] = "Default",
    [NPC_MODE_DISABLED] = "Disabled",
    [NPC_MODE_FORCED] = "Forced",
}

local BIOME_REGION_BY_KEY = {}
for _, biome in ipairs(internal.biomeTabs or {}) do
    BIOME_REGION_BY_KEY[biome.key] = biome.region
end

local RANGE_FIELD_BY_MIN_KEY = {}
for _, field in ipairs(internal.specialRangeFields or {}) do
    RANGE_FIELD_BY_MIN_KEY[field.configKeyMin] = field
end

local ROOM_TYPE_LABELS = {
    Story = "Story",
    Trial = "Trial",
    Fountain = "Fountain",
    Shop = "Shop",
    MiniBoss = "Minibosses",
}

local ROOM_TYPE_ORDER = {
    "Story",
    "Trial",
    "Fountain",
    "Shop",
    "MiniBoss",
}

local FLAT_ROOM_TYPES = {
    Story = true,
    Trial = true,
    Fountain = true,
    Shop = true,
}

local PORTED_ROOM_BIOMES = {
    F = true,
    G = true,
    H = true,
    I = true,
    N = true,
    O = true,
    P = true,
}

local SPECIAL_STATE_FIELD_BY_KEY = {}
for _, field in ipairs(internal.specialStateFields or {}) do
    SPECIAL_STATE_FIELD_BY_KEY[field.configKey] = field
end

local function BuildEncodedValueLists(entry)
    local values = {}
    local displayValues = {}
    for index, value in ipairs(entry.modeValues or {}) do
        local encoded = index - 1
        values[#values + 1] = encoded
        displayValues[encoded] = (entry.modeDisplayValues and entry.modeDisplayValues[value]) or tostring(value)
    end
    return values, displayValues
end

local function BuildNpcModeNode(def)
    return {
        type = "dropdown",
        binds = { value = def.modeKey },
        values = NPC_MODE_VALUES,
        displayValues = NPC_MODE_DISPLAY_VALUES,
        controlWidth = 120,
    }
end

local function BuildNpcDepthNode(def)
    return {
        type = "steppedRange",
        binds = { min = def.configKeyMin, max = def.configKeyMax },
        min = def.minDefault,
        max = def.maxDefault,
        default = def.minDefault,
        defaultMax = def.maxDefault,
        valueWidth = 42,
        valueAlign = "center",
        visibleIf = { alias = def.modeKey, value = NPC_MODE_FORCED },
    }
end

local function BuildNpcBiomeRow(def)
    return {
        type = "split",
        firstSize = 110,
        children = {
            {
                type = "text",
                text = def.region,
                alignToFramePadding = true,
            },
            {
                type = "hstack",
                gap = 12,
                children = {
                    BuildNpcModeNode(def),
                    BuildNpcDepthNode(def),
                },
            },
        },
    }
end

local function BuildRoomModeNode(def)
    return {
        type = "dropdown",
        binds = { value = def.modeKey },
        values = NPC_MODE_VALUES,
        displayValues = NPC_MODE_DISPLAY_VALUES,
        controlWidth = 120,
    }
end

local function BuildRoomDepthNode(def)
    return {
        type = "steppedRange",
        binds = { min = def.configKeyMin, max = def.configKeyMax },
        min = def.minDefault,
        max = def.maxDefault,
        default = def.minDefault,
        defaultMax = def.maxDefault,
        valueWidth = 42,
        valueAlign = "center",
        visibleIf = { alias = def.modeKey, value = NPC_MODE_FORCED },
    }
end

local function BuildRoomDefinitionRow(def)
    return {
        type = "split",
        firstSize = 140,
        children = {
            {
                type = "text",
                text = def.label,
                alignToFramePadding = true,
            },
            {
                type = "hstack",
                gap = 12,
                children = {
                    BuildRoomModeNode(def),
                    BuildRoomDepthNode(def),
                },
            },
        },
    }
end

local function BuildBiomeRoomEntryModeNode(entry)
    local values, displayValues = BuildEncodedValueLists(entry)
    return {
        type = "dropdown",
        binds = { value = entry.modeKey },
        values = values,
        displayValues = displayValues,
        controlWidth = 160,
    }
end

local function BuildBiomeRoomEntryDepthNode(entry)
    if not entry.rangeConfigKeys then
        return nil
    end

    local rangeField = RANGE_FIELD_BY_MIN_KEY[entry.rangeConfigKeys.min]
    local minValue = rangeField and rangeField.min or 0
    local maxValue = rangeField and rangeField.max or 10

    local visibleValues = {}
    for _, value in ipairs(entry.rangeVisibleValues or {}) do
        local encoded = entry.modeValueLookup and entry.modeValueLookup[value]
        if encoded ~= nil then
            visibleValues[#visibleValues + 1] = encoded
        end
    end

    return {
        type = "steppedRange",
        binds = { min = entry.rangeConfigKeys.min, max = entry.rangeConfigKeys.max },
        min = minValue,
        max = maxValue,
        default = minValue,
        defaultMax = maxValue,
        valueWidth = 42,
        valueAlign = "center",
        visibleIf = #visibleValues > 0 and { alias = entry.modeKey, anyOf = visibleValues } or nil,
    }
end

local function BuildBiomeRoomEntryRow(entry)
    local depthNode = BuildBiomeRoomEntryDepthNode(entry)
    local controlChildren = {
        BuildBiomeRoomEntryModeNode(entry),
    }
    if depthNode ~= nil then
        controlChildren[#controlChildren + 1] = depthNode
    end

    local children = {
        {
            type = "split",
            firstSize = 140,
            children = {
                {
                    type = "text",
                    text = entry.label or entry.configKey or entry.modeKey,
                    alignToFramePadding = true,
                },
                {
                    type = "hstack",
                    gap = 12,
                    children = controlChildren,
                },
            },
        },
    }

    if type(entry.helpText) == "string" and entry.helpText ~= "" then
        children[#children + 1] = {
            type = "text",
            text = entry.helpText,
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    return {
        type = "vstack",
        gap = 4,
        children = children,
    }
end

local function BuildRoomSectionNode(title, definitions)
    local children = {}
    for _, def in ipairs(definitions or {}) do
        children[#children + 1] = BuildRoomDefinitionRow(def)
    end

    return {
        type = "collapsible",
        label = title,
        defaultOpen = true,
        children = {
            {
                type = "vstack",
                gap = 8,
                children = children,
            },
        },
    }
end

local function BuildBiomeRoomsNode(biomeKey)
    local biomeDefinitions = internal.biomeDefinitions[biomeKey] or {}
    local biomeRoomEntries = internal.biomeRoomEntries[biomeKey] or {}
    local roomSections = {}
    local roomRows = {}
    local groupedBiomeEntries = {}

    for _, entry in ipairs(biomeRoomEntries) do
        local groupKey = entry.roomGroup or "Rooms"
        groupedBiomeEntries[groupKey] = groupedBiomeEntries[groupKey] or {}
        groupedBiomeEntries[groupKey][#groupedBiomeEntries[groupKey] + 1] = entry
    end

    for _, typeKey in ipairs(ROOM_TYPE_ORDER) do
        local definitions = biomeDefinitions[typeKey]
        if definitions and #definitions > 0 then
            if FLAT_ROOM_TYPES[typeKey] then
                for _, def in ipairs(definitions) do
                    roomRows[#roomRows + 1] = BuildRoomDefinitionRow(def)
                end
            else
                roomSections[#roomSections + 1] = BuildRoomSectionNode(
                    ROOM_TYPE_LABELS[typeKey] or typeKey,
                    definitions
                )
            end
        end

        local extraEntries = groupedBiomeEntries[typeKey]
        if extraEntries and #extraEntries > 0 then
            if FLAT_ROOM_TYPES[typeKey] then
                for _, entry in ipairs(extraEntries) do
                    roomRows[#roomRows + 1] = BuildBiomeRoomEntryRow(entry)
                end
            else
                local entryRows = {}
                for _, entry in ipairs(extraEntries) do
                    entryRows[#entryRows + 1] = BuildBiomeRoomEntryRow(entry)
                end
                roomSections[#roomSections + 1] = {
                    type = "collapsible",
                    label = ROOM_TYPE_LABELS[typeKey] or typeKey,
                    defaultOpen = true,
                    children = {
                        {
                            type = "vstack",
                            gap = 8,
                            children = entryRows,
                        },
                    },
                }
            end
        end
    end

    if #roomRows > 0 then
        table.insert(roomSections, 1, {
            type = "collapsible",
            label = "Rooms",
            defaultOpen = true,
            children = {
                {
                    type = "vstack",
                    gap = 8,
                    children = roomRows,
                },
            },
        })
    end

    if #roomSections == 0 then
        roomSections[1] = {
            type = "text",
            text = "This biome has not been ported yet.",
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    return {
        type = "vstack",
        gap = 12,
        children = roomSections,
    }
end

local function BuildBiomeSpecialEntryNode(special)
    if special.kind == "checkbox" then
        local children = {
            {
                type = "checkbox",
                label = special.label or special.configKey,
                binds = { value = special.configKey },
            },
        }

        if type(special.helpText) == "string" and special.helpText ~= "" then
            children[#children + 1] = {
                type = "text",
                text = special.helpText,
                color = { 0.65, 0.65, 0.65, 1.0 },
            }
        end

        return {
            type = "vstack",
            gap = 4,
            children = children,
        }
    end

    return {
        type = "text",
        text = special.label or special.configKey or "Unsupported special control",
        color = { 0.65, 0.65, 0.65, 1.0 },
    }
end

local function BuildBiomeSpecialsNode(biomeKey)
    local specials = internal.biomeSpecials[biomeKey] or {}
    if #specials == 0 then
        return nil
    end

    local children = {}
    for _, special in ipairs(specials) do
        children[#children + 1] = BuildBiomeSpecialEntryNode(special)
    end

    return {
        type = "collapsible",
        label = "Special",
        defaultOpen = true,
        children = {
            {
                type = "vstack",
                gap = 10,
                children = children,
            },
        },
    }
end

local function BuildRewardFieldNode(reward)
    local field = SPECIAL_STATE_FIELD_BY_KEY[reward.configKey]
    if not field then
        return {
            type = "text",
            text = reward.label or reward.configKey or "Unknown reward field",
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    local children = {}
    if field.type == "dropdown" then
        children[#children + 1] = {
            type = "dropdown",
            label = field.label or reward.label or field.configKey,
            binds = { value = field.configKey },
            values = field.values,
            displayValues = field.displayValues,
            controlWidth = 180,
        }
    elseif field.type == "checkbox" then
        children[#children + 1] = {
            type = "checkbox",
            label = field.label or reward.label or field.configKey,
            binds = { value = field.configKey },
        }
    else
        children[#children + 1] = {
            type = "text",
            text = field.label or reward.label or field.configKey,
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    if type(reward.helpText) == "string" and reward.helpText ~= "" then
        children[#children + 1] = {
            type = "text",
            text = reward.helpText,
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    return {
        type = "vstack",
        gap = 4,
        children = children,
    }
end

local function BuildPackedRewardNode(reward)
    local children = {
        {
            type = "text",
            text = reward.label or reward.configKey,
        },
        {
            type = "packedCheckboxList",
            binds = { value = reward.configKey },
        },
    }

    if type(reward.helpText) == "string" and reward.helpText ~= "" then
        children[#children + 1] = {
            type = "text",
            text = reward.helpText,
            color = { 0.65, 0.65, 0.65, 1.0 },
        }
    end

    return {
        type = "vstack",
        gap = 4,
        children = children,
    }
end

local function BuildBiomeRewardsNode(biomeKey)
    local rewards = internal.biomeRewards[biomeKey] or {}
    if #rewards == 0 then
        return nil
    end

    local children = {}
    for _, reward in ipairs(rewards) do
        if reward.kind == "field" then
            children[#children + 1] = BuildRewardFieldNode(reward)
        elseif reward.kind == "packedCheckboxes" then
            children[#children + 1] = BuildPackedRewardNode(reward)
        end
    end

    if #children == 0 then
        return nil
    end

    return {
        type = "collapsible",
        label = "Rewards",
        defaultOpen = true,
        children = {
            {
                type = "vstack",
                gap = 10,
                children = children,
            },
        },
    }
end

local function BuildNpcGroupNode(group)
    local children = {
        {
            type = "text",
            text = group.label,
        },
    }

    for _, def in ipairs(group.definitions or {}) do
        children[#children + 1] = BuildNpcBiomeRow(def)
    end

    return {
        type = "vstack",
        gap = 8,
        children = children,
    }
end

local function BuildNpcSettingsNode()
    return {
        type = "collapsible",
        label = "Encounter Rules",
        defaultOpen = true,
        children = {
            {
                type = "checkbox",
                label = "Only Allow Forced NPC Encounters",
                binds = { value = "OnlyAllowForcedEncounters" },
            },
            {
                type = "text",
                text = "Blocks NPC encounters left on Default. Only Forced entries can appear.",
                color = { 0.65, 0.65, 0.65, 1.0 },
            },
            {
                type = "checkbox",
                label = "Ignore NPC Max Depth Requirements",
                binds = { value = "IgnoreMaxDepth" },
            },
            {
                type = "text",
                text = "Forced NPC encounters can still appear after max depth.",
                color = { 0.65, 0.65, 0.65, 1.0 },
            },
            {
                type = "stepper",
                label = "Global NPC Spacing",
                binds = { value = "NPCSpacing" },
                min = 1,
                max = 12,
                valueWidth = 36,
                valueAlign = "center",
            },
            {
                type = "text",
                text = "Minimum rooms between field NPC encounters.",
                color = { 0.65, 0.65, 0.65, 1.0 },
            },
        },
    }
end

local function BuildNpcTabNode(region)
    local npcChildren = {
        BuildNpcSettingsNode(),
    }

    for _, groupId in ipairs(internal.npcGroups and internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupId]
        local regionDefinitions = {}
        for _, def in ipairs(group and group.definitions or {}) do
            if BIOME_REGION_BY_KEY[def.biome] == region then
                regionDefinitions[#regionDefinitions + 1] = def
            end
        end
        if #regionDefinitions > 0 then
            npcChildren[#npcChildren + 1] = BuildNpcGroupNode({
                label = group.label,
                definitions = regionDefinitions,
            })
        end
    end

    return {
        type = "vstack",
        tabLabel = "NPCs",
        gap = 14,
        children = npcChildren,
    }
end

local function BuildBiomePlaceholderNode(biome)
    if PORTED_ROOM_BIOMES[biome.key] then
        local children = {
            BuildBiomeRoomsNode(biome.key),
        }

        local rewardsNode = BuildBiomeRewardsNode(biome.key)
        if rewardsNode ~= nil then
            children[#children + 1] = rewardsNode
        end

        local specialsNode = BuildBiomeSpecialsNode(biome.key)
        if specialsNode ~= nil then
            children[#children + 1] = specialsNode
        end

        return {
            type = "vstack",
            tabLabel = biome.label,
            gap = 12,
            children = children,
        }
    end

    return {
        type = "vstack",
        tabLabel = biome.label,
        children = {
            { type = "text", text = biome.label },
            { type = "text", text = "Biome Control v2 shell", color = { 0.65, 0.65, 0.65, 1.0 } },
            { type = "text", text = "This biome has not been ported yet.", color = { 0.65, 0.65, 0.65, 1.0 } },
        },
    }
end

local function BuildRegionTabsNode(region)
    local tabChildren = {
        BuildNpcTabNode(region),
    }
    for _, biome in ipairs(internal.biomeTabs or {}) do
        if biome.region == region then
            table.insert(tabChildren, BuildBiomePlaceholderNode(biome))
        end
    end
    return {
        type = "vstack",
        tabLabel = region,
        gap = 8,
        children = {
            {
                type = "tabs",
                id = "BiomeControl" .. region .. "Tabs",
                orientation = "vertical",
                navWidth = 180,
                children = tabChildren,
            },
        },
    }
end

local function BuildSettingsTabNode()
    return {
        type = "vstack",
        tabLabel = "Settings",
        gap = 10,
        children = {
            {
                type = "collapsible",
                label = "Route Reward Priorities",
                defaultOpen = true,
                children = {
                    {
                        type = "checkbox",
                        label = "Choose First Boon in Each Biome",
                        binds = { value = "PrioritizeSpecificRewardEnabled" },
                    },
                    {
                        type = "text",
                        text = "(Uses route order: Biome 1 through Biome 4)",
                        color = { 0.65, 0.65, 0.65, 1.0 },
                    },
                    {
                        type = "vstack",
                        gap = 8,
                        visibleIf = { alias = "PrioritizeSpecificRewardEnabled", value = true },
                        children = {
                            {
                                type = "dropdown",
                                label = "Route Biome 1 Priority",
                                binds = { value = "PriorityBiome1" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                            {
                                type = "dropdown",
                                label = "Route Biome 2 Priority",
                                binds = { value = "PriorityBiome2" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                            {
                                type = "dropdown",
                                label = "Route Biome 3 Priority",
                                binds = { value = "PriorityBiome3" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                            {
                                type = "dropdown",
                                label = "Route Biome 4 Priority",
                                binds = { value = "PriorityBiome4" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                        },
                    },
                },
            },
            {
                type = "collapsible",
                label = "Trial Reward Priorities",
                defaultOpen = true,
                children = {
                    {
                        type = "checkbox",
                        label = "Choose Boon Priorities in Trial Rooms",
                        binds = { value = "PrioritizeTrialRewardEnabled" },
                    },
                    {
                        type = "vstack",
                        gap = 8,
                        visibleIf = { alias = "PrioritizeTrialRewardEnabled", value = true },
                        children = {
                            {
                                type = "dropdown",
                                label = "Trial Priority A",
                                binds = { value = "PriorityTrial1" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                            {
                                type = "dropdown",
                                label = "Trial Priority B",
                                binds = { value = "PriorityTrial2" },
                                values = internal.priorityOptions,
                                displayValues = internal.priorityDisplayValues,
                                controlWidth = 180,
                            },
                        },
                    },
                },
            },
        },
    }
end

function internal.BuildUiV2DefinitionUi()
    return {
        {
            type = "vstack",
            children = {
                {
                    type = "text",
                    text = "Configure biome rooms, assist NPC encounters, rewards, and biome-specific tweaks.",
                },
                {
                    type = "tabs",
                    id = "BiomeControlRootTabs",
                    children = {
                        BuildRegionTabsNode(UNDERWORLD_REGION),
                        BuildRegionTabsNode(SURFACE_REGION),
                        BuildSettingsTabNode(),
                    },
                },
            },
        },
    }
end

function internal.DrawQuickContent(ui, theme)
    local colors = theme and theme.colors

    if colors and colors.info then
        ui.TextColored(colors.info[1], colors.info[2], colors.info[3], colors.info[4], "Biome Control")
    else
        ui.Text("Biome Control")
    end
    ui.Text("v2 shell active")
end
