local controlDefs = {}

local DEFAULT_ROOM_MODE_VALUES = { "default", "disabled", "forced" }
local DEFAULT_ROOM_MODE_DISPLAY_VALUES = {
    default = "Default",
    disabled = "Disabled",
    forced = "Forced",
}
local PRIORITY_GODS = {
    { label = "Aphrodite",  lootKey = "AphroditeUpgrade",  colorKey = "AphroditeVoice" },
    { label = "Apollo",     lootKey = "ApolloUpgrade",     colorKey = "ApolloVoice" },
    { label = "Ares",       lootKey = "AresUpgrade",       colorKey = "AresVoice" },
    { label = "Demeter",    lootKey = "DemeterUpgrade",    colorKey = "DemeterVoice" },
    { label = "Hephaestus", lootKey = "HephaestusUpgrade", colorKey = "HephaestusVoice" },
    { label = "Hera",       lootKey = "HeraUpgrade",       colorKey = "HeraDamage" },
    { label = "Hestia",     lootKey = "HestiaUpgrade",     colorKey = "HestiaVoice" },
    { label = "Poseidon",   lootKey = "PoseidonUpgrade",   colorKey = "PoseidonVoice" },
    { label = "Zeus",       lootKey = "ZeusUpgrade",       colorKey = "ZeusVoice" },
}

local function normalizedColor(color)
    if type(color) ~= "table" then
        return nil
    end

    local r = tonumber(color[1])
    local g = tonumber(color[2])
    local b = tonumber(color[3])
    local a = tonumber(color[4])
    if r == nil or g == nil or b == nil or a == nil then
        return nil
    end

    return {
        r / 255,
        g / 255,
        b / 255,
        a / 255,
    }
end

local function buildGodChoiceMetadata(emptyLabel)
    local values = { "" }
    local displayValues = {
        [""] = emptyLabel,
    }
    local valueColors = {}
    local godKeyByValue = {}

    for _, god in ipairs(PRIORITY_GODS) do
        values[#values + 1] = god.lootKey
        displayValues[god.lootKey] = god.label
        godKeyByValue[god.lootKey] = god.label
        local color = god.colorKey and game.Color[god.colorKey] or nil
        valueColors[god.lootKey] = normalizedColor(color)
    end

    return values, displayValues, valueColors, godKeyByValue
end

local function buildModeRange(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "ModeWithRange",
        label = opts.label,
        helpText = opts.helpText,
        values = opts.values or DEFAULT_ROOM_MODE_VALUES,
        displayValues = opts.displayValues or DEFAULT_ROOM_MODE_DISPLAY_VALUES,
        default = opts.default or "default",
        range = {
            min = opts.min,
            max = opts.max,
            defaultMin = opts.defaultMin,
            defaultMax = opts.defaultMax,
            visibleWhen = opts.visibleWhen or opts.rangeVisibleWhen,
            controlWidth = opts.controlWidth,
            rangeColumnX = opts.rangeColumnX,
        },
    }
end

function controlDefs.modeWithRange(name, opts)
    return buildModeRange(name, opts)
end

function controlDefs.mode(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "Mode",
        label = opts.label,
        helpText = opts.helpText,
        values = opts.values or DEFAULT_ROOM_MODE_VALUES,
        displayValues = opts.displayValues or DEFAULT_ROOM_MODE_DISPLAY_VALUES,
        default = opts.default or "default",
    }
end

function controlDefs.choice(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "Choice",
        label = opts.label,
        helpText = opts.helpText,
        type = opts.type or opts.storageType,
        values = opts.values,
        valueRange = opts.valueRange,
        displayValues = opts.displayValues,
        valueColors = opts.valueColors,
        default = opts.default,
        min = opts.min,
        max = opts.max,
        maxLen = opts.maxLen,
    }
end

function controlDefs.godChoice(name, opts)
    opts = opts or {}
    local emptyLabel = opts.emptyLabel
    if emptyLabel == nil then
        emptyLabel = "None"
    end
    local values, displayValues, valueColors, godKeyByValue = buildGodChoiceMetadata(emptyLabel)
    return {
        name = name,
        template = "GodChoice",
        label = opts.label,
        helpText = opts.helpText,
        values = values,
        displayValues = displayValues,
        valueColors = valueColors,
        godKeyByValue = godKeyByValue,
        default = opts.default or "",
        maxLen = opts.maxLen,
    }
end

function controlDefs.dreamRoute(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "DreamRoute",
        label = opts.label,
        helpText = opts.helpText,
        values = opts.values,
        displayValues = opts.displayValues,
        naturalNextBiome = opts.naturalNextBiome,
        firstSlotDisallowed = opts.firstSlotDisallowed,
        defaults = opts.defaults,
        defaultEnabled = opts.defaultEnabled,
        labelWidth = opts.labelWidth,
        controlWidth = opts.controlWidth,
    }
end

function controlDefs.flag(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "Flag",
        label = opts.label,
        helpText = opts.helpText,
        default = opts.default,
    }
end

function controlDefs.packedSet(name, opts)
    opts = opts or {}
    return {
        name = name,
        template = "PackedSet",
        label = opts.label,
        helpText = opts.helpText,
        options = opts.options,
        default = opts.default,
    }
end

return controlDefs
