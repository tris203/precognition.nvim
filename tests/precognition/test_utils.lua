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

        before_each(function()
            bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "alpha beta gamma" })
        end)

        after_each(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end)

        local function add_extmark(col, virt_text, virt_text_pos)
            local ns = vim.api.nvim_create_namespace("test_inline_virtual_indent")
            vim.api.nvim_buf_set_extmark(bufnr, ns, 0, col, {
                virt_text = virt_text,
                virt_text_pos = virt_text_pos or "inline",
            })
        end

        it("is zero without virtual text", function()
            eq(0, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("measures leading inline virtual text", function()
            add_extmark(0, { { "     ", "Comment" } })
            eq(5, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("sums multiple leading chunks", function()
            add_extmark(0, { { "  ", "Comment" }, { "   ", "Comment" } })
            eq(5, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("measures the display width of wide leading text", function()
            add_extmark(0, { { "界界", "Comment" } })
            eq(4, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("measures a tab in leading text as the single cell it is drawn in", function()
            add_extmark(0, { { "  ", "Comment" }, { "\t", "Comment" } })
            eq(3, utils.get_inline_virtual_indent(bufnr, 1))

            vim.api.nvim_win_set_buf(0, bufnr)
            eq(vim.fn.virtcol({ 1, 1 }, 1)[2] - 1, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("ignores virtual text that is not inline", function()
            add_extmark(0, { { "     ", "Comment" } }, "eol")
            eq(0, utils.get_inline_virtual_indent(bufnr, 1))
        end)

        it("ignores inline virtual text after the line origin", function()
            add_extmark(6, { { "     ", "Comment" } })
            eq(0, utils.get_inline_virtual_indent(bufnr, 1))
        end)
    end)
end)
