local M = {}

local function tempdir(plugin)
    if jit.os == "Windows" then
        return "D:\\tmp\\" .. plugin
    end
    return vim.loop.os_tmpdir() .. "/" .. plugin
end

local minitest_dir = os.getenv("MINI_TEST_DIR") or tempdir("mini.test")
if vim.fn.isdirectory(minitest_dir) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "https://github.com/echasnovski/mini.test",
        minitest_dir,
    })
end
vim.opt.rtp:append(".")
vim.opt.rtp:append(minitest_dir)
require("mini.test").setup()

local plenary_dir = os.getenv("PLENARY_DIR") or tempdir("plenary.nvim")
if vim.fn.isdirectory(plenary_dir) == 0 then
    vim.fn.system({
        "git",
        "clone",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_dir,
    })
end
vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
require("plenary.busted")

vim.cmd("runtime plugin/plenary.vim")
return M
