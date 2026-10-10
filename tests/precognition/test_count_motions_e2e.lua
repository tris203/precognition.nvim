local precognition = require("precognition")
local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()
local test_utils = require("tests.precognition.utils.utils")

local hello_line = "Hello World this is a test"

---@param lines string[]
---@param cursor integer[]
---@param opts? table
local function start_child(lines, cursor, opts)
    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.lua_func(function(buf_lines, pos, setup_opts)
        require("precognition").setup(
            vim.tbl_extend("force", { targetedMotionHints = { enabled = false } }, setup_opts)
        )
        vim.api.nvim_buf_set_lines(0, 0, -1, false, buf_lines)
        vim.api.nvim_win_set_cursor(0, pos)
    end, lines, cursor, opts or {})
end

---@param cursor? integer[]
local function cursor_moved(cursor)
    child.lua_func(function(pos)
        if pos then
            vim.api.nvim_win_set_cursor(0, pos)
        end
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        vim.wait(150)
    end, cursor)
end

---@return { row: integer?, virt_line: string?, gutter: table<string, integer> }
local function hints()
    return child.lua_func(function()
        local ns = vim.api.nvim_create_namespace("precognition")
        local extmark = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })[1]
        local gutter = {}
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
            local details = mark[4] or {}
            if details.sign_name and details.sign_name:match("precognition_gutter") then
                gutter[details.sign_text] = mark[2]
            end
        end
        return {
            row = extmark and extmark[2],
            virt_line = extmark and extmark[4].virt_lines and extmark[4].virt_lines[1][1][1],
            gutter = gutter,
        }
    end)
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
        precognition.setup({ targetedMotionHints = { enabled = false } })
    end)

    after_each(function()
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
        start_child({ hello_line, "line 2", "", "line 4", "", "line 6" }, { 1, 1 })
        cursor_moved()

        local shown = hints()
        eq(0, shown.row)
        eq("b   e w                  $", shown.virt_line)
        eq({ ["G "] = 5, ["gg"] = 0, ["} "] = 2 }, shown.gutter)

        cursor_moved({ 1, 6 })
        shown = hints()
        eq(0, shown.row)
        eq("b         e w            $", shown.virt_line)

        test_utils.observe_keys(child, "2")
        shown = hints()
        eq(0, shown.row)
        eq("^              e w       $", shown.virt_line)

        test_utils.observe_keys(child, "w")
        cursor_moved()
        shown = hints()
        eq(0, shown.row)
        eq("b         e w            $", shown.virt_line)

        cursor_moved({ 2, 1 })
        shown = hints()
        eq(1, shown.row)
        eq("b  e w", shown.virt_line)
        eq({ ["G "] = 5, ["gg"] = 0, ["} "] = 2 }, shown.gutter)

        cursor_moved({ 4, 1 })
        eq({ ["G "] = 5, ["gg"] = 0, ["{ "] = 2, ["} "] = 4 }, hints().gutter)
    end)

    it("updates counted hints from typed input", function()
        start_child({ hello_line }, { 1, 6 })

        test_utils.observe_keys(child, "2")
        eq("^              e w       $", hints().virt_line)

        test_utils.observe_keys(child, "w")
        cursor_moved()
        eq("b         e w            $", hints().virt_line)
    end)

    it("screenshots counted hints from typed input", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({ targetedMotionHints = { enabled = false } })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World this is a test" })
            vim.api.nvim_win_set_cursor(0, { 1, 6 })
        end)
        test_utils.observe_keys(child, "2")
        ss(child.get_screenshot({ redraw = false }))
    end)

    it("screenshots pending f target characters", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab cab!a" })
            vim.api.nvim_win_set_cursor(0, { 1, 3 })
        end)
        test_utils.observe_keys(child, "f")

        ss(child.get_screenshot({ redraw = false }))
    end)

    it("screenshots counted pending f target characters", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "abacad" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end)
        test_utils.observe_keys(child, "2f")

        ss(child.get_screenshot({ redraw = false }))
    end)

    it("does not treat leading zero as a motion count", function()
        start_child({ hello_line }, { 1, 6 })
        cursor_moved()
        eq("b         e w            $", hints().virt_line)

        test_utils.observe_keys(child, "0")
        eq("b         e w            $", hints().virt_line)
    end)

    it("does not build motion counts while hidden", function()
        start_child({ "a b c d e f g h i j k l m n o p q r s t u v" }, { 1, 1 }, { startVisible = false })

        test_utils.observe_keys(child, "20")
        child.lua_func(function()
            require("precognition").show()
        end)

        eq("b w                                       $", hints().virt_line)
    end)

    it("builds multi-digit motion counts while visible", function()
        start_child({ "a b c d e f g h i j k l m n o p q r s t u v" }, { 1, 1 })

        test_utils.observe_keys(child, "20")

        eq("^                                       w $", hints().virt_line)
    end)

    it("uses typed motion counts in visual mode", function()
        start_child({ hello_line }, { 1, 6 })
        child.type_keys("v")

        test_utils.observe_keys(child, "2")

        eq("^              e w       $", hints().virt_line)
    end)

    it("uses typed motion counts in blockwise visual mode", function()
        start_child({ hello_line }, { 1, 6 })
        child.type_keys("<C-v>")

        test_utils.observe_keys(child, "2")

        eq("^              e w       $", hints().virt_line)
    end)

    it("clears hints for counts above 100", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({
                showBlankVirtLine = false,
                targetedMotionHints = { enabled = false },
                hints = {
                    Caret = { prio = 0 },
                    Dollar = { prio = 0 },
                    MatchingPair = { prio = 0 },
                    Zero = { prio = 0 },
                    b = { prio = 0 },
                    e = { prio = 0 },
                    w = { prio = 0 },
                },
                gutterHints = {
                    G = { prio = 0 },
                    NextParagraph = { prio = 0 },
                    PrevParagraph = { prio = 0 },
                    gg = { prio = 0 },
                },
            })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World this is a test", "line 2" })
            vim.api.nvim_win_set_cursor(0, { 1, 6 })
        end)
        test_utils.observe_keys(child, "101")
        ss(child.get_screenshot())
    end)

    it("ignores operator-pending counts", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            local precognition = require("precognition")
            rawset(vim.api, "nvim_get_mode", function()
                return { mode = "no" }
            end)
            precognition.setup({ targetedMotionHints = { enabled = false } })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Hello World this is a test" })
            vim.api.nvim_win_set_cursor(0, { 1, 6 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
    end)
end)
