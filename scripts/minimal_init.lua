local M = {}

local function tempdir(plugin)
    if jit.os == "Windows" then
        return "D:\\tmp\\" .. plugin
    end
    return vim.loop.os_tmpdir() .. "/" .. plugin
end

local minitest_dir = os.getenv("MINI_TEST") or tempdir("mini.test")
if vim.fn.isdirectory(minitest_dir) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "https://github.com/nvim-mini/mini.test",
        minitest_dir,
    })
end
vim.opt.rtp:append(".")
vim.opt.rtp:append(minitest_dir)
require("mini.test").setup()

return M
