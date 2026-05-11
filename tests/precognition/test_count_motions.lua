local MotionCount = require("precognition.motion_count")
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

describe("motion count state", function()
    local motion_count

    before_each(function()
        motion_count = MotionCount.new()
    end)

    it("collects typed digits in supported modes", function()
        eq(true, motion_count:handle_key("2", "n"))
        eq("2", motion_count:prefix())
        eq(true, motion_count:handle_key("0", "n"))
        eq("20", motion_count:prefix())
        eq({ count = 20, suppressed = false }, motion_count:current())
    end)

    it("does not start a count with zero", function()
        eq(false, motion_count:handle_key("0", "n"))
        eq(nil, motion_count:prefix())
    end)

    it("resets on non-digit keys and unsupported modes", function()
        motion_count:handle_key("2", "n")
        eq(true, motion_count:handle_key("w", "n"))
        eq(nil, motion_count:prefix())

        motion_count:handle_key("3", "n")
        eq(true, motion_count:handle_key("4", "i"))
        eq(nil, motion_count:prefix())
    end)

    it("does not collect digits in operator-pending mode", function()
        motion_count:handle_key("2", "n")
        eq(true, motion_count:handle_key("3", "no"))
        eq(nil, motion_count:prefix())
    end)

    it("suppresses count prefixes above one hundred", function()
        motion_count:set_prefix("101")
        eq({ count = 101, suppressed = true }, motion_count:current())
    end)

    it("supports independent Motion Count instances", function()
        local first = MotionCount.new()
        local second = MotionCount.new()

        first:handle_key("2", "n")
        second:handle_key("1", "n")
        second:handle_key("0", "n")
        second:handle_key("1", "n")

        eq("2", first:prefix())
        eq(2, first:count())
        eq(false, first:is_suppressed())
        eq("101", second:prefix())
        eq(101, second:count())
        eq(true, second:is_suppressed())
    end)

    it("identifies modes that can receive Motion Count input", function()
        eq(true, motion_count:is_supported_prefix_mode("n"))
        eq(true, motion_count:is_supported_prefix_mode("v"))
        eq(true, motion_count:is_supported_prefix_mode("V"))
        eq(true, motion_count:is_supported_prefix_mode("\22"))
        eq(true, motion_count:is_supported_prefix_mode("no"))
        eq(false, motion_count:is_supported_prefix_mode("i"))
    end)

    it("identifies operator-pending mode", function()
        eq(true, motion_count:is_operator_pending_mode("no"))
        eq(true, motion_count:is_operator_pending_mode("nov"))
        eq(false, motion_count:is_operator_pending_mode("n"))
    end)

    it("identifies text-object prefixes", function()
        eq(true, motion_count:is_text_object_prefix("i"))
        eq(true, motion_count:is_text_object_prefix("a"))
        eq(true, motion_count:is_text_object_prefix("di"))
        eq(true, motion_count:is_text_object_prefix("2di"))
        eq(false, motion_count:is_text_object_prefix("d"))
        eq(false, motion_count:is_text_object_prefix(nil))
    end)

    it("identifies operator prefixes", function()
        eq(true, motion_count:is_operator_prefix("d"))
        eq(true, motion_count:is_operator_prefix("2d"))
        eq(false, motion_count:is_operator_prefix("di"))
        eq(false, motion_count:is_operator_prefix(nil))
    end)

    it("returns input state for counted Motion prefixes", function()
        local input = motion_count:handle_input("2", "n", nil)
        eq("2", motion_count:prefix())
        eq({ pending_command_prefix = "2", prefix_changed = true, defer_redraw = false }, input)

        input = motion_count:handle_input("0", "n", input.pending_command_prefix)
        eq("20", motion_count:prefix())
        eq({ pending_command_prefix = "20", prefix_changed = true, defer_redraw = false }, input)
    end)

    it("returns input state for text-object prefixes", function()
        local input = motion_count:handle_input("d", "n", nil)
        eq({ pending_command_prefix = "d", prefix_changed = true, defer_redraw = false }, input)

        input = motion_count:handle_input("i", "no", input.pending_command_prefix)
        eq({ pending_command_prefix = "i", prefix_changed = true, defer_redraw = true }, input)
    end)

    it("clears input state for escape", function()
        motion_count:handle_input("2", "n", nil)
        local input = motion_count:handle_input("\27", "n", "2")

        eq(nil, motion_count:prefix())
        eq({ pending_command_prefix = nil, prefix_changed = true, defer_redraw = false }, input)
    end)
end)

describe("count motions", function()
    local motion_count

    before_each(function()
        motion_count = MotionCount.new()
    end)

    it("applies a motion repeatedly", function()
        local str = "hello world this is a test"
        eq(
            13,
            motion_count:destination(2, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, #str)
        )

        eq(
            18,
            motion_count:destination(3, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )

        eq(
            1,
            motion_count:destination(1, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )
    end)

    it("returns no destination for out-of-bounds motions", function()
        local str = "hello world"
        eq(
            0,
            motion_count:destination(5, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, 1)
        )

        eq(
            0,
            motion_count:destination(4, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, #str, #str)
        )
    end)

    it("returns supported horizontal Counted Motion Destinations", function()
        local str = "hello world this is a test"
        motion_count:set_prefix("2")

        eq({
            w = 13,
            e = 11,
            b = 0,
            W = 13,
            E = 11,
            B = 0,
        }, motion_count:destinations(hm, str, 1, #str))
    end)

    it("suppresses supported horizontal Counted Motion Destinations", function()
        local str = "hello world this is a test"
        motion_count:set_prefix("101")

        eq({
            w = 0,
            e = 0,
            b = 0,
            W = 0,
            E = 0,
            B = 0,
        }, motion_count:destinations(hm, str, 1, #str))
    end)
end)
