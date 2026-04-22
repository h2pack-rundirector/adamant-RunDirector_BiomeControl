local internal = RunDirectorBiomeControl_Internal

local ROUTE_KEYS = {
    "DreamRouteBiome1",
    "DreamRouteBiome2",
    "DreamRouteBiome3",
    "DreamRouteBiome4",
}

local function Read(key)
    return internal.BiomeControlRead(key)
end

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

local function GetConfiguredRoute()
    if Read("DreamRouteEnabled") ~= true then return nil end

    local route = {}
    for _, key in ipairs(ROUTE_KEYS) do
        route[#route + 1] = Read(key)
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

function internal.RegisterDreamHooks()
    lib.hooks.Wrap(internal, "SelectNextDreamBiome", function(base, currentRoomSet)
        if not internal.IsEnabled() then return base(currentRoomSet) end
        if not CurrentRun or not CurrentRun.IsDreamRun or not CurrentRun.CurrentRoom then
            return base(currentRoomSet)
        end

        local route = GetConfiguredRoute()
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
