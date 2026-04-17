local internal = RunDirectorBiomeControl_Internal

internal.registerRoomControl({ id = "Dionysus", type = "Story", biome = "P", min = 3, max = 7 })
internal.registerRoomControl({ id = "Fountain", type = "Fountain", biome = "P", useRegionInKey = true, min = 4, max = 7 })
internal.registerRoomControl({ id = "Shop", type = "Shop", biome = "P", useRegionInKey = true, min = 5, max = 7 })
internal.registerNPCControl({ id = "Heracles", biome = "P", min = 0, max = 10 })
internal.registerNPCControl({ id = "Athena", biome = "P", min = 4, max = 8 })
internal.registerNPCControl({ id = "Icarus", biome = "P", min = 3, max = 8 })
internal.registerRoomControl({ id = "Talos", type = "MiniBoss", biome = "P", roomKey = "P_MiniBoss01", label = "Talos", min = 4, max = 7 })
internal.registerRoomControl({ id = "Dragon", type = "MiniBoss", biome = "P", roomKey = "P_MiniBoss02", label = "Mega-Dracon", min = 4, max = 7 })

function internal.DrawBiomeTab_Olympus(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Rooms", { 0.90, 0.82, 0.56, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Dionysus", "P"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Fountain", "P"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Shop", "P"))

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Talos", "P"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Dragon", "P"))
end
