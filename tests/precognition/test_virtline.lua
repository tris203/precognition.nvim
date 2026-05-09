local VirtLine = require("precognition.virt_line")
local motions_mod = require("precognition.motions")
local motions
local utils = require("precognition.utils")
local eq = MiniTest.expect.equality
local default_config = require("precognition.defaults").config
local config = vim.deepcopy(default_config)
describe("Build Virtual Line", function()
    before_each(function()
        motions_mod.reset_default()
        motions = motions_mod.get_motions()
        config = vim.deepcopy(default_config)
    end)

    it("can build a simple virtual line", function()
        local marks = {
            Caret = 4,
            Dollar = 10,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("   ^     $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a virtual line with a single mark", function()
        local marks = {
            Caret = 4,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("   ^      ", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a virtual line with a single mark at the end", function()
        local marks = {
            Dollar = 10,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("         $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a virtual line with a single mark at the beginning", function()
        local marks = {
            Caret = 1,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("^         ", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can build a complex virtual line", function()
        ---@type Precognition.VirtLine
        ---@diagnostic disable-next-line: missing-fields
        local marks = {
            Caret = 1,
            e = 6,
            b = 4,
            w = 10,
            Dollar = 50,
        }
        local virtual_line = VirtLine.build(config, marks, 50, {})
        local line_num = 1
        for char in virtual_line[1][1]:gmatch(".") do
            if line_num == 1 then
                eq("^", char)
            elseif line_num == 4 then
                eq("b", char)
            elseif line_num == 6 then
                eq("e", char)
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
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)

        local virt_line = VirtLine.build(config, {
            w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = motions.end_of_word(cur_line, cursorcol, line_len, false),
            b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
            Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
            Dollar = motions.line_end(cur_line, cursorcol, line_len),
        }, line_len, {})

        eq("b    e w                     $", virt_line[1][1])
        eq(#line, #virt_line[1][1])
    end)

    it("example virtual line with whitespace padding", function()
        local line = "    abc def"
        local cursorcol = 5
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)

        local virt_line = VirtLine.build(config, {
            w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = motions.end_of_word(cur_line, cursorcol, line_len, false),
            b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
            Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
            Dollar = motions.line_end(cur_line, cursorcol, line_len),
        }, line_len, {})

        eq("    ^ e w $", virt_line[1][1])
        eq(#line, #virt_line[1][1])
    end)

    it("can build a line with extra padding", function()
        local line = "    abc def"
        local cursorcol = 5
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)
        local extra_padding = { { start = 4, length = 4 } }

        local virt_line = VirtLine.build(config, {
            w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = motions.end_of_word(cur_line, cursorcol, line_len, false),
            b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
            Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
            Dollar = motions.line_end(cur_line, cursorcol, line_len),
        }, line_len, extra_padding)

        local total_added = 0
        for _, pad in ipairs(extra_padding) do
            total_added = total_added + pad.length
        end

        eq("        ^ e w $", virt_line[1][1])
        eq(#line + total_added, #virt_line[1][1])
    end)

    it("can build a line with multiple extra padddings", function()
        local line = "    abc def"
        local cursorcol = 5
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)
        local extra_padding = { { start = 4, length = 4 }, { start = 10, length = 5 } }

        local virt_line = VirtLine.build(config, {
            w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = motions.end_of_word(cur_line, cursorcol, line_len, false),
            b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
            Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
            Dollar = motions.line_end(cur_line, cursorcol, line_len),
        }, line_len, extra_padding)

        local total_added = 0
        for _, pad in ipairs(extra_padding) do
            total_added = total_added + pad.length
        end

        eq("        ^ e w      $", virt_line[1][1])
        eq(#line + total_added, #virt_line[1][1])
    end)

    it("can pad a virtual line to a minimum width", function()
        local marks = {
            Caret = 4,
            Dollar = 10,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {}, 20)
        eq("   ^     $          ", virtual_line[1][1])
        eq(20, #virtual_line[1][1])
    end)

    it("does not truncate a virtual line longer than the minimum width", function()
        local marks = {
            Caret = 4,
            Dollar = 10,
        }
        local virtual_line = VirtLine.build(config, marks, 10, {}, 5)
        eq("   ^     $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("can render a blank virtual line when padding to a minimum width", function()
        local virtual_line = VirtLine.build(config, {}, 5, {}, 12)
        eq("            ", virtual_line[1][1])
        eq(12, #virtual_line[1][1])
    end)

    it("example virtual line with emoji", function()
        local line = "# 💭👀precognition.nvim"
        local cursorcol = 20
        local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
        local cur_line = line:gsub("\t", string.rep(" ", tab_width))
        local line_len = vim.fn.strcharlen(cur_line)
        local extra_padding = {}

        utils.add_multibyte_padding(cur_line, extra_padding, line_len)

        local virt_line = VirtLine.build(config, {
            w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = motions.end_of_word(cur_line, cursorcol, line_len, false),
            b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
            Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
            Dollar = motions.line_end(cur_line, cursorcol, line_len),
        }, line_len, extra_padding)

        eq("^                  b  e", virt_line[1][1])
        eq(vim.fn.strdisplaywidth(line), #virt_line[1][1])
    end)
end)

describe("Wrapped Virtual Line", function()
    it("keeps the first visual row when the cursor is in the first wrap section", function()
        local virtual_line = { { "^        w         e         $", "PrecognitionHighlight" } }

        VirtLine.fit_to_wrap(virtual_line, 8, 10)

        eq("^        w", virtual_line[1][1])
    end)

    it("keeps the cursor's visual row when the cursor is in a later wrap section", function()
        local virtual_line = { { "^        w         e         $", "PrecognitionHighlight" } }

        VirtLine.fit_to_wrap(virtual_line, 12, 10)

        eq("         e", virtual_line[1][1])
    end)

    it("keeps the final visual row when the cursor is in the final wrap section", function()
        local virtual_line = { { "^        w         e         $", "PrecognitionHighlight" } }

        VirtLine.fit_to_wrap(virtual_line, 23, 10)

        eq("         $", virtual_line[1][1])
    end)

    it("does not change short virtual lines", function()
        local virtual_line = { { "^   e w $", "PrecognitionHighlight" } }

        VirtLine.fit_to_wrap(virtual_line, 4, 20)

        eq("^   e w $", virtual_line[1][1])
    end)
end)

describe("Priority", function()
    it("0 priority item is not added", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 0,
                    text = "^",
                },
                Dollar = {
                    prio = 0,
                    text = "$",
                },
            },
        })

        local marks = {
            Caret = 4,
            w = 6,
            Dollar = 10,
        }

        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("     w    ", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("a higher priority mark in the same space takes priority", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 0,
                    text = "^",
                },
                Dollar = {
                    prio = 1,
                    text = "$",
                },
            },
        })

        local marks = {
            Caret = 4,
            w = 6,
            Dollar = 10,
        }

        local virtual_line = VirtLine.build(config, marks, 10, {})
        eq("     w   $", virtual_line[1][1])
        eq(10, #virtual_line[1][1])
    end)

    it("a higher priority mark in the same space takes priority", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 1,
                    text = "^",
                },
                Dollar = {
                    prio = 100,
                    text = "$",
                },
            },
        })

        local marks = {
            Caret = 1,
            Dollar = 1,
        }

        local virtual_line = VirtLine.build(config, marks, 1, {})
        eq("$", virtual_line[1][1])
        eq(1, #virtual_line[1][1])

        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 100,
                    text = "^",
                },
                Dollar = {
                    prio = 1,
                    text = "$",
                },
            },
        })

        virtual_line = VirtLine.build(config, marks, 1, {})
        eq("^", virtual_line[1][1])
        eq(1, #virtual_line[1][1])
    end)
end)

describe("Text object virtual line", function()
    before_each(function()
        config = vim.deepcopy(default_config)
    end)

    it("builds text-object hints with range highlights", function()
        local virtual_line = VirtLine.build_text_object(
            config,
            {
                { label = "i", col = 3, prio = 10 },
                { label = "a", col = 5, prio = 9 },
            },
            7,
            {},
            nil,
            {
                { start_col = 2, end_col = 6, depth = 1 },
            }
        )

        eq({
            { " ", "PrecognitionTextObjectAvailability" },
            { " i a ", "PrecognitionTextObjectRange1" },
            { " ", "PrecognitionTextObjectAvailability" },
        }, virtual_line)
    end)

    it("uses Hint Priority for text-object anchors", function()
        local virtual_line = VirtLine.build_text_object(config, {
            { label = "i", col = 3, prio = 1 },
            { label = "a", col = 3, prio = 10 },
        }, 5, {}, nil, {})

        eq("  a  ", virtual_line[1][1])
    end)

    it("pads text-object hints to a minimum width", function()
        local virtual_line = VirtLine.build_text_object(config, {
            { label = "i", col = 3, prio = 10 },
        }, 5, {}, 8, {})

        eq("  i     ", virtual_line[1][1])
        eq(8, vim.fn.strdisplaywidth(virtual_line[1][1]))
    end)
end)

describe("replacement characters", function()
    it("regular replacement chars", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 100,
                    text = "x",
                },
            },
        })

        local marks = {
            Caret = 1,
        }

        local virtual_line = VirtLine.build(config, marks, 1, {})
        eq("x", virtual_line[1][1])
        eq(1, #virtual_line[1][1])
    end)

    it("extended alphabet chars", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 100,
                    text = "â",
                },
            },
        })

        local marks = {
            Caret = 1,
        }

        local virtual_line = VirtLine.build(config, marks, 1, {})
        eq("â", virtual_line[1][1])
        eq(2, #virtual_line[1][1])
    end)

    it("adjacent alphabet chars", function()
        config = vim.deepcopy(default_config)
        -- hello

        local marks = {
            Zero = 1,
            Caret = 2,
            e = 3,
            w = 5,
            Dollar = 8,
        }

        local virtual_line = VirtLine.build(config, marks, 8, {})
        eq("0^e w  $", virtual_line[1][1])
    end)

    it("adjacent extended chars", function()
        config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), {
            ---@diagnostic disable-next-line: missing-fields
            hints = {
                Caret = {
                    prio = 100,
                    text = "â",
                    -- text = "t",
                },
            },
        })
        -- hello

        local marks = {
            Zero = 1,
            Caret = 2,
            e = 3,
            w = 5,
            Dollar = 8,
        }

        local virtual_line = VirtLine.build(config, marks, 8, {})
        eq("0âe w  $", virtual_line[1][1])
    end)
end)
