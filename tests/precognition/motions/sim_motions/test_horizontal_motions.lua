---@type fun(left: any, right: any)
local eq = MiniTest.expect.equality
---@type table
local horizontal_motions = require("precognition.motions.sim_motions.horizontal_motions")

---@param hints Precognition.TargetedMotionHint[]
---@return string[]
local function labels(hints)
    return vim.tbl_map(function(hint)
        return hint.label
    end, hints)
end

describe("sim targeted motions", function()
    ---@type string
    local ambiwidth

    before_each(function()
        ambiwidth = vim.o.ambiwidth
    end)

    after_each(function()
        vim.o.ambiwidth = ambiwidth
    end)

    it("recomputes labels when 'ambiwidth' changes on the same line", function()
        -- U+00B7 is an ambiguous-width character.
        local line = "a·b"

        vim.o.ambiwidth = "single"
        eq({ "·", "b" }, labels(horizontal_motions.targeted_motions.f(line, 1, 3)))

        vim.o.ambiwidth = "double"
        eq({ "b" }, labels(horizontal_motions.targeted_motions.f(line, 1, 3)))
    end)
end)
