local precognition = require("precognition")
local motions = require("precognition.motions").get_motions()
local dts = require("tests.precognition.utils.dts")

local USAGE = [[
Runs dts testing for precognition marks

USAGE:
nvim -u tests/minimal.lua -l tests/precognition/dts.lua SEED_START NUM_SIMS

]]

local M = {}

function M.test(seed)
    local data = dts.generate_random_line(seed)

    --TODO: Currently bracket matching only works with M cpoptions
    --see  `:h %`
    vim.o.cpoptions = vim.o.cpoptions .. "M"

    local cur_line = data.line
    local cursorcol = data.cursor_col
    local line_len = vim.fn.strcharlen(cur_line)

    local virtual_line_marks = {
        Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
        w = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
        e = motions.end_of_word(cur_line, cursorcol, line_len, false),
        b = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
        W = motions.next_word_boundary(cur_line, cursorcol, line_len, true),
        E = motions.end_of_word(cur_line, cursorcol, line_len, true),
        B = motions.prev_word_boundary(cur_line, cursorcol, line_len, true),
        -- TODO: fix some edge cases around pairs and we can enable this
        -- MatchingPair = hm.matching_pair(cur_line, cursorcol, line_len)(cur_line, cursorcol, line_len),
        Dollar = motions.line_end(cur_line, cursorcol, line_len),
        Zero = 1,
    }

    local temp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, { cur_line })

    for loc, col in pairs(virtual_line_marks) do
        local key = precognition.default_hint_config[loc].text
        vim.api.nvim_set_current_buf(temp_buf)
        vim.fn.setcursorcharpos(1, cursorcol)
        local cur_before = vim.fn.getcursorcharpos(0)
        vim.api.nvim_feedkeys(key, "ntx", true)
        local cur_after = vim.fn.getcursorcharpos(0)
        local actual_col = cur_after[3]
        if col ~= 0 then
            if col ~= actual_col then
                vim.print(string.format("[SEED: %d]%s", seed, cur_line))
                vim.print(
                    string.format("with cursor at %s, motion %s, expected %s, got %s", cursorcol, key, col, actual_col)
                )
                vim.print(
                    string.format(
                        "before: %s, input %s, after: %s",
                        vim.inspect(cur_before),
                        key,
                        vim.inspect(cur_after)
                    )
                )
                vim.print(vim.inspect(virtual_line_marks))
                os.exit(1)
            end
        end
    end
    if seed % 10000 == 0 then
        vim.print(string.format("[SEED: %d]", seed))
    end
    vim.api.nvim_buf_delete(temp_buf, { force = true })
end

local seed_start = tonumber(_G.arg[1])
local num_sims = tonumber(_G.arg[2])

if (not num_sims or type(num_sims) ~= "number") or (not seed_start or type(seed_start) ~= "number") then
    print(USAGE)
else
    local seed = seed_start
    local seed_end = seed_start + num_sims
    while seed <= seed_end do
        M.test(seed)
        seed = seed + 1
    end
end

return M
