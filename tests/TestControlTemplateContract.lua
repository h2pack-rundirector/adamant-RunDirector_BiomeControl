-- luacheck: globals TestControlTemplateContract

local lu = require("luaunit")

TestControlTemplateContract = {}

local function copyMap(values)
    local copy = {}
    for key, value in pairs(values or {}) do
        copy[key] = value
    end
    return copy
end

local function makeField(alias)
    return {
        alias = function()
            return alias
        end,
        controlId = function()
            return alias .. "-id"
        end,
        read = function()
            return 0
        end,
        write = function() end,
    }
end

local function makeModeControl()
    local field = makeField("Mode")
    return {
        field = function()
            return field
        end,
    }
end

local function makeSingleFieldControl(alias)
    local field = makeField(alias)
    return {
        field = function()
            return field
        end,
    }
end

local function makeDraw()
    local calls = {}
    return {
        calls = calls,
        widgets = {
            dropdown = function(_, opts)
                calls[#calls + 1] = copyMap(opts)
                return false
            end,
            checkbox = function(_, opts)
                calls[#calls + 1] = copyMap(opts)
                return false
            end,
        },
    }
end

local function sharedOpts()
    return {
        labelWidth = 160,
        controlWidth = 180,
        controlGap = 8,
    }
end

local function assertCallerOptsUntouched(opts)
    lu.assertEquals(opts, {
        labelWidth = 160,
        controlWidth = 180,
        controlGap = 8,
    })
end

function TestControlTemplateContract.testModeDrawDoesNotMutateCallerOpts()
    local shared = assert(loadfile("src/mods/controls/shared.lua"))()
    local mode = assert(loadfile("src/mods/controls/Mode/base.lua"))({
        shared = shared,
    })
    local story = mode.prepare({
        label = "Story",
        values = { "default" },
        displayValues = {
            default = "Default",
        },
    })
    local miniboss = mode.prepare({
        label = "Miniboss",
        values = { "default" },
        displayValues = {
            default = "Default",
        },
    })
    local opts = sharedOpts()
    local draw = makeDraw()

    mode.draw(draw, makeModeControl(), story, opts)
    mode.draw(draw, makeModeControl(), miniboss, opts)

    assertCallerOptsUntouched(opts)
    lu.assertEquals(draw.calls[1].label, "Story")
    lu.assertEquals(draw.calls[2].label, "Miniboss")
    lu.assertEquals(draw.calls[1].labelWidth, 160)
end

function TestControlTemplateContract.testChoiceDrawDoesNotMutateCallerOpts()
    local shared = assert(loadfile("src/mods/controls/shared.lua"))()
    local choice = assert(loadfile("src/mods/controls/Choice/Choice.lua"))({
        shared = shared,
    })
    local first = choice.prepare({
        label = "First",
        values = { "a" },
        displayValues = {
            a = "A",
        },
    })
    local second = choice.prepare({
        label = "Second",
        values = { "b" },
        displayValues = {
            b = "B",
        },
    })
    local opts = sharedOpts()
    local draw = makeDraw()

    choice.draw(draw, makeSingleFieldControl("ValueA"), first, opts)
    choice.draw(draw, makeSingleFieldControl("ValueB"), second, opts)

    assertCallerOptsUntouched(opts)
    lu.assertEquals(draw.calls[1].label, "First")
    lu.assertEquals(draw.calls[2].label, "Second")
end

function TestControlTemplateContract.testChoiceDrawSupportsValueRange()
    local shared = assert(loadfile("src/mods/controls/shared.lua"))()
    local choice = assert(loadfile("src/mods/controls/Choice/Choice.lua"))({
        shared = shared,
    })
    local ranged = choice.prepare({
        label = "Ranged",
        type = "int",
        valueRange = {
            min = 1,
            max = 3,
        },
    })
    local opts = sharedOpts()
    local draw = makeDraw()

    choice.draw(draw, makeSingleFieldControl("Value"), ranged, opts)

    assertCallerOptsUntouched(opts)
    lu.assertNil(draw.calls[1].values)
    lu.assertEquals(draw.calls[1].valueRange, {
        min = 1,
        max = 3,
    })
end

function TestControlTemplateContract.testFlagDrawDoesNotMutateCallerOpts()
    local shared = assert(loadfile("src/mods/controls/shared.lua"))()
    local flag = assert(loadfile("src/mods/controls/Flag/Flag.lua"))({
        shared = shared,
    })
    local first = flag.prepare({
        label = "First Flag",
    })
    local second = flag.prepare({
        label = "Second Flag",
    })
    local opts = sharedOpts()
    local draw = makeDraw()

    flag.draw(draw, makeSingleFieldControl("FlagA"), first, opts)
    flag.draw(draw, makeSingleFieldControl("FlagB"), second, opts)

    assertCallerOptsUntouched(opts)
    lu.assertEquals(draw.calls[1].label, "First Flag")
    lu.assertEquals(draw.calls[2].label, "Second Flag")
end
