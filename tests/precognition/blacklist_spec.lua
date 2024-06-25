local utils = require("precognition.utils")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("blacklist buffers", function()
    it("a regular buffer is not blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(true, false)
        eq(utils.is_blacklisted_buffer(test_buffer), false)
    end)

    it("hidden buffer is not blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_set_option_value("buftype", "", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer), false)
    end)

    it("scratch buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(true, true)
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("hidden scratch buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("nofile buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("prompt buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_set_option_value("buftype", "prompt", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("help buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_set_option_value("buftype", "help", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("terminal buffer is blacklisted", function()
        local test_buffer = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_open_term(test_buffer, {})
        eq(utils.is_blacklisted_buffer(test_buffer), true)
    end)

    it("blacklisted buffer by filetype", function()
        local test_buffer = vim.api.nvim_create_buf(true, false)
        local test_fts = { "startify" }
        vim.api.nvim_set_option_value("filetype", "startify", { buf = test_buffer })
        eq(utils.is_blacklisted_buffer(test_buffer, test_fts), true)
    end)
end)
