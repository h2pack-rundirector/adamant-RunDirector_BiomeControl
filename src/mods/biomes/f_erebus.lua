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
