local M = {}

function M.observe_keys(child, keys)
    child.lua_func(function(keys_to_observe)
        local adapter = require("precognition.observed_command_adapter").current()
        assert(adapter, "expected observed command adapter to be initialised")
        adapter:observe_keys(keys_to_observe, vim.api.nvim_get_mode().mode)
        vim.api.nvim__redraw({ buf = vim.api.nvim_get_current_buf(), flush = true })
        vim.wait(150)
    end, keys)
end

function M.hex2dec(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))

    local dec = (r * 256 ^ 2) + (g * 256) + b

    return dec
end

return M
