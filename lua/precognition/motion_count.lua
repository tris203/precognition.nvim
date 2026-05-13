local M = {}

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

---@param prefix? string
---@return boolean
function M:is_suppressed(prefix)
    return M.parse(prefix) > 100
end

---@param count integer
---@param motion function
---@param str string
---@param cursorcol integer
---@param linelen integer
---@return integer
function M:destination(count, motion, str, cursorcol, linelen)
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
function M:destinations(motions, line, cursorcol, linelen, count_prefix)
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

    local count = M.parse(count_prefix)
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
