local lu = require("luaunit")
local harness = dofile("../../Setup/tests/module_entrypoint_harness.lua")

TestEntrypoint = {}

local function configureBiomeControlEnv(env)
    env.rom.game.Color = harness.makeColorTable()
    env.CurrentRun = nil
    env.GameState = {}
    env.RewardStoreData = {}
    env.RoomData = {
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
    }
    env.RoomSetData = {
        F = {
            F_Combat05 = { Name = "F_Combat05" },
        },
    }
    env.NamedRequirementsData = {
        NoRecentFieldNPCEncounter = {
            { SumPrevRooms = 6 },
        },
    }
    env.EncounterData = {
        ArtemisCombatF = {},
        ArtemisCombatG = {},
        NemesisCombatF = {},
    }
    env.Contains = function(list, value)
        for _, current in ipairs(list or {}) do
            if current == value then
                return true
            end
        end
        return false
    end
    env.GetEligibleLootNames = function()
        return { "ZeusUpgrade", "ApolloUpgrade" }
    end
    env.GiveLoot = function(args)
        return args
    end
    env.SetupRoomReward = function() end
    env.ChooseEncounter = function(_, _, args)
        return args
    end
    env.SelectNextDreamBiome = function()
        return "base"
    end
    env.SelectFieldsDoorCageCount = function()
        return 3
    end
    env.GetInteractedGodsThisRun = function()
        return {}
    end
    env.IsGameStateEligible = function()
        return true
    end
    env.IsEncounterEligible = function()
        return true
    end
end

function TestEntrypoint:testMainLuaBootsRealModule()
    local boot = harness.bootModule({
        pluginGuid = "adamant-RunDirector_BiomeControl",
        moduleSrcDir = "src",
        configureEnv = configureBiomeControlEnv,
    })

    lu.assertNotNil(boot.host)
    lu.assertEquals(boot.host.getIdentity().id, "BiomeControl")
    lu.assertEquals(boot.host.getIdentity().modpack, "run-director")
    lu.assertEquals(#boot.callbacks.imgui, 1)
    lu.assertEquals(#boot.callbacks.menuBar, 2)
end
