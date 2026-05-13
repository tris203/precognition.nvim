local MotionCount = require("precognition.motion_count")
local PendingCommandPrefix = require("precognition.pending_command_prefix")

---@class Precognition.ObservedCommandSnapshot
---@field raw string | nil
---@field prefix Precognition.PendingCommandPrefix
---@field effective_motion_count_prefix string | nil
---@field motion_count integer
---@field count_suppressed boolean
---@field normal_motion_hints_visible boolean
---@field text_object_hints_visible boolean
---@field text_object_prefix string | nil
---@field repeat_target_character_hints_visible boolean

---@class Precognition.ObservedCommandState
---@field private _prefix Precognition.PendingCommandPrefix
local ObservedCommandState = {}
ObservedCommandState.__index = ObservedCommandState

local M = {}

---@return Precognition.ObservedCommandState
function M.new()
    return setmetatable({ _prefix = PendingCommandPrefix.new() }, ObservedCommandState)
end

function ObservedCommandState:reset()
    self._prefix:reset()
end

---@param key string
---@param mode string
---@return { changed: boolean, defer_redraw: boolean, scheduled_prefix: string | nil }
function ObservedCommandState:handle_key(key, mode)
    local input = self._prefix:handle_key(key, mode)
    return {
        changed = input.changed,
        defer_redraw = input.defer_redraw,
        scheduled_prefix = self._prefix:raw(),
    }
end

---@return Precognition.ObservedCommandSnapshot
function ObservedCommandState:snapshot()
    local effective_motion_count_prefix = self._prefix:effective_motion_count_prefix()
    return {
        raw = self._prefix:raw(),
        prefix = self._prefix,
        effective_motion_count_prefix = effective_motion_count_prefix,
        motion_count = MotionCount.parse(effective_motion_count_prefix),
        count_suppressed = MotionCount.parse(effective_motion_count_prefix) > 100,
        normal_motion_hints_visible = self._prefix:normal_motion_hints_visible(),
        text_object_hints_visible = self._prefix:text_object_hints_visible(),
        text_object_prefix = self._prefix:text_object_prefix(),
        repeat_target_character_hints_visible = self._prefix:raw() == nil,
    }
end

M.is_supported_mode = PendingCommandPrefix.is_supported_mode
M.is_operator_pending_mode = PendingCommandPrefix.is_operator_pending_mode
M.targeted_motion_order = PendingCommandPrefix.targeted_motion_order

return M
