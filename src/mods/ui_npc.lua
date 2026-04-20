local internal = RunDirectorBiomeControl_Internal

local NPC_MODE_DEFAULT = 0
local NPC_MODE_DISABLED = 1
local NPC_MODE_FORCED = 2
local NPC_MODE_VALUES = {
    NPC_MODE_DEFAULT,
    NPC_MODE_DISABLED,
    NPC_MODE_FORCED,
}
local NPC_MODE_DISPLAY_VALUES = {
    [NPC_MODE_DEFAULT] = "Default",
    [NPC_MODE_DISABLED] = "Disabled",
    [NPC_MODE_FORCED] = "Forced",
}
local NPC_SPACING_VALUES = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
local NPC_GROUP_COLORS = {
    Artemis = { 15 / 255, 255 / 255, 9 / 255, 1.0 },
    Nemesis = { 115 / 255, 146 / 255, 210 / 255, 1.0 },
    Athena = { 255 / 255, 216 / 255, 60 / 255, 1.0 },
    Heracles = { 255 / 255, 125 / 255, 25 / 255, 1.0 },
    Icarus = { 243 / 255, 215 / 255, 116 / 255, 1.0 },
}

local function DrawFixedLabel(imgui, label, width)
    imgui.AlignTextToFramePadding()
    imgui.Text(label)
    imgui.SameLine()
    imgui.SetCursorPosX(width)
end

local function BuildRegionBiomeKeyLookup(region)
    local keys = {}
    for _, biome in ipairs(internal.biomeTabs or {}) do
        if biome.region == region then
            keys[biome.key] = true
        end
    end
    return keys
end

local function DrawNpcBiomeRow(imgui, session, def)
    local labelColumnX = 36
    local dropdownColumnX = 160
    local rangeColumnX = 310

    imgui.Indent(16)
    DrawFixedLabel(imgui, def.region, labelColumnX)
    imgui.SetCursorPosX(dropdownColumnX)
    lib.widgets.dropdown(imgui, session, def.modeKey, {
        label = "",
        values = NPC_MODE_VALUES,
        displayValues = NPC_MODE_DISPLAY_VALUES,
        controlWidth = 120,
    })

    if session.view[def.modeKey] == NPC_MODE_FORCED then
        imgui.SameLine()
        imgui.SetCursorPosX(rangeColumnX)
        internal.DrawRangeDropdowns(imgui, session, def.configKeyMin, def.configKeyMax, def.minDefault, def.maxDefault)
    end
    imgui.Unindent(16)
end

local function DrawNpcGroup(imgui, session, group)
    local color = NPC_GROUP_COLORS[group.actualNPCName] or { 0.90, 0.82, 0.56, 1.0 }
    lib.widgets.text(imgui, group.label, { color = color })
    for _, def in ipairs(group.definitions or {}) do
        DrawNpcBiomeRow(imgui, session, def)
    end
end

local function DrawNpcRules(imgui, session)
    imgui.Spacing()
    internal.DrawSectionHeading(imgui, "NPC Rules", { 0.70, 0.84, 0.96, 1.0 })
    lib.widgets.checkbox(imgui, session, "OnlyAllowForcedEncounters", {
        label = "Only Allow Forced NPC Encounters",
        tooltip = "Blocks NPC encounters left on Default. Only Forced entries can appear.",
    })
    lib.widgets.text(imgui, "Blocks NPC encounters left on Default. Only Forced entries can appear.", {
        color = { 0.65, 0.65, 0.65, 1.0 },
    })
    lib.widgets.checkbox(imgui, session, "IgnoreMaxDepth", {
        label = "Ignore NPC Max Depth Requirements",
        tooltip = "Forced NPC encounters can still appear after max depth.",
    })
    lib.widgets.text(imgui, "Forced NPC encounters can still appear after max depth.", {
        color = { 0.65, 0.65, 0.65, 1.0 },
    })
    lib.widgets.dropdown(imgui, session, "NPCSpacing", {
        label = "Minimum rooms between field NPC encounters",
        values = NPC_SPACING_VALUES,
        controlWidth = 60,
    })
end

function internal.DrawRegionNpcs(imgui, session, region)
    internal.DrawSectionHeading(imgui, "NPCs", { 0.90, 0.82, 0.56, 1.0 })
    local drewAny = false
    local regionBiomeKeys = BuildRegionBiomeKeyLookup(region)
    for _, groupId in ipairs(internal.npcGroups and internal.npcGroups.orderedIds or {}) do
        local group = internal.npcGroups[groupId]
        local regionDefinitions = {}
        for _, def in ipairs(group and group.definitions or {}) do
            if def.region == region or regionBiomeKeys[def.biome] then
                regionDefinitions[#regionDefinitions + 1] = def
            end
        end
        if #regionDefinitions > 0 then
            if drewAny then
                imgui.Separator()
            end
            DrawNpcGroup(imgui, session, {
                label = group.label,
                actualNPCName = group.actualNPCName,
                definitions = regionDefinitions,
            })
            drewAny = true
        end
    end
    DrawNpcRules(imgui, session)
end
