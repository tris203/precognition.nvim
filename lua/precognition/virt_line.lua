local HintPriority = require("precognition.hint_priority")

local M = {}

---@param cur_line string
---@param charcol number
---@param offset number
---@return number
---@return string
---@return number
function M.calculate_visual_cursorcol(cur_line, charcol, offset)
    local leading_whitespace = string.match(cur_line, "^([ \t]*)")
    local cursorcol = charcol - #leading_whitespace + offset
    local tab_width
    if vim.bo.expandtab then
        tab_width = vim.bo.shiftwidth
    else
        tab_width = vim.bo.tabstop
    end
    local sanitised_line = cur_line:gsub("\t", string.rep(" ", tab_width))
    return cursorcol, sanitised_line, tab_width
end

---@param config Precognition.Config
---@param marks Precognition.VirtLine?
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@return table
function M.build(config, marks, line_len, extra_padding, min_width)
    local utils = require("precognition.utils")
    if not marks or line_len == 0 then
        return {}
    end

    local line_table = utils.create_pad_array(line_len, " ")
    local priority = HintPriority.new()
    for mark, loc in pairs(marks) do
        local updated_hint = priority:add(loc, config.hints[mark].prio, config.hints[mark].text or mark)
        if updated_hint and loc > 0 and loc <= line_len then
            line_table[loc] = updated_hint
        end
    end

    for _, padding in ipairs(extra_padding) do
        line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
    end

    local line = table.concat(line_table)
    if min_width and vim.fn.strdisplaywidth(line) < min_width then
        line = line .. string.rep(" ", min_width - vim.fn.strdisplaywidth(line))
    end
    if line:match("^%s+$") then
        if min_width and config.showBlankVirtLine then
            return { { line, "PrecognitionHighlight" } }
        end
        return {}
    end

    return { { line, "PrecognitionHighlight" } }
end

---@param config Precognition.Config
---@param anchors Precognition.TextObjectAnchor[]
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@param ranges? Precognition.RangePreview[]
---@return table
function M.build_text_object(config, anchors, line_len, extra_padding, min_width, ranges)
    local utils = require("precognition.utils")
    if line_len == 0 then
        return {}
    end

    local virt_line = {}
    local line_table = utils.create_pad_array(line_len, " ")
    local highlights = utils.create_pad_array(line_len, "PrecognitionTextObjectAvailability")

    ranges = ranges or {}
    for index = math.min(#ranges, #config.textObjectHighlightColors), 1, -1 do
        local range = ranges[index]
        local hl_group = "PrecognitionTextObjectRange" .. index
        for col = range.start_col, range.end_col do
            if col > 0 and col <= line_len then
                highlights[col] = hl_group
            end
        end
    end

    local priority = HintPriority.new()
    for _, anchor in ipairs(anchors) do
        local updated_hint = priority:add(anchor.col, anchor.prio, anchor.label)
        if updated_hint and anchor.col > 0 and anchor.col <= line_len then
            line_table[anchor.col] = updated_hint
        end
    end

    for _, padding in ipairs(extra_padding) do
        line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
    end

    local line = table.concat(line_table)
    if min_width and vim.fn.strdisplaywidth(line) < min_width then
        for _ = 1, min_width - vim.fn.strdisplaywidth(line) do
            table.insert(line_table, " ")
            table.insert(highlights, "PrecognitionTextObjectAvailability")
        end
        line = table.concat(line_table)
    end
    if line:match("^%s+$") then
        if min_width and config.showBlankVirtLine then
            return { { line, "PrecognitionTextObjectAvailability" } }
        end
        return {}
    end

    local chunk_text = ""
    local chunk_hl = highlights[1]
    for col = 1, #line_table do
        local char = line_table[col]
        local hl = highlights[col] or "PrecognitionTextObjectAvailability"
        if hl ~= chunk_hl then
            table.insert(virt_line, { chunk_text, chunk_hl })
            chunk_text = char
            chunk_hl = hl
        else
            chunk_text = chunk_text .. char
        end
    end
    if chunk_text ~= "" then
        table.insert(virt_line, { chunk_text, chunk_hl })
    end
    return virt_line
end

---@param line string
---@param start_col integer
---@param width integer
---@return string
local function slice_by_display_cols(line, start_col, width)
    local start_pattern = ("\\%%>%dv"):format(start_col)
    if vim.fn.strdisplaywidth(line) <= start_col + width then
        return vim.fn.matchstr(line, start_pattern .. ".*")
    end

    local pattern = start_pattern .. ("\\_.\\{-}\\%%%dv"):format(start_col + width + 1)
    return vim.fn.matchstr(line, pattern)
end

---@param virt_line table
---@param cursorcol integer
---@param width integer
---@return table
function M.fit_to_wrap(virt_line, cursorcol, width)
    if width <= 0 or #virt_line == 0 then
        return virt_line
    end

    local line = virt_line[1][1]
    if vim.fn.strdisplaywidth(line) <= width then
        return virt_line
    end

    local start_col = math.floor((cursorcol - 1) / width) * width
    virt_line[1][1] = slice_by_display_cols(line, start_col, width)
    return virt_line
end

return M
