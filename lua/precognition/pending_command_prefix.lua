---@class Precognition.PendingCommandPrefix
---@field private _raw string | nil
local PendingCommandPrefix = {}
PendingCommandPrefix.__index = PendingCommandPrefix

local M = {}

local targeted_motion_order = { f = 1, F = 2, t = 3, T = 4 }

---@return Precognition.PendingCommandPrefix
function M.new()
    return setmetatable({ _raw = nil }, PendingCommandPrefix)
end

---@param raw string | nil
---@return Precognition.PendingCommandPrefix
function M.from_raw(raw)
    return setmetatable({ _raw = raw }, PendingCommandPrefix)
end

---@param mode string
---@return boolean
function M.is_supported_mode(mode)
    return mode == "n" or mode == "v" or mode == "V" or mode == "\22" or mode:sub(1, 2) == "no"
end

---@param mode string
---@return boolean
function M.is_operator_pending_mode(mode)
    return mode:sub(1, 2) == "no"
end

---@param raw string | nil
---@return string
local function without_leading_count(raw)
    return ((raw or ""):gsub("^%d+", ""))
end

---@return string | nil
function PendingCommandPrefix:raw()
    return self._raw
end

function PendingCommandPrefix:reset()
    self._raw = nil
end

---@return boolean
function PendingCommandPrefix:is_text_object_prefix()
    local command = without_leading_count(self._raw)
    return command:match("^[vdcy]?%d*[ia]$") ~= nil or command == "i" or command == "a"
end

---@return boolean
function PendingCommandPrefix:is_operator_only_prefix()
    local command = without_leading_count(self._raw)
    return command:match("^[dcy]%d*$") ~= nil
end

---@return boolean
function PendingCommandPrefix:normal_motion_hints_visible()
    return not self:is_text_object_prefix() and not self:pending_targeted_motion_key()
end

---@return boolean
function PendingCommandPrefix:text_object_hints_visible()
    return self:is_text_object_prefix()
end

---@return string | nil
function PendingCommandPrefix:text_object_prefix()
    if self:is_text_object_prefix() then
        return self._raw
    end
    return nil
end

---@param targeted_motions? table<string, Precognition.TargetedMotionFunction>
---@return string | nil
function PendingCommandPrefix:pending_targeted_motion_key(targeted_motions)
    local command = without_leading_count(self._raw)
    local key = command:match("^[dcy]?%d*([fFtT])$") or command:match("^([fFtT])$")
    if not key then
        return nil
    end
    if targeted_motions and not targeted_motions[key] then
        return nil
    end
    return key
end

---@return string | nil
function PendingCommandPrefix:effective_motion_count_prefix()
    if not self._raw then
        return nil
    end
    local operator_count, command = self._raw:match("^(%d+)([dcy].*)$")
    if command then
        local motion_count = command:match("^[dcy](%d+)$")
        if motion_count then
            return tostring((tonumber(operator_count) or 1) * (tonumber(motion_count) or 1))
        end
        return operator_count
    end
    local leading = self._raw:match("^%d+")
    if leading then
        return leading
    end
    local operator_pending = self._raw:match("^[dcy](%d+)$")
    return operator_pending
end

---@return boolean
function PendingCommandPrefix:should_defer_redraw()
    local command = without_leading_count(self._raw)
    return command == "i" or command == "a"
end

---@param key string
---@param mode string
---@return { changed: boolean, defer_redraw: boolean }
function PendingCommandPrefix:handle_key(key, mode)
    local previous = self._raw

    if key == "\27" or key == "\3" or not M.is_supported_mode(mode) then
        self._raw = nil
    elseif key:match("^%d$") and not M.is_operator_pending_mode(mode) then
        if key ~= "0" or self._raw then
            self._raw = (self._raw or "") .. key
        end
    elseif key:match("^%d$") and self._raw and self._raw:match("^%d*[dcy]%d*$") then
        self._raw = self._raw .. key
    elseif
        (mode == "v" or mode == "V" or mode == "\22" or M.is_operator_pending_mode(mode)) and (key == "i" or key == "a")
    then
        self._raw = (self._raw and self._raw:match("^[dcy]%d*$")) and (self._raw .. key) or key
    elseif key:match("^[dcy]$") and not self:is_text_object_prefix() then
        self._raw = (self._raw or "") .. key
    elseif
        targeted_motion_order[key] and (not self._raw or self._raw:match("^%d+$") or self._raw:match("^%d?[dcy]%d*$"))
    then
        self._raw = (self._raw or "") .. key
    elseif (key == "i" or key == "a") and self._raw then
        self._raw = self._raw .. key
    else
        self._raw = nil
    end

    return { changed = self._raw ~= previous, defer_redraw = self:should_defer_redraw() }
end

M.targeted_motion_order = targeted_motion_order

return M
