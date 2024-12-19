local precognition = require("precognition")
local dts = require("tests.precognition.utils.dts")

local USAGE = [[
Runs dts testing for precognition marks

USAGE:
nvim -u tests/minimal.lua -l tests/precognition/dts.lua SEED_START NUM_SIMS

]]

local M = {}

function M.test(seed)
    local data = dts.generate_random_line(seed)

    local cur_line = data.line
    local cursorcol = data.cursor_col

    ---@type Precognition.VirtLine
    local virtual_line_marks = require("precognition.sim").check(cur_line, cursorcol)
    ---return 0 for any hint that is not found in the simmed table
    setmetatable(virtual_line_marks, {
        __index = function()
            return 0
        end,
    })

    virtual_line_marks.MatchingPair = nil

    local temp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, { cur_line })

    for loc, col in pairs(virtual_line_marks) do
        local key = precognition.default_hint_config[loc].text
        vim.api.nvim_set_current_buf(temp_buf)
        vim.fn.setcursorcharpos(1, cursorcol)
        local cur_before = vim.fn.getcursorcharpos(0)
        vim.api.nvim_feedkeys(key, "x", true)
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
                require("precognition.sim").stop()
                os.exit(1)
            end
        end
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
    local start_time = vim.uv.hrtime()
    while seed <= seed_end do
        M.test(seed)
        if seed % 10000 == 0 then
            vim.print(string.format("[SEED: %d]", seed))
            local cur_time = vim.uv.hrtime()
            local elapsed_seconds = (cur_time - start_time) / 1e9
            local completed = seed - seed_start
            local rate = completed / elapsed_seconds
            local remaining = num_sims - completed
            vim.print(string.format("%d sims remaing (est %d seconds)", remaining, remaining / rate))
        end
        seed = seed + 1
    end
end

return M
