local precognition = require("precognition")
local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()
local original_get_mode = vim.api.nvim_get_mode

local function restart_child()
    child.restart({ "-u", "scripts/minimal_init.lua" })
end

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
        rawset(vim.api, "nvim_get_mode", original_get_mode)
        precognition.setup({})
    end)

    after_each(function()
        rawset(vim.api, "nvim_get_mode", original_get_mode)
        if child.is_running() then
            child.stop()
        end
    end)

    it("auto commands are set", function()
        local autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(5, vim.tbl_count(autocmds))
        precognition.peek()
        autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(8, vim.tbl_count(autocmds))
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
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq(2, extmark[2])
            else
                error("unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        precognition.set_motion_count_prefix("2")
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])

        precognition.set_motion_count_prefix(nil)
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
                error("unexpected sign text")
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
                error("unexpected sign text")
            end
        end
    end)

    it("updates counted hints from typed input", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World this is a test" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        precognition.on_key("2")

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])

        precognition.on_key("w")
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])
    end)

    it("does not treat leading zero as a motion count", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World this is a test" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        precognition.on_cursor_moved()
        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        precognition.on_key("0")
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])
    end)

    it("builds multi-digit motion counts", function()
        precognition.hide()
        precognition.setup({ startVisible = false })
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        precognition.on_key("2")
        precognition.on_key("0")
        eq("20", precognition.motion_count_prefix)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "a b c d e f g h i j k l m n o p q r s t u v" })
        vim.api.nvim_win_set_cursor(0, { 1, 1 })
        precognition.show()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("^                                       w $", extmarks[3].virt_lines[1][1][1])
    end)

    it("uses typed motion counts in visual mode", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "v" }
        end)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World this is a test" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        precognition.on_key("2")

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])
    end)

    it("clears hints for counts above 100", function()
        restart_child()
        child.lua_func(function()
            local precognition = require("precognition")
            precognition.setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World this is a test", "line 2" })
            vim.api.nvim_win_set_cursor(0, { 1, 6 })
            precognition.on_cursor_moved()
        end)

        child.lua_func(function()
            local precognition = require("precognition")
            rawset(vim.api, "nvim_get_mode", function()
                return { mode = "n" }
            end)
            precognition.on_key("1")
            precognition.on_key("0")
            precognition.on_key("1")
        end)

        ss(child.get_screenshot())
    end)

    it("ignores operator-pending counts", function()
        restart_child()
        child.lua_func(function()
            local precognition = require("precognition")
            precognition.setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World this is a test" })
            vim.api.nvim_win_set_cursor(0, { 1, 6 })
            precognition.on_cursor_moved()
            rawset(vim.api, "nvim_get_mode", function()
                return { mode = "no" }
            end)
            precognition.on_key("3")
            precognition.on_cursor_moved()
        end)

        ss(child.get_screenshot())
    end)
end)
