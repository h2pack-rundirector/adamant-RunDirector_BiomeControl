local mods = rom.mods
mods["SGG_Modding-ENVY"].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods["SGG_Modding-ModUtil"]
local chalk = mods["SGG_Modding-Chalk"]
local reload = mods["SGG_Modding-ReLoad"]
---@type AdamantModpackLib
lib = mods["adamant-ModpackLib"]

local dataDefaults = import("config.lua")
local config = chalk.auto("config.lua")

local PACK_ID = "run-director"
---@class RunDirectorBiomeControlInternal
---@field packId string|nil
---@field definition ModuleDefinition|nil
---@field store ManagedStore|nil
---@field standaloneUi StandaloneRuntime|nil
---@field BuildDefinitionStorage fun()|nil
---@field BuildHashGroups fun(storage: StorageSchema|nil): table|nil
---@field RegisterHooks fun()|nil
---@field DrawTab fun(imgui: table, session: AuthorSession)|nil
---@field DrawQuickContent fun(imgui: table, session: AuthorSession)|nil
---@field DEFAULT_FIELD_MEDIUM number|nil
---@field REGION_UNDERWORLD integer|nil
---@field REGION_SURFACE integer|nil
---@field REGION_OPTIONS table|nil
---@field regionFilter integer|nil
RunDirectorBiomeControl_Internal = RunDirectorBiomeControl_Internal or {}
---@type RunDirectorBiomeControlInternal
local internal = RunDirectorBiomeControl_Internal
internal.packId = PACK_ID

public.definition = {
    modpack = PACK_ID,
    id = "BiomeControl",
    name = "Biome Control",
    tooltip = "Control biome rooms, NPC encounters, rewards, and biome-specific tweaks.",
    default = dataDefaults.Enabled,
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

public.host = nil
local store
local session
internal.standaloneUi = nil

local function init()
    import_as_fallback(rom.game)
    import("mods/data.lua")
    import("mods/hash_groups.lua")
    import("mods/logic.lua")
    import("mods/ui.lua")

    internal.BuildDefinitionStorage()

    store, session = lib.createStore(config, public.definition, dataDefaults)
    internal.store = store
    RunDirectorBiomeControl_Public = public

    if internal.BuildHashGroups then
        public.definition.hashGroups = internal.BuildHashGroups(public.definition.storage)
    end

    public.host = lib.createModuleHost({
        definition = public.definition,
        store = store,
        session = session,
        hookOwner = internal,
        registerHooks = internal.RegisterHooks,
        drawTab = internal.DrawTab,
        drawQuickContent = internal.DrawQuickContent,
    })
    internal.standaloneUi = lib.standaloneHost(public.host)
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(nil, init)
end)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_imgui(function()
    if internal.standaloneUi and internal.standaloneUi.renderWindow then
        internal.standaloneUi.renderWindow()
    end
end)

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_to_menu_bar(function()
    if internal.standaloneUi and internal.standaloneUi.addMenuBar then
        internal.standaloneUi.addMenuBar()
    end
end)
