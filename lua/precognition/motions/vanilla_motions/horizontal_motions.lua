---@type Precognition.MotionsAdapter
local M = {}

local pairs = vim.split(vim.o.matchpairs, ",")

-- local match_bracket_escape = not vim.o.cpoptions:find("M")

local supportedBrackets = {
    open = {},
    middle = {},
    close = {},
}

local paired_text_objects = {
    { open = "(", close = ")", prio = 50 },
    { open = "{", close = "}", prio = 40 },
    { open = "[", close = "]", prio = 30 },
    { open = "<", close = ">", prio = 20 },
}

local quote_text_objects = {
    { quote = '"', prio = 60 },
    { quote = "'", prio = 59 },
    { quote = "`", prio = 58 },
}

local availability_text_objects = {
    { label = "w", prio = 10 },
    { label = "W", prio = 9 },
}

for _, pair in ipairs(pairs) do
    local open, close = pair:match("(.):(.)")
    if open and close then
        table.insert(supportedBrackets.open, open)
        table.insert(supportedBrackets.middle, nil)
        table.insert(supportedBrackets.close, close)
    end
end

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
---@param recursive boolean?
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, linelen, big_word, recursive)
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
    if not recursive then
        if
            (c_class == cc.punctuation and next_char_class ~= cc.punctuation)
            or (next_char_class == cc.punctuation and c_class ~= cc.punctuation)
            or (c_class == cc.emoji and next_char_class ~= cc.emoji)
            or (next_char_class == cc.emoji and c_class ~= cc.emoji)
        then
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset - 1, 1)
            c_class = utils.char_class(char, big_word)
            next_char_class = utils.char_class(vim.fn.strcharpart(str, (offset - 1) + 1, 1), big_word)
        end
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
            c_class = utils.char_class(vim.fn.strcharpart(str, next_word_start - 1, 1), big_word)
            next_char_class = utils.char_class(vim.fn.strcharpart(str, (next_word_start - 1) + 1, 1), big_word)
            if next_char_class == cc.whitespace then
                --next word is single char
                rev_offset = next_word_start
            elseif c_class == cc.punctuation and next_char_class ~= cc.punctuation then
                --next word starts with punctuation
                rev_offset = next_word_start
            else
                rev_offset = M.end_of_word(str, next_word_start, linelen, big_word, true)
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
                return offset
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

---@param str string
---@param col integer
---@return string
local function char_at(str, col)
    return vim.fn.strcharpart(str, col - 1, 1)
end

---@param str string
---@param cursorcol integer
---@param open string
---@param close string
---@return integer?
---@return integer?
local function find_enclosing_pair(str, cursorcol, open, close)
    local depth = 0
    local open_col
    local cursor_on_close = char_at(str, cursorcol) == close
    for col = cursorcol, 1, -1 do
        local char = char_at(str, col)
        if char == close then
            depth = depth + 1
        elseif char == open then
            if depth == 0 or (cursor_on_close and depth == 1) then
                open_col = col
                break
            end
            depth = depth - 1
        end
    end
    if not open_col then
        return nil, nil
    end

    depth = 0
    for col = open_col + 1, vim.fn.strcharlen(str) do
        local char = char_at(str, col)
        if char == open then
            depth = depth + 1
        elseif char == close then
            if depth == 0 then
                if open_col <= cursorcol and col >= cursorcol then
                    return open_col, col
                end
                return nil, nil
            end
            depth = depth - 1
        end
    end

    return nil, nil
end

---@param str string
---@param cursorcol integer
---@param open string
---@param close string
---@return integer?
---@return integer?
local function find_next_pair(str, cursorcol, open, close)
    local line_len = vim.fn.strcharlen(str)
    for col = cursorcol, line_len do
        if char_at(str, col) == open then
            local depth = 0
            for end_col = col + 1, line_len do
                local char = char_at(str, end_col)
                if char == open then
                    depth = depth + 1
                elseif char == close then
                    if depth == 0 then
                        return col, end_col
                    end
                    depth = depth - 1
                end
            end
        end
    end

    return nil, nil
end

---@param str string
---@param cursorcol integer
---@param quote string
---@return integer?
---@return integer?
local function find_enclosing_quote(str, cursorcol, quote)
    local before
    local cursor_on_quote = char_at(str, cursorcol) == quote
    local search_start = cursor_on_quote and cursorcol - 1 or cursorcol
    for col = search_start, 1, -1 do
        if char_at(str, col) == quote then
            before = col
            break
        end
    end
    if not before then
        before = cursor_on_quote and cursorcol or nil
    end
    if not before then
        return nil, nil
    end

    for col = before + 1, vim.fn.strcharlen(str) do
        if char_at(str, col) == quote then
            return before, col
        end
    end

    return nil, nil
end

---@param str string
---@param cursorcol integer
---@param quote string
---@return integer?
---@return integer?
local function find_next_quote(str, cursorcol, quote)
    local start_col
    for col = cursorcol, vim.fn.strcharlen(str) do
        if char_at(str, col) == quote then
            if start_col then
                return start_col, col
            end
            start_col = col
        end
    end

    return nil, nil
end

---@param prefix string
---@param start_col integer
---@param end_col integer
---@return integer
---@return integer
local function range_for_prefix(prefix, start_col, end_col)
    if prefix:sub(-1) == "i" then
        return start_col + 1, end_col - 1
    end
    return start_col, end_col
end

---@param anchors Precognition.TextObjectAnchor[]
---@param ranges Precognition.RangePreview[]
---@param prefix string
---@param start_col integer
---@param end_col integer
---@param start_label string
---@param end_label string
---@param prio integer
local function add_text_object_hint(anchors, ranges, prefix, start_col, end_col, start_label, end_label, prio)
    table.insert(anchors, { label = start_label, col = start_col, prio = prio })
    table.insert(anchors, { label = end_label, col = end_col, prio = prio })
    local range_start, range_end = range_for_prefix(prefix, start_col, end_col)
    if range_start <= range_end then
        table.insert(ranges, { start_col = range_start, end_col = range_end, depth = end_col - start_col })
    end
end

---@param prefix string
---@param cur_line string
---@param cursorcol integer
---@param line_len integer
---@return Precognition.TextObjectAnchor[]
---@return Precognition.RangePreview[]
function M.text_object_hints(prefix, cur_line, cursorcol, line_len)
    local anchors = {}
    local ranges = {}

    for _, text_object in ipairs(quote_text_objects) do
        local start_col, end_col = find_enclosing_quote(cur_line, cursorcol, text_object.quote)
        if not start_col then
            start_col, end_col = find_next_quote(cur_line, cursorcol, text_object.quote)
        end
        if start_col and end_col then
            add_text_object_hint(
                anchors,
                ranges,
                prefix,
                start_col,
                end_col,
                text_object.quote,
                text_object.quote,
                text_object.prio
            )
        end
    end

    for _, text_object in ipairs(paired_text_objects) do
        local start_col, end_col = find_enclosing_pair(cur_line, cursorcol, text_object.open, text_object.close)
        if not start_col then
            start_col, end_col = find_next_pair(cur_line, cursorcol, text_object.open, text_object.close)
        end
        if start_col and end_col then
            add_text_object_hint(
                anchors,
                ranges,
                prefix,
                start_col,
                end_col,
                text_object.open,
                text_object.close,
                text_object.prio
            )
        end
    end

    local availability_col = math.min(cursorcol, line_len)
    for index, text_object in ipairs(availability_text_objects) do
        local col = availability_col + index - 1
        if col <= line_len then
            table.insert(anchors, { label = text_object.label, col = col, prio = text_object.prio })
        end
    end

    table.sort(ranges, function(a, b)
        return a.depth < b.depth
    end)

    return anchors, ranges
end

return M
