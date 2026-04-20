local internal = RunDirectorBiomeControl_Internal

internal.registerRoomControl({ id = "Arachne", type = "Story", biome = "F", min = 4, max = 8 })
internal.registerRoomControl({ id = "Trial", type = "Trial", biome = "F", useRegionInKey = true, min = 6, max = 10 })
internal.registerRoomControl({ id = "Fountain", type = "Fountain", biome = "F", useRegionInKey = true, min = 4, max = 8 })
internal.registerRoomControl({ id = "Shop", type = "Shop", biome = "F", useRegionInKey = true, min = 4, max = 6 })
internal.registerNPCControl({ id = "Artemis", groupKey = "ArtemisUnderworld", biome = "F", min = 4, max = 10 })
internal.registerNPCControl({ id = "Nemesis", biome = "F", min = 4, max = 10 })
internal.registerRoomControl({ id = "Treant", type = "MiniBoss", biome = "F", roomKey = "F_MiniBoss01", label = "Root-Stalker", min = 4, max = 6 })
internal.registerRoomControl({ id = "FogEmitter", type = "MiniBoss", biome = "F", roomKey = "F_MiniBoss02", label = "Shadow-Spiller", min = 4, max = 6 })
internal.registerRoomControl({ id = "Assassin", type = "MiniBoss", biome = "F", roomKey = "F_MiniBoss03", label = "Master-Slicer", min = 4, max = 6 })

function internal.DrawBiomeTab_Erebus(imgui, session)
    internal.DrawSectionHeading(imgui, "Rooms", { 0.90, 0.82, 0.56, 1.0 })
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Arachne", "F"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Trial", "F"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Fountain", "F"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Shop", "F"))

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Treant", "F"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("FogEmitter", "F"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Assassin", "F"))
end
