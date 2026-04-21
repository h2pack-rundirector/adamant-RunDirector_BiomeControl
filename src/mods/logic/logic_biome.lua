local internal = RunDirectorBiomeControl_Internal

local roomDefinitions = internal.roomDefinitions
local roomLookup = internal.roomLookup

local underworldTrialRooms = {
    F = { "F_Combat05", "F_Combat06", "F_Combat07",
          "F_Combat11", "F_Combat12", "F_Combat13",
          "F_Combat14", "F_Combat15", "F_Combat16",
          "F_Combat17", "F_Combat18", "F_Combat20" },

    G = { "G_Combat02", "G_Combat03", "G_Combat09",
          "G_Combat10", "G_Combat11", "G_Combat12",
          "G_Combat13", "G_Combat14", "G_Combat15",
          "G_Combat16", "G_Combat17" },
}

local function Read(key)
    return internal.BiomeControlRead(key)
end

local function Log(fmt, ...)
    lib.logging.logIf(definition.id, Read("DebugMode") == true, fmt, ...)
end

local function GetDefinitionMode(def)
    return internal.GetModeValue(Read, def)
end

local function PriorityKeyForBiome(biomeIndex)
    biomeIndex = math.max((biomeIndex or 0) - 1, 0)
    if biomeIndex == 0 then return Read("PriorityBiome1") or "" end
    if biomeIndex == 1 then return Read("PriorityBiome2") or "" end
    if biomeIndex == 2 then return Read("PriorityBiome3") or "" end
    if biomeIndex == 3 then return Read("PriorityBiome4") or "" end
    return ""
end

local function PriorityKeyForTrial(trialIndex)
    if trialIndex == 1 then return Read("PriorityTrial1") or "" end
    if trialIndex == 2 then return Read("PriorityTrial2") or "" end
    return ""
end

local function GetRoomKey(def)
    if def.roomKey and def.roomKey ~= "" then
        return def.roomKey
    end
    if def.type == "Story" then
        return def.biome .. "_Story01"
    end
    if def.type == "Fountain" then
        return def.biome .. "_Reprieve01"
    end
    if def.type == "Shop" then
        return def.biome .. "_Shop01"
    end
    if def.type == "Trial" and def.biome == "O" then
        return "O_Devotion01"
    end
end

local function GetRoomData(def, roomKey)
    if RoomData and RoomData[roomKey] then
        return RoomData[roomKey]
    end
    local roomSet = RoomSetData and RoomSetData[def.biome]
    if roomSet then
        return roomSet[roomKey]
    end
end

local function ApplyBiomeDepthRequirements(plan, room, minValue, maxValue)
    if not room or not room.GameStateRequirements then return end

    plan:transform(room, "GameStateRequirements", function(requirements)
        local changed = false
        local copy = {}
        for i, requirement in ipairs(requirements or {}) do
            if type(requirement) == "table" and
                requirement.Path and requirement.Path[1] == "CurrentRun" and
                requirement.Path[2] == "BiomeDepthCache" then
                local requirementCopy = {}
                for reqKey, reqValue in pairs(requirement) do
                    requirementCopy[reqKey] = reqValue
                end

                if requirement.Comparison == ">=" and requirement.Value ~= minValue then
                    requirementCopy.Value = minValue
                    changed = true
                elseif requirement.Comparison == "<=" and requirement.Value ~= maxValue then
                    requirementCopy.Value = maxValue
                    changed = true
                end

                copy[i] = requirementCopy
            else
                copy[i] = requirement
            end
        end
        for key, value in pairs(requirements or {}) do
            if type(key) ~= "number" then
                copy[key] = value
            end
        end
        return changed and copy or requirements
    end)
end

local function ApplyRangeOverride(plan, def, roomKey, minValue, maxValue)
    local room = GetRoomData(def, roomKey)
    if not room then return end
    plan:setMany(room, {
        ForceAtBiomeDepthMin = minValue,
        ForceAtBiomeDepthMax = maxValue,
    })
    ApplyBiomeDepthRequirements(plan, room, minValue, maxValue)
end

local function DisableRoom(plan, def, roomKey)
    local room = GetRoomData(def, roomKey)
    if not room then return end

    plan:appendUnique(room, "GameStateRequirements", {
        Path = { "CurrentRun", "BiomeDepthCache" },
        Comparison = "==",
        Value = -1,
    })
end

local function SetForcedReward(plan, roomSetKey, roomKey, rewardName, minValue, maxValue)
    local roomSet = RoomSetData[roomSetKey]
    if not roomSet or not roomSet[roomKey] then return end
    plan:setMany(roomSet[roomKey], {
        ForcedReward = rewardName,
        ForceAtBiomeDepthMin = minValue,
        ForceAtBiomeDepthMax = maxValue,
    })
end

function internal.BuildBiomePatchPlan(plan)
    for _, def in ipairs(roomDefinitions) do
        local roomKey = GetRoomKey(def)
        if roomKey then
            local mode = GetDefinitionMode(def)
            if mode == "forced" then
                ApplyRangeOverride(
                    plan,
                    def,
                    roomKey,
                    Read(def.configKeyMin),
                    Read(def.configKeyMax)
                )
            elseif mode == "disabled" then
                DisableRoom(plan, def, roomKey)
            end
        end
    end

    for biomeCode, roomKeys in pairs(underworldTrialRooms) do
        local trialDef = roomLookup.Trial and roomLookup.Trial[biomeCode]
        if trialDef and GetDefinitionMode(trialDef) == "forced" then
            for _, roomKey in ipairs(roomKeys) do
                if RoomSetData[biomeCode] and RoomSetData[biomeCode][roomKey] then
                    SetForcedReward(plan, biomeCode, roomKey, "Devotion", Read(trialDef.configKeyMin),
                        Read(trialDef.configKeyMax))
                    Log("Deterministically injected trial reward into " .. roomKey)
                    break
                end
            end
        end
    end

    for _, builder in ipairs(internal.biomePatchBuilders or {}) do
        builder(plan, Read, Log)
    end
end

function internal.RegisterBiomeHooks()
    lib.hooks.Wrap(internal, "GetEligibleLootNames", function(base, excludeLootNames)
        if not internal.IsEnabled() then return base(excludeLootNames) end

        local state = internal.GetRunState()
        if not state then return base(excludeLootNames) end
        state.BiomePrioritySatisfied = state.BiomePrioritySatisfied or {}

        local eligible = base(excludeLootNames)
        local currentBiomeIndex = CurrentRun and CurrentRun.ClearedBiomes or 0
        local priorityLootKey = PriorityKeyForBiome(currentBiomeIndex)
        local isPriorityMode = Read("PrioritizeSpecificRewardEnabled") and priorityLootKey ~= "" and
            not state.BiomePrioritySatisfied[currentBiomeIndex]

        if isPriorityMode and Contains(eligible, priorityLootKey) then
            return { priorityLootKey }
        end

        return eligible
    end)

    lib.hooks.Wrap(internal, "GiveLoot", function(base, args)
        if not internal.IsEnabled() then return base(args) end

        local state = internal.GetRunState()
        if not state then return base(args) end

        local result = base(args)
        local currentBiomeIndex = CurrentRun and CurrentRun.ClearedBiomes or 0
        local lootName = args and (args.ForceLootName or args.Name)
        if Read("PrioritizeSpecificRewardEnabled") and lootName == PriorityKeyForBiome(currentBiomeIndex) then
            state.BiomePrioritySatisfied[currentBiomeIndex] = true
        end
        return result
    end)

    lib.hooks.Wrap(internal, "SetupRoomReward", function(base, currentRun, room, previouslyChosenRewards, args)
        base(currentRun, room, previouslyChosenRewards, args)
        if not internal.IsEnabled() then return end

        local chosenRewardType = args and args.ChosenRewardType or room.ChosenRewardType
        if chosenRewardType ~= "Devotion" or not room or not room.Encounter then return end
        if not Read("PrioritizeTrialRewardEnabled") then return end

        local prioA = PriorityKeyForTrial(1)
        local prioB = PriorityKeyForTrial(2)
        local interacted = GetInteractedGodsThisRun() or {}
        if prioA ~= "" and prioB ~= "" and prioA ~= prioB and
            Contains(interacted, prioA) and Contains(interacted, prioB) and
            Contains(GetEligibleLootNames(), prioA) and
            Contains(GetEligibleLootNames({ prioA }), prioB) then
            room.Encounter.LootAName = prioA
            room.Encounter.LootBName = prioB
        end
    end)

    if internal.RegisterFieldsHooks then
        internal.RegisterFieldsHooks()
    end
end
