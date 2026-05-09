local server = require("tests.precognition.utils.lsp").server
local compat = require("tests.precognition.utils.compat")
local utils = require("precognition.utils")
local precognition = require("precognition")
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()
local buf

local function wait(condition, msg)
    vim.wait(100, condition)
    local result = condition()
    neq(false, result, { fail_reason = msg })
    neq(nil, result, { fail_reason = msg })
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
        pcall(precognition.hide)
        precognition.setup({})
        require("tests.precognition.utils.lsp").Reset()
        buf = vim.api.nvim_create_buf(true, false)
        vim.lsp.start({ cmd = server }, { bufnr = buf })
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
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua([[
            local precognition = require("precognition")
            local lsp = require("tests.precognition.utils.lsp")
            lsp.Reset()
            precognition.setup({})
            local buf = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "here is a string" })
            vim.lsp.start({ cmd = lsp.server }, { bufnr = buf })
            vim.api.nvim_win_set_cursor(0, { 1, 1 })
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            precognition.on_cursor_moved()
        ]])
        ss(child.get_screenshot())
    end)

    after_each(function()
        if child.is_running() then
            child.stop()
        end
        vim.lsp.inlay_hint.enable(false, { bufnr = buf })
        vim.api.nvim_buf_delete(buf, { force = true })
        for _, client in ipairs(compat.get_active_lsp_clients()) do
            client:stop()
        end
        wait(function()
            return vim.tbl_count(compat.get_active_lsp_clients()) == 0
        end, "clients must stop")
    end)
end)
