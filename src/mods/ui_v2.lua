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

local NPC_SPACING_VALUES = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }

local NPC_GROUP_COLORS = {
    Artemis = { 15 / 255, 255 / 255, 9 / 255, 1.0 },
    Nemesis = { 115 / 255, 146 / 255, 210 / 255, 1.0 },
    Athena = { 255 / 255, 216 / 255, 60 / 255, 1.0 },
    Heracles = { 255 / 255, 125 / 255, 25 / 255, 1.0 },
    Icarus = { 243 / 255, 215 / 255, 116 / 255, 1.0 },
}

local BIOME_REGION_BY_KEY = {}
for _, biome in ipairs(internal.biomeTabs or {}) do
    BIOME_REGION_BY_KEY[biome.key] = biome.region
end

local RANGE_FIELD_BY_MIN_KEY = {}
for _, field in ipairs(internal.specialRangeFields or {}) do
    RANGE_FIELD_BY_MIN_KEY[field.configKeyMin] = field
end

local BIOME_SECTION_COLORS = {
    rooms = { 0.90, 0.82, 0.56, 1.0 },
    minibosses = { 0.88, 0.38, 0.32, 1.0 },
    rewards = { 0.70, 0.84, 0.96, 1.0 },
    special = { 1.0, 0.60, 0.28, 1.0 },
}

local BIOME_SUBSECTION_COLORS = {
    rooms = { 0.82, 0.74, 0.48, 1.0 },
}

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

local UI_V2_ROOT_CACHE_KEY = "BiomeControl ui_v2 root"

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
        label = "",
        values = NPC_MODE_VALUES,
        displayValues = NPC_MODE_DISPLAY_VALUES,
        controlWidth = 120,
    }
end

local function BuildIntegerDropdownValues(minValue, maxValue)
    local values = {}
    for value = minValue, maxValue do
        values[#values + 1] = value
    end
    return values
end

local function BuildRangeDropdownPair(minAlias, maxAlias, minValue, maxValue, visibleIf)
    local values = BuildIntegerDropdownValues(minValue, maxValue)
    return {
        type = "hstack",
        gap = 8,
        visibleIf = visibleIf,
        children = {
            {
                type = "text",
                text = "from:",
                alignToFramePadding = true,
            },
            {
                type = "dropdown",
                binds = { value = minAlias },
                values = values,
                label = "",
                controlWidth = 60,
            },
            {
                type = "text",
                text = "to",
                alignToFramePadding = true,
            },
            {
                type = "dropdown",
                binds = { value = maxAlias },
                values = values,
                label = "",
                controlWidth = 60,
            },
        },
    }
end

local function BuildNpcDepthNode(def)
    return BuildRangeDropdownPair(
        def.configKeyMin,
        def.configKeyMax,
        def.minDefault,
        def.maxDefault,
        { alias = def.modeKey, value = NPC_MODE_FORCED })
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
                gap = 18,
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
        label = "",
        values = NPC_MODE_VALUES,
        displayValues = NPC_MODE_DISPLAY_VALUES,
        controlWidth = 120,
    }
end

local function BuildRoomDepthNode(def)
    return BuildRangeDropdownPair(
        def.configKeyMin,
        def.configKeyMax,
        def.minDefault,
        def.maxDefault,
        { alias = def.modeKey, value = NPC_MODE_FORCED })
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
                gap = 18,
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
        label = "",
        values = values,
        displayValues = displayValues,
        controlWidth = 250,
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

    return BuildRangeDropdownPair(
        entry.rangeConfigKeys.min,
        entry.rangeConfigKeys.max,
        minValue,
        maxValue,
        #visibleValues > 0 and { alias = entry.modeKey, anyOf = visibleValues } or nil)
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
                    gap = 18,
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
        type = "vstack",
        gap = 8,
        children = {
            {
                type = "text",
                text = title,
                color = title == "Minibosses"
                    and BIOME_SUBSECTION_COLORS.minibosses
                    or BIOME_SUBSECTION_COLORS.rooms,
            },
            {
                type = "vstack",
                gap = 8,
                children = children,
            },
        },
    }
end

local function WrapBiomeSection(title, color, children)
    if type(children) ~= "table" or #children == 0 then
        return nil
    end

    return {
        type = "vstack",
        gap = 8,
        children = {
            {
                type = "text",
                text = title,
                color = color,
            },
            {
                type = "vstack",
                gap = 10,
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
        if typeKey == "MiniBoss" then
            goto continue
        end

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
                    type = "vstack",
                    gap = 8,
                    children = {
                        {
                            type = "text",
                            text = ROOM_TYPE_LABELS[typeKey] or typeKey,
                            color = (ROOM_TYPE_LABELS[typeKey] or typeKey) == "Minibosses"
                                and BIOME_SUBSECTION_COLORS.minibosses
                                or BIOME_SUBSECTION_COLORS.rooms,
                        },
                        {
                            type = "vstack",
                            gap = 8,
                            children = entryRows,
                        },
                    },
                }
            end
        end

        ::continue::
    end

    if #roomRows > 0 then
        table.insert(roomSections, 1, {
            type = "vstack",
            gap = 8,
            children = roomRows,
        })
    end

    if #roomSections == 0 then
        return nil
    end

    return WrapBiomeSection("Rooms", BIOME_SECTION_COLORS.rooms, roomSections)
end

local function BuildBiomeMinibossesNode(biomeKey)
    local biomeDefinitions = internal.biomeDefinitions[biomeKey] or {}
    local biomeRoomEntries = internal.biomeRoomEntries[biomeKey] or {}
    local children = {}

    local definitions = biomeDefinitions.MiniBoss
    if definitions and #definitions > 0 then
        children[#children + 1] = {
            type = "vstack",
            gap = 8,
            children = (function()
                local rows = {}
                for _, def in ipairs(definitions) do
                    rows[#rows + 1] = BuildRoomDefinitionRow(def)
                end
                return rows
            end)(),
        }
    end

    local extraEntries = biomeRoomEntries and (function()
        local rows = {}
        for _, entry in ipairs(biomeRoomEntries) do
            if (entry.roomGroup or "Rooms") == "MiniBoss" then
                rows[#rows + 1] = BuildBiomeRoomEntryRow(entry)
            end
        end
        return rows
    end)() or nil
    if extraEntries and #extraEntries > 0 then
        if #children > 0 then
            children[#children + 1] = {
                type = "separator",
            }
        end
        children[#children + 1] = {
            type = "vstack",
            gap = 8,
            children = extraEntries,
        }
    end

    if #children == 0 then
        return nil
    end

    return WrapBiomeSection("Minibosses", BIOME_SECTION_COLORS.minibosses, children)
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

    return WrapBiomeSection("Special", BIOME_SECTION_COLORS.special, children)
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

    return WrapBiomeSection("Rewards", BIOME_SECTION_COLORS.rewards, children)
end

local function BuildNpcGroupNode(group)
    local children = {
        {
            type = "text",
            text = group.label,
            color = NPC_GROUP_COLORS[group.actualNPCName] or { 0.90, 0.82, 0.56, 1.0 },
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
        type = "vstack",
        gap = 8,
        children = {
            {
                type = "text",
                text = "NPC Rules",
                color = { 0.70, 0.84, 0.96, 1.0 },
            },
            {
                type = "checkbox",
                label = "Only Allow Forced NPC Encounters",
                tooltip = "Blocks NPC encounters left on Default. Only Forced entries can appear.",
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
                tooltip = "Forced NPC encounters can still appear after max depth.",
                binds = { value = "IgnoreMaxDepth" },
            },
            {
                type = "text",
                text = "Forced NPC encounters can still appear after max depth.",
                color = { 0.65, 0.65, 0.65, 1.0 },
            },
            {
                type = "dropdown",
                label = "Minimum rooms between field NPC encounters",
                binds = { value = "NPCSpacing" },
                values = NPC_SPACING_VALUES,
                controlWidth = 60,
            },
        },
    }
end

local function BuildNpcTabNode(region)
    local npcChildren = {}

    for _, groupId in ipairs(internal.npcGroups and internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupId]
        local regionDefinitions = {}
        for _, def in ipairs(group and group.definitions or {}) do
            if BIOME_REGION_BY_KEY[def.biome] == region then
                regionDefinitions[#regionDefinitions + 1] = def
            end
        end
        if #regionDefinitions > 0 then
            if #npcChildren > 0 then
                npcChildren[#npcChildren + 1] = {
                    type = "separator",
                }
            end
            npcChildren[#npcChildren + 1] = BuildNpcGroupNode({
                label = group.label,
                actualNPCName = group.actualNPCName,
                definitions = regionDefinitions,
            })
        end
    end

    if #npcChildren > 0 then
        npcChildren[#npcChildren + 1] = {
            type = "separator",
        }
    end
    npcChildren[#npcChildren + 1] = BuildNpcSettingsNode()

    return {
        type = "vstack",
        tabLabel = "NPCs",
        gap = 14,
        children = npcChildren,
    }
end

local function BuildBiomePlaceholderNode(biome)
    if PORTED_ROOM_BIOMES[biome.key] then
        local children = {}

        local roomsNode = BuildBiomeRoomsNode(biome.key)
        if roomsNode ~= nil then
            children[#children + 1] = roomsNode
        end

        local minibossesNode = BuildBiomeMinibossesNode(biome.key)
        if minibossesNode ~= nil then
            if #children > 0 then
                children[#children + 1] = {
                    type = "separator",
                }
            end
            children[#children + 1] = minibossesNode
        end

        local rewardsNode = BuildBiomeRewardsNode(biome.key)
        if rewardsNode ~= nil then
            if #children > 0 then
                children[#children + 1] = {
                    type = "separator",
                }
            end
            children[#children + 1] = rewardsNode
        end

        local specialsNode = BuildBiomeSpecialsNode(biome.key)
        if specialsNode ~= nil then
            if #children > 0 then
                children[#children + 1] = {
                    type = "separator",
                }
            end
            children[#children + 1] = specialsNode
        end

        if #children == 0 then
            children[#children + 1] = {
                type = "text",
                text = "This biome has not been ported yet.",
                color = { 0.65, 0.65, 0.65, 1.0 },
            }
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
            { type = "text", text = "Summit is sad.", color = { 0.65, 0.65, 0.65, 1.0 } },
            { type = "text", text = "Nothing to see here.", color = { 0.65, 0.65, 0.65, 1.0 } },

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
        tabId = region,
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
                type = "text",
                text = "Route Reward Priorities",
                color = { 0.90, 0.82, 0.56, 1.0 },
            },
            {
                type = "checkbox",
                label = "Choose First Boon in Each Biome",
                binds = { value = "PrioritizeSpecificRewardEnabled" },
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
            {
                type = "separator",
            },
            {
                type = "text",
                text = "Trial Reward Priorities",
                color = { 0.70, 0.84, 0.96, 1.0 },
            },
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
    }
end

function internal.BuildUiV2DefinitionUi()
    return {
        {
            type = "vstack",
            children = {
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

function internal.GetUiV2RootNode()
    if internal.uiV2RootNode then
        return internal.uiV2RootNode
    end

    local root = internal.definition
        and type(internal.definition.ui) == "table"
        and internal.definition.ui[1]
        or nil
    if type(root) ~= "table" then
        return nil
    end

    lib.ui.prepareNode(
        root,
        UI_V2_ROOT_CACHE_KEY,
        internal.definition.storage,
        internal.definition.customTypes)
    internal.uiV2RootNode = root
    return internal.uiV2RootNode
end

function internal.DrawTab(ui, uiState)
    local rootNode = internal.GetUiV2RootNode()
    if not rootNode then
        return false
    end
    return lib.ui.drawNode(ui, rootNode, uiState, nil, internal.definition.customTypes)
end

local function NormalizeRangePair(uiState, minAlias, maxAlias)
    if not uiState or type(uiState.set) ~= "function" or type(uiState.view) ~= "table" then
        return false
    end

    local minValue = tonumber(uiState.view[minAlias])
    local maxValue = tonumber(uiState.view[maxAlias])
    if minValue == nil or maxValue == nil or minValue <= maxValue then
        return false
    end

    uiState.set(maxAlias, minValue)
    return true
end

function internal.AfterDrawTab(_, uiState)
    local seen = {}

    local function Clamp(minAlias, maxAlias)
        if type(minAlias) ~= "string" or minAlias == "" or type(maxAlias) ~= "string" or maxAlias == "" then
            return
        end
        local key = minAlias .. "|" .. maxAlias
        if seen[key] then
            return
        end
        seen[key] = true
        NormalizeRangePair(uiState, minAlias, maxAlias)
    end

    for _, def in ipairs(internal.roomDefinitions or {}) do
        Clamp(def.configKeyMin, def.configKeyMax)
    end

    for _, def in ipairs(internal.npcDefinitions or {}) do
        Clamp(def.configKeyMin, def.configKeyMax)
    end

    for _, field in ipairs(internal.specialRangeFields or {}) do
        Clamp(field.configKeyMin, field.configKeyMax)
    end

    for _, entries in pairs(internal.biomeRoomEntries or {}) do
        for _, entry in ipairs(entries or {}) do
            if type(entry.rangeConfigKeys) == "table" then
                Clamp(entry.rangeConfigKeys.min, entry.rangeConfigKeys.max)
            end
        end
    end
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
