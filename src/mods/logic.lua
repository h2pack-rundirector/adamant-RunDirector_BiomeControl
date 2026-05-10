local internal = RunDirectorBiomeControl_Internal
local MODULE_ID = "BiomeControl"

function internal.GetRunState(store)
    if not CurrentRun then return nil end
    local state = lib.gameObject.get(CurrentRun, "run-director", MODULE_ID, "run", function()
        return {
            BiomePrioritySatisfied = {},
            ForcedNPCPending = {},
            NPCEncounterSeen = {},
            OnlyAllowForcedEncounters = store.read("OnlyAllowForcedEncounters"),
        }
    end)
    state.OnlyAllowForcedEncounters = store.read("OnlyAllowForcedEncounters")
    state.ForcedNPCPending = {}

    for _, groupKey in ipairs(internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupKey]
        state.ForcedNPCPending[groupKey] = {}
        for _, def in ipairs(group.definitions or {}) do
            local mode = internal.GetModeValue(store.read, def)
            if mode == "forced" then
                state.ForcedNPCPending[groupKey][def.biome] = true
            end
        end
    end

    return state
end

import("mods/logic/logic_biome.lua")
import("mods/logic/logic_npc.lua")
import("mods/logic/logic_dream.lua")

function internal.BuildPatchPlan(plan, host, store)
    if internal.BuildBiomePatchPlan then
        internal.BuildBiomePatchPlan(plan, host, store)
    end
    if internal.BuildNPCPatchPlan then
        internal.BuildNPCPatchPlan(plan, host, store)
    end
end

function internal.RegisterHooks(host, store)
    if internal.RegisterBiomeHooks then
        internal.RegisterBiomeHooks(host, store)
    end
    if internal.RegisterNPCHooks then
        internal.RegisterNPCHooks(host, store)
    end
    if internal.RegisterDreamHooks then
        internal.RegisterDreamHooks(host, store)
    end
end
