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
import("mods/ui_settings.lua")
import("mods/ui_npc.lua")
import("mods/ui_lean.lua")

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
internal.definition = public.definition

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
local PACKED_REWARD_FIELDS = {}

for _, rewards in pairs(internal.biomeRewards or {}) do
    for _, reward in ipairs(rewards) do
        if reward.kind == "packedCheckboxes" and type(reward.configKey) == "string" and reward.configKey ~= "" then
            PACKED_REWARD_FIELDS[reward.configKey] = reward
        end
    end
end

for _, field in ipairs(internal.specialStateFields) do
    if not PACKED_REWARD_FIELDS[field.configKey] then
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
end

for configKey, reward in pairs(PACKED_REWARD_FIELDS) do
    local bits = {}
    for _, option in ipairs(reward.options or {}) do
        bits[#bits + 1] = {
            alias = configKey .. "_" .. tostring(option.name or option.label or option.bit),
            label = option.label or tostring(option.name or option.bit),
            type = "bool",
            offset = option.bit,
            width = 1,
            default = false,
        }
    end
    table.insert(definition.storage, {
        type = "packedInt",
        configKey = configKey,
        alias = configKey,
        default = 0,
        bits = bits,
    })
end

-- Special range fields registered by biome files (two int nodes per pair)
for _, field in ipairs(internal.specialRangeFields) do
    table.insert(definition.storage, { type = "int", configKey = field.configKeyMin, default = field.min, min = field.min, max = field.max })
    table.insert(definition.storage, { type = "int", configKey = field.configKeyMax, default = field.max, min = field.min, max = field.max })
end

-- Mode storage (room modes and NPC modes)
for _, field in ipairs(internal.modeStorageFields) do
    table.insert(definition.storage, field)
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

public.store = lib.store.create(config, definition, dataDefaults)
store = public.store
RunDirectorBiomeControl_Public = public

-- =============================================================================
-- UI
-- The lean immediate-mode shell is the active UI path on this branch.
-- =============================================================================


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
    if internal.RegisterHooks then
        internal.RegisterHooks()
    end
    public.DrawTab = internal.DrawTab
    public.AfterDrawTab = internal.AfterDrawTab
    public.DrawQuickContent = internal.DrawQuickContent
end

local function init()
    import_as_fallback(rom.game)
    registerHooks()
    if lib.coordinator.isEnabled(store, definition.modpack) then
        lib.mutation.apply(definition, store)
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(init, init)
end)

local standaloneUi = lib.special.standaloneUI(
    public.definition,
    store,
    store.uiState,
    {
        getDrawTab = function()
            return public.DrawTab
        end,
        getAfterDrawTab = function()
            return public.AfterDrawTab
        end,
    }
)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_imgui(standaloneUi.renderWindow)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_to_menu_bar(standaloneUi.addMenuBar)
