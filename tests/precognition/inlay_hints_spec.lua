local server = require("tests.precognition.utils.lsp").server
local compat = require("tests.precognition.utils.compat")
local utils = require("precognition.utils")
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

describe("inlay hint utils", function()
    it("calculates lua style inlay hints", function()
        local length, wsoffset = utils.calc_ws_offset({
            bufnr = 1,
            client_id = 1,
            inlay_hint = {
                kind = 2,
                label = {
                    {
                        location = {
                            range = {
                                ["end"] = {
                                    character = 24,
                                    line = 9,
                                },
                                start = {
                                    character = 17,
                                    line = 9,
                                },
                            },
                            uri = "file:///home/tris/.local/share/nvim/mason/packages/lua-language-server/libexec/meta/LuaJIT%20en-us%20utf8/package.lua",
                        },
                        value = "modname:",
                    },
                },
                paddingLeft = false,
                paddingRight = true,
                position = {
                    character = 23,
                    line = 0,
                },
            },
        }, 2, [[local compat = require("precognition.compat")]])

        eq(9, length)
        eq(23, wsoffset)
    end)

    it("calculates rust style inlay hints", function()
        local length, wsoffset = utils.calc_ws_offset({
            bufnr = 1,
            client_id = 1,
            inlay_hint = {
                data = {
                    file_id = 0,
                },
                kind = 1,
                label = {
                    {
                        value = ": ",
                    },
                    {
                        location = {
                            range = {
                                ["end"] = {
                                    character = 17,
                                    line = 364,
                                },
                                start = {
                                    character = 11,
                                    line = 364,
                                },
                            },
                            uri = "file:///home/tris/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library/alloc/src/string.rs",
                        },
                        value = "String",
                    },
                    {
                        value = "",
                    },
                },
                paddingLeft = false,
                paddingRight = false,
                position = {
                    character = 16,
                    line = 7,
                },
            },
        }, 2, [[        let body = res.text().await?;]])

        eq(8, length)
        eq(16, wsoffset)
    end)
end)

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
