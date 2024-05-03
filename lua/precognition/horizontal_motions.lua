local utils = require("precognition.utils")

local M = {}

---@param str string
---@return integer
function M.line_start_non_whitespace(str)
    return str:find("%S") or 0
end

---@param len integer
---@return integer
function M.line_end(len)
    return len
end

---@param str string
---@param start integer
---@return integer | nil
function M.next_word_boundary(str, start)
    local offset = start
    local len = vim.fn.strcharlen(str)
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)

    if c_class ~= 0 then
        while utils.char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    while utils.char_class(char) == 0 and offset <= len do
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
    end
    if offset > len then
        return nil
    end

    return offset
end

---@param str string
---@param start integer
---@return integer | nil
function M.end_of_word(str, start)
    local len = vim.fn.strcharlen(str)
    if start >= len then
        return nil
    end
    local offset = start
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)
    local next_char_class =
        utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    local rev_offset

    if
        (c_class == 1 and next_char_class ~= 1)
        or (next_char_class == 1 and c_class ~= 1)
    then
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        c_class = utils.char_class(char)
        next_char_class =
            utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    end

    if c_class ~= 0 and next_char_class ~= 0 then
        while utils.char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    if c_class == 0 or next_char_class == 0 then
        local next_word_start = M.next_word_boundary(str, offset)
        if next_word_start then
            rev_offset = M.end_of_word(str, next_word_start + 1)
        end
    end

    if rev_offset ~= nil and rev_offset <= 0 then
        return nil
    end

    if rev_offset ~= nil then
        return rev_offset
    end
    return offset - 1
end

---@param str string
---@param start integer
---@return integer | nil
function M.prev_word_boundary(str, start)
    local len = vim.fn.strcharlen(str)
    local offset = start - 1
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)

    if c_class == 0 then
        while utils.char_class(char) == 0 and offset >= 0 do
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
            return nil
        end
    end

    if offset == nil or offset > len or offset < 0 then
        return nil
    end
    return offset + 1
end

return M
