public = {}
_PLUGIN = { guid = "test-biome-control" }

local function deepCopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for key, value in pairs(orig) do
        copy[key] = deepCopy(value)
    end
    return copy
end

rom = {
    mods = {},
    game = {
        DeepCopyTable = deepCopy,
        SetupRunData = function() end,
    },
    ImGui = {},
    ImGuiCol = {
        Text = 1,
    },
    gui = {
        add_to_menu_bar = function() end,
        add_imgui = function() end,
    },
}

rom.mods["SGG_Modding-ENVY"] = {
    auto = function()
        return {}
    end,
}

rom.mods["SGG_Modding-Chalk"] = {
    auto = function()
        return { DebugMode = false }
    end,
    original = function(config)
        return config
    end,
}

local registeredWraps = {}

modutil = {
    once_loaded = {
        game = function() end,
    },
    mod = {
        Path = {
            Wrap = function(path, handler)
                registeredWraps[path] = handler
                local base = _G[path]
                _G[path] = function(...)
                    return handler(base, ...)
                end
            end,
        },
    },
}
rom.mods["SGG_Modding-ModUtil"] = modutil

local function color()
    return { 255, 255, 255, 255 }
end

game = {
    Color = {
        AphroditeVoice = color(),
        ApolloVoice = color(),
        AresVoice = color(),
        DemeterVoice = color(),
        HephaestusVoice = color(),
        HeraDamage = color(),
        HestiaVoice = color(),
        PoseidonVoice = color(),
        ZeusVoice = color(),
    },
}

local function contains(list, value)
    for _, current in ipairs(list or {}) do
        if current == value then
            return true
        end
    end
    return false
end

import = function(path, fenv, ...)
    local libPath = "../../adamant-ModpackLib/src/" .. path
    local modulePath = "src/" .. path
    local chunk = loadfile(libPath, "t", fenv or _ENV) or loadfile(modulePath, "t", fenv or _ENV)
    return assert(chunk, "unable to import " .. tostring(path))(...)
end

dofile("../../adamant-ModpackLib/src/main.lua")
lib = public
rom.mods["adamant-ModpackLib"] = lib

local function installBaseGlobals(opts)
    opts = opts or {}

    CurrentRun = opts.CurrentRun
    GameState = opts.GameState or {}
    RoomData = deepCopy(opts.RoomData or {
        F_Story01 = {
            Name = "F_Story01",
            GameStateRequirements = {
                { Path = { "CurrentRun", "BiomeDepthCache" }, Comparison = ">=", Value = 4 },
                { Path = { "CurrentRun", "BiomeDepthCache" }, Comparison = "<=", Value = 8 },
            },
        },
        F_MiniBoss01 = {
            Name = "F_MiniBoss01",
            GameStateRequirements = {},
        },
        H_MiniBoss01 = {
            Name = "H_MiniBoss01",
            GameStateRequirements = {},
        },
        H_MiniBoss02 = {
            Name = "H_MiniBoss02",
            GameStateRequirements = {},
        },
    })
    RoomSetData = deepCopy(opts.RoomSetData or {
        F = {
            F_Combat05 = { Name = "F_Combat05" },
        },
    })
    NamedRequirementsData = deepCopy(opts.NamedRequirementsData or {
        NoRecentFieldNPCEncounter = {
            { SumPrevRooms = 6 },
        },
    })
    EncounterData = deepCopy(opts.EncounterData or {
        ArtemisCombatF = {},
        ArtemisCombatG = {},
        NemesisCombatF = {},
    })

    Contains = contains
    GetEligibleLootNames = opts.GetEligibleLootNames or function()
        return { "ZeusUpgrade", "ApolloUpgrade" }
    end
    GiveLoot = opts.GiveLoot or function(args)
        return args
    end
    SetupRoomReward = opts.SetupRoomReward or function() end
    ChooseEncounter = opts.ChooseEncounter or function(_, _, args)
        return args
    end
    SelectNextDreamBiome = opts.SelectNextDreamBiome or function()
        return "base"
    end
    SelectFieldsDoorCageCount = opts.SelectFieldsDoorCageCount or function()
        return 3
    end
    GetInteractedGodsThisRun = opts.GetInteractedGodsThisRun or function()
        return {}
    end
    IsGameStateEligible = opts.IsGameStateEligible or function()
        return true
    end
    IsEncounterEligible = opts.IsEncounterEligible or function()
        return true
    end
end

local function applyOverrides(target, overrides)
    for key, value in pairs(overrides or {}) do
        target[key] = value
    end
end

function ResetBiomeControlHarness(opts)
    opts = opts or {}
    registeredWraps = {}
    installBaseGlobals(opts)

    RunDirectorBiomeControl_Internal = {
        DEFAULT_FIELD_MEDIUM = 0.4,
        REGION_UNDERWORLD = 1,
        REGION_SURFACE = 2,
    }

    local internal = RunDirectorBiomeControl_Internal
    dofile("src/mods/data.lua")
    dofile("src/mods/hash_groups.lua")
    dofile("src/mods/logic.lua")

    local dataDefaults = dofile("src/config.lua")
    local config = deepCopy(dataDefaults)
    applyOverrides(config, opts.config)

    local definition = lib.prepareDefinition(internal, dataDefaults, {
        modpack = "run-director",
        id = "BiomeControl",
        name = "Biome Control",
        affectsRunData = true,
        storage = internal.BuildStorage(),
        hashGroupPlan = internal.BuildHashGroupPlan and internal.BuildHashGroupPlan() or nil,
        patchPlan = internal.BuildPatchPlan,
    })

    local store, session = lib.createStore(config, definition)
    internal.store = store

    if opts.registerHooks then
        internal.host = lib.createModuleHost({
            definition = definition,
            store = store,
            session = session,
            hookOwner = internal,
            registerHooks = internal.RegisterHooks,
        })
    end

    return {
        internal = internal,
        definition = definition,
        config = config,
        store = store,
        session = session,
        wrappers = registeredWraps,
    }
end
