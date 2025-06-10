local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("Calculate current cursorcol position", function()
    it("calc current cursor col position for an empty string", function()
        local cursorcol = precognition.calculate_visual_cursorcol("", 1, 0)
        eq(cursorcol, 1)
    end)
    it("calculate col for a line with leading spaces", function()
        local current_line = "    word1 word2 word3"
        local cursorcol = precognition.calculate_visual_cursorcol(current_line, 5, 4)
        eq(cursorcol, 5)
    end)
    it("calculate col for leading tabs only", function()
        local current_line = "\t\t\tword1 word2 word3"
        local cursorcol = precognition.calculate_visual_cursorcol(current_line, 4, 12)
        eq(cursorcol, 13)
    end)
    it("calculate col for leading mix of spaces and tabs in any order", function()
        local current_line = "  \t \t  \t \t  \tword1 word2 word3"
        local cursorcol = precognition.calculate_visual_cursorcol(current_line, 14, 28)
        eq(cursorcol, 29)
    end)
end)
