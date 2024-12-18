local precognition = require("precognition")
local hm = require("precognition.horizontal_motions")
local dts = require("tests.precognition.utils.dts")

local USAGE = [[
Generates lua-ls annotations for lsp.

USAGE:
nvim -u tests/minimal.lua -l tests/precognition/dts.lua SEED_START
]]

local M = {}

function M.test(seed)
    while true do
        local data = dts.generate_random_line(seed)

        local cur_line = data.line
        local cursorcol = data.cursor_col
        local line_len = vim.fn.strcharlen(cur_line)

        local virtual_line_marks = {
            Caret = hm.line_start_non_whitespace(cur_line, cursorcol, line_len),
            w = hm.next_word_boundary(cur_line, cursorcol, line_len, false),
            e = hm.end_of_word(cur_line, cursorcol, line_len, false),
            b = hm.prev_word_boundary(cur_line, cursorcol, line_len, false),
            W = hm.next_word_boundary(cur_line, cursorcol, line_len, true),
            -- E = hm.end_of_word(cur_line, cursorcol, line_len, true),
            B = hm.prev_word_boundary(cur_line, cursorcol, line_len, true),
            -- MatchingPair = hm.matching_pair(cur_line, cursorcol, line_len)(cur_line, cursorcol, line_len),
            Dollar = hm.line_end(cur_line, cursorcol, line_len),
            Zero = 1,
        }

        local temp_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, { cur_line })

        for loc, col in pairs(virtual_line_marks) do
            local key = precognition.default_hint_config[loc].text
            vim.api.nvim_set_current_buf(temp_buf)
            vim.api.nvim_win_set_cursor(0, { 1, cursorcol - 1 })
            vim.api.nvim_feedkeys(key, "ntx", true)
            local cur = vim.api.nvim_win_get_cursor(0)
            -- eq(cursorcol, 1)
            if col ~= 0 then
                if col ~= cur[2] + 1 then
                    vim.print(string.format("[SEED: %d]%s", seed, cur_line))
                    vim.print(
                        string.format(
                            "with cursor at %s, motion %s, expected %s, got %s",
                            cursorcol,
                            key,
                            col,
                            cur[2] + 1
                        )
                    )
                end
            end
        end
        -- vim.print(string.format("seed: %s, done", seed))
        seed = seed + 1
    end
end

local seed = tonumber(_G.arg[1])

if not seed or type(seed) ~= "number" then
    print(USAGE)
else
    M.test(seed)
end

return M
