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
