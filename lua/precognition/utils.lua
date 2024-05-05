local M = {}

---@param char string
---@return integer
function M.char_class(char)
    local byte = string.byte(char)

    if byte and byte < 0x100 then
        if char == " " or char == "\t" or char == "\0" then
            return 0 -- whitespace
        end
        if char == "_" or char:match("%w") then
            return 2 -- word character
        end
        return 1 -- other
    end

    return 1 -- scary unicode edge cases go here
end

return M
