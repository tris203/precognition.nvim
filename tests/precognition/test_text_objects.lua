local precognition = require("precognition")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()
local original_get_mode = vim.api.nvim_get_mode

local function restart_child()
    child.restart({ "-u", "scripts/minimal_init.lua" })
end

local function text_object_extmark()
    local ns = vim.api.nvim_create_namespace("precognition")
    local first = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})[1]
    if not first then
        return nil
    end
    return vim.api.nvim_buf_get_extmark_by_id(0, ns, first[1], {
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

    it("switches from motion hints to inside text object hints", function()
        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)

        local extmark = text_object_extmark()
        eq('    ({       "    w" })', virt_line_text(extmark))
    end)

    it("uses visual mode i as a text object prefix", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "v" }
        end)

        vim.api.nvim_input("i")
        vim.wait(20)
        local ok = vim.wait(150, function()
            if
                not (
                    vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {}
                )[1]
            then
                return false
            end
            return virt_line_text(text_object_extmark()) == '    ({       "    w" })'
        end)
        eq(true, ok)

        local extmark = text_object_extmark()
        eq('    ({       "    w" })', virt_line_text(extmark))
    end)

    it("does not move the visual anchor when pressing v then i from normal mode", function()
        rawset(vim.api, "nvim_get_mode", original_get_mode)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
        vim.api.nvim_win_set_cursor(0, { 3, 1 })

        vim.api.nvim_feedkeys("vi", "nx", true)
        local waited = vim.wait(150, function()
            return (vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_create_namespace("precognition"), 0, -1, {})[1] or {})[1]
                    ~= nil
                and text_object_extmark()[3].virt_lines ~= nil
        end)
        eq(true, waited)

        eq(3, vim.fn.getpos("v")[2])
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true)
    end)

    it("does not clear motion hints when entering visual mode", function()
        local before = virt_line_text(text_object_extmark())

        vim.api.nvim_input("v")
        vim.wait(20)

        eq(before, virt_line_text(text_object_extmark()))
    end)

    it("pads text object hint chunks to the full text area", function()
        precognition.setup({ highlightFullVirtLine = true })
        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)

        local extmark = text_object_extmark()
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())
        local textoff = win_info and win_info[1] and win_info[1].textoff or 0
        local min_width = vim.api.nvim_win_get_width(0) - textoff

        eq(min_width, vim.fn.strdisplaywidth(virt_line_text(extmark)))
    end)

    it("uses operator-pending mode to complete a text object prefix", function()
        vim.api.nvim_input("d")
        vim.wait(20)
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "no" }
        end)

        vim.api.nvim_input("i")
        vim.wait(20)

        local extmark = text_object_extmark()
        eq('    ({       "    w" })', virt_line_text(extmark))
    end)

    it("shows forward spatial hints when the cursor is outside nesting", function()
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)

        local extmark = text_object_extmark()
        eq('   w({       "     " })', virt_line_text(extmark))

        local groups = {}
        for _, chunk in ipairs(extmark[3].virt_lines[1]) do
            groups[chunk[2]] = true
        end
        eq(true, groups.PrecognitionTextObjectRange1)
        eq(true, groups.PrecognitionTextObjectRange2)
        eq(true, groups.PrecognitionTextObjectRange3)
    end)

    it("renders stacked same-line range previews on the virtual line", function()
        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)

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

        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)

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
            vim.api.nvim_input("d")
            vim.wait(20)
            vim.api.nvim_input("i")
            vim.wait(20)

            eq('      ({       "    w" })', virt_line_text(text_object_extmark()))
        end)
        vim.lsp.inlay_hint.is_enabled = original_is_enabled
        vim.lsp.inlay_hint.get = original_get
        if not ok then
            error(err)
        end
    end)

    it("clears the text object prefix after cursor movement", function()
        vim.api.nvim_input("d")
        vim.wait(20)
        vim.api.nvim_input("i")
        vim.wait(20)
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        vim.wait(20)

        eq("^    % b   w          $", virt_line_text(text_object_extmark()))
    end)

    it("clears visual text object hints after the selection moves the cursor", function()
        rawset(vim.api, "nvim_get_mode", function()
            return { mode = "v" }
        end)

        vim.api.nvim_input("i")
        vim.wait(20)

        vim.api.nvim_win_set_cursor(0, { 1, 10 })
        vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        vim.wait(20)
        local ok = vim.wait(150, function()
            return virt_line_text(text_object_extmark()) == "^    % b   w          $"
        end)
        eq(true, ok)

        eq("^    % b   w          $", virt_line_text(text_object_extmark()))
    end)
end)
