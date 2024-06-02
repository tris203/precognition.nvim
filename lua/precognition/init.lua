local M = {}

---@class Precognition.HintOpts
---@field text string
---@field prio integer

---@alias Precognition.PlaceLoc integer

---@class (exact) Precognition.HintConfig
---@field w Precognition.HintOpts
---@field e Precognition.HintOpts
---@field b Precognition.HintOpts
---@field Zero Precognition.HintOpts
---@field MatchingPair Precognition.HintOpts
---@field Caret Precognition.HintOpts
---@field Dollar Precognition.HintOpts

---@class Precognition.GutterHintConfig
---@field G Precognition.HintOpts
---@field gg Precognition.HintOpts
---@field PrevParagraph Precognition.HintOpts
---@field NextParagraph Precognition.HintOpts

---@class Precognition.Config
---@field startVisible boolean
---@field showBlankVirtLine boolean
---@field highlightColor vim.api.keyset.highlight
---@field hints Precognition.HintConfig
---@field gutterHints Precognition.GutterHintConfig

---@class Precognition.PartialConfig
---@field startVisible? boolean
---@field showBlankVirtLine? boolean
---@field highlightColor? vim.api.keyset.highlight
---@field hints? Precognition.HintConfig
---@field gutterHints? Precognition.GutterHintConfig

---@class (exact) Precognition.VirtLine
---@field w Precognition.PlaceLoc
---@field e Precognition.PlaceLoc
---@field b Precognition.PlaceLoc
---@field Zero Precognition.PlaceLoc
---@field Caret Precognition.PlaceLoc
---@field Dollar Precognition.PlaceLoc
---@field MatchingPair Precognition.PlaceLoc

---@class (exact) Precognition.GutterHints
---@field G Precognition.PlaceLoc
---@field gg Precognition.PlaceLoc
---@field PrevParagraph Precognition.PlaceLoc
---@field NextParagraph Precognition.PlaceLoc

---@class Precognition.ExtraPadding
---@field start integer
---@field length integer

---@type Precognition.HintConfig
local defaultHintConfig = {
    Caret = { text = "^", prio = 2 },
    Dollar = { text = "$", prio = 1 },
    MatchingPair = { text = "%", prio = 5 },
    Zero = { text = "0", prio = 1 },
    w = { text = "w", prio = 10 },
    b = { text = "b", prio = 9 },
    e = { text = "e", prio = 8 },
    W = { text = "W", prio = 7 },
    B = { text = "B", prio = 6 },
    E = { text = "E", prio = 5 },
}

---@type Precognition.Config
local default = {
    startVisible = true,
    showBlankVirtLine = true,
    highlightColor = { link = "Comment" },
    hints = defaultHintConfig,
    gutterHints = {
        G = { text = "G", prio = 10 },
        gg = { text = "gg", prio = 9 },
        PrevParagraph = { text = "{", prio = 8 },
        NextParagraph = { text = "}", prio = 8 },
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

---@param marks Precognition.VirtLine
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding
---@return table
local function build_virt_line(marks, line_len, extra_padding)
    if not marks then
        return {}
    end
    if line_len == 0 then
        return {}
    end
    local virt_line = {}
    local line_table = require("precognition.utils").create_pad_array(line_len, " ")

    for mark, loc in pairs(marks) do
        local hint = config.hints[mark].text or mark
        local prio = config.hints[mark].prio or 0
        local col = loc

        if col ~= 0 and prio > 0 then
            local existing = line_table[col]
            if existing == " " and existing ~= hint then
                line_table[col] = hint
            else -- if the character is not a space, then we need to check the prio
                local existing_key
                for key, value in pairs(config.hints) do
                    if value.text == existing then
                        existing_key = key
                        break
                    end
                end
                if existing ~= " " and config.hints[mark].prio > config.hints[existing_key].prio then
                    line_table[col] = hint
                end
            end
        end
    end

    if #extra_padding > 0 then
        for _, padding in ipairs(extra_padding) do
            line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
        end
    end

    local line = table.concat(line_table)
    if line:match("^%s+$") then
        return {}
    end
    table.insert(virt_line, { line, "PrecognitionHighlight" })
    return virt_line
end

---@return Precognition.GutterHints
local function build_gutter_hints()
    local vm = require("precognition.vertical_motions")
    ---@type Precognition.GutterHints
    local gutter_hints = {
        G = vm.file_end(),
        gg = vm.file_start(),
        PrevParagraph = vm.prev_paragraph_line(),
        NextParagraph = vm.next_paragraph_line(),
    }
    return gutter_hints
end

---@param gutter_hints Precognition.GutterHints
---@param bufnr? integer -- buffer number
---@return nil
local function apply_gutter_hints(gutter_hints, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if require("precognition.utils").is_blacklisted_buffer(bufnr) then
        return
    end

    local gutter_table = {}
    for hint, loc in pairs(gutter_hints) do
        if gutter_signs_cache[hint] then
            vim.fn.sign_unplace(gutter_group, { id = gutter_signs_cache[hint].id })
            gutter_signs_cache[hint] = nil
        end

        local prio = config.gutterHints[hint].prio

        -- Build table of valid and priorised gutter hints.
        if loc ~= 0 and loc ~= nil and prio > 0 then
            local existing = gutter_table[loc]
            if not existing or existing.prio < prio then
                gutter_table[loc] = { hint = hint, prio = prio }
            end
        end
    end

    -- Only render valid and prioritised gutter hints.
    for loc, data in pairs(gutter_table) do
        local hint = data.hint
        local sign_name = gutter_name_prefix .. hint
        vim.fn.sign_define(sign_name, {
            text = config.gutterHints[hint].text,
            texthl = "PrecognitionHighlight",
        })
        local ok, res = pcall(vim.fn.sign_place, 0, gutter_group, sign_name, bufnr, {
            lnum = loc,
            priority = 100,
        })
        if ok then
            gutter_signs_cache[hint] = { line = loc, id = res }
        end
        if not ok and loc ~= 0 then
            vim.notify_once(
                "Failed to place sign: " .. hint .. " at line " .. loc .. vim.inspect(res),
                vim.log.levels.WARN
            )
        end
    end
end

local function display_marks()
    local bufnr = vim.api.nvim_get_current_buf()
    if require("precognition.utils").is_blacklisted_buffer(bufnr) then
        return
    end
    local cursorline = vim.fn.line(".")
    local cursorcol = vim.fn.charcol(".")
    if extmark and not dirty then
        return
    end

    local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
    local cur_line = vim.api.nvim_get_current_line():gsub("\t", string.rep(" ", tab_width))
    local line_len = vim.fn.strcharlen(cur_line)
    ---@type Precognition.ExtraPadding[]
    local extra_padding = {}
    -- local after_cursor = vim.fn.strcharpart(cur_line, cursorcol + 1)
    -- local before_cursor = vim.fn.strcharpart(cur_line, 0, cursorcol - 1)
    -- local before_cursor_rev = string.reverse(before_cursor)
    -- local under_cursor = vim.fn.strcharpart(cur_line, cursorcol - 1, 1)

    local hm = require("precognition.horizontal_motions")

    -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
    -- get char offsets for more complex motions.
    --
    ---@type Precognition.VirtLine
    local virtual_line_marks = {
        Caret = hm.line_start_non_whitespace(cur_line, cursorcol, line_len),
        w = hm.next_word_boundary(cur_line, cursorcol, line_len, false),
        e = hm.end_of_word(cur_line, cursorcol, line_len, false),
        b = hm.prev_word_boundary(cur_line, cursorcol, line_len, false),
        W = hm.next_word_boundary(cur_line, cursorcol, line_len, true),
        E = hm.end_of_word(cur_line, cursorcol, line_len, true),
        B = hm.prev_word_boundary(cur_line, cursorcol, line_len, true),
        MatchingPair = hm.matching_pair(cur_line, cursorcol, line_len)(cur_line, cursorcol, line_len),
        Dollar = hm.line_end(cur_line, cursorcol, line_len),
        Zero = 1,
    }

    --multicharacter padding

    require("precognition.utils").add_multibyte_padding(cur_line, extra_padding, line_len)

    local virt_line = build_virt_line(virtual_line_marks, line_len, extra_padding)

    -- TODO: can we add indent lines to the virt line to match indent-blankline or similar (if installed)?

    -- create (or overwrite) the extmark
    if config.showBlankVirtLine or (virt_line and #virt_line > 0) then
        extmark = vim.api.nvim_buf_set_extmark(0, ns, cursorline - 1, 0, {
            id = extmark, -- reuse the same extmark if it exists
            virt_lines = { virt_line },
        })
    end
    apply_gutter_hints(build_gutter_hints())

    dirty = false
end

local function on_cursor_moved(ev)
    local buf = ev and ev.buf or vim.api.nvim_get_current_buf()
    if extmark then
        local ext = vim.api.nvim_buf_get_extmark_by_id(buf, ns, extmark, {
            details = true,
        })
        if ext and ext[1] ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
            vim.api.nvim_buf_del_extmark(0, ns, extmark)
            extmark = nil
        end
    end
    dirty = true
    display_marks()
end

local function on_insert_enter(ev)
    if extmark then
        vim.api.nvim_buf_del_extmark(ev.buf, ns, extmark)
        extmark = nil
    end
    dirty = true
end

local function on_buf_edit()
    apply_gutter_hints(build_gutter_hints())
end

local function on_buf_leave(ev)
    vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
    extmark = nil
    gutter_signs_cache = {}
    vim.fn.sign_unplace(gutter_group)
    dirty = true
end

--- Show the hints until the next keypress or CursorMoved event
function M.peek()
    display_marks()

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
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = au,
        callback = on_cursor_moved,
    })

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = au,
        callback = on_insert_enter,
    })

    display_marks()
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
    if opts.highlightColor then
        config.highlightColor = opts.highlightColor
    end

    ns = vim.api.nvim_create_namespace("precognition")
    au = vim.api.nvim_create_augroup("precognition", { clear = true })

    local hl_name = "PrecognitionHighlight"
    vim.api.nvim_set_hl(0, hl_name, config.highlightColor)

    if config.startVisible then
        M.show()
    end
end

-- This is for testing purposes, since we need to
-- access these variables from outside the module
-- but we don't want to expose them to the user
local state = {
    build_virt_line = function()
        return build_virt_line
    end,
    build_gutter_hints = function()
        return build_gutter_hints
    end,
    on_cursor_moved = function()
        return on_cursor_moved
    end,
    extmark = function()
        return extmark
    end,
    gutter_group = function()
        return gutter_group
    end,
    ns = function()
        return ns
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
