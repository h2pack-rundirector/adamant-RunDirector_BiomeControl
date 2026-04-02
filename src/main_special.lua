-- =============================================================================
-- ADAMANT SPECIAL MODULE TEMPLATE
-- =============================================================================
-- This file is the special-module template variant in this template repo.
-- Copy it to src/main.lua in a real special-module repo.
-- Fill in the TODO sections below.
-- luacheck: globals rom public import_as_fallback SetupRunData SpecialModule_Internal modutil lib store _PLUGIN game

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

SpecialModule_Internal = SpecialModule_Internal or {}
local internal = SpecialModule_Internal

-- =============================================================================
-- Definition
-- =============================================================================

public.definition = {
    modpack        = PACK_ID,
    id             = "TODO_SpecialId",
    name           = "TODO Special Module",
    tabLabel       = "TODO Tab Label",
    special        = true,
    tooltip        = "TODO tooltip",
    default        = false,
    affectsRunData = false,
    stateSchema = {
        -- { type = "dropdown", configKey = "Mode", values = { "A", "B" }, default = "A" },
        -- { type = "checkbox", configKey = { "Nested", "Flag" }, default = false },
    },
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
-- UI
-- =============================================================================

function public.DrawQuickContent(ui, _uiState, _theme)
    local _ = _uiState or _theme
    ui.Text("TODO quick content")
end

function public.DrawTab(ui, _uiState, _theme)
    local _ = _uiState or _theme
    ui.Text("TODO full tab content")
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

local standalone = lib.standaloneSpecialUI(public.definition, store, store.uiState, {
    getDrawQuickContent = function()
        return public.DrawQuickContent
    end,
    getDrawTab = function()
        return public.DrawTab
    end,
})

rom.gui.add_imgui(standalone.renderWindow)
rom.gui.add_to_menu_bar(standalone.addMenuBar)
