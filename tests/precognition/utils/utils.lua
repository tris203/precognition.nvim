local M = {}

function M.hex2dec(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))

    local dec = (r * 256 ^ 2) + (g * 256) + b

    return dec
end

return M
