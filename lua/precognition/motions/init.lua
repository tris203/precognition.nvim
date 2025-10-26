---@type Precognition.MotionsAdapter
local VANILLA_MOTIONS_ADAPTER = vim.deepcopy(require("precognition.motions.vanilla_motions"))

--- This module contains the core logic for managing motions in Precognition.
---@class Precognition.Motions
---@field motions_adapter Precognition.MotionsAdapter
local M = {
    motions_adapter = VANILLA_MOTIONS_ADAPTER,
}

---@enum Precognition.MotionsAdapter.FunctionNames
local FUNCTION_NAMES = {
    -- vertical motions
    "file_start",
    "file_end",
    "next_paragraph_line",
    "prev_paragraph_line",
    "home_line",
    "middle_line",
    "last_line",
    -- horizontal motions
    "line_start_non_whitespace",
    "line_end",
    "next_word_boundary",
    "end_of_word",
    "prev_word_boundary",
    "matching_pair",
    "matching_comment",
    "matching_bracket",
}

--- Reset to vanilla motion adapters.
function M.reset_default()
    M.motions_adapter = VANILLA_MOTIONS_ADAPTER
end

--- Register a motions adapter.
---@param adapter Precognition.MotionsAdapter
function M.register_motions(adapter)
    assert(vim.tbl_isempty(adapter) == false, "cannot register an empty adapter")

    local current_adapter = M.motions_adapter

    -- override the functions defined in the adapter
    vim.iter(FUNCTION_NAMES)
        :filter(function(name)
            return adapter[name]
        end)
        :each(function(name)
            assert(type(adapter[name]) == "function", name .. " must be a function")
            current_adapter[name] = adapter[name]
        end)

    M.motions_adapter = current_adapter
end

--- Get motions adapter.
---@return Precognition.MotionsAdapter
function M.get_motions()
    return M.motions_adapter
end

return M
