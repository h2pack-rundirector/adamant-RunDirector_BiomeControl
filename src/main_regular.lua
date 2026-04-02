-- =============================================================================
-- ADAMANT REGULAR MODULE TEMPLATE
-- =============================================================================
-- Copy this file as src/main.lua in a new module repo.
-- Fill in the TODO sections below.
-- luacheck: globals rom public import_as_fallback SetupRunData RegularModule_Internal modutil lib store _PLUGIN game

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

local PACK_ID = error("TODO: set PACK_ID to your pack id")

RegularModule_Internal = RegularModule_Internal or {}
local internal = RegularModule_Internal

-- =============================================================================
-- Definition
-- =============================================================================

public.definition = {
    modpack        = PACK_ID,
    id             = "TODO_ModId",
    name           = "TODO Module Name",
    category       = "TODO Category",
    group          = "TODO Group",
    tooltip        = "TODO tooltip",
    default        = true,
    affectsRunData = false,

    -- Optional inline options for hosted/standalone managed UI.
    -- configKey must be a flat string in regular modules.
    -- options = {
    --     { type = "checkbox", configKey = "Strict", label = "Strict Mode", default = false },
    --     { type = "dropdown", configKey = "Mode", label = "Mode",
    --       values = { "Vanilla", "Always", "Never" }, default = "Vanilla" },
    -- },
}
public.store = lib.createStore(config, public.definition)
store = public.store

-- Required:
-- Keep raw Chalk config local to main.lua.
-- After store creation, imported files must use store.read/store.write.
-- modutil, lib, and store may be shared across this module's files.

-- =============================================================================
-- Optional run-data lifecycle
-- =============================================================================

-- Patch-only example:
--
-- public.definition.affectsRunData = true
-- public.definition.patchPlan = function(plan, store)
--     plan:set(SomeTable, "SomeKey", 123)
-- end

-- Manual example:
--
-- local backup, restore = lib.createBackupSystem()
--
-- public.definition.affectsRunData = true
-- public.definition.apply = function()
--     backup(SomeTable, "SomeKey")
--     SomeTable.SomeKey = 123
-- end
-- public.definition.revert = restore

-- Hybrid example:
--
-- public.definition.patchPlan = function(plan, store)
--     plan:set(SomeTable, "SomeKey", 123)
-- end
-- public.definition.apply = function()
--     -- procedural remainder
-- end
-- public.definition.revert = function()
--     -- procedural remainder revert
-- end

-- =============================================================================
-- Optional hooks
-- =============================================================================

function internal.RegisterHooks()
    -- modutil.mod.Path.Wrap("SomeGameFunction", function(baseFunc, ...)
    --     if not lib.isEnabled(store, public.definition.modpack) then
    --         return baseFunc(...)
    --     end
    --     return baseFunc(...)
    -- end)
end

-- =============================================================================
-- Bootstrap
-- =============================================================================

local function init()
    import_as_fallback(rom.game)

    if internal.RegisterHooks then
        internal.RegisterHooks()
    end

    if lib.isEnabled(store, public.definition.modpack) then
        lib.applyDefinition(public.definition, store)
    end

    if public.definition.affectsRunData and not lib.isCoordinated(public.definition.modpack) then
        SetupRunData()
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(init, init)
end)

rom.gui.add_to_menu_bar(lib.standaloneUI(public.definition, store))
