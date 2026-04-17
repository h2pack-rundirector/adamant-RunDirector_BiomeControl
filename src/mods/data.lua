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

function internal.SetModeValue(uiState, entryOrKey, value)
    local entry = ResolveModeEntry(entryOrKey)
    if not entry then return end

    local encoded = entry.modeValueLookup[value]
    if encoded == nil then
        encoded = entry.modeValueLookup[entry.defaultMode] or 0
    end

    uiState.set(entry.modeKey, encoded)
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
        { label = "Aphrodite", lootKey = "AphroditeUpgrade" },
        { label = "Apollo", lootKey = "ApolloUpgrade" },
        { label = "Ares", lootKey = "AresUpgrade" },
        { label = "Demeter", lootKey = "DemeterUpgrade" },
        { label = "Hephaestus", lootKey = "HephaestusUpgrade" },
        { label = "Hera", lootKey = "HeraUpgrade" },
        { label = "Hestia", lootKey = "HestiaUpgrade" },
        { label = "Poseidon", lootKey = "PoseidonUpgrade" },
        { label = "Zeus", lootKey = "ZeusUpgrade" },
    }

    for _, god in ipairs(priorityGods) do
        table.insert(internal.priorityOptions, god.lootKey)
        internal.priorityDisplayValues[god.lootKey] = god.label
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

