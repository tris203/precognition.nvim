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

---@param bufnr? integer
---@return boolean
function M.is_blacklisted_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
        return true
    end
    return false
end

---@param motionstring string | nil
---@return integer
function M.count_from_motionstring(motionstring)
    if motionstring == nil then
        return 1
    end

    local count = 1

    for digit in string.gmatch(motionstring, "%d+") do
        count = count * tonumber(digit)
    end
    return count
end

---@param count integer
---@param motion function
---@param str string
---@param cursorcol integer
---@param linelen integer
---@return integer
function M.count_motion(count, motion, str, cursorcol, linelen)
    local ret = cursorcol
    for _ = 1, count do
        ret = motion(str, ret, linelen)
    end
    return ret
end

return M
