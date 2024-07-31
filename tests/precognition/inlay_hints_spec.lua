local server = require("tests.precognition.utils.lsp").server
local compat = require("tests.precognition.utils.compat")
local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same
---@diagnostic disable-next-line: undefined-field
local neq = assert.are_not.same
local buf

local function wait(condition, msg)
    vim.wait(100, condition)
    local result = condition()
    neq(false, result, msg)
    neq(nil, result, msg)
end

describe("lsp based tests", function()
    before_each(function()
        require("tests.precognition.utils.lsp").Reset()
        buf = vim.api.nvim_create_buf(true, false)
        local srv = vim.lsp.start_client({ cmd = server })
        if srv then
            vim.lsp.buf_attach_client(buf, srv)
        end
    end)

    it("initialize lsp", function()
        eq(2, #require("tests.precognition.utils.lsp").messages)
        eq("initialize", require("tests.precognition.utils.lsp").messages[1].method)
        eq("initialized", require("tests.precognition.utils.lsp").messages[2].method)
    end)

    it("can enable inlay hints", function()
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })

        eq(3, #require("tests.precognition.utils.lsp").messages)
        eq("textDocument/inlayHint", require("tests.precognition.utils.lsp").messages[3].method)
    end)

    it("inlay hint shifts the line", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "here is a string" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buf, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq("b  e w         $", extmarks[3].virt_lines[1][1][1])

        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        -- NOTE:The test LSP replies with an inlay hint, that suggest "foo" as line 1, position 4
        --          This means that the inlay hint is shifted by 3 chars

        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buf, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq("b      e w         $", extmarks[3].virt_lines[1][1][1])
    end)

    after_each(function()
        vim.lsp.inlay_hint.enable(false, { bufnr = buf })
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.lsp.stop_client(compat.get_active_lsp_clients())
        wait(function()
            return vim.tbl_count(compat.get_active_lsp_clients()) == 0
        end, "clients must stop")
    end)
end)
