local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("Gutter hints table", function()
    it("should return a table with the correct keys", function()
        local testBuf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
        })

        local hints = precognition.build_gutter_hints(testBuf)

        eq(4, hints["G"])
        eq(1, hints["gg"])
    end)
end)
