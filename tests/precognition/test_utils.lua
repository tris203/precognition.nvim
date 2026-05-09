local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

describe("utils", function()
    it("debounces repeated calls with the latest arguments", function()
        local result
        local debounced = require("precognition.utils").debounce_trailing(function(value)
            result = value
        end, 100)

        debounced("first")
        debounced("second")

        local ok = vim.wait(500, function()
            return result == "second"
        end)

        neq(false, ok)
        eq("second", result)
    end)
end)
