local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("e2e tests", function()
    before_each(function()
        precognition.setup({})
    end)

    it("auto commands are set", function()
        local autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(4, vim.tbl_count(autocmds))
        precognition.peek()
        autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(7, vim.tbl_count(autocmds))
    end)

    -- 0.1 onlu?
    -- it("namespace is created", function()
    --     local ns = vim.api.nvim_get_namespaces()
    --
    --     eq(1, ns["precognition"])
    --     eq(2, ns["precognition_gutter"])
    -- :end)
    --
    it("virtual line is displayed and updated", function()
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World this is a test", "line 2" })
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        precognition.set_showcmd("2")
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])

        precognition.set_showcmd("")
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b  e w", extmarks[3].virt_lines[1][1][1])
    end)
end)
