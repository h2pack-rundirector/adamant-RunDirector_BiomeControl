local internal = RunDirectorBiomeControl_Internal

internal.registerNPCControl({ id = "Nemesis", biome = "H", min = 4, max = 10 })
internal.registerRoomControl({ id = "Vampire", type = "MiniBoss", biome = "H", roomKey = "H_MiniBoss01", label = "Phantom", min = 2, max = 4 })
internal.registerRoomControl({ id = "Lamia", type = "MiniBoss", biome = "H", roomKey = "H_MiniBoss02", label = "Queen Lamia", min = 2, max = 4 })

internal.registerStateField({
    type = "checkbox",
    configKey = "PreventEchoScam",
    label = "Prevent Echo Scam",
})

internal.registerStateField({
    type = "checkbox",
    configKey = "ForceTwoRewardFieldsOpeners",
    label = "Force 2 Rewards In First Two Rooms",
})

internal.registerBiomeSpecial("H", {
    kind = "checkbox",
    configKey = "PreventEchoScam",
    label = "Prevent Echo Scam",
    helpText = "(Prevent miniboss from spawning in same depth as Echo, which can prevent it from spawning at all)",
})

internal.registerBiomeSpecial("H", {
    kind = "checkbox",
    configKey = "ForceTwoRewardFieldsOpeners",
    label = "Force 2 Rewards In First Two Rooms",
    helpText = "(Force normal H combat encounters to offer exactly 2 rewards at biome depth 1 and 2; vanilla 3-reward promotion resumes after depth 2)",
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

function internal.DrawBiomeTab_Fields(imgui, session)
    internal.DrawSectionHeading(imgui, "Minibosses", { 0.88, 0.38, 0.32, 1.0 })
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Vampire", "H"))
    internal.DrawRoomRow(imgui, session, internal.GetRoomDef("Lamia", "H"))

    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "Special", { 1.0, 0.60, 0.28, 1.0 })
    lib.widgets.checkbox(imgui, session, "PreventEchoScam", {
        label = "Prevent Echo Scam",
    })

    imgui.Spacing()
    lib.widgets.checkbox(imgui, session, "ForceTwoRewardFieldsOpeners", {
        label = "Force 2-2 Fields",
    })
end

function internal.RegisterFieldsHooks()
    modutil.mod.Path.Wrap("SelectFieldsDoorCageCount", function(base, run, room)
        if not internal.IsEnabled() then
            return base(run, room)
        end

        if not internal.BiomeControlRead("ForceTwoRewardFieldsOpeners") then
            return base(run, room)
        end

        local biomeDepth = run and tonumber(run.BiomeDepthCache) or 0
        local roomName = room and room.Name or nil

        if biomeDepth <= 2 and type(roomName) == "string" and roomName:match("^H_Combat%d+$") then
            return room.MinDoorCageRewards or 2
        end

        return base(run, room)
    end)
end
