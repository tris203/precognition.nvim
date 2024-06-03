local M = {}

local supportedBrackets = {
    open = { "(", "[", "{" },
    middle = { nil, nil, nil },
    close = { ")", "]", "}" },
}

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
---@param linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.next_word_boundary(str, cursorcol, linelen, big_word)
    local utils = require("precognition.utils")
    local cc = utils.char_classes

    local offset = cursorcol
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char, big_word)

    if c_class ~= cc.whitespace then
        while utils.char_class(char, big_word) == c_class and offset <= linelen do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    while utils.char_class(char, big_word) == cc.whitespace and offset <= linelen do
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
    end
    if offset > linelen then
        return 0
    end

    return offset
end

---@param str string
---@param cursorcol integer
---@param linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, linelen, big_word)
    if cursorcol >= linelen then
        return 0
    end
    local utils = require("precognition.utils")
    local cc = utils.char_classes

    local offset = cursorcol
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char, big_word)
    local next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1), big_word)
    local rev_offset

    if
        (c_class == cc.punctuation and next_char_class ~= cc.punctuation)
        or (next_char_class == cc.punctuation and c_class ~= cc.punctuation)
    then
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        c_class = utils.char_class(char, big_word)
        next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1), big_word)
    end

    if c_class ~= cc.whitespace and next_char_class ~= cc.whitespace then
        while utils.char_class(char, big_word) == c_class and offset <= linelen do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
    end

    if c_class == cc.whitespace or next_char_class == cc.whitespace then
        local next_word_start = M.next_word_boundary(str, cursorcol, linelen, big_word)
        if next_word_start then
            next_char_class = utils.char_class(vim.fn.strcharpart(str, (next_word_start - 1) + 1, 1), big_word)
            --next word is single char
            if next_char_class == cc.whitespace then
                rev_offset = next_word_start
            else
                rev_offset = M.end_of_word(str, next_word_start, linelen, big_word)
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
---@param linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.prev_word_boundary(str, cursorcol, linelen, big_word)
    local utils = require("precognition.utils")
    local cc = utils.char_classes

    local offset = cursorcol - 1
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = utils.char_class(char, big_word)

    if c_class == cc.whitespace then
        while utils.char_class(char, big_word) == cc.whitespace and offset >= 0 do
            offset = offset - 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
        end
        c_class = utils.char_class(char, big_word)
    end

    while utils.char_class(char, big_word) == c_class and offset >= 0 do
        offset = offset - 1
        char = vim.fn.strcharpart(str, offset - 1, 1)
        --if remaining string is whitespace, return 0
        local remaining = string.sub(str, offset)
        if remaining:match("^%s*$") and #remaining > 0 then
            return 0
        end
    end

    if offset == nil or offset > linelen or offset < 0 then
        return 0
    end
    return offset + 1
end

---@param str string
---@param cursorcol integer
---@param linelen integer
---@return Precognition.PlaceLoc
function M.matching_bracket(str, cursorcol, linelen)
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

    local openBracket = supportedBrackets.open[bracketIdx] or ""
    local closeBracket = supportedBrackets.close[bracketIdx] or ""
    local middleBracket = supportedBrackets.middle[bracketIdx] or ""

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
        offset = offset - 1
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

---@param str string
---@param cursorcol integer
---@param linelen integer
---@return Precognition.PlaceLoc
function M.matching_comment(str, cursorcol, linelen)
    local offset = cursorcol
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local next_char = vim.fn.strcharpart(str, (offset - 1) + 1, 1)
    local prev_char = vim.fn.strcharpart(str, (offset - 1) - 1, 1)

    if (char == "/" and next_char == "*") or (prev_char == "/" and char == "*") then
        offset = offset + 1
        while offset <= linelen do
            char = vim.fn.strcharpart(str, offset - 1, 1)
            next_char = vim.fn.strcharpart(str, offset, 1)
            if char == "*" and next_char == "/" then
                -- return the slash of the closing comment
                return offset + 1
            end
            offset = offset + 1
        end
    end

    if (char == "*" and next_char == "/") or (prev_char == "*" and char == "/") then
        offset = offset - 1
        while offset >= 0 do
            char = vim.fn.strcharpart(str, offset - 1, 1)
            next_char = vim.fn.strcharpart(str, offset, 1)
            if char == "/" and next_char == "*" then
                return offset
            end
            offset = offset - 1
        end
    end

    return 0
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return function
function M.matching_pair(str, cursorcol, _linelen)
    local char = vim.fn.strcharpart(str, cursorcol - 1, 1)
    if char == "/" or char == "*" then
        return M.matching_comment
    end

    if vim.tbl_contains(supportedBrackets.open, char) or vim.tbl_contains(supportedBrackets.close, char) then
        return M.matching_bracket
    end

    return function()
        return 0
    end
end

return M
