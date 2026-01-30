---@type Precognition.MotionsAdapter
local M = {}

local sim = require("precognition.motions.sim_motions.sim")

---@type string?
local last_str
---@type integer?
local last_cursorcol
---@type Precognition.VirtLine?
local last_result

---@param str string
---@param cursorcol integer
---@return Precognition.VirtLine
local function check_cached(str, cursorcol)
    if last_str ~= str or last_cursorcol ~= cursorcol or not last_result then
        last_str = str
        last_cursorcol = cursorcol
        last_result = sim.check(str, cursorcol)
    end

    return last_result
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.line_start_non_whitespace(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).Caret
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.line_end(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).Dollar
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.next_word_boundary(str, cursorcol, _linelen, big_word)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.W
    end

    return result.w
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@param _recursive boolean?
---@return Precognition.PlaceLoc
function M.end_of_word(str, cursorcol, _linelen, big_word, _recursive)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.E
    end

    return result.e
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@param big_word boolean
---@return Precognition.PlaceLoc
function M.prev_word_boundary(str, cursorcol, _linelen, big_word)
    local result = check_cached(str, cursorcol)

    if big_word then
        return result.B
    end

    return result.b
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.matching_bracket(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).MatchingPair
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return Precognition.PlaceLoc
function M.matching_comment(str, cursorcol, _linelen)
    return check_cached(str, cursorcol).MatchingPair
end

---@param str string
---@param cursorcol integer
---@param _linelen integer
---@return function
function M.matching_pair(str, cursorcol, _linelen)
    local result = check_cached(str, cursorcol)

    if result.MatchingPair and result.MatchingPair > 0 then
        return function()
            return result.MatchingPair
        end
    end

    return function()
        return 0
    end
end

return M
