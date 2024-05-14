local utils = require("precognition.utils")
local hm = require("precognition.horizontal_motions")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same
describe("motionstrings", function()
    it("can parse motion string", function()
        local count = utils.count_from_motionstring("10")
        eq(10, count)

        count = utils.count_from_motionstring("2w")
        eq(2, count)

        count = utils.count_from_motionstring("2d3w")
        eq(6, count)

        count = utils.count_from_motionstring("i")
        eq(1, count)

        count = utils.count_from_motionstring(nil)
        eq(1, count)

        eq(1, utils.count_from_motionstring(""))

        count = utils.count_from_motionstring("<20>")
        eq(1, count)
    end)
end)

describe("count motions", function()
    it("motion with count", function()
        local str = "hello world this is a test"
        local count = utils.count_motion(2, hm.next_word_boundary, str, 1, #str)
        eq(13, count)

        count = utils.count_motion(3, hm.next_word_boundary, str, 6, #str)
        eq(18, count)

        count = utils.count_motion(1, hm.prev_word_boundary, str, 6, #str)
        eq(1, count)
    end)

    it("out of bound motions", function()
        local str = "hello world"
        local count = utils.count_motion(5, hm.next_word_boundary, str, 1, 1)
        eq(0, count)

        count = utils.count_motion(4, hm.prev_word_boundary, str, #str, #str)
        eq(0, count)
    end)
end)
