local hm = require("precognition.horizontal_motions")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("boundaries", function()
    it("finds the next word boundary", function()
        eq(5, hm.next_word_boundary("abc efg", 1))
        eq(5, hm.next_word_boundary("abc efg", 2))
        eq(5, hm.next_word_boundary("abc efg", 3))
        eq(5, hm.next_word_boundary("abc efg", 4))
        eq(nil, hm.next_word_boundary("abc efg", 5))
        eq(nil, hm.next_word_boundary("abc efg", 6))
        eq(nil, hm.next_word_boundary("abc efg", 7))

        eq(9, hm.next_word_boundary("slighly more complex test", 1))
        eq(9, hm.next_word_boundary("slighly more complex test", 2))
        eq(14, hm.next_word_boundary("slighly more complex test", 10))
        eq(14, hm.next_word_boundary("slighly more complex test", 13))
        eq(22, hm.next_word_boundary("slighly more complex test", 15))
        eq(22, hm.next_word_boundary("slighly more complex test", 21))

        eq(5, hm.next_word_boundary("    myFunction(example, stuff)", 1))
        eq(5, hm.next_word_boundary("    myFunction(example, stuff)", 2))
        eq(5, hm.next_word_boundary("    myFunction(example, stuff)", 3))
        eq(15, hm.next_word_boundary("    myFunction(example, stuff)", 5))
        eq(16, hm.next_word_boundary("    myFunction(example, stuff)", 15))
        eq(23, hm.next_word_boundary("    myFunction(example, stuff)", 16))
        eq(25, hm.next_word_boundary("    myFunction(example, stuff)", 23))
        eq(25, hm.next_word_boundary("    myFunction(example, stuff)", 24))
        eq(30, hm.next_word_boundary("    myFunction(example, stuff)", 25))
        eq(nil, hm.next_word_boundary("    myFunction(example, stuff)", 30))
    end)

    it("can walk string with w", function()
        local test_string = "abcdefg hijklmn opqrstu vwxyz"
        local pos = hm.next_word_boundary(test_string, 1)
        if pos == nil then
            error("pos is nil")
        end
        eq("h", test_string:sub(pos, pos))
        if pos == nil then
            error("pos is nil")
        end
        pos = hm.next_word_boundary(test_string, pos)
        if pos == nil then
            error("pos is nil")
        end
        eq("o", test_string:sub(pos, pos))
        pos = hm.next_word_boundary(test_string, pos)
        if pos == nil then
            error("pos is nil")
        end
        eq("v", test_string:sub(pos, pos))
        pos = hm.next_word_boundary(test_string, pos)
        eq(nil, pos)
    end)

    describe("previous word boundary", function()
        it("finds the previous word boundary", function()
            eq(nil, hm.prev_word_boundary("abc efg", 1))
            eq(1, hm.prev_word_boundary("abc efg", 2))
            eq(1, hm.prev_word_boundary("abc efg", 3))
            eq(1, hm.prev_word_boundary("abc efg", 4))
            eq(1, hm.prev_word_boundary("abc efg", 5))
            eq(5, hm.prev_word_boundary("abc efg", 6))
            eq(5, hm.prev_word_boundary("abc efg", 7))

            eq(9, hm.prev_word_boundary("slighly more complex test", 10))
            eq(9, hm.prev_word_boundary("slighly more complex test", 11))
            eq(14, hm.prev_word_boundary("slighly more complex test", 15))
            eq(14, hm.prev_word_boundary("slighly more complex test", 16))
            eq(22, hm.prev_word_boundary("slighly more complex test", 23))
            eq(22, hm.prev_word_boundary("slighly more complex test", 24))
            eq(22, hm.prev_word_boundary("slighly more complex test", 25))
            eq(nil, hm.prev_word_boundary("slighly more complex test", 1))

            eq(nil, hm.prev_word_boundary("    myFunction(example, stuff)", 1))
            eq(nil, hm.prev_word_boundary("    myFunction(example, stuff)", 2))
            eq(nil, hm.prev_word_boundary("    myFunction(example, stuff)", 3))
            eq(nil, hm.prev_word_boundary("    myFunction(example, stuff)", 4))
            eq(nil, hm.prev_word_boundary("    myFunction(example, stuff)", 5))
            eq(5, hm.prev_word_boundary("    myFunction(example, stuff)", 6))
            eq(5, hm.prev_word_boundary("    myFunction(example, stuff)", 15))
            eq(15, hm.prev_word_boundary("    myFunction(example, stuff)", 16))
            eq(16, hm.prev_word_boundary("    myFunction(example, stuff)", 17))
            eq(16, hm.prev_word_boundary("    myFunction(example, stuff)", 18))
            eq(16, hm.prev_word_boundary("    myFunction(example, stuff)", 19))
            eq(23, hm.prev_word_boundary("    myFunction(example, stuff)", 25))
            eq(25, hm.prev_word_boundary("    myFunction(example, stuff)", 26))
            eq(25, hm.prev_word_boundary("    myFunction(example, stuff)", 27))
            eq(25, hm.prev_word_boundary("    myFunction(example, stuff)", 28))
            eq(25, hm.prev_word_boundary("    myFunction(example, stuff)", 29))
            eq(25, hm.prev_word_boundary("    myFunction(example, stuff)", 30))
        end)

        it("can walk string with b", function()
            local test_string = "abcdefg hijklmn opqrstu vwxyz"
            local pos = hm.prev_word_boundary(test_string, 29)
            if pos == nil then
                error("pos is nil")
            end
            eq("v", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos)
            if pos == nil then
                error("pos is nil")
            end
            eq("o", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos)
            if pos == nil then
                error("pos is nil")
            end
            eq("h", test_string:sub(pos, pos))
            pos = hm.prev_word_boundary(test_string, pos)
            eq(1, pos)
        end)
    end)

    describe("end of current word", function()
        it("finds the end of words", function()
            eq(3, hm.end_of_word("abc efg", 1))
            eq(3, hm.end_of_word("abc efg", 2))
            eq(7, hm.end_of_word("abc efg", 3))

            eq(7, hm.end_of_word("slighly more complex test", 1))
            eq(7, hm.end_of_word("slighly more complex test", 2))
            eq(12, hm.end_of_word("slighly more complex test", 10))
            eq(20, hm.end_of_word("slighly more complex test", 13))
            eq(20, hm.end_of_word("slighly more complex test", 15))
            eq(25, hm.end_of_word("slighly more complex test", 21))

            eq(14, hm.end_of_word("    myFunction(example, stuff)", 1))
            eq(14, hm.end_of_word("    myFunction(example, stuff)", 2))
            eq(14, hm.end_of_word("    myFunction(example, stuff)", 3))
            eq(14, hm.end_of_word("    myFunction(example, stuff)", 5))
            eq(15, hm.end_of_word("    myFunction(example, stuff)", 14))
            eq(22, hm.end_of_word("    myFunction(example, stuff)", 15))
            eq(22, hm.end_of_word("    myFunction(example, stuff)", 16))
            eq(29, hm.end_of_word("    myFunction(example, stuff)", 23))
            eq(29, hm.end_of_word("    myFunction(example, stuff)", 24))
            eq(29, hm.end_of_word("    myFunction(example, stuff)", 25))
            eq(30, hm.end_of_word("    myFunction(example, stuff)", 29))
            eq(nil, hm.end_of_word("    myFunction(example, stuff)", 30))
        end)
    end)
end)

describe("edge case", function()
    it("can handle empty strings", function()
        eq(nil, hm.next_word_boundary("", 1))
        eq(nil, hm.prev_word_boundary("", 1))
        eq(nil, hm.end_of_word("", 1))
    end)

    it("can handle strings with only whitespace", function()
        eq(nil, hm.next_word_boundary(" ", 1))
        eq(nil, hm.prev_word_boundary(" ", 1))
        eq(nil, hm.end_of_word(" ", 1))
    end)

    it("can handle strings with special characters in the middle", function()
        local str = "vim.keymap.set('n', '<leader>t;', ':Test<CR>')"
        eq(5, hm.next_word_boundary(str, 4))
        eq(1, hm.prev_word_boundary(str, 4))
        eq(10, hm.end_of_word(str, 4))
    end)

    it(
        "can handle strings with multiple consecutive special characters",
        function()
            local str = "this || that"
            eq(9, hm.next_word_boundary(str, 6))
            eq(1, hm.prev_word_boundary(str, 6))
            eq(7, hm.end_of_word(str, 6))
        end
    )
end)
