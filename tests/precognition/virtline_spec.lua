local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same
describe("Build Virtual Line", function()
    it("can build a simple virtual line", function()
        ---@type Precognition.VirtLine
        local marks = {
            ["^"] = 4,
            ["$"] = 10,
        }
        local virtual_line = precognition.build_virt_line(marks, 10)
        eq("   ^     $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a virtual line with a single mark", function()
        ---@type Precognition.VirtLine
        local marks = {
            ["^"] = 4,
        }
        local virtual_line = precognition.build_virt_line(marks, 10)
        eq("   ^      ", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a virtual line with a single mark at the end", function()
        ---@type Precognition.VirtLine
        local marks = {
            ["$"] = 10,
        }
        local virtual_line = precognition.build_virt_line(marks, 10)
        eq("         $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it(
        "can build a virtual line with a single mark at the beginning",
        function()
            ---@type Precognition.VirtLine
            local marks = {
                ["^"] = 1,
            }
            local virtual_line = precognition.build_virt_line(marks, 10)
            eq("^         ", virtual_line[1][1])
            eq(10, #virtual_line[1][1])
        end
    )

    it("can build a complex virtual line", function()
        ---@type Precognition.VirtLine
        local marks = {
            ["^"] = 1,
            ["b"] = 4,
            ["w"] = 10,
            ["$"] = 50,
        }
        local virtual_line = precognition.build_virt_line(marks, 50)
        local line_num = 1
        for char in virtual_line[1][1]:gmatch(".") do
            if line_num == 1 then
                eq("^", char)
            elseif line_num == 4 then
                eq("b", char)
            elseif line_num == 10 then
                eq("w", char)
            elseif line_num == 50 then
                eq("$", char)
            else
                eq(" ", char)
            end
            line_num = line_num + 1
        end
        eq(50, #virtual_line[1][1])
    end)

    it("example virtual line", function()
        local line = "abcdef ghijkl mnopqr stuvwx yz"
        local cursorcol = 2
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth
            or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)

        local virt_line = precognition.build_virt_line({
            ["w"] = precognition.next_word_boundary(cur_line, cursorcol),
            ["e"] = precognition.end_of_word(cur_line, cursorcol),
            ["b"] = precognition.prev_word_boundary(cur_line, cursorcol),
            ["^"] = cur_line:find("%S") or 0,
            ["$"] = line_len,
        }, line_len)

        eq("^    e w                     $", virt_line[1][1])
        eq(#line, #virt_line[1][1])
    end)

    it("example virtual line with whitespace padding", function()
        local line = "    abc def"
        -- abc def
        local cursorcol = 5
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth
            or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)

        local virt_line = precognition.build_virt_line({
            ["w"] = precognition.next_word_boundary(cur_line, cursorcol),
            ["e"] = precognition.end_of_word(cur_line, cursorcol),
            ["b"] = precognition.prev_word_boundary(cur_line, cursorcol),
            ["^"] = cur_line:find("%S") or 0,
            ["$"] = line_len,
        }, line_len)

        eq("    ^ e w $", virt_line[1][1])
        eq(#line, #virt_line[1][1])
    end)
end)
