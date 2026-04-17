local internal = RunDirectorBiomeControl_Internal

local THESSALY_MINIBOSS_MODE_OPTIONS = { "default", "charybdis", "captain", "disabled" }
local THESSALY_MINIBOSS_MODE_DISPLAY = {
    default = "Default",
    charybdis = "Force Charybdis",
    captain = "Force The Yargonaut",
    disabled = "Disable Both",
}

local function appendImpossibleRequirement(plan, roomKey)
    local room = RoomData and RoomData[roomKey]
    if not room then return end
    plan:appendUnique(room, "GameStateRequirements", {
        Path = { "CurrentRun", "BiomeDepthCache" },
        Comparison = "==",
        Value = -1,
    })
end

local function applyBiomeDepthRange(plan, roomKey, minValue, maxValue)
    local room = RoomData and RoomData[roomKey]
    if not room then return end

    plan:setMany(room, {
        ForceAtBiomeDepthMin = minValue,
        ForceAtBiomeDepthMax = maxValue,
        AlwaysForce = true,
    })

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

internal.registerNPCControl({ id = "Heracles", biome = "O", min = 0, max = 10 })
internal.registerNPCControl({ id = "Icarus", biome = "O", min = 3, max = 8 })
internal.registerRoomControl({ id = "Circe", type = "Story", biome = "O", min = 4, max = 5 })
internal.registerRoomControl({ id = "Trial", type = "Trial", biome = "O", useRegionInKey = true, min = 2, max = 6 })
internal.registerRoomControl({ id = "Fountain", type = "Fountain", biome = "O", useRegionInKey = true, min = 3, max = 5 })
internal.registerRoomControl({ id = "Shop", type = "Shop", biome = "O", useRegionInKey = true, min = 4, max = 5 })

internal.registerRangeField({
    label = "Forced Range",
    configKeyMin = "PackedForcedThessalyMiniBossMin",
    configKeyMax = "PackedForcedThessalyMiniBossMax",
    min = 3, max = 5,
})

internal.registerBiomeRoom("O", {
    kind = "modeField",
    label = "Miniboss",
    roomGroup = "MiniBoss",
    modeKey = "ThessalyMiniBossMode",
    modeValues = THESSALY_MINIBOSS_MODE_OPTIONS,
    modeDisplayValues = THESSALY_MINIBOSS_MODE_DISPLAY,
    defaultMode = "default",
    helpText = "(Default lets the game decide, Forced selects one miniboss, Disabled suppresses both)",
    rangeConfigKeys = {
        min = "PackedForcedThessalyMiniBossMin",
        max = "PackedForcedThessalyMiniBossMax",
    },
    rangeVisibleValues = { "charybdis", "captain" },
})

internal.registerPatchBuilder(function(plan, read, log)
    local mode = internal.GetModeValue(read, "ThessalyMiniBossMode")
    if mode == "default" then
        return
    end

    if mode == "disabled" then
        appendImpossibleRequirement(plan, "O_MiniBoss01")
        appendImpossibleRequirement(plan, "O_MiniBoss02")
        log("Disabled both Thessaly miniboss rooms")
        return
    end

    local minValue = read("PackedForcedThessalyMiniBossMin") or 3
    local maxValue = read("PackedForcedThessalyMiniBossMax") or 5
    if minValue > maxValue then
        maxValue = minValue
    end

    if mode == "charybdis" then
        applyBiomeDepthRange(plan, "O_MiniBoss01", minValue, maxValue)
        appendImpossibleRequirement(plan, "O_MiniBoss02")
        log("Forced Thessaly Charybdis miniboss")
    elseif mode == "captain" then
        applyBiomeDepthRange(plan, "O_MiniBoss02", minValue, maxValue)
        appendImpossibleRequirement(plan, "O_MiniBoss01")
        log("Forced Thessaly The Yargonaut miniboss")
    end
end)
