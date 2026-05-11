---@class Precognition.MotionCount
---@field private _prefix string | nil
---MotionCount keeps numeric counts and pending commands separate: handle_key updates self._prefix,
---which only contains the numeric count, while callers pass pending_command_prefix through
---handle_input as the authoritative full Vim command string (count + operator/text-object).
local MotionCount = {}
MotionCount.__index = MotionCount

local M = {}

---@param mode string
---@return boolean
function MotionCount.is_supported_prefix_mode(_self, mode)
    return mode == "n" or mode == "v" or mode == "V" or mode == "\22" or mode:sub(1, 2) == "no"
end

---@param mode string
---@return boolean
function MotionCount.is_operator_pending_mode(_self, mode)
    return mode:sub(1, 2) == "no"
end

---@param prefix string | nil
---@return boolean
function MotionCount.is_text_object_prefix(_self, prefix)
    if not prefix then
        return false
    end
    local without_count = prefix:gsub("^%d+", "")
    return without_count:match("^[vdcy]?[ia]$") ~= nil or without_count == "i" or without_count == "a"
end

---@param prefix string | nil
---@return boolean
function MotionCount.is_operator_prefix(_self, prefix)
    if not prefix then
        return false
    end
    local without_count = prefix:gsub("^%d+", "")
    return without_count:match("^[dcy]$") ~= nil
end

---@return Precognition.MotionCount
function M.new()
    return setmetatable({ _prefix = nil }, MotionCount)
end

---@param motionstring string | nil
---@return integer
function M.parse(motionstring)
    if motionstring == nil then
        return 1
    end

    motionstring = motionstring:gsub("<%d+>", "")

    local count = motionstring:match("^%d+")
    return tonumber(count) or 1
end

---@return string | nil
function MotionCount:prefix()
    return self._prefix
end

---@param value string | nil
function MotionCount:set_prefix(value)
    self._prefix = value
end

function MotionCount:reset()
    self._prefix = nil
end

---@param key string
---@param mode string
---@return boolean changed
function MotionCount:handle_key(key, mode)
    local previous = self._prefix
    if not self:is_supported_prefix_mode(mode) then
        self._prefix = nil
    elseif key:match("^%d$") and not self:is_operator_pending_mode(mode) then
        -- Ignore leading 0: it is the "0" motion, not a count.
        if key ~= "0" or self._prefix then
            self._prefix = (self._prefix or "") .. key
        end
    else
        self._prefix = nil
    end

    return self._prefix ~= previous
end

---@class Precognition.MotionCountInput
---@field pending_command_prefix string | nil
---@field prefix_changed boolean
---@field defer_redraw boolean

---@param key string
---@param mode string
---@param pending_command_prefix string | nil
---@return Precognition.MotionCountInput
function MotionCount:handle_input(key, mode, pending_command_prefix)
    local prev_pending_command_prefix = pending_command_prefix
    local defer_redraw = false
    local count_changed = self:handle_key(key, mode)

    if key == "\27" or key == "\3" then
        pending_command_prefix = nil
    elseif key:match("^%d$") and not self:is_operator_pending_mode(mode) then
        -- Ignore leading 0: it is the "0" motion, not a count.
        if key ~= "0" or pending_command_prefix then
            pending_command_prefix = (pending_command_prefix or "") .. key
        end
    elseif
        (mode == "v" or mode == "V" or mode == "\22" or self:is_operator_pending_mode(mode))
        and (key == "i" or key == "a")
    then
        pending_command_prefix = key
        defer_redraw = true
    elseif key:match("^[dcy]$") and not self:is_text_object_prefix(pending_command_prefix) then
        pending_command_prefix = (pending_command_prefix or "") .. key
    elseif (key == "i" or key == "a") and pending_command_prefix then
        pending_command_prefix = pending_command_prefix .. key
    else
        pending_command_prefix = nil
    end

    return {
        pending_command_prefix = pending_command_prefix,
        prefix_changed = count_changed or pending_command_prefix ~= prev_pending_command_prefix,
        defer_redraw = defer_redraw,
    }
end

---@return integer
function MotionCount:count()
    return M.parse(self._prefix)
end

---@return boolean
function MotionCount:is_suppressed()
    return self:count() > 100
end

---@return { count: integer, suppressed: boolean }
function MotionCount:current()
    local count = self:count()
    return {
        count = count,
        suppressed = self:is_suppressed(),
    }
end

---@param count integer
---@param motion function
---@param str string
---@param cursorcol integer
---@param linelen integer
---@return integer
function MotionCount.destination(_self, count, motion, str, cursorcol, linelen)
    local ret = cursorcol
    local out_of_bounds = false
    for _ = 1, count do
        if ret <= 0 or ret > linelen then
            out_of_bounds = true
            break
        end
        ret = motion(str, ret, linelen)
    end
    if out_of_bounds then
        return 0
    end
    return ret
end

---@param motions Precognition.MotionsAdapter
---@param line string
---@param cursorcol integer
---@param linelen integer
---@return table<string, Precognition.PlaceLoc>
function MotionCount:destinations(motions, line, cursorcol, linelen)
    if self:is_suppressed() then
        return {
            w = 0,
            e = 0,
            b = 0,
            W = 0,
            E = 0,
            B = 0,
        }
    end

    local count = self:count()
    return {
        w = self:destination(count, function(str, col, len)
            return motions.next_word_boundary(str, col, len, false)
        end, line, cursorcol, linelen),
        e = self:destination(count, function(str, col, len)
            return motions.end_of_word(str, col, len, false)
        end, line, cursorcol, linelen),
        b = self:destination(count, function(str, col, len)
            return motions.prev_word_boundary(str, col, len, false)
        end, line, cursorcol, linelen),
        W = self:destination(count, function(str, col, len)
            return motions.next_word_boundary(str, col, len, true)
        end, line, cursorcol, linelen),
        E = self:destination(count, function(str, col, len)
            return motions.end_of_word(str, col, len, true)
        end, line, cursorcol, linelen),
        B = self:destination(count, function(str, col, len)
            return motions.prev_word_boundary(str, col, len, true)
        end, line, cursorcol, linelen),
    }
end

return M
