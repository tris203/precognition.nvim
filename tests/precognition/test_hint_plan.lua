local HintPlan = require("precognition.hint_plan")
local MotionCount = require("precognition.motion_count")
local default_config = require("precognition.defaults").config
local eq = MiniTest.expect.equality

local function context(overrides)
    local line = overrides.current_line or "hello world this"
    local motion_count = overrides.motion_count or MotionCount.new()
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line })
    return vim.tbl_extend("force", {
        bufnr = bufnr,
        mode = "n",
        disabled_fts = default_config.disabled_fts,
        pending_command_prefix = nil,
        current_line = line,
        cursorcol = 1,
        line_len = vim.fn.strcharlen(line),
        motion_count = motion_count,
        motions = require("precognition.motions").get_motions(),
        config = default_config,
    }, overrides)
end

describe("Hint planning", function()
    it("suppresses Hints in insert mode", function()
        local plan = HintPlan.build(context({ mode = "i" }))

        eq(true, plan.suppressed)
        eq("none", plan.kind)
    end)

    it("plans normal Inline Hints and Gutter Hints", function()
        local plan = HintPlan.build(context({ current_line = "hello world", cursorcol = 1, line_len = 11 }))

        eq(false, plan.suppressed)
        eq("normal", plan.kind)
        eq(7, plan.inline_hints.w)
        eq(5, plan.inline_hints.e)
        eq(1, plan.gutter_hints.gg)
        eq("table", type(plan.planned_gutter_hints))
    end)

    it("plans Counted Motion Destinations", function()
        local motion_count = MotionCount.new()
        motion_count:set_prefix("2")

        local plan = HintPlan.build(context({
            current_line = "hello world this",
            cursorcol = 1,
            line_len = 16,
            motion_count = motion_count,
        }))

        eq(13, plan.inline_hints.w)
    end)

    it("keeps Counted Motion suppression in Hint planning", function()
        local motion_count = MotionCount.new()
        motion_count:set_prefix("101")

        local plan = HintPlan.build(context({ motion_count = motion_count }))

        eq(false, plan.suppressed)
        eq("Count is too high, not showing hints", plan.message)
        eq(0, plan.inline_hints.w)
    end)

    it("plans text-object Inline Hints from pending prefixes", function()
        local plan = HintPlan.build(context({ pending_command_prefix = "i" }))

        eq(false, plan.suppressed)
        eq("text_object", plan.kind)
        eq("table", type(plan.text_object_anchors))
    end)
end)
