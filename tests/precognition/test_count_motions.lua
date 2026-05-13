local MotionCount = require("precognition.motion_count")
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

    it("uses explicit count prefixes when provided", function()
        motion_count:set_prefix("2")

        eq(3, motion_count:count_for_prefix("3"))
        eq(false, motion_count:is_suppressed("3"))
        eq(true, motion_count:is_suppressed("101"))
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
