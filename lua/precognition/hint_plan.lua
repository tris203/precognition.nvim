local HintPriority = require("precognition.hint_priority")

local M = {}

---@class Precognition.HintPlanContext
---@field bufnr integer
---@field mode string
---@field disabled_fts string[]
---@field pending_command_prefix string | nil
---@field current_line string
---@field cursorcol integer
---@field line_len integer
---@field motion_count Precognition.MotionCount
---@field motions Precognition.MotionsAdapter
---@field config Precognition.Config

---@class Precognition.PlannedGutterHint
---@field hint string
---@field loc integer
---@field text string

---@class Precognition.HintPlan
---@field suppressed boolean
---@field message string | nil
---@field kind "none" | "normal" | "text_object"
---@field inline_hints Precognition.VirtLine | nil
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
        priority:add(loc, config.gutterHints[hint].prio, hint)
    end

    local planned = {}
    for loc, prioritized_hint in pairs(priority:hints_by_destination()) do
        local hint = prioritized_hint.hint
        table.insert(planned, {
            hint = hint,
            loc = loc,
            text = config.gutterHints[hint].text,
        })
    end
    return planned
end

---@param ctx Precognition.HintPlanContext
---@return Precognition.HintPlan
function M.build(ctx)
    if ctx.mode:sub(1, 1) == "i" then
        return { suppressed = true, message = nil, kind = "none" }
    end

    if require("precognition.utils").is_blacklisted_buffer(ctx.bufnr, ctx.disabled_fts) then
        return { suppressed = true, message = nil, kind = "none" }
    end

    if ctx.motion_count:is_operator_prefix(ctx.pending_command_prefix) then
        return { suppressed = true, message = nil, kind = "none" }
    end

    local message = nil
    if ctx.motion_count:is_suppressed() then
        message = "Count is too high, not showing hints"
    end

    if ctx.motion_count:is_text_object_prefix(ctx.pending_command_prefix) then
        local anchors, ranges = ctx.motions.text_object_hints(
            ctx.pending_command_prefix or "",
            ctx.current_line,
            ctx.cursorcol,
            ctx.line_len
        )
        return {
            suppressed = false,
            message = message,
            kind = "text_object",
            text_object_anchors = anchors,
            text_object_ranges = ranges,
        }
    end

    local counted_destinations = ctx.motion_count:destinations(ctx.motions, ctx.current_line, ctx.cursorcol, ctx.line_len)
    local gutter_hints = M.gutter_hints(ctx.motions)
    return {
        suppressed = false,
        message = message,
        kind = "normal",
        inline_hints = {
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
        },
        gutter_hints = gutter_hints,
        planned_gutter_hints = M.prioritize_gutter_hints(ctx.config, gutter_hints),
    }
end

return M
