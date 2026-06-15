local deps = ...
local controlDefs = deps.controlDefs

local settings = {}

function settings.build()
    return {
        controlDefs.flag("OnlyAllowForcedEncounters", {
            label = "Only Allow Forced Encounters",
            helpText = "(When enabled, non-forced special rooms are suppressed)",
        }),
        controlDefs.flag("IgnoreMaxDepth", {
            label = "Ignore Max Depth",
            helpText = "(Allow configured rooms past their normal maximum depth)",
        }),
        controlDefs.choice("NPCSpacing", {
            label = "NPC Spacing",
            type = "int",
            valueRange = {
                min = 1,
                max = 12,
            },
            default = 6,
            min = 1,
            max = 12,
            helpText = "(Minimum depth spacing between forced NPC encounters)",
        }),
    }
end

return settings
