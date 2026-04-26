local internal = RunDirectorBiomeControl_Internal

local UNDERWORLD_REGION = "Underworld"
local SURFACE_REGION = "Surface"
local UNDERWORLD_TAB_ALIAS = "UnderworldTab"
local SURFACE_TAB_ALIAS = "SurfaceTab"

local function DrawSectionHeading(imgui, text, color)
    lib.widgets.text(imgui, text, { color = color })
    lib.widgets.separator(imgui)
end
internal.DrawSectionHeading = DrawSectionHeading

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
    lib.widgets.text(imgui, "No controls are available for this tab.", {
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
    local activeTab = lib.nav.verticalTabs(imgui, {
        id = "BiomeControlUnderworldTabs",
        navWidth = 220,
        tabs = tabs,
        activeKey = session.view[UNDERWORLD_TAB_ALIAS],
    })
    if activeTab ~= session.view[UNDERWORLD_TAB_ALIAS] then
        session.write(UNDERWORLD_TAB_ALIAS, activeTab)
    end

    imgui.BeginChild("BiomeControlUnderworldDetail", 0, 0, false)
    if activeTab == "NPCs" then
        internal.DrawRegionNpcs(imgui, session, UNDERWORLD_REGION)
    elseif activeTab == "F" then
        internal.DrawBiomeTab_Erebus(imgui, session)
    elseif activeTab == "G" then
        internal.DrawBiomeTab_Oceanus(imgui, session)
    elseif activeTab == "H" then
        internal.DrawBiomeTab_Fields(imgui, session)
    elseif activeTab == "I" then
        internal.DrawBiomeTab_Tartarus(imgui, session)
    else
        DrawRegionPlaceholder(imgui, activeTab)
    end
    imgui.EndChild()
end

local function DrawSurfaceTab(imgui, session)
    local tabs = BuildRegionTabList(SURFACE_REGION)
    local activeTab = lib.nav.verticalTabs(imgui, {
        id = "BiomeControlSurfaceTabs",
        navWidth = 220,
        tabs = tabs,
        activeKey = session.view[SURFACE_TAB_ALIAS],
    })
    if activeTab ~= session.view[SURFACE_TAB_ALIAS] then
        session.write(SURFACE_TAB_ALIAS, activeTab)
    end

    imgui.BeginChild("BiomeControlSurfaceDetail", 0, 0, false)
    if activeTab == "NPCs" then
        internal.DrawRegionNpcs(imgui, session, SURFACE_REGION)
    elseif activeTab == "N" then
        internal.DrawBiomeTab_Ephyra(imgui, session, internal.store)
    elseif activeTab == "O" then
        internal.DrawBiomeTab_Thessaly(imgui, session)
    elseif activeTab == "P" then
        internal.DrawBiomeTab_Olympus(imgui, session)
    elseif activeTab == "Q" then
        internal.DrawBiomeTab_Summit(imgui)
    else
        DrawRegionPlaceholder(imgui, activeTab)
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

    if imgui.BeginTabItem("Dream") then
        internal.DrawDreamTab(imgui, session)
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
            session.resetToDefaults()
        end,
    })
end
