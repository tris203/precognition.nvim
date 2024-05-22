local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

local function get_gutter_extmarks(buffer)
    local gutter_extmarks = {}
    for _, extmark in
        pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
            details = true,
        }))
    do
        if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match(precognition.gutter_group) then
            table.insert(gutter_extmarks, extmark)
        end
    end
    return gutter_extmarks
end

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

    it("namespace is created", function()
        local ns = vim.api.nvim_get_namespaces()

        eq(1, ns["precognition"])
        eq(2, ns["precognition_gutter"])
    end)
    --
    it("virtual line is displayed and updated", function()
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        local gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("Comment", extmark[4].sign_hl_group)
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("Comment", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("Comment", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("Comment", extmark[4].sign_hl_group)
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("Comment", extmarks[3].virt_lines[1][1][2])

        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        precognition.on_cursor_moved()

        gutter_extmarks = get_gutter_extmarks(buffer)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b  e w", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 4, 1 })
        precognition.on_cursor_moved()
        gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq(2, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq(4, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end
    end)

    it("virtual line text color can be customised", function()
        precognition.setup({ highlightColor = "Function" })
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        local gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("Function", extmark[4].sign_hl_group)
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("Function", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("Function", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("Function", extmark[4].sign_hl_group)
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("Function", extmarks[3].virt_lines[1][1][2])
    end)
end)
