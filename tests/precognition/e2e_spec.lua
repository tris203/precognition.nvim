local precognition = require("precognition")
local tu = require("tests.precognition.utils.utils")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same
local function neq(expected, actual)
    ---@diagnostic disable-next-line: undefined-field
    assert.are_not.same(expected, actual)
end

local function not_nil(value)
    ---@diagnostic disable-next-line: undefined-field
    assert.not_nil(value)
end

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

    it("hides all hints in insert mode", function()
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

        precognition.hide()
        precognition.show()

        not_nil(precognition.extmark)
        neq({}, tu.get_gutter_extmarks(buffer))

        vim.api.nvim_exec_autocmds("InsertEnter", { group = "precognition" })

        ---@diagnostic disable-next-line: undefined-field
        assert.is_nil(precognition.extmark)
        eq({}, tu.get_gutter_extmarks(buffer))
    end)

    it("does not redraw pending debounced hints in insert mode", function()
        precognition.setup({
            debounceMs = 100,
        })

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

        precognition.hide()
        precognition.show()

        not_nil(precognition.extmark)

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })

        local get_mode = vim.api.nvim_get_mode
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "i" }
        end)

        vim.api.nvim_exec_autocmds("InsertEnter", { group = "precognition" })

        local co = coroutine.running()
        coroutine.yield(vim.defer_fn(function()
            coroutine.resume(co)
        end, 200))

        rawset(vim.api, "nvim_get_mode", get_mode)

        ---@diagnostic disable-next-line: undefined-field
        assert.is_nil(precognition.extmark)
        eq({}, tu.get_gutter_extmarks(buffer))
    end)

    it("shows hints immediately when debounce is configured", function()
        precognition.setup({
            debounceMs = 200,
        })

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

        precognition.hide()
        precognition.show()

        not_nil(precognition.extmark)
        neq({}, tu.get_gutter_extmarks(buffer))
    end)

    it("supports debounce", function()
        precognition.setup({
            debounceMs = 200,
        })

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )

        precognition.on_cursor_moved()

        ---@diagnostic disable-next-line: undefined-field
        assert.is_nil(precognition.extmark)

        eq(
            {},
            vim.api.nvim_buf_get_extmarks(buffer, precognition.ns, 0, -1, {
                details = true,
            })
        )

        local co = coroutine.running()
        coroutine.yield(vim.defer_fn(function()
            coroutine.resume(co)
        end, 300))

        not_nil(precognition.extmark)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("^   e w                  $", extmarks[3].virt_lines[1][1][1])
    end)

    it("debounces repeated calls with the latest arguments", function()
        local result
        local debounced = require("precognition.utils").debounce_trailing(function(value)
            result = value
        end, 100)

        debounced("first")
        debounced("second")

        local co = coroutine.running()
        coroutine.yield(vim.defer_fn(function()
            coroutine.resume(co)
        end, 200))

        eq("second", result)
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

    it("does not display blank full-width virtual lines when blank virtual lines are disabled", function()
        precognition.setup({
            showBlankVirtLine = false,
            highlightFullVirtLine = true,
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = { prio = 0 },
                w = { prio = 0 },
                b = { prio = 0 },
                e = { prio = 0 },
                W = { prio = 0 },
                B = { prio = 0 },
                E = { prio = 0 },
                MatchingPair = { prio = 0 },
                Zero = { prio = 0 },
                Dollar = { prio = 0 },
            },
        })
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello" })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmarks(buffer, precognition.ns, 0, -1, { details = true })
        eq(0, #extmarks)
    end)

    it("pads full-width virtual lines to the text area", function()
        precognition.setup({ highlightFullVirtLine = true })
        local orig_width = vim.api.nvim_win_get_width(0)
        local orig_number = vim.wo.number
        local orig_signcolumn = vim.wo.signcolumn
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World" })
        vim.api.nvim_win_set_width(0, 40)
        vim.wo.number = true
        vim.wo.signcolumn = "yes"
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())[1]
        eq(vim.api.nvim_win_get_width(0) - win_info.textoff, #extmarks[3].virt_lines[1][1][1])
        vim.wo.number = orig_number
        vim.wo.signcolumn = orig_signcolumn
        vim.api.nvim_win_set_width(0, orig_width)
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
