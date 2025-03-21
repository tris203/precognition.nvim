local vm = require("precognition.motions").vertical_motions
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("gutter motion locations", function()
    it("can find file start in a single line buffer", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local start = vm.file_start()
        eq(1, start)
    end)

    it("can find file start in a multi line buffer", function()
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

        local start = vm.file_start()
        eq(1, start)
    end)

    it("can find file end in a single line buffer", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local end_ = vm.file_end(testBuf)
        eq(1, end_)
        eq(vim.api.nvim_buf_line_count(testBuf), end_)
    end)

    it("can find file end in a multi line buffer", function()
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

        local end_ = vm.file_end(testBuf)
        eq(8, end_)
        eq(vim.api.nvim_buf_line_count(testBuf), end_)
    end)

    it("can find the next paragraph line", function()
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

        local next_line = vm.next_paragraph_line(testBuf)
        eq(5, next_line)
    end)

    it("can find the previous paragraph line", function()
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
        vim.api.nvim_win_set_cursor(0, { 6, 0 })

        local prev_line = vm.prev_paragraph_line(testBuf)
        eq(5, prev_line)
    end)

    it("can find the prev paragraph in a file with multiple consecutive blank lines", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "",
            "",
            "MNO",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 10, 0 })

        local prev_line = vm.prev_paragraph_line(testBuf)
        eq(6, prev_line)
    end)

    it("can find the next paragraph in a file with multiple consecutive blank lines", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "",
            "",
            "",
            "GHI",
            "",
            "JKL",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 3, 0 })

        local next_line = vm.next_paragraph_line(testBuf)
        eq(8, next_line)
    end)

    it("lines with just whitespace as part of a paragraph", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "   ",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })

        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local next_line = vm.next_paragraph_line(testBuf)
        eq(5, next_line)
    end)
end)
