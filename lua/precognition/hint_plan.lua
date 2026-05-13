local HintPriority = require("precognition.hint_priority")
local MotionCount = require("precognition.motion_count")
local PendingCommandPrefix = require("precognition.pending_command_prefix")

local M = {}

---@class Precognition.HintPlanContext
---@field bufnr integer
---@field mode string
---@field disabled_fts string[]
---@field command_state Precognition.ObservedCommandSnapshot
---@field current_line string
---@field cursorcol integer
---@field line_len integer
---@field motions Precognition.MotionsAdapter
---@field config Precognition.Config
---@field charsearch table | nil

---@class Precognition.PlannedGutterHint
---@field hint string
---@field loc integer
---@field text string

---@class Precognition.HintPlan
---@field skip_render boolean do not render UI
---@field message string | nil user-facing reason to report
---@field kind "none" | "normal" | "text_object"
---@field inline_hints Precognition.InlineHintCandidate[] | nil
---@field gutter_hints Precognition.GutterHints | nil
---@field planned_gutter_hints Precognition.PlannedGutterHint[] | nil
---@field text_object_anchors Precognition.TextObjectAnchor[] | nil
---@field text_object_ranges Precognition.RangePreview[] | nil

---@param motions Precognition.MotionsAdapter
---@return Precognition.GutterHints
function M.gutter_hints(motions)
    return {
        G = motions.file_end(),
        gg = motions.file_start(),
        PrevParagraph = motions.prev_paragraph_line(),
        NextParagraph = motions.next_paragraph_line(),
    }
end

---@param config Precognition.Config
---@param gutter_hints Precognition.GutterHints
---@return Precognition.PlannedGutterHint[]
function M.prioritize_gutter_hints(config, gutter_hints)
    local priority = HintPriority.new()
    for hint, loc in pairs(gutter_hints) do
        local opts = config.gutterHints[hint]
        if opts then
            priority:add(loc, opts.prio, hint)
        end
    end

    local planned = {}
    for loc, prioritized_hint in pairs(priority:hints_by_destination()) do
        local hint = prioritized_hint.hint
        local opts = config.gutterHints[hint]
        if opts then
            table.insert(planned, {
                hint = hint,
                loc = loc,
                text = opts.text,
            })
        end
    end
    return planned
end

---@param candidates Precognition.InlineHintCandidate[]
---@param config Precognition.Config
---@param inline_hints Precognition.VirtLine
local function add_static_inline_hints(candidates, config, inline_hints)
    for hint, col in pairs(inline_hints) do
        local opts = config.hints[hint]
        if opts then
            table.insert(candidates, {
                label = opts.text or hint,
                col = col,
                prio = opts.prio,
            })
        end
    end
end

---@param candidates Precognition.InlineHintCandidate[]
---@param ctx Precognition.HintPlanContext
local function add_targeted_motion_hints(candidates, ctx)
    if not ctx.config.targetedMotionHints.enabled then
        return
    end
    if not ctx.motions.targeted_motions then
        return
    end

    local prefix = ctx.command_state.prefix
    local pending_targeted_motion = prefix:pending_targeted_motion_key(ctx.motions.targeted_motions)

    local count = pending_targeted_motion and MotionCount.parse(prefix:effective_motion_count_prefix())
        or ctx.command_state.motion_count

    local function add_source(motion_key, targeted_motion)
        for _, hint in ipairs(targeted_motion(ctx.current_line, ctx.cursorcol, ctx.line_len, count)) do
            local hl_group
            if not pending_targeted_motion then
                hl_group = "PrecognitionTargetedMotion"
            end
            table.insert(candidates, {
                label = pending_targeted_motion and hint.label or motion_key,
                col = hint.col,
                prio = hint.prio or ctx.config.targetedMotionHints.prio,
                hl_group = hl_group,
            })
        end
    end

    if pending_targeted_motion then
        add_source(pending_targeted_motion, ctx.motions.targeted_motions[pending_targeted_motion])
        return
    end

    local motion_keys = {}
    for motion_key in pairs(ctx.motions.targeted_motions) do
        table.insert(motion_keys, motion_key)
    end
    table.sort(motion_keys, function(a, b)
        local a_order = PendingCommandPrefix.targeted_motion_order[a] or (100 + a:byte())
        local b_order = PendingCommandPrefix.targeted_motion_order[b] or (100 + b:byte())
        if a_order ~= b_order then
            return a_order < b_order
        end
        return a < b
    end)

    for _, motion_key in ipairs(motion_keys) do
        local targeted_motion = ctx.motions.targeted_motions[motion_key]
        add_source(motion_key, targeted_motion)
    end
end

---@param candidates Precognition.InlineHintCandidate[]
---@param ctx Precognition.HintPlanContext
local function add_repeat_targeted_motion_hints(candidates, ctx)
    if not ctx.config.targetedMotionHints.enabled then
        return
    end
    if not ctx.motions.repeat_targeted_motion_hints then
        return
    end
    if not ctx.command_state.repeat_target_character_hints_visible then
        return
    end

    for _, hint in
        ipairs(
            ctx.motions.repeat_targeted_motion_hints(
                ctx.current_line,
                ctx.cursorcol,
                ctx.line_len,
                ctx.command_state.motion_count,
                ctx.charsearch
            )
        )
    do
        table.insert(candidates, {
            label = hint.label,
            col = hint.col,
            prio = hint.prio or ctx.config.targetedMotionHints.prio + 1,
        })
    end
end

---@param ctx Precognition.HintPlanContext
---@return Precognition.HintPlan
function M.build(ctx)
    local prefix = ctx.command_state.prefix
    if ctx.mode:sub(1, 1) == "i" then
        return { skip_render = true, message = nil, kind = "none" }
    end

    if require("precognition.utils").is_blacklisted_buffer(ctx.bufnr, ctx.disabled_fts) then
        return { skip_render = true, message = nil, kind = "none" }
    end

    local message = nil
    local effective_count_prefix = ctx.command_state.effective_motion_count_prefix
    if ctx.command_state.count_suppressed then
        return { skip_render = true, message = "Count is too high, not showing hints", kind = "none" }
    end

    if prefix:text_object_hints_visible() then
        local anchors, ranges = ctx.motions.text_object_hints(
            prefix:text_object_prefix() or "",
            ctx.current_line,
            ctx.cursorcol,
            ctx.line_len
        )
        return {
            skip_render = false,
            message = message,
            kind = "text_object",
            text_object_anchors = anchors,
            text_object_ranges = ranges,
        }
    end

    local counted_destinations =
        MotionCount:destinations(ctx.motions, ctx.current_line, ctx.cursorcol, ctx.line_len, effective_count_prefix)
    local gutter_hints = M.gutter_hints(ctx.motions)
    local pending_targeted_motion = prefix:pending_targeted_motion_key(ctx.motions.targeted_motions)
    local inline_hints = {
        Caret = ctx.motions.line_start_non_whitespace(ctx.current_line, ctx.cursorcol, ctx.line_len),
        w = counted_destinations.w,
        e = counted_destinations.e,
        b = counted_destinations.b,
        W = counted_destinations.W,
        E = counted_destinations.E,
        B = counted_destinations.B,
        MatchingPair = ctx.motions.matching_pair(ctx.current_line, ctx.cursorcol, ctx.line_len)(
            ctx.current_line,
            ctx.cursorcol,
            ctx.line_len
        ),
        Dollar = ctx.motions.line_end(ctx.current_line, ctx.cursorcol, ctx.line_len),
        Zero = 1,
    }
    local inline_candidates = {}
    if prefix:normal_motion_hints_visible() then
        add_static_inline_hints(inline_candidates, ctx.config, inline_hints)
    end
    add_targeted_motion_hints(inline_candidates, ctx)
    add_repeat_targeted_motion_hints(inline_candidates, ctx)
    return {
        skip_render = false,
        message = message,
        kind = "normal",
        inline_hints = inline_candidates,
        gutter_hints = gutter_hints,
        planned_gutter_hints = M.prioritize_gutter_hints(ctx.config, gutter_hints),
    }
end

return M
