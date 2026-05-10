local mods = rom.mods
mods["SGG_Modding-ENVY"].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods["SGG_Modding-ModUtil"]
local chalk = mods["SGG_Modding-Chalk"]
local reload = mods["SGG_Modding-ReLoad"]
---@module "adamant-ModpackLib"
---@type AdamantModpackLib
lib = mods["adamant-ModpackLib"]

local config = chalk.auto("config.lua")

local PACK_ID = "run-director"
local MODULE_ID = "BiomeControl"
local PLUGIN_GUID = _PLUGIN.guid
---@class RunDirectorBiomeControlInternal
---@field standaloneUi StandaloneRuntime|nil
---@field BuildStorage fun(): StorageSchema|nil
---@field BuildHashGroupPlan fun(): table|nil
---@field BuildPatchPlan fun(plan: table, host: AuthorHost, store: ManagedStore)|nil
---@field RegisterHooks fun(host: AuthorHost, store: ManagedStore)|nil
---@field DrawTab fun(imgui: table, session: AuthorSession)|nil
---@field DrawQuickContent fun(imgui: table, session: AuthorSession)|nil
---@field DEFAULT_FIELD_MEDIUM number|nil
---@field REGION_UNDERWORLD integer|nil
---@field REGION_SURFACE integer|nil
---@field REGION_OPTIONS table|nil
RunDirectorBiomeControl_Internal = RunDirectorBiomeControl_Internal or {}
---@type RunDirectorBiomeControlInternal
local internal = RunDirectorBiomeControl_Internal

internal.DEFAULT_FIELD_MEDIUM = 0.4
internal.REGION_UNDERWORLD = 1
internal.REGION_SURFACE = 2
internal.REGION_OPTIONS = {
    { label = "Underworld", value = internal.REGION_UNDERWORLD },
    { label = "Surface", value = internal.REGION_SURFACE },
}

internal.standaloneUi = nil

local function registerGui()
    rom.gui.add_imgui(function()
        if internal.standaloneUi and internal.standaloneUi.renderWindow then
            internal.standaloneUi.renderWindow()
        end
    end)

    rom.gui.add_to_menu_bar(function()
        if internal.standaloneUi and internal.standaloneUi.addMenuBar then
            internal.standaloneUi.addMenuBar()
        end
    end)
end

local function init()
    import_as_fallback(rom.game)
    import("mods/data.lua")
    import("mods/hash_groups.lua")
    import("mods/logic.lua")
    import("mods/ui.lua")

    local host = lib.createModule({
        owner = internal,
        pluginGuid = PLUGIN_GUID,
        config = config,
        definition = {
            modpack = PACK_ID,
            id = MODULE_ID,
            name = "Biome Control",
            tooltip = "Control biome rooms, NPC encounters, rewards, and biome-specific tweaks.",
            storage = internal.BuildStorage(),
            hashGroupPlan = internal.BuildHashGroupPlan and internal.BuildHashGroupPlan() or nil,
        },
        registerPatchMutation = internal.BuildPatchPlan,
        registerHooks = internal.RegisterHooks,
        drawTab = internal.DrawTab,
        drawQuickContent = internal.DrawQuickContent,
    })
    host.activate()
    if not lib.isModuleCoordinated(PACK_ID) then
        internal.standaloneUi = lib.standaloneHost(PLUGIN_GUID)
    else
        internal.standaloneUi = nil
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(registerGui, init)
end)
