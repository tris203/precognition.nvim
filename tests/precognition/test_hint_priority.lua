local HintPriority = require("precognition.hint_priority")
local eq = MiniTest.expect.equality

describe("Hint Priority", function()
    it("keeps the first Hint when priorities are equal", function()
        local priority = HintPriority.new()
        eq("first", priority:add(3, 5, "first"))
        eq(nil, priority:add(3, 5, "second"))

        eq("first", priority:hints_by_destination()[3].hint)
    end)

    it("uses the highest priority Hint for a Destination", function()
        local priority = HintPriority.new()
        eq("low", priority:add(3, 5, "low"))
        eq("high", priority:add(3, 6, "high"))

        eq("high", priority:hints_by_destination()[3].hint)
    end)

    it("suppresses zero priority Hints and missing Destinations", function()
        local priority = HintPriority.new()
        priority:add(3, 0, "zero")
        priority:add(0, 5, "missing")
        priority:add(nil, 5, "nil")

        local hints_by_destination = priority:hints_by_destination()
        eq(nil, hints_by_destination[3])
        eq(nil, hints_by_destination[0])
    end)
end)
