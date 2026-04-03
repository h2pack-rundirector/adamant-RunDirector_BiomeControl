std = "lua52"
max_line_length = 160
globals = {
    "rom",
    "public",
    "config",
    "modutil",
    "game",
    "chalk",
    "reload",
    "_PLUGIN",
    "lib",
    "store",
    "RunDirectorBiomeControl_Internal",
    "CurrentRun"
    
}
read_globals = {
    "imgui",
    "import_as_fallback",
    "import",
    "SetupRunData",
    "RoomData",
    "RoomSetData",
    "GetInteractedGodsThisRun",
    "GetEligibleLootNames",
    "NamedRequirementsData",
    "EncounterData",
    "IsGameStateEligible",
    "LootData",
    "definition",
    "Contains",
    "IsEncounterEligible"
}
exclude_files = { "src/main.lua", "src/main_special.lua" }