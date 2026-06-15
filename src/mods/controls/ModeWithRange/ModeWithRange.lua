local deps = ...

local base = deps.base

local ModeWithRange = {}

function ModeWithRange.prepare(instance)
    base.prepare(instance)
    instance.range = instance.range or {}
    instance.range.min = instance.range.min or instance.min or 0
    instance.range.max = instance.range.max or instance.max or instance.range.min
    instance.range.defaultMin = instance.range.defaultMin or instance.range.min
    instance.range.defaultMax = instance.range.defaultMax or instance.range.max
    instance.range.visibleWhen = instance.range.visibleWhen or {
        forced = true,
    }
    instance.range.opts = {
        label = "",
        valueRange = {
            min = instance.range.min,
            max = instance.range.max,
        },
        controlWidth = instance.range.controlWidth or 60,
    }
    return instance
end

function ModeWithRange.storage(instance)
    return {
        base.storage(instance)[1],
        {
            key = "Min",
            type = "int",
            default = instance.range.defaultMin,
            min = instance.range.min,
            max = instance.range.max,
        },
        {
            key = "Max",
            type = "int",
            default = instance.range.defaultMax,
            min = instance.range.min,
            max = instance.range.max,
        },
    }
end

local function readRange(fields, instance)
    return fields.Min:read() or instance.range.min, fields.Max:read() or instance.range.max
end

function ModeWithRange.createRuntime(fields, instance)
    local control = base.createRuntime(fields, instance)

    function control.range()
        return readRange(fields, instance)
    end

    function control:read()
        local minValue, maxValue = self:range()
        return {
            mode = self:mode(),
            min = minValue,
            max = maxValue,
        }
    end

    return control
end

function ModeWithRange.createUi(fields, instance)
    return base.addUiMethods(ModeWithRange.createRuntime(fields, instance), fields, instance)
end

local function drawRange(draw, control, instance)
    local imgui = draw.imgui
    local minField = control:field("Min")
    local maxField = control:field("Max")
    local rangeOpts = instance.range.opts

    draw.widgets.text("from:", {
        alignToFramePadding = true,
    })
    imgui.SameLine()
    local minChanged = draw.widgets.dropdown(minField, rangeOpts)

    imgui.SameLine()
    draw.widgets.text("to", {
        alignToFramePadding = true,
    })
    imgui.SameLine()
    local maxChanged = draw.widgets.dropdown(maxField, rangeOpts)

    local currentMin = tonumber(minField:read()) or instance.range.min
    local currentMax = tonumber(maxField:read()) or instance.range.max
    if currentMin > currentMax then
        if minChanged and not maxChanged then
            maxField:write(currentMin)
        else
            minField:write(currentMax)
        end
    end
end

function ModeWithRange.draw(draw, control, instance, opts)
    base.draw(draw, control, instance, opts)
    if instance.range.visibleWhen[control:mode()] ~= true then
        return
    end

    local imgui = draw.imgui
    imgui.SameLine()
    imgui.SetCursorPosX(opts and opts.rangeColumnX or instance.range.rangeColumnX or 310)
    drawRange(draw, control, instance)
end

return ModeWithRange
