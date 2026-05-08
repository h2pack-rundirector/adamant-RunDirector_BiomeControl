local internal = RunDirectorBiomeControl_Internal
local MODULE_ID = "BiomeControl"

local function Read(key)
    return internal.store.read(key)
end

local function IsEnabled()
    return internal.host.isEnabled()
end

internal.BiomeControlRead = Read
internal.IsEnabled = IsEnabled

function internal.GetRunState()
    if not CurrentRun then return nil end
    local state = lib.gameObject.get(CurrentRun, "run-director", MODULE_ID, "run", function()
        return {
            BiomePrioritySatisfied = {},
            ForcedNPCPending = {},
            NPCEncounterSeen = {},
            OnlyAllowForcedEncounters = Read("OnlyAllowForcedEncounters"),
        }
    end)
    state.OnlyAllowForcedEncounters = Read("OnlyAllowForcedEncounters")
    state.ForcedNPCPending = {}

    for _, groupKey in ipairs(internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupKey]
        state.ForcedNPCPending[groupKey] = {}
        for _, def in ipairs(group.definitions or {}) do
            local mode = internal.GetModeValue(Read, def)
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
    if internal.RegisterDreamHooks then
        internal.RegisterDreamHooks()
    end
end
