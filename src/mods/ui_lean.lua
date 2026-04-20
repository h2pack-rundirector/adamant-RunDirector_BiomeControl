local internal = RunDirectorBiomeControl_Internal

local UNDERWORLD_REGION = "Underworld"
local SURFACE_REGION = "Surface"

internal.uiLeanState = internal.uiLeanState or {
    underworldTab = "NPCs",
    surfaceTab = "NPCs",
}

local function DrawSectionHeading(imgui, text, color)
    lib.widgets.text(imgui, text, { color = color })
    lib.widgets.separator(imgui)
end
internal.DrawSectionHeading = DrawSectionHeading

function internal.ResetAllControls(session)
    local changed = lib.resetStorageToDefaults(definition.storage, session, {
        exclude = { ViewRegion = true },
    })
    return changed
end

local function BuildRegionTabList(region)
    local tabs = {
        { key = "NPCs", label = "NPCs" },
    }
    for _, biome in ipairs(internal.biomeTabs or {}) do
        if biome.region == region then
            tabs[#tabs + 1] = {
                key = biome.key,
                label = biome.label,
            }
        end
    end
    return tabs
end

local function DrawFixedLabel(imgui, label, width)
    imgui.AlignTextToFramePadding()
    imgui.Text(label)
    imgui.SameLine()
    imgui.SetCursorPosX(width)
end

local function BuildIntegerValues(minValue, maxValue)
    local values = {}
    for value = minValue, maxValue do
        values[#values + 1] = value
    end
    return values
end

local function BuildEncodedModeOptions(def)
    local values = {}
    local displayValues = {}

    for index, value in ipairs(def.modeValues or internal.roomModeValues) do
        local encoded = index - 1
        values[#values + 1] = encoded
        displayValues[encoded] = (def.modeDisplayValues or internal.roomModeDisplayValues)[value] or tostring(value)
    end

    return values, displayValues
end

local function DrawRangeDropdowns(imgui, session, minAlias, maxAlias, minValue, maxValue)
    local values = BuildIntegerValues(minValue, maxValue)

    lib.widgets.text(imgui, "from:", { alignToFramePadding = true })
    imgui.SameLine()
    local minChanged = lib.widgets.dropdown(imgui, session, minAlias, {
        label = "",
        values = values,
        controlWidth = 60,
    })

    imgui.SameLine()
    lib.widgets.text(imgui, "to", { alignToFramePadding = true })
    imgui.SameLine()
    local maxChanged = lib.widgets.dropdown(imgui, session, maxAlias, {
        label = "",
        values = values,
        controlWidth = 60,
    })

    local currentMin = tonumber(session.view[minAlias]) or minValue
    local currentMax = tonumber(session.view[maxAlias]) or maxValue
    if currentMin > currentMax then
        if minChanged and not maxChanged then
            session.write(maxAlias, currentMin)
        else
            session.write(minAlias, currentMax)
        end
    end
end
internal.DrawRangeDropdowns = DrawRangeDropdowns

local function DrawRoomRow(imgui, session, def)
    if not def then
        lib.widgets.text(imgui, "Missing room definition", {
            color = { 0.65, 0.65, 0.65, 1.0 },
        })
        return
    end

    local labelColumnX = 36
    local dropdownColumnX = 160
    local rangeColumnX = 310
    local modeValues, modeDisplayValues = BuildEncodedModeOptions(def)

    DrawFixedLabel(imgui, def.label, labelColumnX)
    imgui.SetCursorPosX(dropdownColumnX)
    lib.widgets.dropdown(imgui, session, def.modeKey, {
        label = "",
        values = modeValues,
        displayValues = modeDisplayValues,
        controlWidth = 120,
    })

    if internal.GetModeValue(function(key)
        return session.view[key]
    end, def) == "forced" then
        imgui.SameLine()
        imgui.SetCursorPosX(rangeColumnX)
        DrawRangeDropdowns(imgui, session, def.configKeyMin, def.configKeyMax, def.minDefault, def.maxDefault)
    end
end
internal.DrawRoomRow = DrawRoomRow

local function DrawRegionPlaceholder(imgui, region)
    lib.widgets.text(imgui, region)
    lib.widgets.separator(imgui)
    lib.widgets.text(imgui, "Not migrated yet.", {
        color = { 0.65, 0.65, 0.65, 1.0 },
    })
    lib.widgets.text(imgui, "Next step is writing the tabs explicitly against lib.widgets.*.", {
        color = { 0.65, 0.65, 0.65, 1.0 },
    })
end

local function GetRoomDef(id, biome)
    return internal.roomLookup
        and internal.roomLookup[id]
        and internal.roomLookup[id][biome]
        or nil
end
internal.GetRoomDef = GetRoomDef

local function DrawUnderworldTab(imgui, session)
    local tabs = BuildRegionTabList(UNDERWORLD_REGION)
    internal.uiLeanState.underworldTab = lib.nav.verticalTabs(imgui, {
        id = "BiomeControlUnderworldTabs",
        navWidth = 180,
        tabs = tabs,
        activeKey = internal.uiLeanState.underworldTab,
    })

    imgui.BeginChild("BiomeControlUnderworldDetail", 0, 0, false)
    if internal.uiLeanState.underworldTab == "NPCs" then
        internal.DrawRegionNpcs(imgui, session, UNDERWORLD_REGION)
    elseif internal.uiLeanState.underworldTab == "F" then
        internal.DrawBiomeTab_Erebus(imgui, session)
    elseif internal.uiLeanState.underworldTab == "G" then
        internal.DrawBiomeTab_Oceanus(imgui, session)
    elseif internal.uiLeanState.underworldTab == "H" then
        internal.DrawBiomeTab_Fields(imgui, session)
    elseif internal.uiLeanState.underworldTab == "I" then
        internal.DrawBiomeTab_Tartarus(imgui, session)
    else
        DrawRegionPlaceholder(imgui, internal.uiLeanState.underworldTab)
    end
    imgui.EndChild()
end

local function DrawSurfaceTab(imgui, session)
    local tabs = BuildRegionTabList(SURFACE_REGION)
    internal.uiLeanState.surfaceTab = lib.nav.verticalTabs(imgui, {
        id = "BiomeControlSurfaceTabs",
        navWidth = 180,
        tabs = tabs,
        activeKey = internal.uiLeanState.surfaceTab,
    })

    imgui.BeginChild("BiomeControlSurfaceDetail", 0, 0, false)
    if internal.uiLeanState.surfaceTab == "NPCs" then
        internal.DrawRegionNpcs(imgui, session, SURFACE_REGION)
    elseif internal.uiLeanState.surfaceTab == "N" then
        internal.DrawBiomeTab_Ephyra(imgui, session, store)
    elseif internal.uiLeanState.surfaceTab == "O" then
        internal.DrawBiomeTab_Thessaly(imgui, session)
    elseif internal.uiLeanState.surfaceTab == "P" then
        internal.DrawBiomeTab_Olympus(imgui, session)
    elseif internal.uiLeanState.surfaceTab == "Q" then
        internal.DrawBiomeTab_Summit(imgui)
    else
        DrawRegionPlaceholder(imgui, internal.uiLeanState.surfaceTab)
    end
    imgui.EndChild()
end

function internal.DrawTab(imgui, session)
    if not imgui.BeginTabBar("BiomeControlLeanTabs") then
        return false
    end

    if imgui.BeginTabItem("Underworld") then
        DrawUnderworldTab(imgui, session)
        imgui.EndTabItem()
    end

    if imgui.BeginTabItem("Surface") then
        DrawSurfaceTab(imgui, session)
        imgui.EndTabItem()
    end

    if imgui.BeginTabItem("Settings") then
        internal.DrawSettingsTab(imgui, session)
        imgui.EndTabItem()
    end

    imgui.EndTabBar()
    return false
end

function internal.DrawQuickContent(imgui, session)
    lib.widgets.confirmButton(imgui, "biome_control_quick_reset_all", "Reset To Default", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            internal.ResetAllControls(session)
        end,
    })
end
