---@type Precognition.MotionsAdapter
local M = {}

local sim = require("precognition.motions.sim_motions.sim")

---@type string?
local last_str
---@type integer?
local last_cursorcol
---@type Precognition.VirtLine?
local last_result
---@type string?
local last_text_object_line
---@type integer?
local last_text_object_cursorcol
---@type string?
local last_text_object_prefix
---@type Precognition.TextObjectAnchor[]?
local last_text_object_anchors
---@type Precognition.RangePreview[]?
local last_text_object_ranges

local text_objects = {
    { key = '"', start_label = '"', end_label = '"', prio = 60 },
    { key = "'", start_label = "'", end_label = "'", prio = 59 },
    { key = "`", start_label = "`", end_label = "`", prio = 58 },
    { key = "(", start_label = "(", end_label = ")", prio = 50 },
    { key = "{", start_label = "{", end_label = "}", prio = 40 },
    { key = "[", start_label = "[", end_label = "]", prio = 30 },
    { key = "<", start_label = "<", end_label = ">", prio = 20 },
}

local availability_text_objects = {
    { key = "w", label = "w", prio = 10 },
    { key = "W", label = "W", prio = 9 },
}

local function is_single_width_printable_non_whitespace(char)
    return char ~= "" and not char:match("%s") and vim.fn.strdisplaywidth(char) == 1
end

local function char_at(str, col)
    return vim.fn.strcharpart(str, col - 1, 1)
end

---@param str string
---@return string[]
local function addressable_labels(str)
    local labels = {}
    local seen = {}
    for col = 1, vim.fn.strcharlen(str) do
        local char = char_at(str, col)
        if is_single_width_printable_non_whitespace(char) and not seen[char] then
            table.insert(labels, char)
            seen[char] = true
        end
    end
    return labels
end

---@param str string
---@param cursorcol integer
---@param motion string
---@param count integer?
---@return Precognition.TargetedMotionHint[]
local function targeted_motion_targets(str, cursorcol, motion, count)
    local prefix = count and count > 1 and tostring(count) or ""
    local labels = addressable_labels(str)
    local inputs = {}
    local input_to_label = {}
    for _, label in ipairs(labels) do
        local input = prefix .. motion .. label
        table.insert(inputs, input)
        input_to_label[input] = label
    end

    local hints = {}
    local destinations = sim.motion_destinations(str, cursorcol, inputs)
    for _, input in ipairs(inputs) do
        local col = destinations[input]
        if col then
            table.insert(hints, { label = input_to_label[input], col = col })
        end
    end
    return hints
end

---@param cur_line string
---@param cursorcol integer
---@param line_len integer
---@param count integer?
---@param charsearch table | nil
---@return Precognition.TargetedMotionHint[]
function M.repeat_targeted_motion_hints(cur_line, cursorcol, line_len, count, charsearch)
    if not charsearch or charsearch.char == nil or charsearch.char == "" then
        return {}
    end

    local prefix = count and count > 1 and tostring(count) or ""
    local previous_charsearch = vim.fn.getcharsearch()
    vim.fn.setcharsearch(charsearch)
    local destinations = sim.motion_destinations(cur_line, cursorcol, { prefix .. ";", prefix .. "," })
    vim.fn.setcharsearch(previous_charsearch)
    local repeat_col = destinations[prefix .. ";"] or 0
    local reverse_col = destinations[prefix .. ","] or 0

    local hints = {}
    if repeat_col > 0 then
        table.insert(hints, { label = ";", col = repeat_col })
    end
    if reverse_col > 0 then
        table.insert(hints, { label = ",", col = reverse_col })
    end
    return hints
end

---@param str string
---@param cursorcol integer
---@return Precognition.VirtLine
local function check_cached(str, cursorcol)
    if last_str ~= str or last_cursorcol ~= cursorcol or not last_result then
        last_str = str
        last_cursorcol = cursorcol
        last_result = sim.check(str, cursorcol)
    end

    return last_result
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.line_start_non_whitespace(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).Caret
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.line_end(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).Dollar
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.next_word_boundary(str, cursorcol, _linelen, big_word)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.W
    end

    return result.w
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@param _recursive boolean?
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, _linelen, big_word, _recursive)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.E
    end

    return result.e
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.prev_word_boundary(str, cursorcol, _linelen, big_word)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.B
    end

    return result.b
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.matching_bracket(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).MatchingPair
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.matching_comment(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).MatchingPair
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return function
function M.matching_pair(str, cursorcol, _linelen)
    local result = check_cached(str, cursorcol)

    if result.MatchingPair and result.MatchingPair > 0 then
        return function()
            return result.MatchingPair
        end
    end

    return function()
        return 0
    end
end

---@param anchors Precognition.TextObjectAnchor[]
---@param ranges Precognition.RangePreview[]
---@param prefix string
---@param line string
---@param text_object table
---@param around_selection { start_col: integer, end_col: integer }?
---@param range_selection { start_col: integer, end_col: integer }?
local function add_simulated_text_object(anchors, ranges, prefix, line, text_object, around_selection, range_selection)
    if not around_selection then
        return
    end
    local around_start = around_selection.start_col
    local around_end = around_selection.end_col

    -- around_start may include leading whitespace before text_object.start_label, so advance with
    -- vim.fn.strcharpart; sim outputs allow at most one extra char after text_object.end_label.
    while around_start < around_end and vim.fn.strcharpart(line, around_start - 1, 1) ~= text_object.start_label do
        around_start = around_start + 1
    end
    if vim.fn.strcharpart(line, around_end - 1, 1) ~= text_object.end_label then
        around_end = around_end - 1
    end
    if
        vim.fn.strcharpart(line, around_start - 1, 1) ~= text_object.start_label
        or vim.fn.strcharpart(line, around_end - 1, 1) ~= text_object.end_label
    then
        return
    end

    table.insert(anchors, { label = text_object.start_label, col = around_start, prio = text_object.prio })
    table.insert(anchors, { label = text_object.end_label, col = around_end, prio = text_object.prio })

    if not range_selection then
        return
    end
    local range_start = range_selection.start_col
    local range_end = range_selection.end_col
    if prefix:sub(-1) == "a" and range_end and vim.fn.strcharpart(line, range_end - 1, 1) ~= text_object.end_label then
        range_end = range_end - 1
    end
    if range_start and range_end and range_start <= range_end then
        table.insert(ranges, { start_col = range_start, end_col = range_end, depth = around_end - around_start })
    end
end

---@param prefix string
---@param line string
---@param cursorcol integer
---@param line_len integer
---@return Precognition.TextObjectAnchor[]
---@return Precognition.RangePreview[]
function M.text_object_hints(prefix, line, cursorcol, line_len)
    if
        last_text_object_line == line
        and last_text_object_cursorcol == cursorcol
        and last_text_object_prefix == prefix
        and last_text_object_anchors
        and last_text_object_ranges
    then
        return last_text_object_anchors, last_text_object_ranges
    end

    local anchors = {}
    local ranges = {}
    local keys_by_name = {}

    for _, text_object in ipairs(text_objects) do
        keys_by_name["around_" .. text_object.key] = "a" .. text_object.key
        keys_by_name["range_" .. text_object.key] = prefix:sub(-1) .. text_object.key
    end

    for _, text_object in ipairs(availability_text_objects) do
        keys_by_name["availability_" .. text_object.key] = prefix:sub(-1) .. text_object.key
    end

    local selections = sim.select_text_objects(line, cursorcol, keys_by_name)

    for _, text_object in ipairs(text_objects) do
        add_simulated_text_object(
            anchors,
            ranges,
            prefix,
            line,
            text_object,
            selections["around_" .. text_object.key],
            selections["range_" .. text_object.key]
        )
    end

    local availability_cols = {}
    for _, text_object in ipairs(availability_text_objects) do
        local selection = selections["availability_" .. text_object.key]
        local col = selection and selection.end_col
        if col and col <= line_len and not availability_cols[col] then
            table.insert(anchors, { label = text_object.label, col = col, prio = text_object.prio })
            availability_cols[col] = true
        end
    end

    table.sort(ranges, function(a, b)
        return a.depth < b.depth
    end)

    last_text_object_line = line
    last_text_object_cursorcol = cursorcol
    last_text_object_prefix = prefix
    last_text_object_anchors = anchors
    last_text_object_ranges = ranges

    return anchors, ranges
end

M.targeted_motions = {
    f = function(line, cursorcol, _line_len, count)
        return targeted_motion_targets(line, cursorcol, "f", count)
    end,
    F = function(line, cursorcol, _line_len, count)
        return targeted_motion_targets(line, cursorcol, "F", count)
    end,
    t = function(line, cursorcol, _line_len, count)
        return targeted_motion_targets(line, cursorcol, "t", count)
    end,
    T = function(line, cursorcol, _line_len, count)
        return targeted_motion_targets(line, cursorcol, "T", count)
    end,
}

return M
