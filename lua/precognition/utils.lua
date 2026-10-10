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

---Measure the width of leading `inline` virtual text on a line.
---
---Some plugins (notably orgmode's `org_startup_indented` option) render
---indentation as `inline` virtual text at column 0 instead of real leading
---whitespace. This shifts the visible start of the line to the right without
---changing the buffer text or `vim.fn.indent()`. Virtual lines rendered below
---the cursor line are anchored at the buffer's text origin, so callers must
---left-pad them by this width to stay aligned.
---
---The width is read from where the window draws the first character, so it
---only counts virtual text that is visible there, and none that a leading
---tab absorbs on its way to the next tabstop. Empty lines measure as zero.
---@param winid integer window to measure in, 0 for the current window
---@param line integer 1-indexed line number
---@return integer width display width of the leading inline virtual text
function M.get_inline_virtual_indent(winid, line)
    if winid == 0 then
        winid = vim.api.nvim_get_current_win()
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local cur_line = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
    -- skipcc keeps composing characters with the character they are drawn on
    local first_char = vim.fn.strcharpart(cur_line, 0, 1, true)
    if first_char == "" then
        return 0
    end
    local char_width = vim.api.nvim_win_call(winid, function()
        return vim.fn.strdisplaywidth(first_char)
    end)

    local virtualedit = vim.wo[winid].virtualedit
    if virtualedit == "" then
        virtualedit = vim.go.virtualedit
    end
    local virtual_editing = virtualedit:find("all", 1, true)
        or (virtualedit:find("block", 1, true) and vim.api.nvim_get_mode().mode == "\22")
    if virtual_editing then
        -- While virtual editing is active the first character's own columns leave
        -- the virtual text out, so measure up to the start of whatever follows it.
        local ok, virtcol = pcall(vim.fn.virtcol, { line, 1 + #first_char }, true, winid)
        if not ok or type(virtcol) ~= "table" or virtcol[1] == 0 then
            return 0
        end
        return math.max(virtcol[1] - 1 - char_width, 0)
    end

    local ok, virtcol = pcall(vim.fn.virtcol, { line, 1 }, true, winid)
    if not ok or type(virtcol) ~= "table" then
        return 0
    end
    return math.max(virtcol[2] - char_width, 0)
end

---Debounces calls to a function, and ensures it only runs once per delay
---even if called repeatedly.
---@param fn fun(...: any)
---@param delay integer
function M.debounce_trailing(fn, delay)
    local timer = assert(vim.uv.new_timer())

    -- Ugly hack to ensure timer is closed when the function is garbage collected
    -- unfortunate but necessary to avoid creating a new timer for each call.
    --
    -- In LuaJIT, only userdata can have finalizers. `newproxy` creates an opaque userdata
    -- which we can attach a finalizer to and use as a "canary."
    local proxy = newproxy(true)
    getmetatable(proxy).__gc = function()
        if not timer:is_closing() then
            timer:close()
        end
    end

    return function(...)
        local _ = proxy
        local args = { ... }
        timer:stop()
        timer:start(
            delay,
            0,
            vim.schedule_wrap(function()
                fn(unpack(args))
            end)
        )
    end
end

return M
