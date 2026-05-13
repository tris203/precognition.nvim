local HintPlan = require("precognition.hint_plan")
local MotionCount = require("precognition.motion_count")
local PendingCommandPrefix = require("precognition.pending_command_prefix")
local default_config = require("precognition.defaults").config
local eq = MiniTest.expect.equality
local buffers = {}

local function context(overrides)
    local line = overrides.current_line or "hello world this"
    local motion_count = overrides.motion_count or MotionCount.new()
    local bufnr = vim.api.nvim_create_buf(true, false)
    table.insert(buffers, bufnr)
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
    after_each(function()
        for _, bufnr in ipairs(buffers) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        buffers = {}
    end)

    it("suppresses Hints in insert mode", function()
        local plan = HintPlan.build(context({ mode = "i" }))

        eq(true, plan.skip_render)
        eq("none", plan.kind)
    end)

    it("plans normal Inline Hints and Gutter Hints", function()
        local plan = HintPlan.build(context({ current_line = "hello world", cursorcol = 1, line_len = 11 }))

        eq(false, plan.skip_render)
        eq("normal", plan.kind)
        eq(
            { 7 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "w"
                end, plan.inline_hints)
            )
        )
        eq(
            { 5 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "e"
                end, plan.inline_hints)
            )
        )
        eq(1, plan.gutter_hints.gg)
        eq("table", type(plan.planned_gutter_hints))
    end)

    it("plans Target Character Hints as targeted Motion keys before a targeted Motion is pending", function()
        local plan = HintPlan.build(context({
            current_line = "ab cab!a",
            cursorcol = 4,
            line_len = 8,
        }))

        eq(false, plan.skip_render)
        eq("normal", plan.kind)
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 5
        end, plan.inline_hints))
        for _, candidate in ipairs(plan.inline_hints) do
            if candidate.label == "f" then
                eq("PrecognitionTargetedMotion", candidate.hl_group)
            end
        end
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 6
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 7
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "F" and candidate.col == 2
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "F" and candidate.col == 1
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "t" and candidate.col == 4
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "t" and candidate.col == 5
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "t" and candidate.col == 6
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "T" and candidate.col == 3
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "T" and candidate.col == 1
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == " " and candidate.col == 3
        end, plan.inline_hints))
    end)

    it("plans Target Character Hints as characters while a targeted Motion is pending", function()
        local plan = HintPlan.build(context({
            current_line = "ab cab!a",
            cursorcol = 4,
            line_len = 8,
            pending_command_prefix = "f",
        }))

        eq(false, plan.skip_render)
        eq("normal", plan.kind)
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 5
        end, plan.inline_hints))
        for _, candidate in ipairs(plan.inline_hints) do
            if candidate.label == "a" and candidate.col == 5 then
                eq(nil, candidate.hl_group)
            end
        end
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "b" and candidate.col == 6
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "!" and candidate.col == 7
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "c" and candidate.col == 3
        end, plan.inline_hints))
        eq(
            {},
            vim.tbl_filter(function(candidate)
                return candidate.label == "w"
            end, plan.inline_hints)
        )
        eq(
            {},
            vim.tbl_filter(function(candidate)
                return candidate.label == "e"
            end, plan.inline_hints)
        )
    end)

    it("plans backward Target Character Hints as characters while F is pending", function()
        local plan = HintPlan.build(context({
            current_line = "ab cab!a",
            cursorcol = 4,
            line_len = 8,
            pending_command_prefix = "F",
        }))

        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == " " and candidate.col == 3
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "b" and candidate.col == 2
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 1
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "!" and candidate.col == 7
        end, plan.inline_hints))
    end)

    it("plans till Target Character Hints as characters while t is pending", function()
        local plan = HintPlan.build(context({
            current_line = "ab cab!a",
            cursorcol = 4,
            line_len = 8,
            pending_command_prefix = "t",
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 4
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "b" and candidate.col == 5
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "!" and candidate.col == 6
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 7
        end, plan.inline_hints))
    end)

    it("plans backward till Target Character Hints as characters while T is pending", function()
        local plan = HintPlan.build(context({
            current_line = "ab cab!a",
            cursorcol = 4,
            line_len = 8,
            pending_command_prefix = "T",
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "b" and candidate.col == 3
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 2
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "!" and candidate.col == 7
        end, plan.inline_hints))
    end)

    it("plans counted Target Character Hints", function()
        local motion_count = MotionCount.new()
        motion_count:set_prefix("2")
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 1,
            line_len = 6,
            motion_count = motion_count,
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 5
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "t" and candidate.col == 4
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 3
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "t" and candidate.col == 2
        end, plan.inline_hints))
    end)

    it("plans counted pending Target Character Hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 1,
            line_len = 6,
            pending_command_prefix = "2f",
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 5
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 3
        end, plan.inline_hints))
        eq(
            {},
            vim.tbl_filter(function(candidate)
                return candidate.label == "w"
            end, plan.inline_hints)
        )
    end)

    it("plans counted pending till Target Character Hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 1,
            line_len = 6,
            pending_command_prefix = "2t",
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 4
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "a" and candidate.col == 2
        end, plan.inline_hints))
        eq(
            {},
            vim.tbl_filter(function(candidate)
                return candidate.label == "w"
            end, plan.inline_hints)
        )
    end)

    it("can disable Target Character Hints", function()
        local config = vim.deepcopy(default_config)
        config.targetedMotionHints.enabled = false
        local plan = HintPlan.build(context({
            current_line = "abc",
            cursorcol = 1,
            line_len = 3,
            config = config,
        }))

        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 2
        end, plan.inline_hints))
        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 3
        end, plan.inline_hints))
    end)

    it("plans repeat Target Character Hints after f", function()
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 3,
            line_len = 6,
            charsearch = { char = "a", forward = 1, ["until"] = 0 },
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 5
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "," and candidate.col == 1
        end, plan.inline_hints))
    end)

    it("prioritizes repeat Target Character Hints over discovery hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 3,
            line_len = 6,
            charsearch = { char = "a", forward = 1, ["until"] = 0 },
        }))

        local repeat_hint = vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 5
        end, plan.inline_hints)[1]
        local discovery_hint = vim.tbl_filter(function(candidate)
            return candidate.label == "f" and candidate.col == 5
        end, plan.inline_hints)[1]

        eq(true, repeat_hint.prio > discovery_hint.prio)
    end)

    it("uses normal highlight for repeat Target Character Hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacad",
            cursorcol = 3,
            line_len = 6,
            charsearch = { char = "a", forward = 1, ["until"] = 0 },
        }))

        local repeat_hint = vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 5
        end, plan.inline_hints)[1]

        eq(nil, repeat_hint.hl_group)
    end)

    it("plans repeat Target Character Hints after T", function()
        local plan = HintPlan.build(context({
            current_line = "abacadxa",
            cursorcol = 5,
            line_len = 8,
            charsearch = { char = "a", forward = 0, ["until"] = 1 },
        }))

        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 4
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == "," and candidate.col == 7
        end, plan.inline_hints))
    end)

    it("skips the previous t target when planning repeat till hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacadaba",
            cursorcol = 4,
            line_len = 9,
            charsearch = { char = "a", forward = 1, ["until"] = 1 },
        }))

        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 4
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 6
        end, plan.inline_hints))
    end)

    it("skips the previous T target when planning repeat till hints", function()
        local plan = HintPlan.build(context({
            current_line = "abacadaba",
            cursorcol = 6,
            line_len = 9,
            charsearch = { char = "a", forward = 0, ["until"] = 1 },
        }))

        eq(0, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 6
        end, plan.inline_hints))
        eq(1, #vim.tbl_filter(function(candidate)
            return candidate.label == ";" and candidate.col == 4
        end, plan.inline_hints))
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

        eq(
            { 13 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "w"
                end, plan.inline_hints)
            )
        )
    end)

    it("keeps normal Motion Hints visible for operator-only Pending Command Prefixes", function()
        local plan = HintPlan.build(context({ pending_command_prefix = "d" }))

        eq(false, plan.skip_render)
        eq("normal", plan.kind)
        eq(
            { 7 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "w"
                end, plan.inline_hints)
            )
        )
    end)

    it("plans operator-pending Counted Motion Destinations", function()
        local plan = HintPlan.build(context({
            current_line = "one two three four five six seven",
            cursorcol = 1,
            line_len = 33,
            prefix = PendingCommandPrefix.from_raw("2d3"),
        }))

        eq(
            { 29 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "w"
                end, plan.inline_hints)
            )
        )
    end)

    it("keeps Counted Motion suppression in Hint planning", function()
        local motion_count = MotionCount.new()
        motion_count:set_prefix("101")

        local plan = HintPlan.build(context({ motion_count = motion_count }))

        eq(false, plan.skip_render)
        eq("Count is too high, not showing hints", plan.message)
        eq(
            { 0 },
            vim.tbl_map(
                function(candidate)
                    return candidate.col
                end,
                vim.tbl_filter(function(candidate)
                    return candidate.label == "w"
                end, plan.inline_hints)
            )
        )
    end)

    it("plans text-object Inline Hints from pending prefixes", function()
        local plan = HintPlan.build(context({ pending_command_prefix = "i" }))

        eq(false, plan.skip_render)
        eq("text_object", plan.kind)
        eq("table", type(plan.text_object_anchors))
    end)
end)
