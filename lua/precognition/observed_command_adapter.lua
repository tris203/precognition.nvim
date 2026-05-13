local ObservedCommandState = require("precognition.observed_command_state")

---@class Precognition.ObservedCommandAdapterCallbacks
---@field is_visible fun(): boolean
---@field mark_dirty fun()
---@field redraw fun(preserve_visual: boolean?)
---@field current_mode fun(): string

---@class Precognition.ObservedCommandAdapter
---@field private _state Precognition.ObservedCommandState
---@field private _callbacks Precognition.ObservedCommandAdapterCallbacks
---@field private _redraw_scheduled boolean
local Adapter = {}
Adapter.__index = Adapter

local M = {}
local current

---@param callbacks Precognition.ObservedCommandAdapterCallbacks
---@return Precognition.ObservedCommandAdapter
function M.new(callbacks)
    current = setmetatable({
        _state = ObservedCommandState.new(),
        _callbacks = callbacks,
        _redraw_scheduled = false,
    }, Adapter)
    return current
end

---@return Precognition.ObservedCommandAdapter | nil
function M.current()
    return current
end

function Adapter:reset()
    self._state:reset()
    self._redraw_scheduled = false
end

---@return Precognition.ObservedCommandSnapshot
function Adapter:snapshot()
    return self._state:snapshot()
end

---@param cmd_prefix string
function Adapter:_schedule_text_object_repaint(cmd_prefix)
    if self._redraw_scheduled then
        return
    end

    self._redraw_scheduled = true
    vim.schedule(function()
        self._redraw_scheduled = false
        if not self._callbacks.is_visible() then
            return
        end

        local mode = self._callbacks.current_mode()
        if not M.is_visual_mode(mode) and not ObservedCommandState.is_operator_pending_mode(mode) then
            return
        end
        if self._state:snapshot().raw ~= cmd_prefix then
            return
        end

        self._callbacks.mark_dirty()
        self._callbacks.redraw(true)
    end)
end

---@param key string
---@param mode string
function Adapter:observe_key(key, mode)
    local input = self._state:handle_key(key, mode)
    if not self._callbacks.is_visible() or not input.changed then
        return
    end

    self._callbacks.mark_dirty()
    if input.defer_redraw then
        local scheduled_prefix = input.scheduled_prefix
        if not scheduled_prefix then
            return
        end
        self._callbacks.redraw(true)
        self:_schedule_text_object_repaint(scheduled_prefix)
    else
        self._callbacks.redraw()
    end
end

---@param keys string
---@param mode string
function Adapter:observe_keys(keys, mode)
    for key in keys:gmatch(".") do
        self:observe_key(key, mode)
    end
end

---@param mode string
---@return boolean
function M.is_visual_mode(mode)
    return mode == "v" or mode == "V" or mode == "\22"
end

M.is_supported_mode = ObservedCommandState.is_supported_mode
M.is_operator_pending_mode = ObservedCommandState.is_operator_pending_mode

return M
