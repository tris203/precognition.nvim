local precognition = require("precognition")
local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()
local original_get_mode = vim.api.nvim_get_mode
local test_utils = require("tests.precognition.utils.utils")

local function text_object_extmark()
    local ns = vim.api.nvim_create_namespace("precognition")
    local first = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})[1]
    if not first or not first[1] then
        return nil
    end
    return vim.api.nvim_buf_get_extmark_by_id(0, ns, first[1], {
        details = true,
    })
end

---@param opts? table
---@param cursor? integer[]
local function start_child(opts, cursor)
    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.lua_func(function(setup_opts, pos)
        require("precognition").setup(setup_opts)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call({ key = "value" })' })
        vim.api.nvim_win_set_cursor(0, pos)
    end, opts or {}, cursor or { 1, 15 })
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

---@return { text: string?, groups: table<string, boolean> }
local function hints()
    return child.lua_func(function()
        local ns = vim.api.nvim_create_namespace("precognition")
        local extmark = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })[1]
        local virt_line = extmark and extmark[4].virt_lines and extmark[4].virt_lines[1]
        if not virt_line then
            return { groups = {} }
        end

        local text, groups = "", {}
        for _, chunk in ipairs(virt_line) do
            text = text .. chunk[1]
            if type(chunk[2]) == "string" then
                groups[chunk[2]] = true
            end
        end
        return { text = text, groups = groups }
    end)
end

describe("text object hints", function()
    before_each(function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "n" }
        end)
        pcall(precognition.hide)
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        precognition.setup({})
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call({ key = "value" })' })
        vim.api.nvim_win_set_cursor(0, { 1, 15 })
    end)

    after_each(function()
        rawset(vim.api, "nvim_get_mode", original_get_mode)
        pcall(precognition.hide)
        if child.is_running() then
            child.stop()
        end
    end)

    it("switches from motion hints to inside text object hints", function()
        start_child()

        test_utils.observe_keys(child, "di")

        eq('    ({       "    w" })', hints().text)
    end)

    it("uses visual mode i as a text object prefix", function()
        start_child()
        child.type_keys("v")

        test_utils.observe_keys(child, "i")

        eq('    ({       "    w" })', hints().text)
    end)

    it("does not move the visual anchor when pressing v then i from normal mode", function()
        rawset(vim.api, "nvim_get_mode", original_get_mode)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
        vim.api.nvim_win_set_cursor(0, { 3, 1 })

        vim.api.nvim_feedkeys("vi", "nx", true)
        local waited = vim.wait(150, function()
            local extmarks = vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_create_namespace("precognition"), 0, -1, {})
            local has_extmark = (extmarks[1] or {})[1] ~= nil
            local extmark = text_object_extmark()
            local has_virt_lines = extmark and extmark[3].virt_lines ~= nil
            return has_extmark and has_virt_lines or false
        end)
        eq(true, waited)

        eq(3, vim.fn.getpos("v")[2])
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true)
    end)

    it("does not clear motion hints when entering visual mode", function()
        start_child()
        cursor_moved()
        local before = hints().text
        eq("^FTFF%TFFFTFTBb ffewtW$", before)

        child.type_keys("v")

        eq(before, hints().text)
    end)

    it("pads text object hint chunks to the full text area", function()
        start_child({ highlightFullVirtLine = true })
        child.lua_func(function()
            -- Keep the text area fixed when text object hints clear the gutter signs.
            vim.wo.signcolumn = "yes"
            vim.cmd("redraw")
        end)

        test_utils.observe_keys(child, "di")

        local min_width = child.lua_func(function()
            local win_info = vim.fn.getwininfo(vim.fn.win_getid())
            local textoff = win_info and win_info[1] and win_info[1].textoff or 0
            return vim.api.nvim_win_get_width(0) - textoff
        end)
        eq(min_width, vim.fn.strdisplaywidth(hints().text))
    end)

    it("uses operator-pending mode to complete a text object prefix", function()
        start_child()
        child.type_keys("d")
        eq("no", child.fn.mode(1))

        test_utils.observe_keys(child, "i")

        eq('    ({       "    w" })', hints().text)
    end)

    it("shows forward spatial hints when the cursor is outside nesting", function()
        start_child(nil, { 1, 1 })

        test_utils.observe_keys(child, "di")

        local shown = hints()
        eq('   w({       "     " })', shown.text)
        eq(true, shown.groups.PrecognitionTextObjectRange1)
        eq(true, shown.groups.PrecognitionTextObjectRange2)
        eq(true, shown.groups.PrecognitionTextObjectRange3)
    end)

    it("renders stacked same-line range previews on the virtual line", function()
        start_child()

        test_utils.observe_keys(child, "di")

        local shown = hints()
        eq('    ({       "    w" })', shown.text)
        eq(true, shown.groups.PrecognitionTextObjectRange1)
        eq(true, shown.groups.PrecognitionTextObjectRange2)
        eq(true, shown.groups.PrecognitionTextObjectRange3)
    end)

    it("screenshots inside text object hints with stacked ranges", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call({ key = "value" })' })
            vim.api.nvim_win_set_cursor(0, { 1, 15 })
        end)
        test_utils.observe_keys(child, "di")

        ss(child.get_screenshot({ redraw = false }))
    end)

    it("screenshots around text object hints with stacked ranges", function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua_func(function()
            require("precognition").setup({})
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call({ key = "value" })' })
            vim.api.nvim_win_set_cursor(0, { 1, 15 })
        end)
        test_utils.observe_keys(child, "da")

        ss(child.get_screenshot({ redraw = false }))
    end)

    it("customises text object range highlights", function()
        precognition.setup({
            textObjectHighlightColors = {
                { link = "Search" },
                { link = "IncSearch" },
                { foreground = "#ff0000", background = "#00ff00" },
            },
        })

        eq("Search", vim.api.nvim_get_hl(0, { name = "PrecognitionTextObjectRange1", link = true }).link)
        eq("IncSearch", vim.api.nvim_get_hl(0, { name = "PrecognitionTextObjectRange2", link = true }).link)

        local range3 = vim.api.nvim_get_hl(0, { name = "PrecognitionTextObjectRange3", link = false })
        eq(0xff0000, range3.fg)
        eq(0x00ff00, range3.bg)
    end)

    it("only uses configured text object range highlights", function()
        start_child({ textObjectHighlightColors = { { link = "Search" } } })

        test_utils.observe_keys(child, "di")

        local shown = hints()
        eq('    ({       "    w" })', shown.text)
        eq(true, shown.groups.PrecognitionTextObjectRange1)
        eq(nil, shown.groups.PrecognitionTextObjectRange2)
        eq(nil, shown.groups.PrecognitionTextObjectRange3)
    end)

    it("accounts for inlay hint padding in text object hints", function()
        start_child()
        child.lua_func(function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.lsp.inlay_hint.is_enabled = function()
                return true
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.lsp.inlay_hint.get = function()
                return {
                    {
                        inlay_hint = {
                            label = "xx",
                            paddingLeft = false,
                            paddingRight = false,
                            position = { character = 4 },
                        },
                    },
                }
            end
        end)

        test_utils.observe_keys(child, "di")

        eq('      ({       "    w" })', hints().text)
    end)

    it("clears the text object prefix after cursor movement", function()
        start_child()
        test_utils.observe_keys(child, "di")
        eq('    ({       "    w" })', hints().text)

        cursor_moved()

        eq("^FTFF%TFFFTFTBb ffewtW$", hints().text)
    end)

    it("clears visual text object hints after the selection moves the cursor", function()
        start_child()
        child.type_keys("v")
        test_utils.observe_keys(child, "i")
        eq('    ({       "    w" })', hints().text)

        cursor_moved({ 1, 10 })

        eq("^FTFF%TbFF wtffffff tf$", hints().text)
    end)
end)
