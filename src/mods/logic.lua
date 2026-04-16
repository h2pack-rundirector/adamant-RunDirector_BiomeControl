local internal = RunDirectorBiomeControl_Internal

local function Read(key)
    return store.read(key)
end

local function IsEnabled()
    return lib.coordinator.isEnabled(store, internal.packId)
end

internal.BiomeControlRead = Read
internal.IsEnabled = IsEnabled

function internal.GetRunState()
    if not CurrentRun then return nil end
    if not CurrentRun.RunDirector_BiomeControl_State then
        CurrentRun.RunDirector_BiomeControl_State = {
            BiomePrioritySatisfied = {},
            ForcedNPCPending = {},
            NPCEncounterSeen = {},
            OnlyAllowForcedEncounters = Read("OnlyAllowForcedEncounters"),
        }
    end

    local state = CurrentRun.RunDirector_BiomeControl_State
    state.OnlyAllowForcedEncounters = Read("OnlyAllowForcedEncounters")
    state.ForcedNPCPending = {}

    for _, groupKey in ipairs(internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupKey]
        state.ForcedNPCPending[groupKey] = {}
        for _, def in ipairs(group.definitions or {}) do
            local mode = internal.GetPackedModeValue(Read, def)
            if mode == "forced" then
                state.ForcedNPCPending[groupKey][def.biome] = true
            end
        end
    end

    return state
end

import("mods/logic_biome.lua")
import("mods/logic_npc.lua")

function internal.BuildPatchPlan(plan)
    if internal.BuildBiomePatchPlan then
        internal.BuildBiomePatchPlan(plan)
    end
    if internal.BuildNPCPatchPlan then
        internal.BuildNPCPatchPlan(plan)
    end
end

function internal.RegisterHooks()
    if internal.RegisterBiomeHooks then
        internal.RegisterBiomeHooks()
    end
    if internal.RegisterNPCHooks then
        internal.RegisterNPCHooks()
    end
end
