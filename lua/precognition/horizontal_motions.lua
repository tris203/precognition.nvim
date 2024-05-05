local utils = require("precognition.utils")

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
        return 0
    end

    return offset
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, _linelen)
    local len = vim.fn.strcharlen(str)
    if cursorcol >= len then
        return 0
    end
    local offset = cursorcol
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char)
    local next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    local rev_offset

    if (c_class == 1 and next_char_class ~= 1) or (next_char_class == 1 and c_class ~= 1) then
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        c_class = utils.char_class(char)
        next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1))
    end

    if c_class ~= 0 and next_char_class ~= 0 then
        while utils.char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    if c_class == 0 or next_char_class == 0 then
        local next_word_start = M.next_word_boundary(str, offset, 0)
        if next_word_start then
            rev_offset = M.end_of_word(str, next_word_start + 1, 0)
        end
    end

    if rev_offset ~= nil and rev_offset <= 0 then
        return 0
    end

    if rev_offset ~= nil then
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
            return 0
        end
    end

    if offset == nil or offset > len or offset < 0 then
        return 0
    end
    return offset + 1
end

---@param str string
---@param cursorcol integer
---@param linelen integer
---@return Precognition.PlaceLoc
function M.matching_bracket(str, cursorcol, linelen)
    local supportedBrackets = {
        open = { "(", "[", "{" },
        middle = { "", "", "" },
        close = { ")", "]", "}" },
    }
    local under_cursor = vim.fn.strcharpart(str, cursorcol - 1, 1)
    local offset = cursorcol

    if
        not vim.tbl_contains(supportedBrackets.open, under_cursor)
        and not vim.tbl_contains(supportedBrackets.close, under_cursor)
    then
        -- walk until we find a bracket
        return 0
    end
    local idxFound = false
    local bracketIdx
    if not idxFound then
        for i, bracket in ipairs(supportedBrackets.open) do
            if bracket == under_cursor then
                bracketIdx = i
                idxFound = true
                break
            end
        end
    end

    if not idxFound then
        for i, bracket in ipairs(supportedBrackets.close) do
            if bracket == under_cursor then
                bracketIdx = i
                idxFound = true
                break
            end
        end
    end

    if not idxFound then
        return 0
    end

    local openBracket = supportedBrackets.open[bracketIdx]
    local closeBracket = supportedBrackets.close[bracketIdx]
    local middleBracket = supportedBrackets.middle[bracketIdx]

    if under_cursor == openBracket then
        local depth = 1
        offset = offset + 1
        while offset <= linelen do
            local char = vim.fn.strcharpart(str, offset - 1, 1)
            if char == openBracket then
                depth = depth + 1
            end
            if char == closeBracket or char == middleBracket then
                depth = depth - 1
                if depth == 0 then
                    break
                end
            end
            offset = offset + 1
        end
    end

    if under_cursor == closeBracket then
        local depth = 1
        offset = offset - 2
        while offset >= 0 do
            local char = vim.fn.strcharpart(str, offset - 1, 1)
            if char == closeBracket then
                depth = depth + 1
            end
            if char == openBracket or char == middleBracket then
                depth = depth - 1
                if depth == 0 then
                    break
                end
            end
            offset = offset - 1
        end
    end

    if offset < 0 or offset > linelen then
        return 0
    end
    return offset
end

return M
