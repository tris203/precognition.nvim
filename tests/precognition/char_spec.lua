local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("char classing", function()
    it("white space is classeed", function()
        eq(precognition.char_class(" "), 0)
        eq(precognition.char_class("\t"), 0)
        eq(precognition.char_class("\0"), 0)
    end)

    it("word characters are classed", function()
        eq(precognition.char_class("_"), 2)
        eq(precognition.char_class("a"), 2)
        eq(precognition.char_class("A"), 2)
        eq(precognition.char_class("0"), 2)
    end)

    it("other characters are classed", function()
        eq(precognition.char_class("!"), 1)
        eq(precognition.char_class("@"), 1)
        eq(precognition.char_class("."), 1)
    end)
end)

describe("boundaries", function()
    it("finds the next word boundary", function()
        eq(5, precognition.next_word_boundary("abc efg", 1))
        eq(5, precognition.next_word_boundary("abc efg", 2))
        eq(5, precognition.next_word_boundary("abc efg", 3))
        eq(5, precognition.next_word_boundary("abc efg", 4))
        eq(nil, precognition.next_word_boundary("abc efg", 5))
        eq(nil, precognition.next_word_boundary("abc efg", 6))
        eq(nil, precognition.next_word_boundary("abc efg", 7))

        eq(9, precognition.next_word_boundary("slighly more complex test", 1))
        eq(9, precognition.next_word_boundary("slighly more complex test", 2))
        eq(14, precognition.next_word_boundary("slighly more complex test", 10))
        eq(14, precognition.next_word_boundary("slighly more complex test", 13))
        eq(22, precognition.next_word_boundary("slighly more complex test", 15))
        eq(22, precognition.next_word_boundary("slighly more complex test", 21))

        eq(
            5,
            precognition.next_word_boundary("    myFunction(example, stuff)", 1)
        )
        eq(
            5,
            precognition.next_word_boundary("    myFunction(example, stuff)", 2)
        )
        eq(
            5,
            precognition.next_word_boundary("    myFunction(example, stuff)", 3)
        )
        eq(
            15,
            precognition.next_word_boundary("    myFunction(example, stuff)", 5)
        )
        eq(
            16,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                15
            )
        )
        eq(
            23,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                16
            )
        )
        eq(
            25,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                23
            )
        )
        eq(
            25,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                24
            )
        )
        eq(
            30,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                25
            )
        )
        eq(
            nil,
            precognition.next_word_boundary(
                "    myFunction(example, stuff)",
                30
            )
        )
    end)

    it("can walk string with w", function()
        local test_string = "abcdefg hijklmn opqrstu vwxyz"
        local pos = precognition.next_word_boundary(test_string, 1)
        eq("h", test_string:sub(pos, pos))
        pos = precognition.next_word_boundary(test_string, pos)
        eq("o", test_string:sub(pos, pos))
        pos = precognition.next_word_boundary(test_string, pos)
        eq("v", test_string:sub(pos, pos))
        pos = precognition.next_word_boundary(test_string, pos)
        eq(nil, pos)
    end)

    describe("previous word boundary", function()
        it("finds the previous word boundary", function()
            eq(nil, precognition.prev_word_boundary("abc efg", 1))
            eq(1, precognition.prev_word_boundary("abc efg", 2))
            eq(1, precognition.prev_word_boundary("abc efg", 3))
            eq(1, precognition.prev_word_boundary("abc efg", 4))
            eq(1, precognition.prev_word_boundary("abc efg", 5))
            eq(5, precognition.prev_word_boundary("abc efg", 6))
            eq(5, precognition.prev_word_boundary("abc efg", 7))

            eq(
                9,
                precognition.prev_word_boundary("slighly more complex test", 10)
            )
            eq(
                9,
                precognition.prev_word_boundary("slighly more complex test", 11)
            )
            eq(
                14,
                precognition.prev_word_boundary("slighly more complex test", 15)
            )
            eq(
                14,
                precognition.prev_word_boundary("slighly more complex test", 16)
            )
            eq(
                22,
                precognition.prev_word_boundary("slighly more complex test", 23)
            )
            eq(
                22,
                precognition.prev_word_boundary("slighly more complex test", 24)
            )
            eq(
                22,
                precognition.prev_word_boundary("slighly more complex test", 25)
            )
            eq(
                nil,
                precognition.prev_word_boundary("slighly more complex test", 1)
            )

            eq(
                nil,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    1
                )
            )
            eq(
                nil,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    2
                )
            )
            eq(
                nil,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    3
                )
            )
            eq(
                nil,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    4
                )
            )
            eq(
                nil,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    5
                )
            )
            eq(
                5,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    6
                )
            )
            eq(
                5,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    16
                )
            )
            eq(
                16,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    17
                )
            )
            eq(
                16,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    18
                )
            )
            eq(
                16,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    19
                )
            )
            eq(
                24,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    25
                )
            )
            eq(
                25,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    26
                )
            )
            eq(
                25,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    27
                )
            )
            eq(
                25,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    28
                )
            )
            eq(
                25,
                precognition.prev_word_boundary(
                    "    myFunction(example, stuff)",
                    29
                )
            )
            --TODO: This isnt right, it should ne 25, but i dont know the rules
            --there is something odd if there is only one class 2 under the cursor
            -- eq(25, precognition.prev_word_boundary("    myFunction(example, stuff)", 30))
        end)

        it("can walk string with b", function()
            local test_string = "abcdefg hijklmn opqrstu vwxyz"
            local pos = precognition.prev_word_boundary(test_string, 29)
            eq("v", test_string:sub(pos, pos))
            pos = precognition.prev_word_boundary(test_string, pos)
            eq("o", test_string:sub(pos, pos))
            pos = precognition.prev_word_boundary(test_string, pos)
            eq("h", test_string:sub(pos, pos))
            pos = precognition.prev_word_boundary(test_string, pos)
            eq(1, pos)
        end)
    end)

    describe("end of current word", function()
        it("finds the end of words", function()
            eq(3, precognition.end_of_word("abc efg", 1))
            eq(3, precognition.end_of_word("abc efg", 2))
            eq(7, precognition.end_of_word("abc efg", 3))

            eq(7, precognition.end_of_word("slighly more complex test", 1))
            eq(7, precognition.end_of_word("slighly more complex test", 2))
            eq(12, precognition.end_of_word("slighly more complex test", 10))
            eq(20, precognition.end_of_word("slighly more complex test", 13))
            eq(20, precognition.end_of_word("slighly more complex test", 15))
            eq(25, precognition.end_of_word("slighly more complex test", 21))

            eq(
                14,
                precognition.end_of_word("    myFunction(example, stuff)", 1)
            )
            eq(
                14,
                precognition.end_of_word("    myFunction(example, stuff)", 2)
            )
            eq(
                14,
                precognition.end_of_word("    myFunction(example, stuff)", 3)
            )
            eq(
                14,
                precognition.end_of_word("    myFunction(example, stuff)", 5)
            )
            --TODO: These next two dont work either for the same reason as the previous
            --something to do with the bracket being under the cursor
            -- eq(15, precognition.end_of_word("    myFunction(example, stuff)", 14))
            -- eq(22, precognition.end_of_word("    myFunction(example, stuff)", 15))
            eq(
                22,
                precognition.end_of_word("    myFunction(example, stuff)", 16)
            )
            eq(
                29,
                precognition.end_of_word("    myFunction(example, stuff)", 23)
            )
            eq(
                29,
                precognition.end_of_word("    myFunction(example, stuff)", 24)
            )
            eq(
                29,
                precognition.end_of_word("    myFunction(example, stuff)", 25)
            )
            eq(
                29,
                precognition.end_of_word("    myFunction(example, stuff)", 29)
            )
            eq(
                nil,
                precognition.end_of_word("    myFunction(example, stuff)", 30)
            )
        end)
    end)
end)
