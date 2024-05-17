local utils = require("precognition.utils")
local cc = utils.char_classes

local M = {}

---@param str string
---@param _cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.line_start_non_whitespace(str, _cursorcol, _linelen)
    return str:find("%S") or 0
end

---@param _str string
---@param _cursorcol integer
---@param linelen integer
---@return Precognition.PlaceLoc
function M.line_end(_str, _cursorcol, linelen)
    return linelen or nil
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.next_word_boundary(str, cursorcol, _linelen)
    local offset = cursorcol
    local len = vim.fn.strcharlen(str)
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)

    if c_class ~= cc.whitespace then
        while utils.char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    while utils.char_class(char) == cc.whitespace and offset <= len do
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
    end
    if offset > len then
        return 0
    end

    return offset
end

---@param str string
---@param cursorcol integer
---@param linelen integer
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, linelen)
    if cursorcol >= linelen then
        return 0
    end
    local offset = cursorcol
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)
    local next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    local rev_offset

    if
        (c_class == cc.other and next_char_class ~= cc.other) or (next_char_class == cc.other and c_class ~= cc.other)
    then
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        c_class = utils.char_class(char)
        next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    end

    if c_class ~= cc.whitespace and next_char_class ~= cc.whitespace then
        while utils.char_class(char) == c_class and offset <= linelen do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    if c_class == cc.whitespace or next_char_class == cc.whitespace then
        local next_word_start = M.next_word_boundary(str, cursorcol, linelen)
        if next_word_start then
            next_char_class = utils.char_class(vim.fn.strcharpart(str, (next_word_start - 1) + 1, 1))
            --next word is single char
            if next_char_class == cc.whitespace then
                rev_offset = next_word_start
            else
                rev_offset = M.end_of_word(str, next_word_start, linelen)
            end
        end
    end

    if rev_offset and rev_offset <= 0 then
        return 0
    end

    if rev_offset ~= nil then
        --e should never be behind the cursor
        if rev_offset < cursorcol then
            return 0
        end
        return rev_offset
    end
    return offset - 1
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.prev_word_boundary(str, cursorcol, _linelen)
    local len = vim.fn.strcharlen(str)
    local offset = cursorcol - 1
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)

    if c_class == cc.whitespace then
        while utils.char_class(char) == cc.whitespace and offset >= 0 do
            offset = offset - 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
        c_class = utils.char_class(char)
    end

    while utils.char_class(char) == c_class and offset >= 0 do
        offset = offset - 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        --if remaining string is whitespace, return nil_wrap
        local remaining = string.sub(str, offset)
        if remaining:match("^%s*$") and #remaining > 0 then
            return 0
        end
    end

    if offset == nil or offset > len or offset < 0 then
        return 0
    end
    return offset + 1
end

return M
