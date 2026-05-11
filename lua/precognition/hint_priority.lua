local M = {}

---@class Precognition.PrioritizedHint
---@field priority integer
---@field hint any

---@class Precognition.HintPriority
---@field private _hints_by_destination table<integer, Precognition.PrioritizedHint>
local HintPriority = {}
HintPriority.__index = HintPriority

---@return Precognition.HintPriority
function M.new()
    return setmetatable({ _hints_by_destination = {} }, HintPriority)
end

---Add a candidate Hint. Priority zero suppresses a Hint;
---equal priority keeps the first Hint so rendering stays stable.
---@param destination integer | nil
---@param priority integer | nil
---@param hint any
---@return any updated_hint
function HintPriority:add(destination, priority, hint)
    priority = priority or 0
    if not destination or destination == 0 or priority <= 0 then
        return nil
    end

    local existing = self._hints_by_destination[destination]
    if not existing or priority > existing.priority then
        self._hints_by_destination[destination] = {
            hint = hint,
            priority = priority,
        }
        return hint
    end

    return nil
end

---@return table<integer, Precognition.PrioritizedHint>
function HintPriority:hints_by_destination()
    return self._hints_by_destination
end

return M
