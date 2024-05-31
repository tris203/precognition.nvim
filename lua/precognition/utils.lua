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

---@param len integer
---@param str string
---@return string[]
function M.create_pad_array(len, str)
    local pad_array = {}
    for i = 1, len do
        pad_array[i] = str
    end
    return pad_array
end

---Add extra padding for multi byte character characters
---@param cur_line string
---@param extra_padding Precognition.ExtraPadding[]
---@param line_len integer
function M.add_multibyte_padding(cur_line, extra_padding, line_len)
    for i = 1, line_len do
        local char = vim.fn.strcharpart(cur_line, i - 1, 1)
        local width = vim.fn.strdisplaywidth(char)
        if width > 1 then
            table.insert(extra_padding, { start = i, length = width - 1 })
        end
    end
end

return M
