local internal = RunDirectorBiomeControl_Internal

local ROUTE_KEYS = {
    "DreamRouteBiome1",
    "DreamRouteBiome2",
    "DreamRouteBiome3",
    "DreamRouteBiome4",
}

local function IsKnownBiome(value)
    return internal.dreamBiomeDisplayValues[value] ~= nil
end

local function IsValidRoute(route)
    local used = {}

    for index, biome in ipairs(route) do
        if not IsKnownBiome(biome) then return false end
        if index == 1 and (biome == "F" or biome == "N") then return false end
        if used[biome] then return false end
        if index > 1 and internal.dreamNaturalNextBiome[route[index - 1]] == biome then return false end
        used[biome] = true
    end

    return #route == 4
end

local function GetConfiguredRoute(read)
    if read("DreamRouteEnabled") ~= true then return nil end

    local route = {}
    for _, key in ipairs(ROUTE_KEYS) do
        route[#route + 1] = read(key)
    end

    if not IsValidRoute(route) then
        return nil
    end
    return route
end

local function UpdateDreamBiomePool(route, slot)
    CurrentRun.DreamBiomePool = {}
    for index = slot + 1, #route do
        CurrentRun.DreamBiomePool[#CurrentRun.DreamBiomePool + 1] = route[index]
    end
end

function internal.RegisterDreamHooks(host, store)
    local read = store.read

    lib.hooks.Wrap(internal, "SelectNextDreamBiome", function(base, currentRoomSet)
        if not host.isEnabled() then return base(currentRoomSet) end
        if not CurrentRun or not CurrentRun.IsDreamRun or not CurrentRun.CurrentRoom then
            return base(currentRoomSet)
        end

        local route = GetConfiguredRoute(read)
        if not route then return base(currentRoomSet) end

        local slot = (CurrentRun.EnteredBiomes or 0) + 1
        local nextRoomSet = route[slot]
        if not nextRoomSet then return base(currentRoomSet) end
        if currentRoomSet and internal.dreamNaturalNextBiome[currentRoomSet] == nextRoomSet then
            return base(currentRoomSet)
        end

        CurrentRun.CurrentRoom.NextRoomSet = { nextRoomSet }
        if slot == 1 then
            GameState.LastDreamStartingBiome = nextRoomSet
        end
        UpdateDreamBiomePool(route, slot)
    end)
end
