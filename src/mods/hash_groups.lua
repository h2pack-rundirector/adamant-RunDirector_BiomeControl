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

function internal.BuildHashGroupPlan()
    return {
        {
            keyPrefix = "global",
            items = {
                {
                    "OnlyAllowForcedEncounters",
                    "IgnoreMaxDepth",
                    "NPCSpacing",
                    "PrioritizeSpecificRewardEnabled",
                    "PrioritizeTrialRewardEnabled",
                },
            },
        },
        {
            keyPrefix = "F",
            items = {
                getRangedControlAliases(getRoomDef("Arachne", "F")),
                getRangedControlAliases(getRoomDef("Trial", "F")),
                getRangedControlAliases(getRoomDef("Fountain", "F")),
                getRangedControlAliases(getRoomDef("Shop", "F")),
                getRangedControlAliases(getRoomDef("Treant", "F")),
                getRangedControlAliases(getRoomDef("FogEmitter", "F")),
                getRangedControlAliases(getRoomDef("Assassin", "F")),
                getRangedControlAliases(getNpcDef("Artemis", "F")),
                getRangedControlAliases(getNpcDef("Nemesis", "F")),
            },
        },
        {
            keyPrefix = "G",
            items = {
                getRangedControlAliases(getRoomDef("Narcissus", "G")),
                getRangedControlAliases(getRoomDef("Trial", "G")),
                getRangedControlAliases(getRoomDef("Fountain", "G")),
                getRangedControlAliases(getRoomDef("Shop", "G")),
                getRangedControlAliases(getRoomDef("WaterUnit", "G")),
                getRangedControlAliases(getRoomDef("Crawler", "G")),
                getRangedControlAliases(getRoomDef("Jellyfish", "G")),
                getRangedControlAliases(getNpcDef("Artemis", "G")),
                getRangedControlAliases(getNpcDef("Nemesis", "G")),
            },
        },
        {
            keyPrefix = "H",
            items = {
                getRangedControlAliases(getRoomDef("Vampire", "H")),
                getRangedControlAliases(getRoomDef("Lamia", "H")),
                getRangedControlAliases(getNpcDef("Nemesis", "H")),
                {
                    "PreventEchoScam",
                    "ForceTwoRewardFieldsOpeners",
                },
            },
        },
        {
            keyPrefix = "I",
            items = {
                getRangedControlAliases(getRoomDef("RatCatcher", "I")),
                getRangedControlAliases(getRoomDef("GoldElemental", "I")),
                {
                    "PackedNPCNemesisTartarusMin",
                    "PackedNPCNemesisTartarusMax",
                },
            },
        },
        {
            keyPrefix = "N",
            items = {
                "EphyraStoryMode",
                "EphyraMiniBossMode",
                getRangedControlAliases(getNpcDef("Artemis", "N")),
                getRangedControlAliases(getNpcDef("Heracles", "N")),
            },
        },
        {
            keyPrefix = "O",
            items = {
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
            },
        },
        {
            keyPrefix = "P",
            items = {
                getRangedControlAliases(getRoomDef("Dionysus", "P")),
                getRangedControlAliases(getRoomDef("Fountain", "P")),
                getRangedControlAliases(getRoomDef("Shop", "P")),
                getRangedControlAliases(getRoomDef("Talos", "P")),
                getRangedControlAliases(getRoomDef("Dragon", "P")),
                getRangedControlAliases(getNpcDef("Heracles", "P")),
                getRangedControlAliases(getNpcDef("Athena", "P")),
                getRangedControlAliases(getNpcDef("Icarus", "P")),
            },
        },
    }
end

return internal
