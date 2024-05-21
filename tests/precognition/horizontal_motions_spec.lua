local hm = require("precognition.horizontal_motions")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("boundaries", function()
    it("finds the next word boundary", function()
        local str = "abc efg"
        eq(5, hm.next_word_boundary(str, 1, #str, false))
        eq(5, hm.next_word_boundary(str, 2, #str, false))
        eq(5, hm.next_word_boundary(str, 3, #str, false))
        eq(5, hm.next_word_boundary(str, 4, #str, false))
        eq(0, hm.next_word_boundary(str, 5, #str, false))
        eq(0, hm.next_word_boundary(str, 6, #str, false))
        eq(0, hm.next_word_boundary(str, 7, #str, false))

        str = "slighly more complex test"
        eq(9, hm.next_word_boundary(str, 1, #str, false))
        eq(9, hm.next_word_boundary(str, 2, #str, false))
        eq(14, hm.next_word_boundary(str, 10, #str, false))
        eq(14, hm.next_word_boundary(str, 13, #str, false))
        eq(22, hm.next_word_boundary(str, 15, #str, false))
        eq(22, hm.next_word_boundary(str, 21, #str, false))

        str = "    myFunction(example, stuff)"
        eq(5, hm.next_word_boundary(str, 1, #str, false))
        eq(5, hm.next_word_boundary(str, 2, #str, false))
        eq(5, hm.next_word_boundary(str, 3, #str, false))
        eq(15, hm.next_word_boundary(str, 5, #str, false))
        eq(16, hm.next_word_boundary(str, 15, #str, false))
        eq(23, hm.next_word_boundary(str, 16, #str, false))
        eq(25, hm.next_word_boundary(str, 23, #str, false))
        eq(25, hm.next_word_boundary(str, 24, #str, false))
        eq(30, hm.next_word_boundary(str, 25, #str, false))
        eq(0, hm.next_word_boundary(str, 30, #str, false))
    end)

    it("finds next big word boundary", function()
        local str = "a big.word string"
        eq(12, hm.next_word_boundary(str, 3, #str, true))
        eq(12, hm.next_word_boundary(str, 4, #str, true))
    end)

    it("can walk string with w", function()
        local test_string = "abcdefg hijklmn opqrstu vwxyz"
        local pos = hm.next_word_boundary(test_string, 1, #test_string, false)
        if pos == 0 then
            error("pos is 0")
        end
        eq("h", test_string:sub(pos, pos))
        if pos == 0 then
            error("pos is 0")
        end
        pos = hm.next_word_boundary(test_string, pos, #test_string, false)
        if pos == 0 then
            error("pos is 0")
        end
        eq("o", test_string:sub(pos, pos))
        pos = hm.next_word_boundary(test_string, pos, #test_string, false)
        if pos == 0 then
            error("pos is 0")
        end
        eq("v", test_string:sub(pos, pos))
        pos = hm.next_word_boundary(test_string, pos, #test_string, false)
        eq(0, pos)
    end)

    describe("previous word boundary", function()
        it("finds the previous word boundary", function()
            local str = "abc efg"
            eq(0, hm.prev_word_boundary(str, 1, #str, false))
            eq(1, hm.prev_word_boundary(str, 2, #str, false))
            eq(1, hm.prev_word_boundary(str, 3, #str, false))
            eq(1, hm.prev_word_boundary(str, 4, #str, false))
            eq(1, hm.prev_word_boundary(str, 5, #str, false))
            eq(5, hm.prev_word_boundary(str, 6, #str, false))
            eq(5, hm.prev_word_boundary(str, 7, #str, false))

            str = "slighly more complex test"
            eq(9, hm.prev_word_boundary(str, 10, #str, false))
            eq(9, hm.prev_word_boundary(str, 11, #str, false))
            eq(14, hm.prev_word_boundary(str, 15, #str, false))
            eq(14, hm.prev_word_boundary(str, 16, #str, false))
            eq(22, hm.prev_word_boundary(str, 23, #str, false))
            eq(22, hm.prev_word_boundary(str, 24, #str, false))
            eq(22, hm.prev_word_boundary(str, 25, #str, false))
            eq(0, hm.prev_word_boundary(str, 1, #str, false))

            str = "    myFunction(example, stuff)"
            eq(0, hm.prev_word_boundary(str, 1, #str, false))
            eq(0, hm.prev_word_boundary(str, 2, #str, false))
            eq(0, hm.prev_word_boundary(str, 3, #str, false))
            eq(0, hm.prev_word_boundary(str, 4, #str, false))
            eq(0, hm.prev_word_boundary(str, 5, #str, false))
            eq(5, hm.prev_word_boundary(str, 6, #str, false))
            eq(5, hm.prev_word_boundary(str, 15, #str, false))
            eq(15, hm.prev_word_boundary(str, 16, #str, false))
            eq(16, hm.prev_word_boundary(str, 17, #str, false))
            eq(16, hm.prev_word_boundary(str, 18, #str, false))
            eq(16, hm.prev_word_boundary(str, 19, #str, false))
            eq(23, hm.prev_word_boundary(str, 25, #str, false))
            eq(25, hm.prev_word_boundary(str, 26, #str, false))
            eq(25, hm.prev_word_boundary(str, 27, #str, false))
            eq(25, hm.prev_word_boundary(str, 28, #str, false))
            eq(25, hm.prev_word_boundary(str, 29, #str, false))
            eq(25, hm.prev_word_boundary(str, 30, #str, false))
        end)

        it("finds previous big word boundary", function()
            local str = "a big.word string"
            eq(3, hm.prev_word_boundary(str, 10, #str, true))
            eq(3, hm.prev_word_boundary(str, 10, #str, true))
        end)

        it("can walk string with b", function()
            local test_string = "abcdefg hijklmn opqrstu vwxyz"
            local pos = hm.prev_word_boundary(test_string, 29, #test_string, false)
            if pos == 0 then
                error("pos is 0")
            end
            eq("v", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos, #test_string, false)
            if pos == 0 then
                error("pos is 0")
            end
            eq("o", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos, #test_string, false)
            if pos == 0 then
                error("pos is 0")
            end
            eq("h", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos, #test_string, false)
            eq(1, pos)
        end)
    end)

    describe("end of current word", function()
        it("finds the end of words", function()
            local str = "abc efg"
            eq(3, hm.end_of_word(str, 1, #str, false))
            eq(3, hm.end_of_word(str, 2, #str, false))
            eq(7, hm.end_of_word(str, 3, #str, false))

            str = "slighly more complex test"
            eq(7, hm.end_of_word(str, 1, #str, false))
            eq(7, hm.end_of_word(str, 2, #str, false))
            eq(12, hm.end_of_word(str, 10, #str, false))
            eq(20, hm.end_of_word(str, 13, #str, false))
            eq(20, hm.end_of_word(str, 15, #str, false))
            eq(25, hm.end_of_word(str, 21, #str, false))

            str = "    myFunction(example, stuff)"
            eq(14, hm.end_of_word(str, 1, #str, false))
            eq(14, hm.end_of_word(str, 2, #str, false))
            eq(14, hm.end_of_word(str, 3, #str, false))
            eq(14, hm.end_of_word(str, 5, #str, false))
            eq(15, hm.end_of_word(str, 14, #str, false))
            eq(22, hm.end_of_word(str, 15, #str, false))
            eq(22, hm.end_of_word(str, 16, #str, false))
            eq(29, hm.end_of_word(str, 23, #str, false))
            eq(29, hm.end_of_word(str, 24, #str, false))
            eq(29, hm.end_of_word(str, 25, #str, false))
            eq(30, hm.end_of_word(str, 29, #str, false))
            eq(0, hm.end_of_word(str, 30, #str, false))
        end)

        it("finds the end of the current big word", function()
            local str = "a big.word string"
            eq(10, hm.end_of_word(str, 3, #str, true))
        end)
    end)
end)

describe("matching_pair returns the correction function", function()
    it("returns the correct function for the given character", function()
        local test_string = "()[]{}/*"
        eq(hm.matching_pair(test_string, 1, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 2, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 3, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 4, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 5, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 6, #test_string), hm.matching_bracket)
        eq(hm.matching_pair(test_string, 7, #test_string), hm.matching_comment)
        eq(hm.matching_pair(test_string, 8, #test_string), hm.matching_comment)
    end)

    it("returns a function that returns 0 for other characters", function()
        local test_string = "abcdefghijklmnopqrstuvwxyz!@#$%^&*_+-=,.<>?|\\~`"
        for i = 1, #test_string do
            local func = hm.matching_pair(test_string, i, #test_string)
            eq(0, func(test_string, i, #test_string))
        end
    end)
end)

describe("matching brackets", function()
    it("if cursor is over a bracket it can find the pair", function()
        local str = "abc (efg)"
        eq(9, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 6, #str))
        eq(0, hm.matching_bracket(str, 7, #str))
        eq(0, hm.matching_bracket(str, 8, #str))
        eq(5, hm.matching_bracket(str, 9, #str))
    end)

    it("if cursor is over a square bracket it can find the pair", function()
        local str = "abc [efg]"
        eq(9, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 6, #str))
        eq(0, hm.matching_bracket(str, 7, #str))
        eq(0, hm.matching_bracket(str, 8, #str))
        eq(5, hm.matching_bracket(str, 9, #str))
    end)

    it("if cursor is over a curly bracket it can find the pair", function()
        local str = "abc {efg}"
        eq(9, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 6, #str))
        eq(0, hm.matching_bracket(str, 7, #str))
        eq(0, hm.matching_bracket(str, 8, #str))
        eq(5, hm.matching_bracket(str, 9, #str))
    end)

    it("nested brackets find the correct pair", function()
        local str = "abc (efg [hij] klm)"
        eq(19, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 6, #str))
        eq(14, hm.matching_bracket(str, 10, #str))
        eq(10, hm.matching_bracket(str, 14, #str))
        eq(0, hm.matching_bracket(str, 15, #str))
        eq(5, hm.matching_bracket(str, 19, #str))
    end)

    it("nested brackets of the same type find the correct pair", function()
        local str = "abc (efg (hij) klm)"
        eq(19, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 6, #str))
        eq(14, hm.matching_bracket(str, 10, #str))
        eq(10, hm.matching_bracket(str, 14, #str))
        eq(0, hm.matching_bracket(str, 15, #str))
        eq(5, hm.matching_bracket(str, 19, #str))
    end)

    it("if cursor is over an unclosed bracket it returns 0", function()
        local str = "abc (efg"
        eq(0, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 5, #str))
        eq(0, hm.matching_bracket(str, 5, #str))
    end)
end)

describe("matching comments", function()
    it("if cursor is over a comment it can find the pair", function()
        local str = "abc /*efg*/"
        eq(11, hm.matching_comment(str, 5, #str))
        eq(11, hm.matching_comment(str, 6, #str))
        eq(0, hm.matching_comment(str, 7, #str))
        eq(5, hm.matching_comment(str, 10, #str))
        eq(5, hm.matching_comment(str, 11, #str))
    end)

    it("if cursor is over an unclosed comment it returns 0", function()
        local str = "abc /*efg"
        eq(0, hm.matching_comment(str, 5, #str))
        eq(0, hm.matching_comment(str, 6, #str))
    end)
end)

describe("edge case", function()
    it("can handle empty strings", function()
        eq(0, hm.next_word_boundary("", 1, 0, false))
        eq(0, hm.prev_word_boundary("", 1, 0, false))
        eq(0, hm.end_of_word("", 1, 0, false))
    end)

    it("can handle strings with only whitespace", function()
        eq(0, hm.next_word_boundary(" ", 1, 1, false))
        eq(0, hm.prev_word_boundary(" ", 1, 1, false))
        eq(0, hm.end_of_word(" ", 1, 1, false))
    end)

    it("can handle strings with special characters in the middle", function()
        local str = "vim.keymap.set('n', '<leader>t;', ':Test<CR>')"
        eq(5, hm.next_word_boundary(str, 4, #str, false))
        eq(1, hm.prev_word_boundary(str, 4, #str, false))
        eq(10, hm.end_of_word(str, 4, #str, false))
    end)

    it("can handle strings with multiple consecutive special characters", function()
        local str = "this || that"
        eq(9, hm.next_word_boundary(str, 6, #str, false))
        eq(1, hm.prev_word_boundary(str, 6, #str, false))
        eq(7, hm.end_of_word(str, 6, #str, false))
    end)

    it("strings with spaces at the end", function()
        local str = "there is a space "
        eq(0, hm.end_of_word(str, 16, #str, false))
    end)

    it("single character next word ends", function()
        local str = "show_something = true,"
        eq(14, hm.end_of_word(str, 1, #str, false))
        eq(16, hm.end_of_word(str, 14, #str, false))
        eq(16, hm.end_of_word(str, 15, #str, false))
        eq(22, hm.end_of_word(str, 21, #str, false))
    end)
end)
