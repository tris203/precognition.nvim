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

---calculates the white space offset of a partial string
---@param hint vim.lsp.inlay_hint.get.ret
---@param tab_width integer
---@param current_line string
---@return integer
---@return integer
function M.calc_ws_offset(hint, tab_width, current_line)
    -- + 1 here because of trailing padding
    local length = #hint.inlay_hint.label[1].value + 1
    local start = hint.inlay_hint.position.character
    local prefix = vim.fn.strcharpart(current_line, 0, start)
    local expanded = string.gsub(prefix, "\t", string.rep(" ", tab_width))
    local ws_offset = vim.fn.strcharlen(expanded)
    return length, ws_offset
end

return M
