local compat = require("precognition.compat")
local defaults = require("precognition.defaults")
local HintPlan = require("precognition.hint_plan")
local MotionCount = require("precognition.motion_count")
local PendingCommandPrefix = require("precognition.pending_command_prefix")
local Renderer = require("precognition.renderer")
local VirtLine = require("precognition.virt_line")

local M = {}

---@class Precognition.HintOpts
---@field text string
---@field prio number

---@class Precognition.TargetedMotionHintConfig
---@field enabled boolean
---@field prio number

---@alias Precognition.PlaceLoc integer

---@class (exact) Precognition.HintConfig
---@field w Precognition.HintOpts
---@field e Precognition.HintOpts
---@field b Precognition.HintOpts
---@field W Precognition.HintOpts
---@field E Precognition.HintOpts
---@field B Precognition.HintOpts
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
---@field targetedMotionHighlightColor vim.api.keyset.highlight
---@field textObjectHighlightColors vim.api.keyset.highlight[]
---@field targetedMotionHints Precognition.TargetedMotionHintConfig
---@field hints Precognition.HintConfig
---@field gutterHints Precognition.GutterHintConfig
---@field disabled_fts string[]

---@class Precognition.PartialConfig
---@field debounceMs? integer
---@field startVisible? boolean
---@field showBlankVirtLine? boolean
---@field highlightFullVirtLine? boolean
---@field highlightColor? vim.api.keyset.highlight
---@field targetedMotionHighlightColor? vim.api.keyset.highlight
---@field textObjectHighlightColors? vim.api.keyset.highlight[]
---@field targetedMotionHints? Precognition.TargetedMotionHintConfig
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

---@class Precognition.InlineHintCandidate
---@field label string
---@field col integer
---@field prio number
---@field hl_group? string

---@class Precognition.TargetedMotionHint
---@field label string
---@field col integer
---@field prio? number

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

---@type Precognition.Config
local default = defaults.config

---@type Precognition.Config
local config = vim.deepcopy(default)

---@type boolean
local dirty -- whether a redraw is needed
---@type boolean
local visible = false

---@type integer
local au = vim.api.nvim_create_augroup("precognition", { clear = true })
---@type Precognition.MotionCount
local motion_count = MotionCount.new()
---@type Precognition.Renderer
local renderer = Renderer.new()
---@type string | nil
local pending_command_prefix
---@type Precognition.PendingCommandPrefix
local prefix = PendingCommandPrefix.new()
---@type boolean
local handling_key = false
---@type boolean
local redraw_scheduled = false
---@type boolean
local restoring_visual_selection = false
---@type boolean
local was_count_suppressed = false

---@type function?
local cached_on_cursor_moved

local function clear_hints(bufnr)
    renderer:clear(bufnr)
    dirty = true
end

---@param marks Precognition.VirtLine | Precognition.InlineHintCandidate[] | nil
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@return table
local function build_virt_line(marks, line_len, extra_padding, min_width)
    return VirtLine.build(config, marks, line_len, extra_padding, min_width)
end

---@param gutter_hints Precognition.PlannedGutterHint[]
---@param bufnr? integer -- buffer number
---@return nil
local function apply_gutter_hints(gutter_hints, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    for hint, _ in pairs(config.gutterHints) do
        renderer:clear_gutter_hint(hint)
    end

    for _, gutter_hint in ipairs(gutter_hints) do
        renderer:render_gutter_hint(gutter_hint.hint, gutter_hint.loc, bufnr, gutter_hint.text)
    end
end

---@param cur_line string
---@param charcol number
---@param offset number
---@return number
---@return string
---@return number
local function calculate_visual_cursorcol(cur_line, charcol, offset)
    return VirtLine.calculate_visual_cursorcol(cur_line, charcol, offset)
end

---@param mode string
---@return boolean
local function is_visual_mode(mode)
    return mode == "v" or mode == "V" or mode == "\22"
end

local function display_marks()
    local utils = require("precognition.utils")
    local bufnr = vim.api.nvim_get_current_buf()
    local cursorline = vim.fn.line(".")
    if cursorline < 1 or cursorline > vim.api.nvim_buf_line_count(bufnr) then
        return
    end
    local cursorcol, cur_line, tab_width =
        calculate_visual_cursorcol(vim.api.nvim_get_current_line(), vim.fn.charcol("."), vim.fn.indent(cursorline))
    if renderer:extmark() and not dirty then
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

    local motions = require("precognition.motions").get_motions()
    local active_prefix = prefix
    if pending_command_prefix ~= prefix:raw() then
        active_prefix = PendingCommandPrefix.from_raw(pending_command_prefix)
    end
    local plan = HintPlan.build({
        bufnr = bufnr,
        mode = vim.api.nvim_get_mode().mode,
        disabled_fts = config.disabled_fts,
        pending_command_prefix = pending_command_prefix,
        prefix = active_prefix,
        current_line = cur_line,
        cursorcol = cursorcol,
        line_len = line_len,
        motion_count = motion_count,
        motions = motions,
        config = config,
        charsearch = vim.fn.getcharsearch(),
    })
    local count_suppressed = motion_count:is_suppressed(active_prefix:effective_motion_count_prefix())
    if plan.message and (not count_suppressed or not was_count_suppressed) then
        vim.notify_once(plan.message, vim.log.levels.INFO)
    end
    was_count_suppressed = count_suppressed

    if plan.skip_render then
        clear_hints(bufnr)
        return
    end

    if plan.kind == "text_object" then
        add_inlay_hint_padding()
        utils.add_multibyte_padding(cur_line, extra_padding, line_len)

        local min_width
        if config.highlightFullVirtLine then
            local win_info = vim.fn.getwininfo(vim.fn.win_getid())
            local textoff = win_info and win_info[1] and win_info[1].textoff or 0
            min_width = vim.api.nvim_win_get_width(0) - textoff
        end

        local virt_line = VirtLine.build_text_object(
            config,
            plan.text_object_anchors or {},
            line_len,
            extra_padding,
            min_width,
            plan.text_object_ranges
        )

        if config.showBlankVirtLine or (virt_line and #virt_line > 0) then
            renderer:render_inline_hint_virt_line(bufnr, cursorline, virt_line)
        end

        dirty = false
        return
    end

    -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
    -- get char offsets for more complex motions.

    add_inlay_hint_padding()
    --multicharacter padding

    utils.add_multibyte_padding(cur_line, extra_padding, line_len)

    local min_width
    if config.highlightFullVirtLine then
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())
        local textoff = win_info and win_info[1] and win_info[1].textoff or 0
        min_width = vim.api.nvim_win_get_width(0) - textoff
    end
    ---@type Precognition.InlineHintCandidate[]
    local inline_hints = assert(plan.inline_hints)
    local virt_line = build_virt_line(inline_hints, line_len, extra_padding, min_width)

    -- TODO: can we add indent lines to the virt line to match indent-blankline or similar (if installed)?

    if vim.wo.wrap then
        local win_info = vim.fn.getwininfo(vim.fn.win_getid())
        local textoff = win_info and win_info[1] and win_info[1].textoff or 0
        virt_line = VirtLine.fit_to_wrap(virt_line, cursorcol, vim.api.nvim_win_get_width(0) - textoff)
    end

    -- create (or overwrite) the extmark
    if config.showBlankVirtLine or (virt_line and #virt_line > 0) then
        renderer:render_inline_hint_virt_line(bufnr, cursorline, virt_line)
    end
    apply_gutter_hints(plan.planned_gutter_hints or {})

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

    renderer:flush(vim.api.nvim_get_current_buf())
end

---@param cmd_prefix string
local function schedule_visual_text_object_repaint(cmd_prefix)
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
        if not is_visual_mode(mode) and not PendingCommandPrefix.is_operator_pending_mode(mode) then
            return
        end
        if pending_command_prefix ~= cmd_prefix then
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
        local text_object_selection_finished = is_visual_mode(mode) and prefix:text_object_hints_visible()
        if not is_visual_mode(mode) or text_object_selection_finished then
            pending_command_prefix = nil
            prefix:reset()
        end
        local buf = ev and ev.buf or vim.api.nvim_get_current_buf()
        renderer:clear_inline_hint_if_moved(buf, vim.api.nvim_win_get_cursor(0)[1])
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
    if not PendingCommandPrefix.is_supported_mode(mode) then
        return
    end

    handling_key = true
    local ok, err = xpcall(function()
        if not visible then
            motion_count:reset()
            pending_command_prefix = nil
            prefix:reset()
            return
        end

        local count_changed = motion_count:handle_key(key, mode)
        local input = prefix:handle_key(key, mode)
        motion_count:set_prefix(prefix:effective_motion_count_prefix())
        pending_command_prefix = prefix:raw()
        if visible and (count_changed or input.changed) then
            dirty = true
            if input.defer_redraw then
                local scheduled_prefix = pending_command_prefix
                if not scheduled_prefix then
                    return
                end
                redraw_marks(true)
                schedule_visual_text_object_repaint(scheduled_prefix)
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
    prefix:reset()
    redraw_scheduled = false
    cached_on_cursor_moved = nil
    was_count_suppressed = false
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

--- Return whether automatic hints are currently visible.
---@return boolean
function M.is_visible()
    return visible
end

local function setup_highlights()
    vim.api.nvim_set_hl(0, "PrecognitionHighlight", config.highlightColor)
    vim.api.nvim_set_hl(0, "PrecognitionTargetedMotion", config.targetedMotionHighlightColor)
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
    if opts.targetedMotionHighlightColor then
        config.targetedMotionHighlightColor = opts.targetedMotionHighlightColor
    end
    if opts.textObjectHighlightColors then
        config.textObjectHighlightColors = opts.textObjectHighlightColors
    end

    renderer:reset()
    au = vim.api.nvim_create_augroup("precognition", { clear = true })
    cached_on_cursor_moved = nil
    motion_count:reset()
    pending_command_prefix = nil
    prefix:reset()
    handling_key = false
    redraw_scheduled = false
    restoring_visual_selection = false
    was_count_suppressed = false

    setup_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Set precognition.nvim's highlights up",
        group = au,
        callback = setup_highlights,
    })

    create_command()

    vim.on_key(on_key, renderer:ns())
    if config.startVisible then
        M.show()
    end
end

return M
