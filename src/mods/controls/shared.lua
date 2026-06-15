local shared = {}

local COMMON_DRAW_OPT_KEYS = {
    "id",
    "labelWidth",
    "controlWidth",
    "controlGap",
    "color",
    "action",
    "value",
    "default",
}

function shared.cloneList(values)
    local copy = {}
    for index, value in ipairs(values or {}) do
        copy[index] = value
    end
    return copy
end

function shared.cloneMap(values)
    local copy = {}
    for key, value in pairs(values or {}) do
        copy[key] = value
    end
    return copy
end

function shared.drawOpts(instance)
    local target = instance.drawOpts
    if not target then
        target = {}
        instance.drawOpts = target
    end
    return target
end

function shared.applyCommonDrawOpts(target, opts, instance)
    target.label = opts and opts.label or instance.label or ""
    target.tooltip = instance.helpText
    for _, key in ipairs(COMMON_DRAW_OPT_KEYS) do
        target[key] = opts and opts[key] or nil
    end
    return target
end

return shared
