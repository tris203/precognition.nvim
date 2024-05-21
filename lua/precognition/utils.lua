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
    big_word = big_word or false
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

return M
