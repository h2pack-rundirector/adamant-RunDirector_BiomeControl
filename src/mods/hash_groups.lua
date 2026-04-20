local internal = RunDirectorBiomeControl_Internal

local function getRoomDef(id, biome)
    return internal.roomLookup
        and internal.roomLookup[id]
        and internal.roomLookup[id][biome]
        or nil
end

local function getNpcDef(id, biome)
    return internal.npcLookup
        and internal.npcLookup[id]
        and internal.npcLookup[id][biome]
        or nil
end

local function getRangedControlAliases(def)
    if not def then
        return nil
    end

    return {
        def.modeKey,
        def.configKeyMin,
        def.configKeyMax,
    }
end

local function getAliasWidth(aliasNodes, alias)
    local node = aliasNodes[alias]
    if not node then
        error(string.format("BiomeControl hashGroups: unknown alias '%s'", tostring(alias)))
    end

    local width = lib.hashing.getPackWidth(node)
    if not width then
        error(string.format("BiomeControl hashGroups: alias '%s' is not packable", tostring(alias)))
    end

    return width
end

local function packAliasItems(groups, aliasNodes, keyPrefix, items)
    local groupIndex = 1
    local currentAliases = {}
    local currentBits = 0

    local function flush()
        if #currentAliases == 0 then
            return
        end

        local group = { key = string.format("%s_%d", keyPrefix, groupIndex) }
        for _, alias in ipairs(currentAliases) do
            group[#group + 1] = alias
        end
        groups[#groups + 1] = group
        groupIndex = groupIndex + 1
        currentAliases = {}
        currentBits = 0
    end

    for _, itemAliases in ipairs(items or {}) do
        if itemAliases and #itemAliases > 0 then
            local itemBits = 0
            for _, alias in ipairs(itemAliases) do
                itemBits = itemBits + getAliasWidth(aliasNodes, alias)
            end

            if itemBits > 32 then
                error(string.format("BiomeControl hashGroups: item in '%s' exceeds 32 bits", keyPrefix))
            end

            if currentBits > 0 and currentBits + itemBits > 32 then
                flush()
            end

            for _, alias in ipairs(itemAliases) do
                currentAliases[#currentAliases + 1] = alias
            end
            currentBits = currentBits + itemBits
        end
    end

    flush()
end

function internal.BuildHashGroups(storage)
    local aliasNodes = lib.hashing.getAliases(storage)
    local groups = {}

    packAliasItems(groups, aliasNodes, "global", {
        {
            "OnlyAllowForcedEncounters",
            "IgnoreMaxDepth",
            "NPCSpacing",
            "PrioritizeSpecificRewardEnabled",
            "PrioritizeTrialRewardEnabled",
        },
    })

    packAliasItems(groups, aliasNodes, "F", {
        getRangedControlAliases(getRoomDef("Arachne", "F")),
        getRangedControlAliases(getRoomDef("Trial", "F")),
        getRangedControlAliases(getRoomDef("Fountain", "F")),
        getRangedControlAliases(getRoomDef("Shop", "F")),
        getRangedControlAliases(getRoomDef("Treant", "F")),
        getRangedControlAliases(getRoomDef("FogEmitter", "F")),
        getRangedControlAliases(getRoomDef("Assassin", "F")),
        getRangedControlAliases(getNpcDef("Artemis", "F")),
        getRangedControlAliases(getNpcDef("Nemesis", "F")),
    })

    packAliasItems(groups, aliasNodes, "G", {
        getRangedControlAliases(getRoomDef("Narcissus", "G")),
        getRangedControlAliases(getRoomDef("Trial", "G")),
        getRangedControlAliases(getRoomDef("Fountain", "G")),
        getRangedControlAliases(getRoomDef("Shop", "G")),
        getRangedControlAliases(getRoomDef("WaterUnit", "G")),
        getRangedControlAliases(getRoomDef("Crawler", "G")),
        getRangedControlAliases(getRoomDef("Jellyfish", "G")),
        getRangedControlAliases(getNpcDef("Artemis", "G")),
        getRangedControlAliases(getNpcDef("Nemesis", "G")),
    })

    packAliasItems(groups, aliasNodes, "H", {
        getRangedControlAliases(getRoomDef("Vampire", "H")),
        getRangedControlAliases(getRoomDef("Lamia", "H")),
        getRangedControlAliases(getNpcDef("Nemesis", "H")),
        {
            "PreventEchoScam",
            "ForceTwoRewardFieldsOpeners",
        },
    })

    packAliasItems(groups, aliasNodes, "I", {
        getRangedControlAliases(getRoomDef("RatCatcher", "I")),
        getRangedControlAliases(getRoomDef("GoldElemental", "I")),
        {
            "PackedNPCNemesisTartarusMin",
            "PackedNPCNemesisTartarusMax",
        },
    })

    packAliasItems(groups, aliasNodes, "N", {
        { "EphyraStoryMode" },
        { "EphyraMiniBossMode" },
        getRangedControlAliases(getNpcDef("Artemis", "N")),
        getRangedControlAliases(getNpcDef("Heracles", "N")),
    })

    packAliasItems(groups, aliasNodes, "O", {
        getRangedControlAliases(getRoomDef("Circe", "O")),
        getRangedControlAliases(getRoomDef("Trial", "O")),
        getRangedControlAliases(getRoomDef("Fountain", "O")),
        getRangedControlAliases(getRoomDef("Shop", "O")),
        {
            "ThessalyMiniBossMode",
            "PackedForcedThessalyMiniBossMin",
            "PackedForcedThessalyMiniBossMax",
        },
        getRangedControlAliases(getNpcDef("Heracles", "O")),
        getRangedControlAliases(getNpcDef("Icarus", "O")),
    })

    packAliasItems(groups, aliasNodes, "P", {
        getRangedControlAliases(getRoomDef("Dionysus", "P")),
        getRangedControlAliases(getRoomDef("Fountain", "P")),
        getRangedControlAliases(getRoomDef("Shop", "P")),
        getRangedControlAliases(getRoomDef("Talos", "P")),
        getRangedControlAliases(getRoomDef("Dragon", "P")),
        getRangedControlAliases(getNpcDef("Heracles", "P")),
        getRangedControlAliases(getNpcDef("Athena", "P")),
        getRangedControlAliases(getNpcDef("Icarus", "P")),
    })

    return groups
end

return internal
