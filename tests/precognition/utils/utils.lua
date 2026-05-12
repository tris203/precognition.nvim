local M = {}

local function show_with_display_marks_upvalue(child, upvalue_name, prefix)
    child.lua_func(function(name_to_set, prefix_to_set)
        local precognition = require("precognition")
        precognition.hide()

        local _, display_marks = debug.getupvalue(precognition.peek, 1)
        for index = 1, math.huge do
            local name, value = debug.getupvalue(display_marks, index)
            if name == nil then
                break
            end
            if name == name_to_set then
                if value and value.set_prefix then
                    value:set_prefix(prefix_to_set)
                else
                    debug.setupvalue(display_marks, index, prefix_to_set)
                end
                break
            end
        end
        precognition.show()
        vim.api.nvim__redraw({ buf = vim.api.nvim_get_current_buf(), flush = true })
    end, upvalue_name, prefix)
end

function M.show_with_pending_prefix(child, prefix)
    show_with_display_marks_upvalue(child, "pending_command_prefix", prefix)
end

function M.show_with_motion_count(child, prefix)
    show_with_display_marks_upvalue(child, "motion_count", prefix)
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
