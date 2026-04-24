local internal = RunDirectorBiomeControl_Internal

function internal.DrawBiomeTab_Summit(imgui)
    internal.DrawSectionHeading(imgui, "Summit", { 0.90, 0.82, 0.56, 1.0 })
    lib.widgets.text(imgui, "Summit is boring. Nothing to see here.", {
        color = { 0.65, 0.65, 0.65, 1.0 },
    })
end
