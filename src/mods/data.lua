RunDirectorBiomeControl_Internal = RunDirectorBiomeControl_Internal or {}
local internal = RunDirectorBiomeControl_Internal

local biomeMap = {
    F = "Erebus",
    G = "Oceanus",
    H = "Fields",
    I = "Tartarus",
    N = "Ephyra",
    O = "Thessaly",
    P = "Olympus",
    Q = "Summit",
}

local function cloneData(data)
    local copy = {}
    for key, value in pairs(data) do
        copy[key] = value
    end
    return copy
end

local roomDefinitions = {}
local npcDefinitions = {}

internal.roomDefinitionSpecs = {}
internal.npcDefinitionSpecs = {}
internal.biomeRoomEntries = {}
internal.biomeRewards = {}
internal.biomeSpecials = {}
internal.specialStateFields = {}
internal.specialRangeFields = {}
internal.biomePatchBuilders = {}
internal.modeEntryLookup = {}
internal.modeStorageFields = {}
internal.priorityOptions = { "" }
internal.priorityDisplayValues = { [""] = "None" }
internal.priorityValueColors = {}
internal.roomModeValues = { "default", "disabled", "forced" }
internal.roomModeDisplayValues = {
    default = "Default",
    disabled = "Disabled",
    forced = "Forced",
}
internal.hubRewardReplacementOptions = { "" }
internal.hubRewardReplacementDisplayValues = {
    [""] = "Hermes (Default)",
}
internal.dreamBiomeOptions = { "F", "G", "H", "I", "N", "O", "P", "Q" }
internal.dreamBiomeDisplayValues = {}
internal.dreamNaturalNextBiome = {
    F = "G",
    G = "H",
    H = "I",
    N = "O",
    N_SubRooms = "O",
    O = "P",
    P = "Q",
}

internal.biomeTabs = {
    { key = "F", label = "Erebus",   slug = "f_erebus",   region = "Underworld" },
    { key = "G", label = "Oceanus",  slug = "g_oceanus",  region = "Underworld" },
    { key = "H", label = "Fields",   slug = "h_fields",   region = "Underworld" },
    { key = "I", label = "Tartarus", slug = "i_tartarus", region = "Underworld" },
    { key = "N", label = "Ephyra",   slug = "n_ephyra",   region = "Surface" },
    { key = "O", label = "Thessaly", slug = "o_thessaly", region = "Surface" },
    { key = "P", label = "Olympus",  slug = "p_olympus",  region = "Surface" },
    { key = "Q", label = "Summit",   slug = "q_summit",   region = "Surface" },
}

for biomeCode, biomeName in pairs(biomeMap) do
    internal.dreamBiomeDisplayValues[biomeCode] = biomeName
end

function internal.registerRoomControl(data)
    table.insert(internal.roomDefinitionSpecs, cloneData(data))
end

function internal.registerNPCControl(data)
    table.insert(internal.npcDefinitionSpecs, cloneData(data))
end

function internal.registerBiomeSpecial(biome, special)
    internal.biomeSpecials[biome] = internal.biomeSpecials[biome] or {}
    table.insert(internal.biomeSpecials[biome], cloneData(special))
end

function internal.registerBiomeRoom(biome, room)
    internal.biomeRoomEntries[biome] = internal.biomeRoomEntries[biome] or {}
    table.insert(internal.biomeRoomEntries[biome], cloneData(room))
end

function internal.registerBiomeReward(biome, reward)
    internal.biomeRewards[biome] = internal.biomeRewards[biome] or {}
    table.insert(internal.biomeRewards[biome], cloneData(reward))
end

function internal.registerStateField(field)
    table.insert(internal.specialStateFields, cloneData(field))
end

function internal.registerRangeField(field)
    table.insert(internal.specialRangeFields, cloneData(field))
end

function internal.registerPatchBuilder(builder)
    table.insert(internal.biomePatchBuilders, builder)
end

local function PrepareModeField(entry)
    entry.modeValues = entry.modeValues or internal.roomModeValues
    entry.modeDisplayValues = entry.modeDisplayValues or internal.roomModeDisplayValues
    entry.defaultMode = entry.defaultMode or entry.modeValues[1] or "default"
    entry.modeValueLookup = {}
    for index, value in ipairs(entry.modeValues) do
        entry.modeValueLookup[value] = index - 1
    end
    internal.modeEntryLookup[entry.modeKey] = entry
    table.insert(internal.modeStorageFields, {
        type = "int",
        alias = entry.modeKey,
        configKey = entry.modeKey,
        default = entry.modeValueLookup[entry.defaultMode] or 0,
        min = 0,
        max = math.max(#entry.modeValues - 1, 0),
    })
end

local function ResolveModeEntry(entryOrKey)
    if type(entryOrKey) == "table" then
        return entryOrKey
    end
    return internal.modeEntryLookup[entryOrKey]
end

function internal.GetModeValue(readFn, entryOrKey)
    local entry = ResolveModeEntry(entryOrKey)
    if not entry then return "default" end

    local encoded = readFn(entry.modeKey)
    encoded = math.floor(tonumber(encoded) or 0)
    return entry.modeValues[encoded + 1] or entry.defaultMode
end

function internal.SetModeValue(session, entryOrKey, value)
    local entry = ResolveModeEntry(entryOrKey)
    if not entry then return end

    local encoded = entry.modeValueLookup[value]
    if encoded == nil then
        encoded = entry.modeValueLookup[entry.defaultMode] or 0
    end

    session.write(entry.modeKey, encoded)
end

function internal.GetModeDisplay(entryOrKey, value)
    local entry = ResolveModeEntry(entryOrKey)
    if not entry then
        return tostring(value)
    end
    return entry.modeDisplayValues[value] or tostring(value)
end

do
    local priorityGods = {
        { label = "Aphrodite",  lootKey = "AphroditeUpgrade",  colorKey = "AphroditeVoice" },
        { label = "Apollo",     lootKey = "ApolloUpgrade",     colorKey = "ApolloVoice" },
        { label = "Ares",       lootKey = "AresUpgrade",       colorKey = "AresVoice" },
        { label = "Demeter",    lootKey = "DemeterUpgrade",    colorKey = "DemeterVoice" },
        { label = "Hephaestus", lootKey = "HephaestusUpgrade", colorKey = "HephaestusVoice" },
        { label = "Hera",       lootKey = "HeraUpgrade",       colorKey = "HeraDamage" },
        { label = "Hestia",     lootKey = "HestiaUpgrade",     colorKey = "HestiaVoice" },
        { label = "Poseidon",   lootKey = "PoseidonUpgrade",   colorKey = "PoseidonVoice" },
        { label = "Zeus",       lootKey = "ZeusUpgrade",       colorKey = "ZeusVoice" },
    }

    for _, god in ipairs(priorityGods) do
        table.insert(internal.priorityOptions, god.lootKey)
        internal.priorityDisplayValues[god.lootKey] = god.label
        local inGameColor = god.colorKey and game.Color[god.colorKey] or nil
        if type(inGameColor) == "table" then
            internal.priorityValueColors[god.lootKey] = {
                inGameColor[1] / 255,
                inGameColor[2] / 255,
                inGameColor[3] / 255,
                inGameColor[4] / 255,
            }
        end
        table.insert(internal.hubRewardReplacementOptions, god.lootKey)
        internal.hubRewardReplacementDisplayValues[god.lootKey] = god.label
    end
end

local function DefineRoomControl(data)
    local entry = cloneData(data)
    local regionName = biomeMap[entry.biome] or entry.biome
    entry.region = regionName
    entry.minDefault = entry.min
    entry.maxDefault = entry.max

    if not entry.label then
        if entry.type == "Story" or entry.type == "Trial" or entry.type == "Fountain" or entry.type == "Shop" then
            entry.label = entry.type
        else
            entry.label = string.format("%s (%s)", entry.id, regionName)
        end
    end

    local keyIdentifier = entry.id
    if entry.useRegionInKey then
        if entry.id == entry.type then
            keyIdentifier = regionName
        else
            keyIdentifier = entry.id .. regionName
        end
    end
    entry.configKeyMin = entry.configKeyMin or ("Packed" .. entry.type .. keyIdentifier .. "Min")
    entry.configKeyMax = entry.configKeyMax or ("Packed" .. entry.type .. keyIdentifier .. "Max")
    entry.modeKey = entry.modeKey or ("Mode" .. entry.type .. keyIdentifier)
    PrepareModeField(entry)

    table.insert(roomDefinitions, entry)
end

local function DefineNPCControl(data)
    local entry = cloneData(data)
    local regionName = biomeMap[entry.biome] or entry.biome
    entry.region = regionName
    entry.minDefault = entry.min
    entry.maxDefault = entry.max
    entry.label = entry.label or entry.id
    entry.groupKey = entry.groupKey or entry.id
    entry.configKeyMin = entry.configKeyMin or ("PackedNPC" .. entry.id .. regionName .. "Min")
    entry.configKeyMax = entry.configKeyMax or ("PackedNPC" .. entry.id .. regionName .. "Max")
    entry.modeKey = entry.modeKey or ("ModeNPC" .. entry.id .. regionName)
    entry.modeValues = entry.modeValues or internal.roomModeValues
    entry.modeDisplayValues = entry.modeDisplayValues or internal.roomModeDisplayValues
    entry.defaultMode = entry.defaultMode or "default"
    PrepareModeField(entry)
    table.insert(npcDefinitions, entry)
end

for _, biome in ipairs(internal.biomeTabs) do
    import("mods/biomes/" .. biome.slug .. ".lua")
end

for _, entry in ipairs(internal.roomDefinitionSpecs) do
    DefineRoomControl(entry)
end

for _, entry in ipairs(internal.npcDefinitionSpecs) do
    DefineNPCControl(entry)
end

for _, biome in ipairs(internal.biomeTabs) do
    if not internal.biomeRoomEntries[biome.key] then
        internal.biomeRoomEntries[biome.key] = {}
    end
    if not internal.biomeSpecials[biome.key] then
        internal.biomeSpecials[biome.key] = {}
    end
    if not internal.biomeRewards[biome.key] then
        internal.biomeRewards[biome.key] = {}
    end
end

for _, entries in pairs(internal.biomeRoomEntries) do
    for _, entry in ipairs(entries) do
        if entry.kind == "modeField" then
            entry.modeKey = entry.modeKey or entry.configKey or entry.label
            PrepareModeField(entry)
        end
    end
end

internal.roomDefinitions = roomDefinitions
internal.roomLookup = {}
internal.biomeDefinitions = {}
internal.npcDefinitions = npcDefinitions
internal.npcLookup = {}
internal.npcGroups = { orderedIds = {} }

for _, def in ipairs(roomDefinitions) do
    internal.roomLookup[def.id] = internal.roomLookup[def.id] or {}
    internal.roomLookup[def.id][def.biome] = def

    internal.biomeDefinitions[def.biome] = internal.biomeDefinitions[def.biome] or {}
    internal.biomeDefinitions[def.biome][def.type] = internal.biomeDefinitions[def.biome][def.type] or {}
    table.insert(internal.biomeDefinitions[def.biome][def.type], def)
end

for _, def in ipairs(npcDefinitions) do
    internal.npcLookup[def.id] = internal.npcLookup[def.id] or {}
    internal.npcLookup[def.id][def.biome] = def
    if not internal.npcGroups[def.groupKey] then
        internal.npcGroups[def.groupKey] = {
            id = def.groupKey,
            label = def.label,
            actualNPCName = def.id,
            region = def.region,
            definitions = {},
            lookup = {},
        }
        table.insert(internal.npcGroups.orderedIds, def.groupKey)
    end
    table.insert(internal.npcGroups[def.groupKey].definitions, def)
    internal.npcGroups[def.groupKey].lookup[def.biome] = def
end

for _, npcId in ipairs(internal.npcGroups.orderedIds) do
    local group = internal.npcGroups[npcId]
    table.sort(group.definitions, function(a, b)
        return a.biome < b.biome
    end)
end

function internal.BuildStorage()
    local storage = {
        { type = "bool",   configKey = "OnlyAllowForcedEncounters" },
        { type = "bool",   configKey = "IgnoreMaxDepth" },
        { type = "int",    configKey = "NPCSpacing",                     min = 1, max = 12 },
        { type = "bool",   configKey = "PrioritizeSpecificRewardEnabled" },
        { type = "string", configKey = "PriorityBiome1" },
        { type = "string", configKey = "PriorityBiome2" },
        { type = "string", configKey = "PriorityBiome3" },
        { type = "string", configKey = "PriorityBiome4" },
        { type = "bool",   configKey = "PrioritizeTrialRewardEnabled" },
        { type = "string", configKey = "PriorityTrial1" },
        { type = "string", configKey = "PriorityTrial2" },
        { type = "bool",   configKey = "DreamRouteEnabled" },
        { type = "string", configKey = "DreamRouteBiome1", default = "G" },
        { type = "string", configKey = "DreamRouteBiome2", default = "I" },
        { type = "string", configKey = "DreamRouteBiome3", default = "N" },
        { type = "string", configKey = "DreamRouteBiome4", default = "P" },
        { type = "string", alias = "UnderworldTab", lifetime = "transient", default = "NPCs", maxLen = 32 },
        { type = "string", alias = "SurfaceTab",    lifetime = "transient", default = "NPCs", maxLen = 32 },
    }

    local storageTypeMap = { checkbox = "bool", stepper = "int", dropdown = "string", int32 = "int" }
    local packedRewardFields = {}

    for _, rewards in pairs(internal.biomeRewards or {}) do
        for _, reward in ipairs(rewards) do
            if reward.kind == "packedCheckboxes" and type(reward.configKey) == "string" and reward.configKey ~= "" then
                packedRewardFields[reward.configKey] = reward
            end
        end
    end

    for _, field in ipairs(internal.specialStateFields) do
        if not packedRewardFields[field.configKey] then
            local storageType = storageTypeMap[field.type] or field.type
            local default = field.default
            if default == nil then
                if storageType == "bool" then
                    default = false
                elseif storageType == "string" then
                    default = ""
                else
                    default = field.min or 0
                end
            end
            table.insert(storage, {
                type = storageType,
                configKey = field.configKey,
                default = default,
                min = field.min,
                max = field.max,
            })
        end
    end

    for configKey, reward in pairs(packedRewardFields) do
        local bits = {}
        for _, option in ipairs(reward.options or {}) do
            bits[#bits + 1] = {
                alias = configKey .. "_" .. tostring(option.name or option.label or option.bit),
                label = option.label or tostring(option.name or option.bit),
                type = "bool",
                offset = option.bit,
                width = 1,
                default = false,
            }
        end
        table.insert(storage, {
            type = "packedInt",
            configKey = configKey,
            alias = configKey,
            default = 0,
            bits = bits,
        })
    end

    for _, field in ipairs(internal.specialRangeFields) do
        table.insert(storage, {
            type = "int",
            configKey = field.configKeyMin,
            default = field.min,
            min = field.min,
            max = field.max,
        })
        table.insert(storage, {
            type = "int",
            configKey = field.configKeyMax,
            default = field.max,
            min = field.min,
            max = field.max,
        })
    end

    for _, field in ipairs(internal.modeStorageFields) do
        table.insert(storage, field)
    end

    local function addDepthStorageNodes(definitions)
        local seen = {}
        for _, def in ipairs(definitions) do
            if not seen[def.configKeyMin] then
                seen[def.configKeyMin] = true
                table.insert(storage, {
                    type = "int",
                    configKey = def.configKeyMin,
                    default = def.minDefault,
                    min = def.minDefault,
                    max = def.maxDefault,
                })
            end
            if not seen[def.configKeyMax] then
                seen[def.configKeyMax] = true
                table.insert(storage, {
                    type = "int",
                    configKey = def.configKeyMax,
                    default = def.maxDefault,
                    min = def.minDefault,
                    max = def.maxDefault,
                })
            end
        end
    end

    addDepthStorageNodes(internal.roomDefinitions)
    addDepthStorageNodes(internal.npcDefinitions)

    return storage
end
