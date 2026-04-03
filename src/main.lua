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

local config = chalk.auto("config.lua")

local PACK_ID = "run-director"
RunDirectorBiomeControl_Internal = RunDirectorBiomeControl_Internal or {}
local internal = RunDirectorBiomeControl_Internal
internal.packId = PACK_ID

import("mods/data.lua")

public.definition = {
    modpack = PACK_ID,
    id = "RunDirectorBiomeControl",
    name = "Biome Control",
    tabLabel = "Biome Control",
    category = "Run Director",
    group = "Run Setup",
    tooltip = "Control biome rooms, NPC encounters, rewards, and biome-specific tweaks.",
    default = false,
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
internal.schemaFieldByConfigKey = {}
internal.depthRuntimeFields = {}

local function AddSchemaField(schema, seen, field)
    local key = tostring(field.configKey)
    if seen[key] then return end
    seen[key] = true
    table.insert(schema, field)
end

local function AddDepthSchemaFields(schema, seen, definitions)
    for _, def in ipairs(definitions) do
        AddSchemaField(schema, seen, {
            type = "stepper",
            configKey = def.configKeyMin,
            label = def.label .. " Min",
            default = config[def.configKeyMin] or def.minDefault,
            min = def.minDefault,
            max = def.maxDefault,
        })
        AddSchemaField(schema, seen, {
            type = "stepper",
            configKey = def.configKeyMax,
            label = def.label .. " Max",
            default = config[def.configKeyMax] or def.maxDefault,
            min = def.minDefault,
            max = def.maxDefault,
        })
    end
end

local function BuildDepthRuntimeFields(definitions)
    for _, def in ipairs(definitions) do
        local minField = internal.schemaFieldByConfigKey[def.configKeyMin]
        local maxField = internal.schemaFieldByConfigKey[def.configKeyMax]
        internal.depthRuntimeFields[def.configKeyMin] = {
            type = "stepper",
            configKey = minField.configKey,
            label = "Min",
            default = minField.default,
            min = minField.min,
            max = minField.max,
        }
        internal.depthRuntimeFields[def.configKeyMax] = {
            type = "stepper",
            configKey = maxField.configKey,
            label = "Max",
            default = maxField.default,
            min = maxField.min,
            max = maxField.max,
        }
    end
end

definition.stateSchema = {}
do
    local seen = {}
    AddSchemaField(definition.stateSchema, seen, {
        type = "checkbox",
        configKey = "OnlyAllowForcedEncounters",
        label = "Only Allow Forced NPC Encounters",
        default = config.OnlyAllowForcedEncounters,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "checkbox",
        configKey = "IgnoreMaxDepth",
        label = "Ignore NPC Max Depth Requirements",
        default = config.IgnoreMaxDepth,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "stepper",
        configKey = "NPCSpacing",
        label = "Global NPC Spacing",
        default = config.NPCSpacing,
        min = 1,
        max = 12,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "checkbox",
        configKey = "PrioritizeSpecificRewardEnabled",
        label = "Prioritize First Reward in Each Biome",
        default = config.PrioritizeSpecificRewardEnabled,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityBiome1",
        label = "Route Biome 1 Priority",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityBiome1,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityBiome2",
        label = "Route Biome 2 Priority",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityBiome2,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityBiome3",
        label = "Route Biome 3 Priority",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityBiome3,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityBiome4",
        label = "Route Biome 4 Priority",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityBiome4,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "checkbox",
        configKey = "PrioritizeTrialRewardEnabled",
        label = "Prioritize Trial Rewards",
        default = config.PrioritizeTrialRewardEnabled,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityTrial1",
        label = "Trial Priority A",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityTrial1,
    })
    AddSchemaField(definition.stateSchema, seen, {
        type = "dropdown",
        configKey = "PriorityTrial2",
        label = "Trial Priority B",
        values = internal.priorityOptions,
        displayValues = internal.priorityDisplayValues,
        default = config.PriorityTrial2,
    })

    for _, field in ipairs(internal.specialStateFields) do
        AddSchemaField(definition.stateSchema, seen, {
            type = field.type,
            configKey = field.configKey,
            label = field.label,
            default = config[field.configKey],
            min = field.min,
            max = field.max,
            values = field.values,
            displayValues = field.displayValues,
        })
    end

    for _, configKey in ipairs(internal.packedModeConfigKeys) do
        AddSchemaField(definition.stateSchema, seen, {
            type = "int32",
            configKey = configKey,
            default = config[configKey] or 0,
        })
    end

    for _, configKey in ipairs(internal.packedNPCModeConfigKeys) do
        AddSchemaField(definition.stateSchema, seen, {
            type = "int32",
            configKey = configKey,
            default = config[configKey] or 0,
        })
    end

    AddDepthSchemaFields(definition.stateSchema, seen, internal.roomDefinitions)
    AddDepthSchemaFields(definition.stateSchema, seen, internal.npcDefinitions)
end

for _, field in ipairs(definition.stateSchema) do
    internal.schemaFieldByConfigKey[field.configKey] = field
end

BuildDepthRuntimeFields(internal.roomDefinitions)
BuildDepthRuntimeFields(internal.npcDefinitions)

public.store = lib.createStore(config, definition)
store = public.store
RunDirectorBiomeControl_Public = public

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
