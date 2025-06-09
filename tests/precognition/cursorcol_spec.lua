local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

local tabstop = 4

describe("Calculate current cursorcol position", function()
    it("calc current cursor col position for an empty string", function()
        local whitespace = ""
        local current_line = whitespace .. ""
        -- number of tabs in the whitespace we're testing for
        local num_tabs = select(2, string.gsub(whitespace, "\t", ""))
        local cursorposition = #whitespace + 1 -- cursor starts at column 1 for empty lines
        local offset = #whitespace:gsub("\t", string.rep(" ", tabstop))
        local cursorcol = precognition.calculate_cursorcol(current_line, cursorposition, offset)
        eq(cursorcol, cursorposition + tabstop * num_tabs - num_tabs)
    end)
    it("calculate col for leading spaces only", function()
        local whitespace = "    "
        local current_line = whitespace .. "word1 word2 word3"
        local num_tabs = select(2, string.gsub(whitespace, "\t", ""))
        local cursorposition = #whitespace + 1 -- place the initial cursor on the first char of the first word
        local offset = #whitespace:gsub("\t", string.rep(" ", tabstop))
        local cursorcol = precognition.calculate_cursorcol(current_line, cursorposition, offset)
        eq(cursorcol, cursorposition + tabstop * num_tabs - num_tabs)
    end)
    it("calculate col for leading tabs only", function()
        local whitespace = "\t\t\t"
        local current_line = whitespace .. "word1 word2 word3"
        local num_tabs = select(2, string.gsub(whitespace, "\t", ""))
        local cursorposition = #whitespace + 1
        local offset = #whitespace:gsub("\t", string.rep(" ", tabstop))
        local cursorcol = precognition.calculate_cursorcol(current_line, cursorposition, offset)
        eq(cursorcol, cursorposition + tabstop * num_tabs - num_tabs)
    end)
    it("calculate col for leading mix of spaces and tabs in any order", function()
        local whitespace = "  \t \t  \t \t  \t"
        local current_line = whitespace .. "word1 word2 word3"

        local num_tabs = select(2, string.gsub(whitespace, "\t", ""))
        local cursorposition = #whitespace + 1
        local offset = #whitespace:gsub("\t", string.rep(" ", tabstop))
        local cursorcol = precognition.calculate_cursorcol(current_line, cursorposition, offset)
        eq(cursorcol, cursorposition + tabstop * num_tabs - num_tabs)
    end)
end)
