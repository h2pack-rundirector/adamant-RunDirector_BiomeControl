local internal = RunDirectorBiomeControl_Internal

local EPHYRA_STORY_MODE_OPTIONS = { "default", "disabled", "forced" }
local EPHYRA_STORY_MODE_DISPLAY = {
    default = "Default",
    forced = "Forced",
    disabled = "Disabled",
}

local EPHYRA_MINIBOSS_MODE_OPTIONS = { "default", "satyr_crossbow", "boar", "disabled" }
local EPHYRA_MINIBOSS_MODE_DISPLAY = {
    default = "Default",
    satyr_crossbow = "Force Satyr Champion",
    boar = "Force Erymanthian Boar",
    disabled = "Disable Both",
}

local subRoomRewardOptions = {
    { bit = 0,  label = "Max Mana Small",         name = "MaxManaDropSmall" },
    { bit = 1,  label = "Max Health Small",       name = "MaxHealthDropSmall" },
    { bit = 2,  label = "Empty Max Health Small", name = "EmptyMaxHealthSmallDrop" },
    { bit = 3,  label = "Tiny Money",             name = "RoomMoneyTinyDrop" },
    { bit = 4,  label = "Air Boost",              name = "AirBoost" },
    { bit = 5,  label = "Earth Boost",            name = "EarthBoost" },
    { bit = 6,  label = "Fire Boost",             name = "FireBoost" },
    { bit = 7,  label = "Water Boost",            name = "WaterBoost" },
    { bit = 8,  label = "Gift",                   name = "GiftDrop" },
    { bit = 9,  label = "Meta Currency",          name = "MetaCurrencyDrop" },
    { bit = 10, label = "Card Points",            name = "MetaCardPointsCommonDrop" },
    { bit = 11, label = "Max Health",             name = "MaxHealthDrop" },
    { bit = 12, label = "Max Mana",               name = "MaxManaDrop" },
    { bit = 13, label = "Stack Upgrade",          name = "StackUpgrade" },
    { bit = 14, label = "Money",                  name = "RoomMoneyDrop" },
    { bit = 15, label = "Minor Talent",           name = "MinorTalentDrop" },
}

local subRoomRewardsHardOptions = {
    { bit = 0, label = "Max Health",    name = "MaxHealthDrop" },
    { bit = 1, label = "Max Mana",      name = "MaxManaDrop" },
    { bit = 2, label = "Stack Upgrade", name = "StackUpgrade" },
    { bit = 3, label = "Money",         name = "RoomMoneyDrop" },
}

local function isOptionBanned(packedValue, bit)
    return bit32.band(packedValue or 0, bit32.lshift(1, bit)) ~= 0
end

local function filterRewardStore(list, packedValue, options)
    local banned = {}
    for _, option in ipairs(options) do
        if isOptionBanned(packedValue, option.bit) then
            banned[option.name] = true
        end
    end

    local newList = {}
    for _, entry in ipairs(list or {}) do
        if not banned[entry.Name] then
            table.insert(newList, entry)
        end
    end
    return newList
end

local function appendImpossibleRequirement(plan, roomKey)
    local room = RoomData and RoomData[roomKey]
    if not room then return end
    plan:appendUnique(room, "GameStateRequirements", {
        Path = { "CurrentRun", "BiomeDepthCache" },
        Comparison = "==",
        Value = -1,
    })
end

internal.registerNPCControl({ id = "Artemis", groupKey = "ArtemisSurface", biome = "N", min = 4, max = 10 })
internal.registerNPCControl({ id = "Heracles", biome = "N", min = 0, max = 10 })

internal.registerStateField({
    type = "dropdown",
    configKey = "ReplaceHermesInEphyra",
    label = "Hub Hermes Replacement",
    default = "",
    values = internal.hubRewardReplacementOptions,
    displayValues = internal.hubRewardReplacementDisplayValues,
})
internal.registerStateField({
    type = "int",
    configKey = "PackedBannedEphyraSubRoomRewards",
    default = 0,
})
internal.registerStateField({
    type = "int",
    configKey = "PackedBannedEphyraSubRoomRewardsHard",
    default = 0,
})

internal.registerBiomeRoom("N", {
    kind = "modeField",
    label = "Story",
    roomGroup = "Story",
    modeKey = "EphyraStoryMode",
    modeValues = EPHYRA_STORY_MODE_OPTIONS,
    modeDisplayValues = EPHYRA_STORY_MODE_DISPLAY,
    defaultMode = "default",
    helpText = "(Default lets the game decide, Forced guarantees Medea when normally eligible, Disabled suppresses it)",
})
internal.registerBiomeRoom("N", {
    kind = "modeField",
    label = "Miniboss",
    roomGroup = "MiniBoss",
    modeKey = "EphyraMiniBossMode",
    modeValues = EPHYRA_MINIBOSS_MODE_OPTIONS,
    modeDisplayValues = EPHYRA_MINIBOSS_MODE_DISPLAY,
    defaultMode = "default",
    helpText = "(Choose which Ephyra miniboss can appear, or disable both)",
})

internal.registerBiomeReward("N", {
    kind = "field",
    configKey = "ReplaceHermesInEphyra",
    helpText = "(Replace the Hermes slot in Ephyra HubRewards with another god or remove it)",
})
internal.registerBiomeReward("N", {
    kind = "packedCheckboxes",
    configKey = "PackedBannedEphyraSubRoomRewards",
    label = "SubRoomRewards",
    options = subRoomRewardOptions,
    helpText = "(Checked rewards are banned from normal Ephyra subroom reward pools)",
})
internal.registerBiomeReward("N", {
    kind = "packedCheckboxes",
    configKey = "PackedBannedEphyraSubRoomRewardsHard",
    label = "SubRoomRewardsHard",
    options = subRoomRewardsHardOptions,
    helpText = "(Checked rewards are banned from hard Ephyra subroom reward pools)",
})

internal.registerPatchBuilder(function(plan, read, log)
    local replacement = read("ReplaceHermesInEphyra") or ""
    if replacement == "" then
        return
    end

    local hermesHubReward = nil
    for _, entry in ipairs(LootData.HubRewards or {}) do
        if entry.Name == "HermesUpgrade" then
            hermesHubReward = entry
            break
        end
    end

    if hermesHubReward == nil then
        return
    end

    local copy = {}
    for key, value in pairs(hermesHubReward) do
        copy[key] = value
    end
    copy.Name = replacement
    copy.GameStateRequirements = nil
    plan:setElement(LootData, "HubRewards", hermesHubReward, copy)

    log("Replaced Hermes in Ephyra HubRewards with %s", replacement)
end)

internal.registerPatchBuilder(function(plan, read, log)
    local replacement = read("ReplaceHermesInEphyra") or ""
    if replacement == "" or replacement == "HermesUpgrade" then
        return
    end

    if EncounterData == nil or EncounterData.BaseArtemisCombat == nil then
        return
    end

    plan:appendUnique(EncounterData.BaseArtemisCombat, "RequireNotRoomReward", replacement)

    log("Added %s to BaseArtemisCombat.RequireNotRoomReward", replacement)
end)

internal.registerPatchBuilder(function(plan, read, log)
    local storyMode = internal.GetPackedModeValue(read, "EphyraStoryMode")
    if storyMode == "forced" and RoomData and RoomData.N_Story01 then
        plan:setMany(RoomData.N_Story01, { AlwaysForce = true })
        log("Forced Ephyra story room when eligible")
    elseif storyMode == "disabled" then
        appendImpossibleRequirement(plan, "N_Story01")
        log("Disabled Ephyra story room")
    end

    local minibossMode = internal.GetPackedModeValue(read, "EphyraMiniBossMode")
    if minibossMode == "satyr_crossbow" then
        plan:setMany(RoomData.N_MiniBoss01, { AlwaysForce = true })
        appendImpossibleRequirement(plan, "N_MiniBoss02")
        log("Forced Ephyra Satyr Champion miniboss")
    elseif minibossMode == "boar" then
        plan:setMany(RoomData.N_MiniBoss02, { AlwaysForce = true })
        appendImpossibleRequirement(plan, "N_MiniBoss01")
        log("Forced Ephyra Erymanthian Boar miniboss")
    elseif minibossMode == "disabled" then
        appendImpossibleRequirement(plan, "N_MiniBoss01")
        appendImpossibleRequirement(plan, "N_MiniBoss02")
        log("Disabled both Ephyra miniboss rooms")
    end
end)

internal.registerPatchBuilder(function(plan, read, log)
    local packedNormal = read("PackedBannedEphyraSubRoomRewards") or 0
    local packedHard = read("PackedBannedEphyraSubRoomRewardsHard") or 0

    plan:transform(LootData, "SubRoomRewards", function(list)
        return filterRewardStore(list, packedNormal, subRoomRewardOptions)
    end)
    plan:transform(LootData, "SubRoomRewardsHard", function(list)
        return filterRewardStore(list, packedHard, subRoomRewardsHardOptions)
    end)

    log("Applied Ephyra subroom reward bans")
end)
