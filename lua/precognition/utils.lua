local M = {}

---@enum cc
M.char_classes = {
    whitespace = 0,
    punctuation = 1,
    word = 2,
    emoji = 3,
    other = "other",
    UNKNOWN = -1,
}

---@param char string
---@param big_word boolean
---@return cc
function M.char_class(char, big_word)
    assert(type(big_word) == "boolean", "big_word must be a boolean")
    local cc = M.char_classes

    if char == "" then
        return cc.UNKNOWN
    end

    if char == "\0" then
        return cc.whitespace
    end

    local c_class = vim.fn.charclass(char)

    if big_word and c_class ~= 0 then
        return cc.punctuation
    end

    return c_class
end

---@param bufnr? integer
---@param disabled_fts string[]
---@return boolean
function M.is_blacklisted_buffer(bufnr, disabled_fts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
        return true
    end

    if disabled_fts == nil then
        return false
    end

    for _, ft in ipairs(disabled_fts) do
        if vim.api.nvim_get_option_value("filetype", { buf = bufnr }) == ft then
            return true
        end
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
---@return integer length total padding required for the hint
---@return integer offset offset where the padding starts
function M.calc_ws_offset(hint, tab_width, current_line)
    ---@alias InlayHintLabelPartArray lsp.InlayHintLabelPart[]
    local length = 0
    if type(hint.inlay_hint.label) == "string" then
        length = #hint.inlay_hint.label
    elseif type(hint.inlay_hint.label) == "table" then
        for _, v in
            ipairs(hint.inlay_hint.label --[[@as InlayHintLabelPartArray]])
        do
            length = length + #v.value
        end
    end
    if hint.inlay_hint.paddingLeft then
        length = length + 1
    end
    if hint.inlay_hint.paddingRight then
        length = length + 1
    end
    local start = hint.inlay_hint.position.character
    local prefix = vim.fn.strcharpart(current_line, 0, start)
    local expanded = string.gsub(prefix, "\t", string.rep(" ", tab_width))
    local ws_offset = vim.fn.strcharlen(expanded)
    return length, ws_offset
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
