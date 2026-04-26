local lu = require("luaunit")

TestBiomeControlLogic = {}

function TestBiomeControlLogic:testPatchPlanAppliesAndRevertsRoomAndNpcMutations()
    local harness = ResetBiomeControlHarness({
        config = {
            ModeStoryArachne = 2,
            PackedStoryArachneMin = 5,
            PackedStoryArachneMax = 7,
            ModeMiniBossTreant = 1,
            NPCSpacing = 9,
            PreventEchoScam = true,
        },
    })

    local okApply, applyErr = lib.lifecycle.applyMutation(harness.definition, harness.store)
    lu.assertTrue(okApply, tostring(applyErr))

    lu.assertEquals(RoomData.F_Story01.ForceAtBiomeDepthMin, 5)
    lu.assertEquals(RoomData.F_Story01.ForceAtBiomeDepthMax, 7)
    lu.assertEquals(RoomData.F_Story01.GameStateRequirements[1].Value, 5)
    lu.assertEquals(RoomData.F_Story01.GameStateRequirements[2].Value, 7)
    lu.assertEquals(#RoomData.F_MiniBoss01.GameStateRequirements, 1)
    lu.assertEquals(RoomData.F_MiniBoss01.GameStateRequirements[1].Value, -1)
    lu.assertEquals(NamedRequirementsData.NoRecentFieldNPCEncounter[1].SumPrevRooms, 9)
    lu.assertEquals(#RoomData.H_MiniBoss01.GameStateRequirements, 1)
    lu.assertEquals(RoomData.H_MiniBoss01.GameStateRequirements[1].Value, 3)

    local okRevert, revertErr = lib.lifecycle.revertMutation(harness.definition, harness.store)
    lu.assertTrue(okRevert, tostring(revertErr))

    lu.assertNil(RoomData.F_Story01.ForceAtBiomeDepthMin)
    lu.assertNil(RoomData.F_Story01.ForceAtBiomeDepthMax)
    lu.assertEquals(RoomData.F_Story01.GameStateRequirements[1].Value, 4)
    lu.assertEquals(RoomData.F_Story01.GameStateRequirements[2].Value, 8)
    lu.assertEquals(#RoomData.F_MiniBoss01.GameStateRequirements, 0)
    lu.assertEquals(NamedRequirementsData.NoRecentFieldNPCEncounter[1].SumPrevRooms, 6)
    lu.assertEquals(#RoomData.H_MiniBoss01.GameStateRequirements, 0)
end

function TestBiomeControlLogic:testBiomePriorityFiltersEligibleLootUntilSatisfied()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            PrioritizeSpecificRewardEnabled = true,
            PriorityBiome1 = "ApolloUpgrade",
        },
        CurrentRun = {
            ClearedBiomes = 0,
        },
        GetEligibleLootNames = function()
            return { "ZeusUpgrade", "ApolloUpgrade" }
        end,
    })

    lu.assertEquals(GetEligibleLootNames({}), { "ApolloUpgrade" })

    GiveLoot({ ForceLootName = "ApolloUpgrade" })
    lu.assertEquals(GetEligibleLootNames({}), { "ZeusUpgrade", "ApolloUpgrade" })
end

function TestBiomeControlLogic:testTrialRewardPrioritySetsEncounterLootPair()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            PrioritizeTrialRewardEnabled = true,
            PriorityTrial1 = "ApolloUpgrade",
            PriorityTrial2 = "ZeusUpgrade",
        },
        CurrentRun = {},
        GetInteractedGodsThisRun = function()
            return { "ApolloUpgrade", "ZeusUpgrade" }
        end,
        GetEligibleLootNames = function(excluded)
            if excluded and excluded[1] == "ApolloUpgrade" then
                return { "ZeusUpgrade" }
            end
            return { "ApolloUpgrade", "ZeusUpgrade" }
        end,
    })

    local room = {
        ChosenRewardType = "Devotion",
        Encounter = {},
    }
    SetupRoomReward(CurrentRun, room, nil, {})

    lu.assertEquals(room.Encounter.LootAName, "ApolloUpgrade")
    lu.assertEquals(room.Encounter.LootBName, "ZeusUpgrade")
end

function TestBiomeControlLogic:testForcedNpcEncounterNarrowsLegalEncounterList()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            ModeNPCArtemisErebus = 2,
            PackedNPCArtemisErebusMin = 4,
            PackedNPCArtemisErebusMax = 10,
        },
        CurrentRun = {},
        ChooseEncounter = function(_, _, args)
            return args.LegalEncounters
        end,
    })

    local currentRun = {
        BiomeDepthCache = 4,
    }
    local room = {
        RoomSetName = "F",
        LegalEncounters = {
            "NemesisCombatF",
            "ArtemisCombatF",
        },
    }
    local result = ChooseEncounter(currentRun, room, {})

    lu.assertEquals(result, { "ArtemisCombatF" })
end

function TestBiomeControlLogic:testOnlyAllowForcedEncountersFiltersUnforcedNpcEncounters()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            OnlyAllowForcedEncounters = true,
        },
        CurrentRun = {},
        ChooseEncounter = function(_, _, args)
            return args.LegalEncounters
        end,
    })

    local currentRun = {
        BiomeDepthCache = 4,
    }
    local room = {
        RoomSetName = "F",
        LegalEncounters = {
            "NemesisCombatF",
            "ArtemisCombatF",
            "GenericCombatF",
        },
    }
    local result = ChooseEncounter(currentRun, room, {})

    lu.assertEquals(result, { "GenericCombatF" })
end

function TestBiomeControlLogic:testFieldsTwoRewardHookOverridesEarlyCombatRooms()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            ForceTwoRewardFieldsOpeners = true,
        },
    })

    local result = SelectFieldsDoorCageCount({
        BiomeDepthCache = 2,
    }, {
        Name = "H_Combat01",
        MinDoorCageRewards = 2,
    })

    lu.assertEquals(result, 2)
end

function TestBiomeControlLogic:testDreamRouteSetsNextRoomSetAndPool()
    ResetBiomeControlHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            DreamRouteEnabled = true,
            DreamRouteBiome1 = "G",
            DreamRouteBiome2 = "I",
            DreamRouteBiome3 = "N",
            DreamRouteBiome4 = "P",
        },
        CurrentRun = {
            IsDreamRun = true,
            EnteredBiomes = 0,
            CurrentRoom = {},
        },
        GameState = {},
    })

    SelectNextDreamBiome(nil)

    lu.assertEquals(CurrentRun.CurrentRoom.NextRoomSet, { "G" })
    lu.assertEquals(CurrentRun.DreamBiomePool, { "I", "N", "P" })
    lu.assertEquals(GameState.LastDreamStartingBiome, "G")
end
