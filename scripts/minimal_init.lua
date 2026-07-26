local M = {}

---@type string
local mini_test_version = "v0.17.0"

local function tempdir(plugin)
    return vim.uv.os_tmpdir() .. "/" .. plugin
end

local minitest_dir = os.getenv("MINI_TEST") or tempdir("mini.test")
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
require("mini.test").setup()

return M
