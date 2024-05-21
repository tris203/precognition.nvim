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
        eq(utils.char_class(" ", false), 0)
        eq(utils.char_class("\t", false), 0)
        eq(utils.char_class("\0", false), 0)
    end)

    it("word characters are classed", function()
        eq(utils.char_class("_", false), 2)
        eq(utils.char_class("a", false), 2)
        eq(utils.char_class("A", false), 2)
        eq(utils.char_class("0", false), 2)
    end)

    it("other characters are classed", function()
        eq(utils.char_class("!", false), 1)
        eq(utils.char_class("@", false), 1)
        eq(utils.char_class(".", false), 1)
    end)
end)

describe("big_word classing", function()
    it("big_word whitespace is classed", function()
        eq(utils.char_class(" ", true), 0)
        eq(utils.char_class("\t", true), 0)
        eq(utils.char_class("\0", true), 0)
    end)

    it("big_word word characters are classed", function()
        eq(utils.char_class("_", true), 1)
        eq(utils.char_class("a", true), 1)
        eq(utils.char_class("A", true), 1)
        eq(utils.char_class("0", true), 1)
    end)

    it("big_word other characters are classed", function()
        eq(utils.char_class("!", true), 1)
        eq(utils.char_class("@", true), 1)
        eq(utils.char_class(".", true), 1)
    end)
end)
