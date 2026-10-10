local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

describe("utils", function()
    it("debounces repeated calls with the latest arguments", function()
        local result
        local debounced = require("precognition.utils").debounce_trailing(function(value)
            result = value
        end, 100)

        debounced("first")
        debounced("second")

        local ok = vim.wait(500, function()
            return result == "second"
        end)

        neq(false, ok)
        eq("second", result)
    end)

    describe("get_inline_virtual_indent", function()
        local utils = require("precognition.utils")
        local bufnr
        local winid

        before_each(function()
            bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "alpha beta gamma" })
            vim.api.nvim_win_set_buf(0, bufnr)
            winid = vim.api.nvim_get_current_win()
        end)

        after_each(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end)

        local function add_extmark(col, virt_text, virt_text_pos, opts)
            local ns = vim.api.nvim_create_namespace("test_inline_virtual_indent")
            vim.api.nvim_buf_set_extmark(
                bufnr,
                ns,
                0,
                col,
                vim.tbl_extend("force", {
                    virt_text = virt_text,
                    virt_text_pos = virt_text_pos or "inline",
                }, opts or {})
            )
        end

        it("is zero without virtual text", function()
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("measures leading inline virtual text", function()
            add_extmark(0, { { "     ", "Comment" } })
            eq(5, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("sums multiple leading chunks", function()
            add_extmark(0, { { "  ", "Comment" }, { "   ", "Comment" } })
            eq(5, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("measures the display width of wide leading text", function()
            add_extmark(0, { { "界界", "Comment" } })
            eq(4, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("measures a tab in leading text as the single cell it is drawn in", function()
            add_extmark(0, { { "  ", "Comment" }, { "\t", "Comment" } })
            eq(3, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("measures leading inline virtual text under virtualedit", function()
            vim.wo[winid].virtualedit = "all"
            add_extmark(0, { { "   ", "Comment" } })
            local width = utils.get_inline_virtual_indent(winid, 1)
            vim.wo[winid].virtualedit = ""
            eq(3, width)
        end)

        it("measures leading inline virtual text before a lone character", function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "界" })
            add_extmark(0, { { "   ", "Comment" } })
            eq(3, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("measures leading inline virtual text before a composed character", function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "a\204\129lpha" })
            add_extmark(0, { { "   ", "Comment" } })
            eq(3, utils.get_inline_virtual_indent(winid, 1))

            vim.wo[winid].virtualedit = "all"
            local width = utils.get_inline_virtual_indent(winid, 1)
            vim.wo[winid].virtualedit = ""
            eq(3, width)
        end)

        it("is zero on an empty line", function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
            add_extmark(0, { { "   ", "Comment" } })
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("ignores leading text absorbed by a leading tab", function()
            vim.bo[bufnr].tabstop = 8
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "\talpha" })
            add_extmark(0, { { "   ", "Comment" } })
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("ignores leading text hidden by an invalidated extmark", function()
            add_extmark(0, { { "   ", "Comment" } }, "inline", { end_col = 5, invalidate = true })
            vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 5, { "" })
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("ignores virtual text that is not inline", function()
            add_extmark(0, { { "     ", "Comment" } }, "eol")
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)

        it("ignores inline virtual text after the line origin", function()
            add_extmark(6, { { "     ", "Comment" } })
            eq(0, utils.get_inline_virtual_indent(winid, 1))
        end)
    end)
end)
