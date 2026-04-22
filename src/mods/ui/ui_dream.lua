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

local function IsValidAtSlot(value, slot, previous, used)
    if not IsKnownBiome(value) then return false end
    if slot == 1 and (value == "F" or value == "N") then return false end
    if used[value] then return false end
    if previous and internal.dreamNaturalNextBiome[previous] == value then return false end
    return true
end

local function FirstValidValue(slot, previous, used)
    for _, value in ipairs(internal.dreamBiomeOptions or {}) do
        if IsValidAtSlot(value, slot, previous, used) then
            return value
        end
    end
    return ""
end

local function NormalizeRoute(session)
    local previous = nil
    local used = {}

    for slot, key in ipairs(ROUTE_KEYS) do
        local value = session.view[key]
        if not IsValidAtSlot(value, slot, previous, used) then
            value = FirstValidValue(slot, previous, used)
            session.write(key, value)
        end
        used[value] = true
        previous = value
    end
end

local function BuildSlotValues(slot, previous, used, current)
    local values = {}
    for _, value in ipairs(internal.dreamBiomeOptions or {}) do
        if value == current or IsValidAtSlot(value, slot, previous, used) then
            values[#values + 1] = value
        end
    end
    return values
end

function internal.DrawDreamTab(imgui, session)
    NormalizeRoute(session)

    internal.DrawSectionHeading(imgui, "Dream Route", { 0.72, 0.80, 1.0, 1.0 })
    lib.widgets.checkbox(imgui, session, "DreamRouteEnabled", {
        label = "Override Dream Run Biomes",
    })

    if session.view.DreamRouteEnabled ~= true then
        return
    end

    local previous = nil
    local used = {}
    for slot, key in ipairs(ROUTE_KEYS) do
        local current = session.view[key]
        local changed = lib.widgets.dropdown(imgui, session, key, {
            label = "Biome " .. slot,
            values = BuildSlotValues(slot, previous, used, current),
            displayValues = internal.dreamBiomeDisplayValues,
            labelWidth = 80,
            controlWidth = 180,
        })

        if changed then
            NormalizeRoute(session)
            current = session.view[key]
        end

        used[current] = true
        previous = current
    end
end
