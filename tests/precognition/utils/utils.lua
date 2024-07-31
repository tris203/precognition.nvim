local precognition = require("precognition")

local M = {}

function M.get_gutter_extmarks(buffer)
    local gutter_extmarks = {}
    for _, extmark in
        pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
            details = true,
        }))
    do
        if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match(precognition.gutter_group) then
            table.insert(gutter_extmarks, extmark)
        end
    end
    return gutter_extmarks
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
