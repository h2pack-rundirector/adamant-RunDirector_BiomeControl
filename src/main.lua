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
---@class RunDirectorBiomeControlModuleAnchor
---@field standaloneUi StandaloneRuntime|nil
MODULE_ANCHOR = MODULE_ANCHOR or {}
---@type RunDirectorBiomeControlModuleAnchor
local moduleAnchor = MODULE_ANCHOR

moduleAnchor.standaloneUi = nil

local function registerGui()
    rom.gui.add_imgui(function()
        if moduleAnchor.standaloneUi and moduleAnchor.standaloneUi.renderWindow then
            moduleAnchor.standaloneUi.renderWindow()
        end
    end)

    rom.gui.add_to_menu_bar(function()
        if moduleAnchor.standaloneUi and moduleAnchor.standaloneUi.addMenuBar then
            moduleAnchor.standaloneUi.addMenuBar()
        end
    end)
end

local function init()
    import_as_fallback(rom.game)
    local data = import("mods/data.lua")
    local hashGroups = import("mods/hash_groups.lua").bind(data)
    local logic = import("mods/logic.lua").bind(data)
    local ui = import("mods/ui.lua").bind(data)

    local host = lib.tryCreateModule({
        owner = moduleAnchor,
        pluginGuid = PLUGIN_GUID,
        config = config,
        definition = {
            modpack = PACK_ID,
            id = MODULE_ID,
            name = "Biome Control",
            tooltip = "Control biome rooms, NPC encounters, rewards, and biome-specific tweaks.",
            storage = data.storage.build(),
            hashGroupPlan = hashGroups.buildHashGroupPlan(),
        },
        registerPatchMutation = logic.buildPatchPlan,
        registerHooks = logic.registerHooks,
        drawTab = ui.drawTab,
        drawQuickContent = ui.drawQuickContent,
    })
    if not host then
        return
    end

    local ok = host.tryActivate()
    if not ok then
        return
    end

    if not lib.isModuleCoordinated(PACK_ID) then
        moduleAnchor.standaloneUi = lib.standaloneHost(PLUGIN_GUID)
    else
        moduleAnchor.standaloneUi = nil
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(registerGui, init)
end)
