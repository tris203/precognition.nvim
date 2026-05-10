local utils = require("precognition.utils")
local hm = require("precognition.motions.vanilla_motions.horizontal_motions")
local eq = MiniTest.expect.equality

describe("motion strings", function()
    it("parses the leading count prefix", function()
        eq(10, utils.motion_count_from_motionstring("10"))
        eq(2, utils.motion_count_from_motionstring("2w"))
        eq(2, utils.motion_count_from_motionstring("2d3w"))
        eq(1, utils.motion_count_from_motionstring("i"))
        eq(1, utils.motion_count_from_motionstring(nil))
        eq(1, utils.motion_count_from_motionstring(""))
        eq(1, utils.motion_count_from_motionstring("<20>"))
    end)
end)

describe("count motions", function()
    it("applies a motion repeatedly", function()
        local str = "hello world this is a test"
        eq(
            13,
            utils.count_motion(2, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, #str)
        )

        eq(
            18,
            utils.count_motion(3, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )

        eq(
            1,
            utils.count_motion(1, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, 6, #str)
        )
    end)

    it("returns no destination for out-of-bounds motions", function()
        local str = "hello world"
        eq(
            0,
            utils.count_motion(5, function(s, col, len)
                return hm.next_word_boundary(s, col, len, false)
            end, str, 1, 1)
        )

        eq(
            0,
            utils.count_motion(4, function(s, col, len)
                return hm.prev_word_boundary(s, col, len, false)
            end, str, #str, #str)
        )
    end)
end)
