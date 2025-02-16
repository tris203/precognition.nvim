local precognition = require("precognition")
local tu = require("tests.precognition.utils.utils")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("e2e tests", function()
    before_each(function()
        precognition.setup({})
    end)

    it("auto commands are set", function()
        local autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(5, vim.tbl_count(autocmds))
        precognition.peek()
        autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(8, vim.tbl_count(autocmds))
    end)

    -- it("namespace is created", function()
    --     local ns = vim.api.nvim_get_namespaces()
    --
    --     eq(1, ns["precognition"])
    --     eq(2, ns["precognition_gutter"])
    -- end)
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

        local gutter_extmarks = tu.get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Comment" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq({ link = "Comment" }, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))

        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        precognition.on_cursor_moved()

        gutter_extmarks = tu.get_gutter_extmarks(buffer)

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
        gutter_extmarks = tu.get_gutter_extmarks(buffer)

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
        precognition.setup({ highlightColor = { link = "Function" } })
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

        local gutter_extmarks = tu.get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))
    end)

    it("virtual line can be customised without a link", function()
        local background = "#00ff00"
        local foreground = "#ff0000"
        local customColor = { foreground = foreground, background = background }
        local customMark = { fg = tu.hex2dec(foreground), bg = tu.hex2dec(background) }
        precognition.setup({ highlightColor = customColor })
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

        local gutter_extmarks = tu.get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq(customMark, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))
    end)

    it("preserves highlight groups through a colorscheme change", function()
        vim.cmd.colorscheme("default")
        local hl = vim.api.nvim_get_hl(0, { name = "PrecognitionHighlight" })
        eq(false, vim.tbl_isempty(hl))
    end)
end)

describe("Gutter Priority", function()
    it("0 priority item is not added", function()
        precognition.setup({
            ---@diagnostic disable-next-line: missing-fields
            gutterHints = {
                G = { text = "G", prio = 0 },
            },
        })

        local testBuf = vim.api.nvim_create_buf(true, false)

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

        precognition.on_cursor_moved()

        local gutter_extmarks = tu.get_gutter_extmarks(testBuf)

        for _, extmark in pairs(gutter_extmarks) do
            eq(true, extmark[4].sign_text ~= "G ")
            eq(true, extmark[4].sign_name ~= "precognition_gutter_G")
        end
    end)

    it("higher priority item replaces", function()
        precognition.setup({
            ---@diagnostic disable-next-line: missing-fields
            gutterHints = {
                G = { text = "G", prio = 3 },
                gg = { text = "gg", prio = 100 },
                NextParagraph = { text = "}", prio = 2 },
                PrevParagraph = { text = "{", prio = 1 },
            },
        })

        local testBuf = vim.api.nvim_create_buf(true, false)

        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        precognition.on_cursor_moved()

        local gutter_extmarks = tu.get_gutter_extmarks(testBuf)

        eq(1, vim.tbl_count(gutter_extmarks))
        eq("gg", gutter_extmarks[1][4].sign_text)
    end)
end)
