local M = {}

---@enum cc
M.char_classes = {
    whitespace = 0,
    other = 1,
    word = 2,
}

---@param char string
---@param big_word boolean
---@return integer
function M.char_class(char, big_word)
    assert(type(big_word) == "boolean", "big_word must be a boolean")
    local cc = M.char_classes
    local byte = string.byte(char)

    if byte and byte < 0x100 then
        if char == " " or char == "\t" or char == "\0" then
            return cc.whitespace
        end
        if char == "_" or char:match("%w") then
            return big_word and cc.other or cc.word
        end
        return cc.other
    end

    return cc.other -- scary unicode edge cases go here
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

    local mode = vim.api.nvim_get_mode().mode
    local cursorrow, cursorcol = unpack(vim.api.nvim_win_get_cursor(0))

    if (mode == "v") and motionstring == string.format("%d", cursorcol + 1) then
        --HACK: this is a special case for visual mode
        --this will cause an edge case bug that if the count is the same as the cursor positions
        --it will not display the count - but we cant work aroynd it with the current implementation
        return 1
    end

    if mode == "V" and motionstring == string.format("%d", cursorrow + 1) then
        return 1
    end

    --HACK: replace_termcodes doesnt get <20> so we need to remove it
    motionstring = motionstring:gsub("<%d+>", "")

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
---@param big_word boolean
---@return integer
function M.count_motion(count, motion, str, cursorcol, linelen, big_word)
    local ret = cursorcol
    local out_of_bounds = false
    for _ = 1, count do
        if ret <= 0 or ret > linelen then
            out_of_bounds = true
            break
        end
        ret = motion(str, ret, linelen, big_word)
    end
    if out_of_bounds then
        return 0
    end
    return ret
end

return M
