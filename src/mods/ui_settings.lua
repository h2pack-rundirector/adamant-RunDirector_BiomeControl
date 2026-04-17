local internal = RunDirectorBiomeControl_Internal

function internal.DrawSettingsTab(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Route Reward Priorities", { 0.90, 0.82, 0.56, 1.0 })
    lib.widgets.checkbox(imgui, uiState, "PrioritizeSpecificRewardEnabled", {
        label = "Choose First Boon in Each Biome",
    })

    if uiState.view["PrioritizeSpecificRewardEnabled"] == true then
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome1", {
            label = "Biome 1 Choice ",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome2", {
            label = "Biome 2 Choice",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome3", {
            label = "Biome 3 Choice",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityBiome4", {
            label = "Biome 4 Choice",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
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
            label = "Trial Choice A   ",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
            controlWidth = 180,
        })
        lib.widgets.dropdown(imgui, uiState, "PriorityTrial2", {
            label = "Trial Choice B   ",
            values = internal.priorityOptions,
            displayValues = internal.priorityDisplayValues,
            valueColors = internal.priorityValueColors,
            controlWidth = 180,
        })
    end

    imgui.Spacing()
    lib.widgets.separator(imgui)
    imgui.Spacing()
    lib.widgets.confirmButton(imgui, "biome_control_reset_all_settings", "Reset All Controls", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            internal.ResetAllControls(uiState)
        end,
    })
end
