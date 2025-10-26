local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("Gutter hints table", function()
    it("should return a table with the correct keys", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 4, 0 })

        local hints = precognition.build_gutter_hints(testBuf)

        -- Verify all expected hints are present
        assert.is_not_nil(hints["gg"])
        assert.is_not_nil(hints["H"])
        assert.is_not_nil(hints["PrevParagraph"])
        assert.is_not_nil(hints["M"])
        assert.is_not_nil(hints["NextParagraph"])
        assert.is_not_nil(hints["L"])
        assert.is_not_nil(hints["G"])
        
        -- Verify specific expected values
        eq(1, hints["gg"])
        eq(3, hints["PrevParagraph"])
        eq(5, hints["NextParagraph"])
        eq(8, hints["G"])
        
        -- Verify HML ordering
        assert.is_true(hints["H"] <= hints["M"])
        assert.is_true(hints["M"] <= hints["L"])
    end)

    it("should return a table with the correct keys when the buffer is empty", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {})
        vim.api.nvim_set_current_buf(testBuf)

        local hints = precognition.build_gutter_hints(testBuf)

        -- Verify all expected hints are present
        assert.is_not_nil(hints["gg"])
        assert.is_not_nil(hints["H"])
        assert.is_not_nil(hints["M"])
        assert.is_not_nil(hints["L"])
        assert.is_not_nil(hints["PrevParagraph"])
        assert.is_not_nil(hints["NextParagraph"])
        assert.is_not_nil(hints["G"])
        
        -- For empty buffer, all should be 1
        eq(1, hints["gg"])
        eq(1, hints["H"])
        eq(1, hints["M"])
        eq(1, hints["L"])
        eq(1, hints["PrevParagraph"])
        eq(1, hints["NextParagraph"])
        eq(1, hints["G"])
    end)

    it("should return a table with the correct keys when the buffer is a single line", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local hints = precognition.build_gutter_hints(testBuf)
        
        -- Verify all expected hints are present
        assert.is_not_nil(hints["gg"])
        assert.is_not_nil(hints["H"])
        assert.is_not_nil(hints["M"])
        assert.is_not_nil(hints["L"])
        assert.is_not_nil(hints["PrevParagraph"])
        assert.is_not_nil(hints["NextParagraph"])
        assert.is_not_nil(hints["G"])
        
        -- For single line buffer, all should be 1
        eq(1, hints["gg"])
        eq(1, hints["H"])
        eq(1, hints["M"])
        eq(1, hints["L"])
        eq(1, hints["PrevParagraph"])
        eq(1, hints["NextParagraph"])
        eq(1, hints["G"])
    end)

    it("moving the cursor will update the hints table", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 4, 0 })

        local hints = precognition.build_gutter_hints(testBuf)

        -- Verify specific expected values
        eq(1, hints["gg"])
        eq(3, hints["PrevParagraph"])
        eq(5, hints["NextParagraph"])
        eq(8, hints["G"])
        -- Verify HML are present and ordered
        assert.is_not_nil(hints["H"])
        assert.is_not_nil(hints["M"])
        assert.is_not_nil(hints["L"])
        assert.is_true(hints["H"] <= hints["M"])
        assert.is_true(hints["M"] <= hints["L"])

        vim.api.nvim_win_set_cursor(0, { 6, 0 })
        hints = precognition.build_gutter_hints(testBuf)
        eq(1, hints["gg"])
        eq(5, hints["PrevParagraph"])
        eq(7, hints["NextParagraph"])
        eq(8, hints["G"])
        -- Verify HML are still properly ordered
        assert.is_true(hints["H"] <= hints["M"])
        assert.is_true(hints["M"] <= hints["L"])
    end)

    it("adding a line will update the hints table", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local hints = precognition.build_gutter_hints(testBuf)
        eq(1, hints["gg"])
        eq(1, hints["PrevParagraph"])
        eq(1, hints["NextParagraph"])
        eq(1, hints["G"])

        vim.api.nvim_buf_set_lines(testBuf, 1, 1, false, { "DEF" })

        hints = precognition.build_gutter_hints(testBuf)
        eq(1, hints["gg"])
        eq(1, hints["PrevParagraph"])
        eq(2, hints["NextParagraph"])
        eq(2, hints["G"])

        vim.api.nvim_buf_set_lines(testBuf, 2, 2, false, { "GHI" })

        hints = precognition.build_gutter_hints(testBuf)

        eq(1, hints["gg"])
        eq(1, hints["PrevParagraph"])
        eq(3, hints["NextParagraph"])
        eq(3, hints["G"])

        vim.api.nvim_buf_set_lines(testBuf, 3, 3, false, { "" })
        vim.api.nvim_buf_set_lines(testBuf, 4, 4, false, { "JKL" })

        hints = precognition.build_gutter_hints(testBuf)

        eq(1, hints["gg"])
        eq(1, hints["PrevParagraph"])
        eq(4, hints["NextParagraph"])
        eq(5, hints["G"])
    end)
end)
