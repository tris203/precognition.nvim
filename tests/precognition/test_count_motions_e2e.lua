local precognition = require("precognition")
local eq = MiniTest.expect.equality
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
        if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match("precognition_gutter") then
            table.insert(gutter_extmarks, extmark)
        end
    end
    return gutter_extmarks
end

local function has_autocmd(autocmds, event, buffer)
    for _, autocmd in ipairs(autocmds) do
        if autocmd.event == event and autocmd.buffer == buffer then
            return true
        end
    end

    return false
end

local function count_autocmds(autocmds, event, buffer)
    local count = 0
    for _, autocmd in ipairs(autocmds) do
        if autocmd.event == event and autocmd.buffer == buffer then
            count = count + 1
        end
    end

    return count
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
        eq(true, has_autocmd(autocmds, "ColorScheme"))
        eq(true, has_autocmd(autocmds, "CursorMoved"))
        eq(true, has_autocmd(autocmds, "BufLeave"))
        eq(true, has_autocmd(autocmds, "CursorMovedI"))
        eq(true, has_autocmd(autocmds, "InsertEnter"))

        local buffer = vim.api.nvim_get_current_buf()
        local cursor_moved_count = count_autocmds(autocmds, "CursorMoved", buffer)
        local insert_enter_count = count_autocmds(autocmds, "InsertEnter", buffer)
        local buf_leave_count = count_autocmds(autocmds, "BufLeave", buffer)

        precognition.peek()
        autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(cursor_moved_count + 1, count_autocmds(autocmds, "CursorMoved", buffer))
        eq(insert_enter_count + 1, count_autocmds(autocmds, "InsertEnter", buffer))
        eq(buf_leave_count + 1, count_autocmds(autocmds, "BufLeave", buffer))
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

        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
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
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_input("2"); vim.wait(20)
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_input("w"); vim.wait(20)
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        gutter_extmarks = get_gutter_extmarks(buffer)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
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
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)
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

        vim.api.nvim_input("2"); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_input("w"); vim.wait(20)
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
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

        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)
        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_input("0"); vim.wait(20)
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])
    end)

    it("does not build motion counts while hidden", function()
        precognition.hide()
        precognition.setup({ startVisible = false })
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        vim.api.nvim_input("2"); vim.wait(20)
        vim.api.nvim_input("0"); vim.wait(20)
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "a b c d e f g h i j k l m n o p q r s t u v" })
        vim.api.nvim_win_set_cursor(0, { 1, 1 })
        precognition.show()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("b w                                       $", extmarks[3].virt_lines[1][1][1])
    end)

    it("builds multi-digit motion counts while visible", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        vim.api.nvim_input("2"); vim.wait(20)
        vim.api.nvim_input("0"); vim.wait(20)
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "a b c d e f g h i j k l m n o p q r s t u v" })
        vim.api.nvim_win_set_cursor(0, { 1, 1 })
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" }); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
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

        vim.api.nvim_input("2"); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])
    end)

    it("uses typed motion counts in blockwise visual mode", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "\22" }
        end)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Hello World this is a test" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        vim.api.nvim_input("2"); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("^              e w       $", extmarks[3].virt_lines[1][1][1])
    end)

    it("suppresses only counted hints for counts above 100", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        vim.api.nvim_input("1"); vim.wait(20)
        vim.api.nvim_input("0"); vim.wait(20)
        vim.api.nvim_input("1"); vim.wait(20)

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, vim.api.nvim_create_namespace("precognition"), (vim.api.nvim_buf_get_extmarks(buffer, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1], {
            details = true,
        })
        eq("^                        $", extmarks[3].virt_lines[1][1][1])
        eq(3, #get_gutter_extmarks(buffer))
    end)

end)
