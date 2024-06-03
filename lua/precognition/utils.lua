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
