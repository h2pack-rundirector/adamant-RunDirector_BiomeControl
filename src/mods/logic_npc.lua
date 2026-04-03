local internal = RunDirectorBiomeControl_Internal

local npcLookup = internal.npcLookup
local npcPriorityList = { "Artemis", "Icarus", "Heracles", "Athena", "Nemesis" }
local forcePattern = "[FGHINOPQ]$"
local strictPattern = "[FGHINOPQ]0?2?$"

local function Read(key)
    return internal.BiomeControlRead(key)
end

local function GetCurrentNPCRange(def)
    local minValue = Read(def.configKeyMin) or 0
    local maxValue = Read(def.configKeyMax) or 99
    return minValue, maxValue
end

function internal.BuildNPCPatchPlan(plan)
    if NamedRequirementsData.NoRecentFieldNPCEncounter and NamedRequirementsData.NoRecentFieldNPCEncounter[1] then
        plan:set(NamedRequirementsData.NoRecentFieldNPCEncounter[1], "SumPrevRooms", Read("NPCSpacing") or 6)
    end
end

function internal.RegisterNPCHooks()
    modutil.mod.Path.Wrap("ChooseEncounter", function(base, currentRun, room, args)
        if not internal.IsEnabled() then return base(currentRun, room, args) end

        args = args or {}
        local legalEncounters = args.LegalEncounters or room.LegalEncounters
        if not legalEncounters then return base(currentRun, room, args) end

        local state = internal.GetRunState()
        if not state then return base(currentRun, room, args) end

        local currentRoomSet = room and room.RoomSetName
        local biomeDepth = currentRun.BiomeDepthCache or 0
        local encounterSeen = state.NPCEncounterSeen or {}
        local pending = state.ForcedNPCPending or {}

        for _, groupKey in ipairs(internal.npcGroups.orderedIds or {}) do
            local group = internal.npcGroups[groupKey]
            local actualNPCName = group.actualNPCName
            local perPending = pending[groupKey]
            if perPending and currentRoomSet and perPending[currentRoomSet] and not encounterSeen[actualNPCName] then
                local def = group.lookup and group.lookup[currentRoomSet]
                if def then
                    local minValue, maxValue = GetCurrentNPCRange(def)
                    local depthOkay = biomeDepth >= minValue and (Read("IgnoreMaxDepth") or biomeDepth <= maxValue)
                    if depthOkay then
                        for _, encounterName in ipairs(legalEncounters) do
                            if type(encounterName) == "string"
                                and encounterName:find(actualNPCName, 1, true)
                                and encounterName:find("Combat", 1, true)
                                and encounterName:find(forcePattern) then
                                local encData = EncounterData and EncounterData[encounterName]
                                local eligible = true
                                if encData and encData.GameStateRequirements then
                                    eligible = IsGameStateEligible(encData, encData.GameStateRequirements, args)
                                        and IsEncounterEligible(currentRun, room, encData, args)
                                end
                                if eligible then
                                    args.LegalEncounters = { encounterName }
                                    return base(currentRun, room, args)
                                end
                            end
                        end
                    end
                end
            end
        end

        if state.OnlyAllowForcedEncounters then
            local filtered = {}
            local changed = false

            for _, encounterName in ipairs(legalEncounters) do
                local restricted = false
                if type(encounterName) == "string"
                    and encounterName:find(strictPattern)
                    and encounterName:find("Combat", 1, true) then
                    for _, npcName in ipairs(npcPriorityList) do
                        if encounterName:find(npcName, 1, true) then
                            local def = npcLookup[npcName] and npcLookup[npcName][currentRoomSet]
                            local mode
                            if def then
                                local group = internal.npcGroups[def.groupKey]
                                local perPending = pending[def.groupKey]
                                mode = internal.GetPackedModeValue(Read, group)
                                local minValue, maxValue = GetCurrentNPCRange(def)
                                if mode == "disabled" then
                                    restricted = true
                                elseif mode ~= currentRoomSet then
                                    restricted = true
                                elseif not (perPending and currentRoomSet and perPending[currentRoomSet]) then
                                    restricted = true
                                elseif biomeDepth < minValue then
                                    restricted = true
                                elseif not Read("IgnoreMaxDepth") and biomeDepth > maxValue then
                                    restricted = true
                                end
                            elseif state.OnlyAllowForcedEncounters then
                                restricted = true
                            end
                            break
                        end
                    end
                end

                if restricted then
                    changed = true
                else
                    table.insert(filtered, encounterName)
                end
            end

            if changed then
                args.LegalEncounters = filtered
            end
        end

        return base(currentRun, room, args)
    end)

    for _, npcName in ipairs(npcPriorityList) do
        modutil.mod.Path.Wrap("Begin" .. npcName .. "Encounter", function(base, currentRun, room, args)
            if internal.IsEnabled() then
                local state = internal.GetRunState()
                if state then
                    state.NPCEncounterSeen[npcName] = true
                end
            end
            return base(currentRun, room, args)
        end)
    end
end
