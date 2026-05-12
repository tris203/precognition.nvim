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

---@param priority Precognition.HintPriority
---@param line_table string[]
---@param highlights string[]
---@param loc integer?
---@param prio number?
---@param label string
---@param hl_group? string
---@param line_len integer
local function add_hint(priority, line_table, highlights, loc, prio, label, hl_group, line_len)
    local updated_hint = priority:add(loc, prio, label, hl_group)
    if updated_hint and loc and loc > 0 and loc <= line_len then
        line_table[loc] = updated_hint
        local hints = priority:hints_by_destination()
        local prioritized_hint = hints and hints[loc]
        highlights[loc] = (prioritized_hint and prioritized_hint.hl_group) or "PrecognitionHighlight"
    end
end

---@param config Precognition.Config
---@param marks Precognition.VirtLine
---@param priority Precognition.HintPriority
---@param line_table string[]
---@param highlights string[]
---@param line_len integer
local function add_virt_line_marks(config, marks, priority, line_table, highlights, line_len)
    for key, loc in pairs(marks) do
        local opts = config.hints[key]
        if opts then
            add_hint(priority, line_table, highlights, loc, opts.prio, opts.text or key, nil, line_len)
        end
    end
end

---@param candidates Precognition.InlineHintCandidate[]
---@param priority Precognition.HintPriority
---@param line_table string[]
---@param highlights string[]
---@param line_len integer
local function add_inline_hint_candidates(candidates, priority, line_table, highlights, line_len)
    for _, candidate in ipairs(candidates) do
        add_hint(
            priority,
            line_table,
            highlights,
            candidate.col,
            candidate.prio,
            candidate.label,
            candidate.hl_group,
            line_len
        )
    end
end

---@overload fun(
---config: Precognition.Config,
---marks: Precognition.VirtLine,
---line_len: integer,
---extra_padding: Precognition.ExtraPadding[],
---min_width?: integer): table
---@overload fun(config: Precognition.Config,
---marks: Precognition.InlineHintCandidate[],
---line_len: integer,
---extra_padding: Precognition.ExtraPadding[],
---min_width?: integer): table
---@param config Precognition.Config
---@param marks Precognition.VirtLine | Precognition.InlineHintCandidate[] | nil
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
    local highlights = utils.create_pad_array(line_len, "PrecognitionHighlight")
    local priority = HintPriority.new()

    if vim.islist(marks) then
        add_inline_hint_candidates(marks, priority, line_table, highlights, line_len)
    else
        ---@cast marks Precognition.VirtLine
        add_virt_line_marks(config, marks, priority, line_table, highlights, line_len)
    end

    for _, padding in ipairs(extra_padding) do
        line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
    end

    local line = table.concat(line_table)
    if min_width and vim.fn.strdisplaywidth(line) < min_width then
        for _ = 1, min_width - vim.fn.strdisplaywidth(line) do
            table.insert(line_table, " ")
            table.insert(highlights, "PrecognitionHighlight")
        end
        line = table.concat(line_table)
    end
    if line:match("^%s+$") then
        if min_width and config.showBlankVirtLine then
            return { { line, "PrecognitionHighlight" } }
        end
        return {}
    end

    local virt_line = {}
    local chunk_text = ""
    local chunk_hl = highlights[1]
    for col = 1, #line_table do
        local char = line_table[col]
        local hl = highlights[col] or "PrecognitionHighlight"
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
    -- \%Nv anchors the match to virtual/display columns, unlike string indexes.
    local start_pattern = ("\\%%%dv"):format(start_col + 1)
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

    local line = ""
    for _, chunk in ipairs(virt_line) do
        line = line .. chunk[1]
    end
    if vim.fn.strdisplaywidth(line) <= width then
        return virt_line
    end

    local start_col = math.floor((math.max(cursorcol, 1) - 1) / width) * width
    local clipped = slice_by_display_cols(line, start_col, width)
    local clipped_width = vim.fn.strdisplaywidth(clipped)
    local clipped_virt_line = {}
    local chunk_start_col = 0

    for _, chunk in ipairs(virt_line) do
        local chunk_text = chunk[1]
        local chunk_width = vim.fn.strdisplaywidth(chunk_text)
        local chunk_end_col = chunk_start_col + chunk_width
        local overlap_start_col = math.max(chunk_start_col, start_col)
        local overlap_end_col = math.min(chunk_end_col, start_col + clipped_width)

        if overlap_start_col < overlap_end_col then
            table.insert(clipped_virt_line, {
                slice_by_display_cols(chunk_text, overlap_start_col - chunk_start_col, overlap_end_col - overlap_start_col),
                chunk[2] or "PrecognitionHighlight",
            })
        end

        chunk_start_col = chunk_end_col
    end

    if #clipped_virt_line == 0 then
        return { { clipped, virt_line[1][2] or "PrecognitionHighlight" } }
    end
    return clipped_virt_line
end

return M
