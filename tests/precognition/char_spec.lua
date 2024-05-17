local utils = require("precognition.utils")
local cc = utils.char_classes
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("static classes", function()
    it("are set correctly", function()
        eq(cc.whitespace, 0)
        eq(cc.other, 1)
        eq(cc.word, 2)
    end)
end)

describe("char classing", function()
    it("white space is classeed", function()
        eq(utils.char_class(" "), 0)
        eq(utils.char_class("\t"), 0)
        eq(utils.char_class("\0"), 0)
    end)

    it("word characters are classed", function()
        eq(utils.char_class("_"), 2)
        eq(utils.char_class("a"), 2)
        eq(utils.char_class("A"), 2)
        eq(utils.char_class("0"), 2)
    end)

    it("other characters are classed", function()
        eq(utils.char_class("!"), 1)
        eq(utils.char_class("@"), 1)
        eq(utils.char_class("."), 1)
    end)
end)
