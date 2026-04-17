local internal = RunDirectorBiomeControl_Internal

internal.registerRoomControl({ id = "Narcissus", type = "Story", biome = "G", min = 3, max = 6 })
internal.registerRoomControl({ id = "Trial", type = "Trial", biome = "G", useRegionInKey = true, min = 3, max = 7 })
internal.registerRoomControl({ id = "Fountain", type = "Fountain", biome = "G", useRegionInKey = true, min = 4, max = 6 })
internal.registerRoomControl({ id = "Shop", type = "Shop", biome = "G", useRegionInKey = true, min = 3, max = 6 })
internal.registerNPCControl({ id = "Artemis", groupKey = "ArtemisUnderworld", biome = "G", min = 4, max = 10 })
internal.registerNPCControl({ id = "Nemesis", biome = "G", min = 4, max = 10 })
internal.registerRoomControl({ id = "WaterUnit", type = "MiniBoss", biome = "G", roomKey = "G_MiniBoss01", label = "Deep Serpent", min = 4, max = 7 })
internal.registerRoomControl({ id = "Crawler", type = "MiniBoss", biome = "G", roomKey = "G_MiniBoss02", label = "King Vermin", min = 4, max = 7 })
internal.registerRoomControl({ id = "Jellyfish", type = "MiniBoss", biome = "G", roomKey = "G_MiniBoss03", label = "Hellifish", min = 4, max = 7 })

function internal.DrawBiomeTab_Oceanus(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Rooms", { 0.90, 0.82, 0.56, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Narcissus", "G"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Trial", "G"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Fountain", "G"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Shop", "G"))

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("WaterUnit", "G"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Crawler", "G"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Jellyfish", "G"))
end
