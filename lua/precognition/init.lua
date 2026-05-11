local compat = require("precognition.compat")
local HintPriority = require("precognition.hint_priority")
local MotionCount = require("precognition.motion_count")

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
---@field debounceMs integer
---@field startVisible boolean
---@field showBlankVirtLine boolean
---@field highlightFullVirtLine boolean
---@field highlightColor vim.api.keyset.highlight
---@field textObjectHighlightColors vim.api.keyset.highlight[]
---@field hints Precognition.HintConfig
---@field gutterHints Precognition.GutterHintConfig
---@field disabled_fts string[]

---@class Precognition.PartialConfig
---@field debounceMs? integer
---@field startVisible? boolean
---@field showBlankVirtLine? boolean
---@field highlightFullVirtLine? boolean
---@field highlightColor? vim.api.keyset.highlight
---@field textObjectHighlightColors? vim.api.keyset.highlight[]
---@field hints? Precognition.HintConfig
---@field gutterHints? Precognition.GutterHintConfig

---@class (exact) Precognition.VirtLine
---@field w? Precognition.PlaceLoc
---@field e? Precognition.PlaceLoc
---@field b? Precognition.PlaceLoc
---@field W? Precognition.PlaceLoc
---@field E? Precognition.PlaceLoc
---@field B? Precognition.PlaceLoc
---@field Zero Precognition.PlaceLoc
---@field Caret Precognition.PlaceLoc
---@field Dollar Precognition.PlaceLoc
---@field MatchingPair Precognition.PlaceLoc

---@class Precognition.TextObjectAnchor
---@field label string
---@field col integer
---@field prio integer

---@class Precognition.RangePreview
---@field start_col integer
---@field end_col integer
---@field depth integer

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
    debounceMs = 0,
    startVisible = true,
    showBlankVirtLine = true,
    highlightFullVirtLine = false,
    highlightColor = { link = "Comment" },
    textObjectHighlightColors = {
        { link = "DiffText" },
        { link = "DiffChange" },
        { link = "Visual" },
    },
    hints = defaultHintConfig,
    gutterHints = {
        G = { text = "G", prio = 10 },
        gg = { text = "gg", prio = 9 },
        PrevParagraph = { text = "{", prio = 8 },
        NextParagraph = { text = "}", prio = 8 },
    },
    disabled_fts = {
        "startify",
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
---@type integer
local range_ns = vim.api.nvim_create_namespace("precognition_text_object_ranges")
---@type string
local gutter_group = "precognition_gutter"
---@type Precognition.MotionCount
local motion_count = MotionCount.new()
---@type string | nil
local pending_command_prefix
---@type boolean
local handling_key = false
---@type boolean
local redraw_scheduled = false
---@type boolean
local restoring_visual_selection = false

---@type function?
local cached_on_cursor_moved

local function clear_hints(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if extmark then
        vim.api.nvim_buf_del_extmark(bufnr, ns, extmark)
        extmark = nil
    end
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, range_ns, 0, -1)
    vim.fn.sign_unplace(gutter_group)
    gutter_signs_cache = {}
    dirty = true
end

---@param anchors Precognition.TextObjectAnchor[]
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@param ranges? Precognition.RangePreview[]
---@return table
local function build_text_object_virt_line(anchors, line_len, extra_padding, min_width, ranges)
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

    if #extra_padding > 0 then
        for _, padding in ipairs(extra_padding) do
            line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
        end
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

---@param marks Precognition.VirtLine
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@return table
local function build_virt_line(marks, line_len, extra_padding, min_width)
    local utils = require("precognition.utils")
    if not marks then
        return {}
    end
    if line_len == 0 then
        return {}
    end
    local virt_line = {}
    local line_table = utils.create_pad_array(line_len, " ")

    local priority = HintPriority.new()
    for mark, loc in pairs(marks) do
        local updated_hint = priority:add(loc, config.hints[mark].prio, config.hints[mark].text or mark)
        if updated_hint and loc > 0 and loc <= line_len then
            line_table[loc] = updated_hint
        end
    end

    if #extra_padding > 0 then
        for _, padding in ipairs(extra_padding) do
            line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
        end
    end

    local line = table.concat(line_table)
    if min_width and vim.fn.strdisplaywidth(line) < min_width then
        line = line .. string.rep(" ", min_width - vim.fn.strdisplaywidth(line))
    end
    if line:match("^%s+$") then
        if min_width and config.showBlankVirtLine then
            return { { line, "PrecognitionHighlight" } }
        else
            return {}
        end
    end
    table.insert(virt_line, { line, "PrecognitionHighlight" })
    return virt_line
end

---@return Precognition.GutterHints
local function build_gutter_hints()
    local motions = require("precognition.motions").get_motions()
    ---@type Precognition.GutterHints
    local gutter_hints = {
        G = motions.file_end(),
        gg = motions.file_start(),
        PrevParagraph = motions.prev_paragraph_line(),
        NextParagraph = motions.next_paragraph_line(),
    }
    return gutter_hints
end

---@param hint string
---@param loc integer
---@param bufnr integer
local function place_gutter_hint(hint, loc, bufnr)
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
        return
    end
    if loc ~= 0 then
        vim.notify_once("Failed to place sign: " .. hint .. " at line " .. loc .. vim.inspect(res), vim.log.levels.WARN)
    end
end

---@param gutter_hints Precognition.GutterHints
---@param bufnr? integer -- buffer number
---@return nil
local function apply_gutter_hints(gutter_hints, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if require("precognition.utils").is_blacklisted_buffer(bufnr, config.disabled_fts) then
        return
    end

    local priority = HintPriority.new()
    for hint, loc in pairs(gutter_hints) do
        if gutter_signs_cache[hint] then
            vim.fn.sign_unplace(gutter_group, { id = gutter_signs_cache[hint].id })
            gutter_signs_cache[hint] = nil
        end

        priority:add(loc, config.gutterHints[hint].prio, hint)
    end

    -- Only render valid and prioritised gutter hints.
    for loc, prioritized_hint in pairs(priority:hints_by_destination()) do
        place_gutter_hint(prioritized_hint.hint, loc, bufnr)
    end
end

---@param cur_line string
---@param charcol number
---@param offset number
---@return number
---@return string
---@return number
local function calculate_visual_cursorcol(cur_line, charcol, offset)
    --matches all leading spaces and tabs in any order
    local leading_whitespace = string.match(cur_line, "^([ \t]*)")
    -- offset would be the equivalent space characters occupied by the whitespace
    -- vim.fn.indent gives us this value
    local cursorcol = charcol - #leading_whitespace + offset
    local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
    local sanitised_line = cur_line:gsub("\t", string.rep(" ", tab_width))
    return cursorcol, sanitised_line, tab_width
end

---@param prefix string | nil
---@return boolean
local function is_text_object_prefix(prefix)
    if not prefix then
        return false
    end
    local without_count = prefix:gsub("^%d+", "")
    return without_count:match("^[vdcy]?[ia]$") ~= nil or without_count == "i" or without_count == "a"
end

---@param prefix string | nil
---@return boolean
local function is_operator_prefix(prefix)
    if not prefix then
        return false
    end
    local without_count = prefix:gsub("^%d+", "")
    return without_count:match("^[dcy]$") ~= nil
end

---@param mode string
---@return boolean
local function is_visual_mode(mode)
    return mode == "v" or mode == "V" or mode == "\22"
end

local function display_marks()
    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
        return
    end

    local utils = require("precognition.utils")
    if motion_count:is_suppressed() then
        vim.notify_once("Count is too high, not showing hints", vim.log.levels.INFO)
    end

    local bufnr = vim.api.nvim_get_current_buf()
    if utils.is_blacklisted_buffer(bufnr, config.disabled_fts) then
        return
    end
    local cursorline = vim.fn.line(".")
    if cursorline < 1 or cursorline > vim.api.nvim_buf_line_count(bufnr) then
        return
    end
    local cursorcol, cur_line, tab_width =
        calculate_visual_cursorcol(vim.api.nvim_get_current_line(), vim.fn.charcol("."), vim.fn.indent(cursorline))
    if extmark and not dirty then
        return
    end

    local line_len = vim.fn.strcharlen(cur_line)

    ---@type Precognition.ExtraPadding[]
    local extra_padding = {}

    local function add_inlay_hint_padding()
        if compat.inlay_hints_enabled({ bufnr = 0 }) then
            local inlays_hints = compat.get_inlay_hints({
                bufnr = 0,
                range = {
                    start = { line = cursorline - 1, character = 0 },
                    ["end"] = { line = cursorline - 1, character = line_len - 1 },
                },
            })

            for _, hint in ipairs(inlays_hints) do
                local length, ws_offset = utils.calc_ws_offset(hint, tab_width, vim.api.nvim_get_current_line())
                table.insert(extra_padding, { start = ws_offset, length = length })
            end
        end
    end

    if is_operator_prefix(pending_command_prefix) then
        clear_hints()
        return
    end

    if is_text_object_prefix(pending_command_prefix) then
        add_inlay_hint_padding()
        utils.add_multibyte_padding(cur_line, extra_padding, line_len)

        local min_width
        if config.highlightFullVirtLine then
            local win_info = vim.fn.getwininfo(vim.fn.win_getid())
            local textoff = win_info and win_info[1] and win_info[1].textoff or 0
            min_width = vim.api.nvim_win_get_width(0) - textoff
        end

        local motions = require("precognition.motions").get_motions()
        local anchors, ranges = motions.text_object_hints(pending_command_prefix, cur_line, cursorcol, line_len)
        local virt_line = build_text_object_virt_line(anchors, line_len, extra_padding, min_width, ranges)

        if config.showBlankVirtLine or (virt_line and #virt_line > 0) then
            extmark = vim.api.nvim_buf_set_extmark(0, ns, cursorline - 1, 0, {
                id = extmark,
                virt_lines = { virt_line },
            })
        end

        dirty = false
        return
    end

    local motions = require("precognition.motions").get_motions()
    local counted_destinations = motion_count:destinations(motions, cur_line, cursorcol, line_len)

    -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
    -- get char offsets for more complex motions.

    ---@type Precognition.VirtLine
    local virtual_line_marks = {
        Caret = motions.line_start_non_whitespace(cur_line, cursorcol, line_len),
        w = counted_destinations.w,
        e = counted_destinations.e,
        b = counted_destinations.b,
        W = counted_destinations.W,
        E = counted_destinations.E,
        B = counted_destinations.B,
        MatchingPair = motions.matching_pair(cur_line, cursorcol, line_len)(cur_line, cursorcol, line_len),
        Dollar = motions.line_end(cur_line, cursorcol, line_len),
        Zero = 1,
    }

    add_inlay_hint_padding()
    --multicharacter padding

    utils.add_multibyte_padding(cur_line, extra_padding, line_len)

    local min_width
    if config.highlightFullVirtLine then
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())
        local textoff = win_info and win_info[1] and win_info[1].textoff or 0
        min_width = vim.api.nvim_win_get_width(0) - textoff
    end
    local virt_line = build_virt_line(virtual_line_marks, line_len, extra_padding, min_width)

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

local function restore_visual_selection(win, bufnr, cursor, visual_start)
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= bufnr then
        return
    end
    if vim.api.nvim_get_current_win() ~= win or not is_visual_mode(vim.api.nvim_get_mode().mode) then
        return
    end

    local was_handling_key = handling_key
    handling_key = true
    restoring_visual_selection = true
    local ok, err = pcall(function()
        vim.cmd("normal! o")
        vim.api.nvim_win_set_cursor(0, { visual_start[2], visual_start[3] - 1 })
        vim.cmd("normal! o")
        vim.api.nvim_win_set_cursor(0, cursor)
    end)
    restoring_visual_selection = false
    handling_key = was_handling_key
    if not ok then
        error(err)
    end
end

---@param preserve_visual boolean?
---@param fn fun()
local function preserving_visual_selection(preserve_visual, fn)
    if not preserve_visual or not is_visual_mode(vim.api.nvim_get_mode().mode) then
        fn()
        return
    end

    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local visual_start = vim.fn.getpos("v")
    fn()
    restore_visual_selection(win, bufnr, cursor, visual_start)
end

---@param preserve_visual boolean?
local function redraw_marks(preserve_visual)
    preserving_visual_selection(preserve_visual, display_marks)

    -- nvim__redraw is experimental, but we intentionally use it here to flush this buffer's hints.
    vim.api.nvim__redraw({ buf = vim.api.nvim_get_current_buf(), flush = true })
end

---@param prefix string
local function schedule_visual_text_object_repaint(prefix)
    if redraw_scheduled then
        return
    end

    redraw_scheduled = true
    vim.schedule(function()
        redraw_scheduled = false
        if not visible then
            return
        end

        local mode = vim.api.nvim_get_mode().mode
        if not is_visual_mode(mode) and not motion_count:is_operator_pending_mode(mode) then
            return
        end
        if pending_command_prefix ~= prefix then
            return
        end

        dirty = true
        redraw_marks(true)
    end)
end

local function on_insert_enter(ev)
    clear_hints(ev.buf)
end

---@param draw fun()
local function cursor_moved_handler(draw)
    return function(ev)
        if restoring_visual_selection then
            return
        end

        local mode = vim.api.nvim_get_mode().mode
        local text_object_selection_finished = is_visual_mode(mode) and is_text_object_prefix(pending_command_prefix)
        if not is_visual_mode(mode) or text_object_selection_finished then
            pending_command_prefix = nil
        end
        local buf = ev and ev.buf or vim.api.nvim_get_current_buf()
        if extmark then
            local ext = vim.api.nvim_buf_get_extmark_by_id(buf, ns, extmark, {
                details = true,
            })
            if ext and ext[1] ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
                vim.api.nvim_buf_del_extmark(buf, ns, extmark)
                extmark = nil
            end
        end
        dirty = true
        if is_visual_mode(mode) and not text_object_selection_finished then
            preserving_visual_selection(true, draw)
        else
            draw()
        end
    end
end

local function on_buf_leave(ev)
    clear_hints(ev.buf)
end

local function create_command()
    local subcommands = {
        peek = M.peek,
        toggle = M.toggle,
        show = M.show,
        hide = M.hide,
    }

    local function execute(args)
        local cmd_args = args.fargs
        local subcmd = cmd_args[1]
        if not subcmd then
            return
        end
        if subcommands[subcmd] then
            subcommands[subcmd]()
        else
            vim.notify("Invalid subcommand: " .. subcmd, vim.log.levels.ERROR, {
                title = "Precognition",
            })
        end
    end

    local function complete(_line, _len, _arg_lead)
        return vim.tbl_keys(subcommands)
    end

    vim.api.nvim_create_user_command("Precognition", execute, {
        nargs = "*",
        complete = complete,
    })
end

local function make_draw()
    local prev_line
    local draw = display_marks
    if config.debounceMs > 0 then
        local debounced = require("precognition.utils").debounce_trailing(function()
            if not visible then
                return
            end
            display_marks()
        end, config.debounceMs)
        draw = function(...)
            local line = vim.api.nvim_win_get_cursor(0)[1]
            if line == prev_line then
                display_marks()
            else
                prev_line = line
            end
            debounced(...)
        end
    end

    return draw
end

local function get_on_cursor_moved()
    if not cached_on_cursor_moved then
        cached_on_cursor_moved = cursor_moved_handler(make_draw())
    end

    return cached_on_cursor_moved
end

---@param key string
local function on_key(key)
    if handling_key then
        return
    end

    local mode = vim.api.nvim_get_mode().mode
    if not motion_count:is_supported_prefix_mode(mode) then
        return
    end

    handling_key = true
    local ok, err = xpcall(function()
        if not visible then
            motion_count:reset()
            pending_command_prefix = nil
            return
        end

        local prev_pending_command_prefix = pending_command_prefix
        local defer_redraw = false
        local count_changed = motion_count:handle_key(key, mode)

        if key == "\27" or key == "\3" then
            pending_command_prefix = nil
        elseif key:match("^%d$") and not motion_count:is_operator_pending_mode(mode) then
            if key == "0" and not pending_command_prefix then
                pending_command_prefix = nil
            else
                pending_command_prefix = (pending_command_prefix or "") .. key
            end
        elseif (is_visual_mode(mode) or motion_count:is_operator_pending_mode(mode)) and (key == "i" or key == "a") then
            pending_command_prefix = key
            defer_redraw = true
        elseif key:match("^[dcy]$") and not is_text_object_prefix(pending_command_prefix) then
            pending_command_prefix = (pending_command_prefix or "") .. key
        elseif (key == "i" or key == "a") and pending_command_prefix then
            pending_command_prefix = pending_command_prefix .. key
        else
            pending_command_prefix = nil
        end

        local prefix_changed = count_changed or pending_command_prefix ~= prev_pending_command_prefix
        if visible and prefix_changed then
            dirty = true
            if defer_redraw then
                local prefix = pending_command_prefix
                if not prefix then
                    return
                end
                redraw_marks(true)
                schedule_visual_text_object_repaint(prefix)
            else
                redraw_marks()
            end
        end
    end, debug.traceback)

    handling_key = false
    if not ok then
        error(err)
    end
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
    cached_on_cursor_moved = nil

    -- clear and redraw the hints when the cursor moves
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = au,
        callback = get_on_cursor_moved(),
    })

    -- clear the extmark entirely when leaving a buffer (hints should only show in current buffer)
    vim.api.nvim_create_autocmd("BufLeave", {
        group = au,
        callback = on_buf_leave,
    })

    -- clear extmarks and gutter hints when the cursor moves in insert mode
    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = au,
        callback = on_insert_enter,
    })
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = au,
        callback = on_insert_enter,
    })

    display_marks()
end

--- Disable automatic showing of hints
function M.hide()
    visible = false
    motion_count:reset()
    pending_command_prefix = nil
    redraw_scheduled = false
    cached_on_cursor_moved = nil
    clear_hints()
    au = vim.api.nvim_create_augroup("precognition", { clear = true })
end

--- Toggle automatic showing of hints
--- with return value indicating the visible state
function M.toggle()
    if visible then
        M.hide()
    else
        M.show()
    end
    return visible
end

local function setup_highlights()
    vim.api.nvim_set_hl(0, "PrecognitionHighlight", config.highlightColor)
    vim.api.nvim_set_hl(0, "PrecognitionTextObjectHint", { link = "PrecognitionHighlight" })
    vim.api.nvim_set_hl(0, "PrecognitionTextObjectAvailability", { link = "PrecognitionHighlight" })
    for index, highlight in ipairs(config.textObjectHighlightColors) do
        vim.api.nvim_set_hl(0, "PrecognitionTextObjectRange" .. index, highlight)
    end
end

---@param opts Precognition.PartialConfig
function M.setup(opts)
    opts = opts or {}
    if opts.startVisible == false then
        M.hide()
    end

    config = vim.tbl_deep_extend("force", vim.deepcopy(default), opts)
    if opts.highlightColor then
        config.highlightColor = opts.highlightColor
    end
    if opts.textObjectHighlightColors then
        config.textObjectHighlightColors = opts.textObjectHighlightColors
    end

    ns = vim.api.nvim_create_namespace("precognition")
    range_ns = vim.api.nvim_create_namespace("precognition_text_object_ranges")
    au = vim.api.nvim_create_augroup("precognition", { clear = true })
    cached_on_cursor_moved = nil
    motion_count:reset()
    pending_command_prefix = nil
    handling_key = false
    redraw_scheduled = false
    restoring_visual_selection = false

    setup_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Set precognition.nvim's highlights up",
        group = au,
        callback = setup_highlights,
    })

    create_command()

    vim.on_key(on_key, ns)
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
    calculate_visual_cursorcol = function()
        return calculate_visual_cursorcol
    end,
    build_gutter_hints = function()
        return build_gutter_hints
    end,
    on_cursor_moved = function()
        return get_on_cursor_moved()
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
    range_ns = function()
        return range_ns
    end,
    default_hint_config = function()
        return defaultHintConfig
    end,
    is_visible = function()
        return visible
    end,
    set_motion_count_prefix = function()
        return function(cmd)
            motion_count:set_prefix(cmd)
        end
    end,
    motion_count_prefix = function()
        return motion_count:prefix()
    end,
    set_pending_command_prefix = function()
        return function(cmd)
            pending_command_prefix = cmd
        end
    end,
    pending_command_prefix = function()
        return pending_command_prefix
    end,
    build_text_object_hints = function()
        return require("precognition.motions").get_motions().text_object_hints
    end,
    on_key = function()
        return on_key
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
