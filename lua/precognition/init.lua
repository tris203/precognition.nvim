local M = {}

---@alias SupportedHints "'^'" | "'b'" | "'w'" | "'$'"
---@alias SupportedGutterHints "G" | "gg" | "{" | "}"

---@class Precognition.Config
---@field startVisible boolean
---@field hints { SupportedHints: string }
---@field gutterHints { SupportedGutterHints: string }

---@class Precognition.PartialConfig
---@field startVisible? boolean
---@field hints? { SupportedHints: string }
---@field gutterHints? { SupportedGutterHints: string }

---@alias Precognition.VirtLine { [ SupportedHints]: integer | nil }
---@alias Precognition.GutterHints { [ SupportedGutterHints]: integer | nil }

---@type Precognition.Config
local default = {
    startVisible = true,
    hints = {
        ["^"] = "^",
        ["$"] = "$",
        ["w"] = "w",
        -- ["W"] = "W",
        ["b"] = "b",
        ["e"] = "e",
        -- ["ge"] = "ge", -- should we support multi-char / multi-byte hints?
    },
    gutterHints = {
        ["G"] = "G",
        ["gg"] = "gg",
        ["{"] = " {",
        ["}"] = " }",
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
---@type string
local gutter_name_prefix = "precognition_gutter_" -- prefix for gutter signs object naame
---@type {SupportedGutterHints: { line: integer, id: integer }} -- cache for gutter signs
local gutter_signs_cache = {} -- cache for gutter signs

---@type integer
local au = vim.api.nvim_create_augroup("precognition", { clear = true })
---@type integer
local ns = vim.api.nvim_create_namespace("precognition")
---@type string
local gutter_group = "precognition_gutter"

---@param char string
---@return integer
local function char_class(char)
    local byte = string.byte(char)

    if byte and byte < 0x100 then
        if char == " " or char == "\t" or char == "\0" then
            return 0 -- whitespace
        end
        if char == "_" or char:match("%w") then
            return 2 -- word character
        end
        return 1 -- other
    end

    return 1 -- scary unicode edge cases go here
end

---@param str string
---@param start integer
---@return integer | nil
local function next_word_boundary(str, start)
    local offset = start - 1
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
    if (offset + 1) > len then
        return nil
    end

    return offset + 1
end

---@param str string
---@param start integer
---@return integer | nil
local function end_of_word(str, start)
    local len = vim.fn.strcharlen(str)
    if start >= len then
        return nil
    end
    local offset = start - 1
    local char = vim.fn.strcharpart(str, offset, 1)
    local c_class = char_class(char)
    local next_char_class = char_class(vim.fn.strcharpart(str, offset + 1, 1))
    local rev_offset

    if c_class ~= 0 and next_char_class ~= 0 then
        while char_class(char) == c_class and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset, 1)
        end
    end

    if c_class == 0 or next_char_class == 0 then
        local next_word_start = next_word_boundary(str, offset)
        if next_word_start then
            rev_offset = end_of_word(str, next_word_start + 1)
        end
    end

    if rev_offset ~= nil and rev_offset <= 0 then
        return nil
    end

    if rev_offset ~= nil then
        return rev_offset
    end
    return offset
end

---@param str string
---@param start integer
---@return integer | nil
local function prev_word_boundary(str, start)
    local len = vim.fn.strcharlen(str)
    local offset = len - start + 1
    str = string.reverse(str)
    local char = vim.fn.strcharpart(str, offset - 1, 1)
    local c_class = char_class(char)

    if c_class == 0 then
        while char_class(char) == 0 and offset <= len do
            offset = offset + 1
            char = vim.fn.strcharpart(str, offset, 1)
        end
    end

    c_class = char_class(char)
    while char_class(char) == c_class and offset <= len do
        offset = offset + 1
        char = vim.fn.strcharpart(str, offset, 1)
        --if remaining string is whitespace, return nil_wrap
        local remaining = string.sub(str, offset)
        if remaining:match("^%s*$") and #remaining > 0 then
            return nil
        end
    end

    if offset == nil or (len - offset + 1) > len or (len - offset + 1) <= 0 then
        return nil
    end
    return len - offset + 1
end

---@param marks Precognition.VirtLine
---@param line_len integer
---@return table
local function build_virt_line(marks, line_len)
    local virt_line = {}
    local line = string.rep(" ", line_len)

    for mark, loc in pairs(marks) do
        local hint = config.hints[mark] or mark
        local col = loc

        if col ~= nil then
            line = line:sub(1, col - 1) .. hint .. line:sub(col + 1)
        end
    end
    table.insert(virt_line, { line, "Comment" })

    return virt_line
end

---@param buf integer == bufnr
---@return Precognition.GutterHints
local function build_gutter_hints(buf)
    local gutter_hints = {
        ["G"] = vim.api.nvim_buf_line_count(buf),
        ["gg"] = 1,
        ["{"] = vim.fn.search("^\\s*$", "bn"),
        ["}"] = vim.fn.search("^\\s*$", "n"),
    }

    return gutter_hints
end

---@param gutter_hints Precognition.GutterHints
---@return nil
local function apply_gutter_hints(gutter_hints)
    for hint, loc in pairs(gutter_hints) do
        if config.gutterHints[hint] then
            if gutter_signs_cache[hint] then
                vim.fn.sign_unplace(
                    gutter_group,
                    { id = gutter_signs_cache[hint].id }
                )
                gutter_signs_cache[hint] = nil
            end
            vim.fn.sign_define(gutter_name_prefix .. hint, {
                text = config.gutterHints[hint],
                texthl = "Comment",
            })
            gutter_signs_cache[hint] = {
                loc = loc,
                id = vim.fn.sign_place(
                    0,
                    gutter_group,
                    gutter_name_prefix .. hint,
                    0,
                    {
                        lnum = loc,
                        priority = 100,
                    }
                ),
            }
        end
    end
end

local function on_cursor_hold()
    local cursorline, cursorcol = unpack(vim.api.nvim_win_get_cursor(0))
    cursorcol = cursorcol + 1
    if extmark and not dirty then
        return
    end

    local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
    local cur_line =
        vim.api.nvim_get_current_line():gsub("\t", string.rep(" ", tab_width))
    local line_len = vim.fn.strcharlen(cur_line)
    -- local after_cursor = vim.fn.strcharpart(cur_line, cursorcol + 1)
    -- local before_cursor = vim.fn.strcharpart(cur_line, 0, cursorcol - 1)
    -- local before_cursor_rev = string.reverse(before_cursor)
    -- local under_cursor = vim.fn.strcharpart(cur_line, cursorcol - 1, 1)

    -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
    -- get char offsets for more complex motions.

    local virt_line = build_virt_line({
        ["w"] = next_word_boundary(cur_line, cursorcol),
        ["e"] = end_of_word(cur_line, cursorcol),
        ["b"] = prev_word_boundary(cur_line, cursorcol),
        ["^"] = cur_line:find("%S") or 0,
        ["$"] = line_len,
    }, line_len)

    -- TODO: can we add indent lines to the virt line to match indent-blankline or similar (if installed)?

    -- create (or overwrite) the extmark
    extmark = vim.api.nvim_buf_set_extmark(0, ns, cursorline - 1, 0, {
        id = extmark, -- reuse the same extmark if it exists
        virt_lines = { virt_line },
    })

    apply_gutter_hints(build_gutter_hints(0))

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

local function on_buf_edit()
    apply_gutter_hints(build_gutter_hints(0))
end

local function on_buf_leave(ev)
    vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
    extmark = nil
    gutter_signs_cache = {}
    vim.fn.sign_unplace(gutter_group)
    dirty = true
    on_buf_edit()
end

--- Show the hints until the next keypress or CursorMoved event
function M.peek()
    on_cursor_hold()

    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
        buffer = vim.api.nvim_get_current_buf(),
        once = true,
        group = au,
        callback = on_buf_leave,
    })
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

    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = au,
        callback = on_buf_edit,
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

    on_cursor_hold()
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
    vim.fn.sign_unplace(gutter_group)
    gutter_signs_cache = {}
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
    if config.startVisible then
        M.show()
    end
end

-- This is for testing purposes, since we need to
-- access these variables from outside the module
-- but we don't want to expose them to the user
local state = {
    char_class = function()
        return char_class
    end,
    next_word_boundary = function()
        return next_word_boundary
    end,
    prev_word_boundary = function()
        return prev_word_boundary
    end,
    end_of_word = function()
        return end_of_word
    end,
    build_virt_line = function()
        return build_virt_line
    end,
    build_gutter_hints = function()
        return build_gutter_hints
    end,
}

setmetatable(M, {
    __index = function(_, k)
        if state[k] then
            return state[k]()
        end
    end,
})

return M
