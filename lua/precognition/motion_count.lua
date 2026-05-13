---@class Precognition.MotionCount
---@field private _prefix string | nil
---MotionCount keeps numeric count semantics separate from typed command state.
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

---@return integer
function MotionCount:count()
    return M.parse(self._prefix)
end

---@param prefix? string
---@return integer
function MotionCount:count_for_prefix(prefix)
    return M.parse(prefix or self._prefix)
end

---@param prefix? string
---@return boolean
function MotionCount:is_suppressed(prefix)
    return self:count_for_prefix(prefix) > 100
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
---@param count_prefix? string
---@return table<string, Precognition.PlaceLoc>
function MotionCount:destinations(motions, line, cursorcol, linelen, count_prefix)
    if self:is_suppressed(count_prefix) then
        return {
            w = 0,
            e = 0,
            b = 0,
            W = 0,
            E = 0,
            B = 0,
        }
    end

    local count = self:count_for_prefix(count_prefix)
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
