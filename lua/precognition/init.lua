local M = {}

---@class Precognition.Config
---@field hints table<string, string>

---@class Precognition.PartialConfig
---@field hints? table<string, string>

---@type Precognition.Config
local default = {
    hints = {
        ["^"] = "^",
        ["$"] = "$",
        ["w"] = "w",
        ["W"] = "W",
        ["b"] = "b",
        ["e"] = "e",
        ["ge"] = "ge", -- should we support multi-char / multi-byte hints?
    },
}

---@type Precognition.Config
local config = default

---@type integer?
local extmark -- the active extmark in the current buffer
---@type boolean
local dirty -- whether a redraw is needed
---@type boolean
local visible = false

---@type integer
local au = vim.api.nvim_create_augroup("precognition", { clear = true })
---@type integer
local ns = vim.api.nvim_create_namespace("precognition")

local function char_class(char)
    local byte = string.byte(char)

    if byte and byte < 0x100 then
        if char == " " or char == "\t" or char == "\0" then
            return 0
        end
        if char == "_" or char:match("%w") then
            return 2
        end
        return 1
    end

    return 1 -- scary unicode edge cases go here
end

---@param str string
---@param start integer
---@return integer
local function next_word_boundary(str, start)
    local offset = start
    local len = vim.fn.strcharlen(str)
    local char = vim.fn.strcharpart(str, offset, 1)
    local c_class = char_class(char)

    if c_class ~= 0 then
        while char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset, 1)
        end
    end

    while char_class(char) == 0 and offset <= len do
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset, 1)
    end
    return offset
end

local function on_cursor_hold()
    local cursorline, cursorcol = unpack(vim.api.nvim_win_get_cursor(0))
    if extmark and not dirty then
        return
    end

    local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
    local cur_line = vim.api.nvim_get_current_line():gsub("\t", string.rep(" ", tab_width))
    local line_len = vim.fn.strcharlen(cur_line)
    local after_cursor = vim.fn.strcharpart(cur_line, cursorcol - 1)

    -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
    -- get char offsets for more complex motions.
    local line_start = cur_line:find("%S") or 0
    local line_end = line_len

    -- TODO: handle EOL - either hide the hint, or show a hint on the next line
    local motion_w = next_word_boundary(after_cursor, 0)

    if motion_w <= 1 then
        motion_w = next_word_boundary(after_cursor, math.max(0, motion_w)) - motion_w
    else
        motion_w = motion_w - 1
    end

    local virt_line = {}

    -- create the list of hints to show in { hint, column } format
    -- TODO: extract this into a function, add hints for other motions
    local marks = {}
    table.insert(marks, { "^", math.max(0, line_start - 1) })
    table.insert(marks, { "$", line_end - 1 })
    if motion_w then
        table.insert(marks, { "w", cursorcol + motion_w })
    end

    table.sort(marks, function(a, b)
        return a[2] < b[2]
    end)

    -- build the virtual line out of virt text chunks
    local last_col = 0
    for _, mark in ipairs(marks) do
        local hint = config.hints[mark[1]] or mark[1]
        local col = mark[2]
        if col > last_col then
            -- TODO: handle inline virtual text spacing
            -- add padding between hints
            table.insert(virt_line, { string.rep(" ", (col - last_col)) })
            last_col = col + 1
        end
        table.insert(virt_line, { hint, "Comment" })
    end

    -- TODO: can we add indent lines to the virt line to match indent-blankline or similar (if installed)?

    -- create (or overwrite) the extmark
    extmark = vim.api.nvim_buf_set_extmark(0, ns, cursorline - 1, 0, {
        id = extmark, -- reuse the same extmark if it exists
        virt_lines = { virt_line },
    })

    dirty = false
end

local function on_cursor_moved(ev)
    if extmark then
        local ext = vim.api.nvim_buf_get_extmark_by_id(ev.buf, ns, extmark, {
            details = true,
        })
        if ext and ext[1] ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
            vim.api.nvim_buf_del_extmark(0, ns, extmark)
            extmark = nil
        end
    end
    dirty = true
end

local function on_insert_enter(ev)
    if extmark then
        vim.api.nvim_buf_del_extmark(ev.buf, ns, extmark)
        extmark = nil
    end
    dirty = true
end

local function on_buf_leave(ev)
    vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
    extmark = nil
    dirty = true
end

--- Show the hints until the next keypress or CursorMoved event
function M.peek()
    error("not implemented")
end

--- Enable automatic showing of hints
function M.show()
    if visible then
        return
    end
    visible = true

    -- clear the extmark entirely when leaving a buffer (hints should only show in current buffer)
    vim.api.nvim_create_autocmd("BufLeave", {
        group = au,
        callback = on_buf_leave,
    })

    -- clear the extmark when the cursor moves, or when insert mode is entered
    --
    --  TODO: maybe we should debounce on CursorMoved instead of using CursorHold?
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = au,
        callback = on_cursor_moved,
    })

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = au,
        callback = on_insert_enter,
    })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = au,
        -- TODO: add debounce / delay before showing hints to reduce flickering
        -- during fast movements
        callback = on_cursor_hold,
    })

    on_cursor_hold({ buf = vim.api.nvim_get_current_buf() })
end

--- Disable automatic showing of hints
function M.hide()
    if not visible then
        return
    end
    visible = false
    if extmark then
        vim.api.nvim_buf_del_extmark(0, ns, extmark)
        extmark = nil
    end
    au = vim.api.nvim_create_augroup("precognition", { clear = true })
end

--- Toggle automatic showing of hints
function M.toggle()
    if visible then
        M.hide()
    else
        M.show()
    end
end

---@param opts Precognition.PartialConfig
function M.setup(opts)
    config = vim.tbl_deep_extend("force", default, opts or {})

    ns = vim.api.nvim_create_namespace("precognition")
    au = vim.api.nvim_create_augroup("precognition", { clear = true })

    -- This is a test with basic functionality, definitely should be moved out of the setup function and into
    -- functions that the public methods can call.

    M.show()
end

return M
