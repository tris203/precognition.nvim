local precognition = require("precognition")
local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()
local original_get_mode = vim.api.nvim_get_mode

local function restart_child()
    child.restart({ "-u", "scripts/minimal_init.lua" })
end

local function screenshot_text_object_prefix(prefix)
    restart_child()
    child.lua_func(function()
        local precognition = require("precognition")
        precognition.setup({})
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'call({ key = "value" })' })
        vim.api.nvim_win_set_cursor(0, { 1, 15 })
    end)
    for key in prefix:gmatch(".") do
        child.lua(string.format("require('precognition').on_key(%q)", key))
    end
    ss(child.get_screenshot())
end

local function text_object_extmark()
    return vim.api.nvim_buf_get_extmark_by_id(0, precognition.ns, precognition.extmark, {
        details = true,
    })
end

local function virt_line_text(extmark)
    local text = ""
    for _, chunk in ipairs(extmark[3].virt_lines[1]) do
        text = text .. chunk[1]
    end
    return text
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

    it("screenshots inside text object hints with stacked ranges", function()
        screenshot_text_object_prefix("di")
    end)

    it("screenshots around text object hints with stacked ranges", function()
        screenshot_text_object_prefix("da")
    end)

    it("switches from motion hints to inside text object hints", function()
        precognition.on_key("d")
        precognition.on_key("i")

        local extmark = text_object_extmark()
        eq('    ({       " wW  " })', virt_line_text(extmark))
    end)

    it("uses visual mode i as a text object prefix", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "v" }
        end)

        precognition.on_key("i")

        local extmark = text_object_extmark()
        eq('    ({       " wW  " })', virt_line_text(extmark))
    end)

    it("does not clear motion hints when entering visual mode", function()
        local before = virt_line_text(text_object_extmark())

        precognition.on_key("v")

        eq(nil, precognition.pending_command_prefix)
        eq(before, virt_line_text(text_object_extmark()))
    end)

    it("pads text object hint chunks to the full text area", function()
        precognition.setup({ highlightFullVirtLine = true })
        precognition.on_key("d")
        precognition.on_key("i")

        local extmark = text_object_extmark()
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())
        local textoff = win_info and win_info[1] and win_info[1].textoff or 0
        local min_width = vim.api.nvim_win_get_width(0) - textoff

        eq(min_width, vim.fn.strdisplaywidth(virt_line_text(extmark)))
    end)

    it("uses operator-pending mode to complete a text object prefix", function()
        precognition.on_key("d")
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "no" }
        end)

        precognition.on_key("i")

        local extmark = text_object_extmark()
        eq('    ({       " wW  " })', virt_line_text(extmark))
    end)

    it("shows forward spatial hints when the cursor is outside nesting", function()
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_key("d")
        precognition.on_key("i")

        local extmark = text_object_extmark()
        eq(' wW ({       "     " })', virt_line_text(extmark))

        local groups = {}
        for _, chunk in ipairs(extmark[3].virt_lines[1]) do
            groups[chunk[2]] = true
        end
        eq(true, groups.PrecognitionTextObjectRange1)
        eq(true, groups.PrecognitionTextObjectRange2)
        eq(true, groups.PrecognitionTextObjectRange3)
    end)

    it("renders stacked same-line range previews on the virtual line", function()
        precognition.on_key("d")
        precognition.on_key("i")

        local extmark = text_object_extmark()
        local groups = {}
        for _, chunk in ipairs(extmark[3].virt_lines[1]) do
            groups[chunk[2]] = true
        end

        eq(true, groups.PrecognitionTextObjectRange1)
        eq(true, groups.PrecognitionTextObjectRange2)
        eq(true, groups.PrecognitionTextObjectRange3)
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
        precognition.setup({
            textObjectHighlightColors = {
                { link = "Search" },
            },
        })

        precognition.on_key("d")
        precognition.on_key("i")

        local groups = {}
        for _, chunk in ipairs(text_object_extmark()[3].virt_lines[1]) do
            groups[chunk[2]] = true
        end

        eq(true, groups.PrecognitionTextObjectRange1)
        eq(nil, groups.PrecognitionTextObjectRange2)
        eq(nil, groups.PrecognitionTextObjectRange3)
    end)

    it("accounts for inlay hint padding in text object hints", function()
        local original_is_enabled = vim.lsp.inlay_hint.is_enabled
        local original_get = vim.lsp.inlay_hint.get
        vim.lsp.inlay_hint.is_enabled = function()
            return true
        end
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

        local ok, err = pcall(function()
            precognition.on_key("d")
            precognition.on_key("i")

            eq('      ({       " wW  " })', virt_line_text(text_object_extmark()))
        end)
        vim.lsp.inlay_hint.is_enabled = original_is_enabled
        vim.lsp.inlay_hint.get = original_get
        if not ok then
            error(err)
        end
    end)

    it("clears the text object prefix after cursor movement", function()
        precognition.on_key("d")
        precognition.on_key("i")
        eq("di", precognition.pending_command_prefix)

        precognition.on_cursor_moved()

        eq(nil, precognition.pending_command_prefix)
    end)
end)
