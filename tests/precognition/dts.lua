local motions = require("precognition.motions").get_motions()
local dts = require("tests.precognition.utils.dts")
local hint_config = require("precognition.defaults").hints

local MAX_FAILURE_DETAILS = 10
local MAX_REPEAT_CHECKS_PER_SEED = 10

local USAGE = [[
Runs dts testing for precognition marks

USAGE:
nvim -u scripts/minimal_init.lua -l tests/precognition/dts.lua SEED_START NUM_SIMS

]]

local M = {}

local function cursor_position()
    local cur = vim.fn.getcursorcharpos(0)
    return { line = cur[2], col = cur[3] }
end

local function same_position(left, right)
    return left.line == right.line and left.col == right.col
end

local function feed_motion(input)
    vim.cmd({ cmd = "normal", bang = true, args = { input } })
end

local function add_failure(failures, failure)
    table.insert(failures, failure)
end

local function check_cursor_candidate(failures, seed, line, cursorcol, candidate)
    vim.fn.setcursorcharpos(2, cursorcol)
    local before = cursor_position()

    feed_motion(candidate.input)

    local actual = cursor_position()
    local expected = candidate.expected
    if expected.no_destination then
        if not same_position(before, actual) then
            add_failure(failures, {
                kind = candidate.kind,
                seed = seed,
                line = line,
                cursor = cursorcol,
                input = candidate.input,
                source_input = candidate.source_input,
                expected = "no destination",
                actual = actual,
            })
        end
        return false, actual
    end

    if not same_position(expected, actual) then
        add_failure(failures, {
            kind = candidate.kind,
            seed = seed,
            line = line,
            cursor = cursorcol,
            input = candidate.input,
            source_input = candidate.source_input,
            expected = expected,
            actual = actual,
        })
        return false, actual
    end

    return true, actual
end

local function static_cursor_candidates(cur_line, cursorcol, line_len)
    return {
        {
            kind = "cursor",
            loc = "Caret",
            input = hint_config.Caret.text,
            col = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
        },
        {
            kind = "cursor",
            loc = "w",
            input = hint_config.w.text,
            col = motions.next_word_boundary(cur_line, cursorcol, line_len, false),
        },
        {
            kind = "cursor",
            loc = "e",
            input = hint_config.e.text,
            col = motions.end_of_word(cur_line, cursorcol, line_len, false),
        },
        {
            kind = "cursor",
            loc = "b",
            input = hint_config.b.text,
            col = motions.prev_word_boundary(cur_line, cursorcol, line_len, false),
        },
        {
            kind = "cursor",
            loc = "W",
            input = hint_config.W.text,
            col = motions.next_word_boundary(cur_line, cursorcol, line_len, true),
        },
        {
            kind = "cursor",
            loc = "E",
            input = hint_config.E.text,
            col = motions.end_of_word(cur_line, cursorcol, line_len, true),
        },
        {
            kind = "cursor",
            loc = "B",
            input = hint_config.B.text,
            col = motions.prev_word_boundary(cur_line, cursorcol, line_len, true),
        },
        -- TODO: fix some edge cases around pairs and we can enable this
        -- {
        --     kind = "cursor",
        --     loc = "MatchingPair",
        --     input = hint_config.MatchingPair.text,
        --     col = motions.matching_pair(cur_line, cursorcol, line_len)(cur_line, cursorcol, line_len),
        -- },
        {
            kind = "cursor",
            loc = "Dollar",
            input = hint_config.Dollar.text,
            col = motions.line_end(cur_line, cursorcol, line_len),
        },
        {
            kind = "cursor",
            loc = "Zero",
            input = hint_config.Zero.text,
            col = 1,
        },
    }
end

local function targeted_candidates(cur_line, cursorcol, line_len)
    local candidates = {}
    local motion_keys = vim.tbl_keys(motions.targeted_motions or {})
    table.sort(motion_keys)
    for _, motion_key in ipairs(motion_keys) do
        local targeted_motion = motions.targeted_motions[motion_key]
        for _, hint in ipairs(targeted_motion(cur_line, cursorcol, line_len)) do
            table.insert(candidates, {
                kind = "targeted",
                input = motion_key .. hint.label,
                label = hint.label,
                motion_key = motion_key,
                expected = { line = 2, col = hint.col },
            })
        end
    end
    table.sort(candidates, function(left, right)
        if left.input == right.input then
            return left.expected.col < right.expected.col
        end
        return left.input < right.input
    end)
    return candidates
end

local function check_repeat_candidates(
    failures,
    seed,
    line,
    _cursorcol,
    targeted_candidate,
    repeated_from,
    remaining_checks
)
    if not motions.repeat_targeted_motion_hints then
        return 0
    end

    local repeat_hints = motions.repeat_targeted_motion_hints(
        line,
        repeated_from.col,
        vim.fn.strcharlen(line),
        nil,
        vim.fn.getcharsearch()
    )
    local checks = 0
    for _, hint in ipairs(repeat_hints) do
        if checks >= remaining_checks then
            break
        end
        checks = checks + 1
        check_cursor_candidate(failures, seed, line, repeated_from.col, {
            kind = "repeat_targeted",
            input = hint.label,
            expected = { line = 2, col = hint.col },
            source_input = targeted_candidate.input,
        })
    end
    return checks
end

function M.test(seed, failures)
    local data = dts.generate_random_line(seed)

    local cur_line = data.line
    local cursorcol = data.cursor_col
    local line_len = vim.fn.strcharlen(cur_line)

    local temp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, { "", cur_line, "" })
    vim.api.nvim_set_current_buf(temp_buf)

    for _, candidate in ipairs(static_cursor_candidates(cur_line, cursorcol, line_len)) do
        if not hint_config[candidate.loc] then
            error(string.format("missing hint_config entry for loc %s: %s", candidate.loc, vim.inspect(hint_config)))
        end

        if candidate.col ~= 0 then
            candidate.expected = { line = 2, col = candidate.col }
            check_cursor_candidate(failures, seed, cur_line, cursorcol, candidate)
        end
    end

    local repeat_checks = 0
    for _, candidate in ipairs(targeted_candidates(cur_line, cursorcol, line_len)) do
        local ok, actual = check_cursor_candidate(failures, seed, cur_line, cursorcol, candidate)
        if ok and repeat_checks < MAX_REPEAT_CHECKS_PER_SEED then
            repeat_checks = repeat_checks
                + check_repeat_candidates(
                    failures,
                    seed,
                    cur_line,
                    cursorcol,
                    candidate,
                    actual,
                    MAX_REPEAT_CHECKS_PER_SEED - repeat_checks
                )
        end
    end

    vim.api.nvim_buf_delete(temp_buf, { force = true })
end

local function failure_key(failure)
    return string.format("%s:%s", failure.kind, failure.input)
end

local function print_failures(failures)
    if #failures == 0 then
        return
    end

    vim.print(string.format("DTS failed with %d failure(s)", #failures))
    local counts = {}
    for _, failure in ipairs(failures) do
        local key = failure_key(failure)
        counts[key] = (counts[key] or 0) + 1
    end

    vim.print("Failure counts:")
    for key, count in pairs(counts) do
        vim.print(string.format("  %s: %d", key, count))
    end

    vim.print(string.format("First %d failure details:", math.min(MAX_FAILURE_DETAILS, #failures)))
    for index = 1, math.min(MAX_FAILURE_DETAILS, #failures) do
        vim.print(vim.inspect(failures[index]))
    end
end

local seed_start = tonumber(_G.arg[1])
local num_sims = tonumber(_G.arg[2])

if (not num_sims or type(num_sims) ~= "number") or (not seed_start or type(seed_start) ~= "number") then
    print(USAGE)
else
    local failures = {}
    local seed = seed_start
    local seed_end = seed_start + num_sims
    local start_time = vim.uv.hrtime()
    while seed <= seed_end do
        M.test(seed, failures)
        if seed % 10000 == 0 then
            vim.print(string.format("[SEED: %d]", seed))
            local cur_time = vim.uv.hrtime()
            local elapsed_seconds = (cur_time - start_time) / 1e9
            local completed = seed - seed_start
            elapsed_seconds = elapsed_seconds > 0 and elapsed_seconds or 1
            completed = completed > 0 and completed or 1
            local rate = completed / (elapsed_seconds or 1)
            local remaining = num_sims - completed
            vim.print(string.format("%d sims remaing (est %d seconds)", remaining, remaining / rate))
        end
        seed = seed + 1
    end

    if #failures > 0 then
        print_failures(failures)
        os.exit(1)
    end
end

return M
