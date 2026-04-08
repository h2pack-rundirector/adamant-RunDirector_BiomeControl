local mods = rom.mods
mods["SGG_Modding-ENVY"].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods["SGG_Modding-ModUtil"]
local chalk = mods["SGG_Modding-Chalk"]
local reload = mods["SGG_Modding-ReLoad"]
lib = mods["adamant-ModpackLib"]

local dataDefaults = import("config.lua")
local config = chalk.auto("config.lua")

local PACK_ID = "run-director"
RunDirectorBiomeControl_Internal = RunDirectorBiomeControl_Internal or {}
local internal = RunDirectorBiomeControl_Internal
internal.packId = PACK_ID

import("mods/data.lua")

public.definition = {
    modpack = PACK_ID,
    id = "BiomeControl",
    name = "Biome Control",
    tooltip = "Control biome rooms, NPC encounters, rewards, and biome-specific tweaks.",
    default = dataDefaults.Enabled,
    special = true,
    affectsRunData = true,
}
definition = public.definition

internal.DEFAULT_FIELD_MEDIUM = 0.4
internal.REGION_UNDERWORLD = 1
internal.REGION_SURFACE = 2
internal.REGION_OPTIONS = {
    { label = "Underworld", value = internal.REGION_UNDERWORLD },
    { label = "Surface", value = internal.REGION_SURFACE },
}
internal.regionFilter = config.ViewRegion or internal.REGION_UNDERWORLD

-- =============================================================================
-- STORAGE
-- =============================================================================

definition.storage = {
    { type = "bool",   configKey = "OnlyAllowForcedEncounters" },
    { type = "bool",   configKey = "IgnoreMaxDepth" },
    { type = "int",    configKey = "NPCSpacing",                     min = 1, max = 12 },
    { type = "bool",   configKey = "PrioritizeSpecificRewardEnabled" },
    { type = "string", configKey = "PriorityBiome1" },
    { type = "string", configKey = "PriorityBiome2" },
    { type = "string", configKey = "PriorityBiome3" },
    { type = "string", configKey = "PriorityBiome4" },
    { type = "bool",   configKey = "PrioritizeTrialRewardEnabled" },
    { type = "string", configKey = "PriorityTrial1" },
    { type = "string", configKey = "PriorityTrial2" },
    { type = "int",    configKey = "ViewRegion" },
}

-- Special state fields registered by biome files
local STORAGE_TYPE_MAP = { checkbox = "bool", stepper = "int", dropdown = "string", int32 = "int" }

for _, field in ipairs(internal.specialStateFields) do
    local storageType = STORAGE_TYPE_MAP[field.type] or field.type
    local default = field.default
    if default == nil then
        if storageType == "bool" then default = false
        elseif storageType == "string" then default = ""
        else default = field.min or 0
        end
    end
    table.insert(definition.storage, {
        type      = storageType,
        configKey = field.configKey,
        default   = default,
        min       = field.min,
        max       = field.max,
    })
end

-- Special range fields registered by biome files (two int nodes per pair)
for _, field in ipairs(internal.specialRangeFields) do
    table.insert(definition.storage, { type = "int", configKey = field.configKeyMin, default = field.min, min = field.min, max = field.max })
    table.insert(definition.storage, { type = "int", configKey = field.configKeyMax, default = field.max, min = field.min, max = field.max })
end

-- Packed mode storage (room modes and NPC modes)
for _, configKey in ipairs(internal.packedModeConfigKeys) do
    table.insert(definition.storage, { type = "int", configKey = configKey, default = 0 })
end
for _, configKey in ipairs(internal.packedNPCModeConfigKeys) do
    table.insert(definition.storage, { type = "int", configKey = configKey, default = 0 })
end

-- Depth storage nodes: two ints per room/NPC definition
local function AddDepthStorageNodes(definitions)
    local seen = {}
    for _, def in ipairs(definitions) do
        if not seen[def.configKeyMin] then
            seen[def.configKeyMin] = true
            table.insert(definition.storage, { type = "int", configKey = def.configKeyMin, default = def.minDefault, min = def.minDefault, max = def.maxDefault })
        end
        if not seen[def.configKeyMax] then
            seen[def.configKeyMax] = true
            table.insert(definition.storage, { type = "int", configKey = def.configKeyMax, default = def.maxDefault, min = def.minDefault, max = def.maxDefault })
        end
    end
end

AddDepthStorageNodes(internal.roomDefinitions)
AddDepthStorageNodes(internal.npcDefinitions)

-- =============================================================================
-- STORE
-- =============================================================================

public.store = lib.createStore(config, definition, dataDefaults)
store = public.store
RunDirectorBiomeControl_Public = public

-- =============================================================================
-- UI NODE REGISTRIES
-- Built after createStore so storage aliases are resolved.
-- Nodes are not in definition.ui — BiomeControl uses custom DrawTab.
-- ui.lua calls lib.drawUiNode via these lookup tables.
-- =============================================================================

local uiNodes = {
    { type = "dropdown", label = "Route Biome 1 Priority", binds = { value = "PriorityBiome1" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "dropdown", label = "Route Biome 2 Priority", binds = { value = "PriorityBiome2" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "dropdown", label = "Route Biome 3 Priority", binds = { value = "PriorityBiome3" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "dropdown", label = "Route Biome 4 Priority", binds = { value = "PriorityBiome4" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "dropdown", label = "Trial Priority A",       binds = { value = "PriorityTrial1" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "dropdown", label = "Trial Priority B",       binds = { value = "PriorityTrial2" }, values = internal.priorityOptions, displayValues = internal.priorityDisplayValues },
    { type = "stepper",  label = "Global NPC Spacing",     binds = { value = "NPCSpacing"     }, min = 1, max = 12 },
}

local function MakeDepthRangeGeometry()
    return {
        separatorStart = 160,
        control2Start = 200,
        valueWidth = 110,
        valueAlign = "center",
        incrementStart = 100,
        decrementStart  = 0,
    }
end

for _, field in ipairs(internal.specialStateFields) do
    if field.type == "dropdown" then
        table.insert(uiNodes, {
            type          = "dropdown",
            label         = field.label or field.configKey,
            binds         = { value = field.configKey },
            values        = field.values,
            displayValues = field.displayValues,
        })
    end
end

for _, def in ipairs(internal.roomDefinitions) do
    table.insert(uiNodes, {
        type = "steppedRange", label = "",
        binds = { min = def.configKeyMin, max = def.configKeyMax },
        min = def.minDefault, max = def.maxDefault,
        default = def.minDefault, defaultMax = def.maxDefault,
        geometry = MakeDepthRangeGeometry(),
    })
end

for _, def in ipairs(internal.npcDefinitions) do
    table.insert(uiNodes, {
        type = "steppedRange", label = "",
        binds = { min = def.configKeyMin, max = def.configKeyMax },
        min = def.minDefault, max = def.maxDefault,
        default = def.minDefault, defaultMax = def.maxDefault,
        geometry = MakeDepthRangeGeometry(),
    })
end

for _, field in ipairs(internal.specialRangeFields) do
    table.insert(uiNodes, {
        type = "steppedRange", label = "",
        binds = { min = field.configKeyMin, max = field.configKeyMax },
        min = field.min, max = field.max,
        default = field.min, defaultMax = field.max,
        geometry = MakeDepthRangeGeometry(),
    })
end

internal.uiNodes = lib.prepareUiNodes(uiNodes, "BiomeControl ui", definition.storage)

-- =============================================================================
-- PATCH PLAN + HOOKS
-- =============================================================================

definition.patchPlan = function(plan)
    if internal.BuildPatchPlan then
        internal.BuildPatchPlan(plan)
    end
end

local function registerHooks()
    import("mods/logic.lua")
    import("mods/ui.lua")
    if internal.RegisterHooks then
        internal.RegisterHooks()
    end
    public.DrawTab = internal.DrawTab
    public.DrawQuickContent = internal.DrawQuickContent
end

local function init()
    import_as_fallback(rom.game)
    registerHooks()
    if lib.isEnabled(store, definition.modpack) then
        lib.applyDefinition(definition, store)
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(init, init)
end)

local standaloneUi = lib.standaloneSpecialUI(
    public.definition,
    store,
    store.uiState,
    {
        getDrawQuickContent = function()
            return public.DrawQuickContent
        end,
        getDrawTab = function()
            return public.DrawTab
        end,
    }
)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_imgui(standaloneUi.renderWindow)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_to_menu_bar(standaloneUi.addMenuBar)
