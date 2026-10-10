local M = {}

---@type string
local mini_test_version = "v0.18.0"

local function tempdir(plugin)
    return vim.uv.os_tmpdir() .. "/" .. plugin
end

local minitest_dir = os.getenv("MINI_TEST") or tempdir("mini.test-" .. mini_test_version)
if vim.fn.isdirectory(minitest_dir) == 0 then
    local output = vim.fn.system({
        "git",
        "clone",
        "--branch",
        mini_test_version,
        "--depth",
        "1",
        "https://github.com/nvim-mini/mini.test",
        minitest_dir,
    })
    if vim.v.shell_error ~= 0 then
        error("Failed to clone mini.test into " .. minitest_dir .. ":\n" .. output)
    end
end
vim.opt.rtp:append(".")
vim.opt.rtp:append(minitest_dir)
local MiniTest = require("mini.test")

---Stdout reporter that also fails the run when a case never reaches a final
---state, e.g. because the run quit while the case was still waiting.
local function strict_stdout_reporter()
    local reporter = MiniTest.gen_reporter.stdout({ quit_on_finish = false })
    local start, finish = reporter.start, reporter.finish
    local all_cases = {}

    reporter.start = function(cases)
        all_cases = cases
        start(cases)
    end

    reporter.finish = function()
        finish()

        local failed = false
        for _, case in ipairs(all_cases) do
            local state = case.exec and case.exec.state or "Not started"
            if not (state:find("^Pass") or state:find("^Fail")) then
                failed = true
                local id = table.concat(case.desc, " | ")
                if #case.args > 0 then
                    id = ("%s + args %s"):format(id, vim.inspect(case.args, { newline = "", indent = "" }))
                end
                io.stdout:write(("UNFINISHED (%s): %s\n"):format(state, id))
            end
            failed = failed or #(case.exec and case.exec.fails or {}) > 0
        end
        io.stdout:flush()
        vim.cmd(("silent! %dcquit"):format(failed and 1 or 0))
    end

    return reporter
end

MiniTest.setup({ execute = { reporter = strict_stdout_reporter() } })

return M
