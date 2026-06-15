local lu = require("luaunit")

TestBiomeControlData = {}

local function getStorageNode(storage, alias)
    for _, node in ipairs(storage) do
        if node.alias == alias then
            return node
        end
    end
end

function TestBiomeControlData:testResolverKeepsBiomeAndNpcControlNames()
    local data = dofile("src/mods/data.lua")
    local resolver = data.resolver
    local controls = data.buildControls()

    local arachne = resolver.room("F", "Arachne")
    lu.assertEquals(arachne, "StoryArachne")
    lu.assertEquals(controls.StoryArachne.template, "ModeWithRange")
    lu.assertEquals(controls.StoryArachne.range.min, 4)
    lu.assertEquals(controls.StoryArachne.range.max, 8)

    local trial = resolver.room("F", "Trial")
    lu.assertEquals(trial, "TrialErebus")
    lu.assertEquals(controls.TrialErebus.range.min, 6)
    lu.assertEquals(controls.TrialErebus.range.max, 10)

    local nemesis = resolver.npc("Nemesis", "I")
    lu.assertEquals(nemesis, "NPCNemesisTartarus")
    lu.assertEquals(controls.NPCNemesisTartarus.template, "ModeWithRange")
end

function TestBiomeControlData:testStoryLabelsUseEncounterNames()
    local data = dofile("src/mods/data.lua")
    local resolver = data.resolver
    local controls = data.buildControls()

    lu.assertEquals(resolver.roomInfo("F", "Arachne").label, "Arachne")
    lu.assertEquals(resolver.roomInfo("O", "Circe").label, "Circe")
    lu.assertEquals(resolver.roomInfo("P", "Dionysus").label, "Dionysus")
    lu.assertEquals(controls.EphyraStoryMode.label, "Medea")
end

function TestBiomeControlData:testControlsAreDeclaredBySemanticTemplate()
    local data = dofile("src/mods/data.lua")
    local controls = data.buildControls()

    lu.assertEquals(controls.PreventEchoScam.template, "Flag")
    lu.assertEquals(controls.ReplaceHermesInEphyra.template, "GodChoice")
    lu.assertEquals(controls.ReplaceHermesInEphyra.displayValues[""], "Hermes (Default)")
    lu.assertEquals(controls.EphyraMiniBossMode.template, "Mode")
    lu.assertEquals(controls.ThessalyMiniBossMode.template, "ModeWithRange")
    lu.assertEquals(controls.PackedBannedEphyraSubRoomRewards.template, "PackedSet")
    lu.assertEquals(#controls.PackedBannedEphyraSubRoomRewards.options, 16)
end

function TestBiomeControlData:testStorageOnlyKeepsNonControlAliases()
    local data = dofile("src/mods/data.lua")
    local storage = data.buildStorage()

    lu.assertNil(getStorageNode(storage, "DreamRouteEnabled"))
    lu.assertNil(getStorageNode(storage, "DreamRouteBiome1"))
    lu.assertNil(getStorageNode(storage, "PriorityBiome1"))
    lu.assertNil(getStorageNode(storage, "PreventEchoScam"))
    lu.assertNil(getStorageNode(storage, "StoryArachne"))
end

function TestBiomeControlData:testBaseAndBiomeControlsShareOneDeclarationSurface()
    local data = dofile("src/mods/data.lua")
    local controls = data.buildControls()

    lu.assertEquals(controls.OnlyAllowForcedEncounters.template, "Flag")
    lu.assertEquals(controls.IgnoreMaxDepth.template, "Flag")
    lu.assertEquals(controls.NPCSpacing.template, "Choice")
    lu.assertNil(controls.NPCSpacing.values)
    lu.assertEquals(controls.NPCSpacing.valueRange, {
        min = 1,
        max = 12,
    })
    lu.assertEquals(controls.DreamRoute.template, "DreamRoute")
    lu.assertEquals(controls.PriorityBiome1.template, "GodChoice")
    lu.assertEquals(controls.PriorityTrial1.template, "GodChoice")
    lu.assertEquals(controls.StoryArachne.template, "ModeWithRange")
end
