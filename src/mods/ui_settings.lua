local internal = RunDirectorBiomeControl_Internal

function internal.DrawSettingsTab(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Route Reward Priorities", { 0.90, 0.82, 0.56, 1.0 })
    lib.widgets.checkbox(imgui, uiState, "PrioritizeSpecificRewardEnabled", {
        label = "Choose First Boon in Each Biome",
    })

    if uiState.view["PrioritizeSpecificRewardEnabled"] == true then
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome1", {
            label = "Route Biome 1 Priority",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome2", {
            label = "Route Biome 2 Priority",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome3", {
            label = "Route Biome 3 Priority",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome4", {
            label = "Route Biome 4 Priority",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
    end

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Trial Reward Priorities", { 0.70, 0.84, 0.96, 1.0 })
    lib.widgets.checkbox(imgui, uiState, "PrioritizeTrialRewardEnabled", {
        label = "Choose Boon Priorities in Trial Rooms",
    })

    if uiState.view["PrioritizeTrialRewardEnabled"] == true then
        lib.widgets.dropdown(imgui, uiState, "PriorityTrial1", {
            label = "Trial Priority A",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityTrial2", {
            label = "Trial Priority B",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            controlWidth = 180,
        })
    end
end
