local internal = RunDirectorBiomeControl_Internal

internal.registerNPCControl({ id = "Nemesis", biome = "H", min = 4, max = 10 })
internal.registerRoomControl({ id = "Vampire", type = "MiniBoss", biome = "H", roomKey = "H_MiniBoss01", label = "Phantom", min = 2, max = 4 })
internal.registerRoomControl({ id = "Lamia", type = "MiniBoss", biome = "H", roomKey = "H_MiniBoss02", label = "Queen Lamia", min = 2, max = 4 })

internal.registerStateField({
    type = "checkbox",
    configKey = "PreventEchoScam",
    label = "Prevent Echo Scam",
})

internal.registerBiomeSpecial("H", {
    kind = "checkbox",
    configKey = "PreventEchoScam",
    label = "Prevent Echo Scam",
    helpText = "(Prevent miniboss from spawning in same depth as Echo, which can prevent it from spawning at all)",
})

internal.registerPatchBuilder(function(plan, read)
    if not read("PreventEchoScam") then return end

    local depthRequirement = {
        Path = { "CurrentRun", "BiomeDepthCache" },
        Comparison = "!=",
        Value = 3,
    }

    for _, roomKey in ipairs({ "H_MiniBoss01", "H_MiniBoss02" }) do
        if RoomData and RoomData[roomKey] then
            plan:appendUnique(RoomData[roomKey], "GameStateRequirements", depthRequirement)
        end
    end
end)

function internal.DrawBiomeTab_Fields(imgui, uiState)
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Vampire", "H"))
    internal.DrawRoomRow(imgui, uiState, internal.GetRoomDef("Lamia", "H"))

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Special", { 1.0, 0.60, 0.28, 1.0 })
    lib.widgets.checkbox(imgui, uiState, "PreventEchoScam", {
        label = "Prevent Echo Scam",
    })
    lib.widgets.text(imgui,
        "(Prevent miniboss from spawning in same depth as Echo, which can prevent it from spawning at all)",
        {
            color = { 0.65, 0.65, 0.65, 1.0 },
        })
end
