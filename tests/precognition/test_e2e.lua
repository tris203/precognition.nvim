local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()

describe("e2e tests", function()
    before_each(function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
    end)
    after_each(function()
        if child.is_running() then
            child.stop()
        end
    end)

    it("auto commands are set", function()
        child.lua_func(function()
            local eq = MiniTest.expect.equality
            local precognition = require("precognition")

            precognition.setup({})
            local autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
            eq(5, vim.tbl_count(autocmds))
            precognition.peek()
            autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
            eq(8, vim.tbl_count(autocmds))
        end)
    end)

    it("virtual line is displayed and updated", function()
        child.lua_func(function()
            require("precognition").setup({})
            vim.api.nvim_buf_set_lines(
                0,
                0,
                -1,
                false,
                { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
            )
            vim.api.nvim_win_set_cursor(0, { 1, 1 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("hides all hints in insert mode", function()
        child.lua_func(function()
            local precognition = require("precognition")
            local eq = MiniTest.expect.equality
            local neq = MiniTest.expect.no_equality
            local function get_gutter_extmarks(buffer)
                local gutter_extmarks = {}
                for _, extmark in
                    pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
                        details = true,
                    }))
                do
                    if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match("precognition_gutter") then
                        table.insert(gutter_extmarks, extmark)
                    end
                end
                return gutter_extmarks
            end
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

            precognition.setup({})
            precognition.hide()
            precognition.show()

            neq(
                nil,
                (
                    vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1]
                    or {}
                )[1]
            )
            neq({}, get_gutter_extmarks(buffer))

            vim.api.nvim_exec_autocmds("InsertEnter", { group = "precognition" })

            eq(
                nil,
                (
                    vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1]
                    or {}
                )[1]
            )
            eq({}, get_gutter_extmarks(buffer))
        end)
    end)

    it("does not redraw pending debounced hints in insert mode", function()
        child.lua_func(function()
            local precognition = require("precognition")
            local eq = MiniTest.expect.equality
            local neq = MiniTest.expect.no_equality
            local function get_gutter_extmarks(buffer)
                local gutter_extmarks = {}
                for _, extmark in
                    pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
                        details = true,
                    }))
                do
                    if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match("precognition_gutter") then
                        table.insert(gutter_extmarks, extmark)
                    end
                end
                return gutter_extmarks
            end
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

            neq(
                nil,
                (
                    vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1]
                    or {}
                )[1]
            )

            vim.api.nvim_win_set_cursor(0, { 2, 1 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })

            local get_mode = vim.api.nvim_get_mode
            rawset(vim.api, "nvim_get_mode", function()
                return { mode = "i" }
            end)

            local ok, err = pcall(function()
                vim.api.nvim_exec_autocmds("InsertEnter", { group = "precognition" })

                vim.wait(200)
            end)
            rawset(vim.api, "nvim_get_mode", get_mode)
            if not ok then
                error(err)
            end

            eq(
                nil,
                (
                    vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1]
                    or {}
                )[1]
            )
            eq({}, get_gutter_extmarks(buffer))
        end)
    end)

    it("shows hints immediately when debounce is configured", function()
        child.lua_func(function()
            local precognition = require("precognition")
            local neq = MiniTest.expect.no_equality
            local function get_gutter_extmarks(buffer)
                local gutter_extmarks = {}
                for _, extmark in
                    pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
                        details = true,
                    }))
                do
                    if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match("precognition_gutter") then
                        table.insert(gutter_extmarks, extmark)
                    end
                end
                return gutter_extmarks
            end
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

            neq(
                nil,
                (
                    vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1]
                    or {}
                )[1]
            )
            neq({}, get_gutter_extmarks(buffer))
        end)
    end)

    it("supports debounce", function()
        child.lua_func(function()
            local precognition = require("precognition")
            local eq = MiniTest.expect.equality
            local neq = MiniTest.expect.no_equality
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

            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })

            local ns = vim.api.nvim_create_namespace("precognition")

            eq(nil, (vim.api.nvim_buf_get_extmarks(buffer, ns, 0, -1, {})[1] or {})[1])

            eq(
                {},
                vim.api.nvim_buf_get_extmarks(buffer, ns, 0, -1, {
                    details = true,
                })
            )

            local ok = vim.wait(500, function()
                return (vim.api.nvim_buf_get_extmarks(buffer, ns, 0, -1, {})[1] or {})[1] ~= nil
            end)

            neq(false, ok)
            local extmark_id = vim.api.nvim_buf_get_extmarks(buffer, ns, 0, -1, {})[1][1]
            neq(nil, extmark_id)

            local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, ns, extmark_id, {
                details = true,
            })

            eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
            eq("^   e w                  $", extmarks[3].virt_lines[1][1][1])
        end)
    end)

    it("keeps full virtual lines when wrapping is disabled", function()
        child.lua_func(function()
            require("precognition").setup({})
            vim.o.columns = 20
            vim.wo.wrap = false
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha beta gamma delta epsilon" })
            vim.api.nvim_win_set_cursor(0, { 1, 12 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("clips wrapped virtual lines to the cursor's visual row", function()
        child.lua_func(function()
            require("precognition").setup({})
            vim.o.columns = 20
            vim.wo.wrap = true
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha beta gamma delta epsilon" })
            vim.api.nvim_win_set_cursor(0, { 1, 22 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("virtual line text color can be customised", function()
        child.lua_func(function()
            require("precognition").setup({ highlightColor = { link = "Function" } })
            vim.api.nvim_buf_set_lines(
                0,
                0,
                -1,
                false,
                { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
            )
            vim.api.nvim_win_set_cursor(0, { 1, 1 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("virtual line can be customised without a link", function()
        child.lua_func(function()
            require("precognition").setup({ highlightColor = { foreground = "#ff0000", background = "#00ff00" } })
            vim.api.nvim_buf_set_lines(
                0,
                0,
                -1,
                false,
                { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
            )
            vim.api.nvim_win_set_cursor(0, { 1, 1 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("does not display blank full-width virtual lines when blank virtual lines are disabled", function()
        child.lua_func(function()
            require("precognition").setup({
                showBlankVirtLine = false,
                highlightFullVirtLine = true,
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
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("pads full-width virtual lines to the text area", function()
        child.lua_func(function()
            local precognition = require("precognition")
            precognition.setup({ highlightFullVirtLine = true })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World" })
            vim.wo.number = true
            vim.wo.signcolumn = "yes"
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("preserves highlight groups through a colorscheme change", function()
        child.lua_func(function()
            local eq = MiniTest.expect.equality
            require("precognition").setup({})
            vim.cmd.colorscheme("default")
            local hl = vim.api.nvim_get_hl(0, { name = "PrecognitionHighlight" })
            eq(false, vim.tbl_isempty(hl))
        end)
    end)
end)

describe("Gutter Priority", function()
    before_each(function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
    end)
    after_each(function()
        if child.is_running() then
            child.stop()
        end
    end)

    it("0 priority item is not added", function()
        child.lua_func(function()
            require("precognition").setup({ gutterHints = { G = { text = "G", prio = 0 } } })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ABC", "DEF", "", "GHI", "", "JKL", "", "MNO" })
            vim.api.nvim_win_set_cursor(0, { 4, 0 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)

    it("higher priority item replaces", function()
        child.lua_func(function()
            require("precognition").setup({
                gutterHints = {
                    G = { text = "G", prio = 3 },
                    gg = { text = "gg", prio = 100 },
                    NextParagraph = { text = "}", prio = 2 },
                    PrevParagraph = { text = "{", prio = 1 },
                },
            })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ABC" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)
end)
