local MotionCount = require("precognition.motion_count")
local ObservedCommandState = require("precognition.observed_command_state")
local PendingCommandPrefix = require("precognition.pending_command_prefix")
local hm = require("precognition.motions.vanilla_motions.horizontal_motions")
local eq = MiniTest.expect.equality

describe("motion strings", function()
    it("parses the leading count prefix", function()
        eq(10, MotionCount.parse("10"))
        eq(2, MotionCount.parse("2w"))
        eq(2, MotionCount.parse("2d3w"))
        eq(1, MotionCount.parse("i"))
        eq(1, MotionCount.parse(nil))
        eq(1, MotionCount.parse(""))
        eq(1, MotionCount.parse("<20>"))
    end)
end)

describe("observed command state", function()
    it("combines operator and operator-pending Motion Counts", function()
        local state = ObservedCommandState.new()

        state:handle_key("2", "n")
        state:handle_key("d", "n")
        state:handle_key("3", "no")

        local snapshot = state:snapshot()
        eq("2d3", snapshot.raw)
        eq("6", snapshot.effective_motion_count_prefix)
        eq(6, snapshot.motion_count)
        eq(true, snapshot.normal_motion_hints_visible)
        eq(false, snapshot.text_object_hints_visible)
    end)

    it("surfaces Text Object Hint and redraw state", function()
        local state = ObservedCommandState.new()

        state:handle_key("d", "n")
        local input = state:handle_key("i", "no")

        local snapshot = state:snapshot()
        eq("di", snapshot.raw)
        eq(true, snapshot.text_object_hints_visible)
        eq("di", snapshot.text_object_prefix)
        eq(false, input.defer_redraw)
        eq("di", input.scheduled_prefix)
    end)

    it("surfaces pending Target Character Hint state", function()
        local state = ObservedCommandState.new()

        state:handle_key("2", "n")
        state:handle_key("f", "n")

        local snapshot = state:snapshot()
        eq("2f", snapshot.raw)
        eq("2", snapshot.effective_motion_count_prefix)
        eq(2, snapshot.motion_count)
        eq(false, snapshot.normal_motion_hints_visible)
        eq(false, snapshot.repeat_target_character_hints_visible)
        eq("f", snapshot.prefix:pending_targeted_motion_key({ f = function() end }))
    end)

    it("suppresses counts above 100 from typed input", function()
        local state = ObservedCommandState.new()

        state:handle_key("1", "n")
        state:handle_key("0", "n")
        state:handle_key("1", "n")

        local snapshot = state:snapshot()
        eq("101", snapshot.raw)
        eq(true, snapshot.count_suppressed)
    end)
end)

describe("motion count calculation", function()
    it("suppresses count prefixes above one hundred", function()
        eq(false, MotionCount:is_suppressed("100"))
        eq(true, MotionCount:is_suppressed("101"))
    end)
end)

describe("pending command prefixes", function()
    it("identifies modes that can receive Pending Command Prefix input", function()
        eq(true, PendingCommandPrefix.is_supported_mode("n"))
        eq(true, PendingCommandPrefix.is_supported_mode("v"))
        eq(true, PendingCommandPrefix.is_supported_mode("V"))
        eq(true, PendingCommandPrefix.is_supported_mode("\22"))
        eq(true, PendingCommandPrefix.is_supported_mode("no"))
        eq(false, PendingCommandPrefix.is_supported_mode("i"))
    end)

    it("keeps normal Motion Hints visible for operator-only prefixes", function()
        local prefix = PendingCommandPrefix.from_raw("d")

        eq(true, prefix:normal_motion_hints_visible())
        eq(false, prefix:text_object_hints_visible())
    end)

    it("switches to Text Object Hints for text-object prefixes", function()
        local prefix = PendingCommandPrefix.from_raw("2di")

        eq(false, prefix:normal_motion_hints_visible())
        eq(true, prefix:text_object_hints_visible())
        eq("2di", prefix:text_object_prefix())
    end)

    it("combines operator and operator-pending Motion Counts", function()
        local prefix = PendingCommandPrefix.new()

        prefix:handle_key("2", "n")
        prefix:handle_key("d", "n")
        prefix:handle_key("3", "no")

        eq("2d3", prefix:raw())
        eq("6", prefix:effective_motion_count_prefix())
        eq(true, prefix:normal_motion_hints_visible())
    end)

    it("identifies pending targeted Motions", function()
        local prefix = PendingCommandPrefix.from_raw("2f")

        eq("f", prefix:pending_targeted_motion_key({ f = function() end }))
        eq(false, prefix:normal_motion_hints_visible())
    end)
end)

describe("count motions", function()
    it("applies a motion repeatedly", function()
        local str = "hello world this is a test"
        eq(
            13,
            MotionCount:destination(2, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, #str)
        )

        eq(
            18,
            MotionCount:destination(3, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )

        eq(
            1,
            MotionCount:destination(1, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )
    end)

    it("returns no destination for out-of-bounds motions", function()
        local str = "hello world"
        eq(
            0,
            MotionCount:destination(5, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, 1)
        )

        eq(
            0,
            MotionCount:destination(4, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, #str, #str)
        )
    end)

    it("returns supported horizontal Counted Motion Destinations", function()
        local str = "hello world this is a test"

        eq({
            w = 13,
            e = 11,
            b = 0,
            W = 13,
            E = 11,
            B = 0,
        }, MotionCount:destinations(hm, str, 1, #str, "2"))
    end)

    it("suppresses supported horizontal Counted Motion Destinations", function()
        local str = "hello world this is a test"

        eq({
            w = 0,
            e = 0,
            b = 0,
            W = 0,
            E = 0,
            B = 0,
        }, MotionCount:destinations(hm, str, 1, #str, "101"))
    end)
end)
