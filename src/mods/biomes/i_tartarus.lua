local internal = RunDirectorBiomeControl_Internal

internal.registerNPCControl({ id = "Nemesis", biome = "I", min = 4, max = 10 })
internal.registerRoomControl({ id = "RatCatcher", type = "MiniBoss", biome = "I", roomKey = "I_MiniBoss01", label = "The Verminancer", min = 3, max = 7 })
internal.registerRoomControl({ id = "GoldElemental", type = "MiniBoss", biome = "I", roomKey = "I_MiniBoss02", label = "Goldwrath", min = 3, max = 7 })

function internal.DrawBiomeTab_Tartarus(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("RatCatcher", "I"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("GoldElemental", "I"))
end
