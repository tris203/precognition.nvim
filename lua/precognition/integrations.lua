local default_hm = require("precognition.horizontal_motions")

--- This module contains functions for integrating with other plugins.
--- Other plugins can use these to inform Precognition about their
--- motion logic.
local M = {}

---@class Precognition.HorizontalMotionsAdapter
---@field line_start_non_whitespace? fun(str: string, cursorcol: integer, linelen: integer): integer
---@field line_end? fun(str: string, cursorcol: integer, linelen: integer): integer
---@field next_word_boundary? fun(str: string, cursorcol: integer, linelen: integer, big_word: boolean): integer
---@field end_of_word? fun(str: string, cursorcol: integer, linelen: integer,
---                                     big_word: boolean, recursive: boolean?): integer
---@field prev_word_boundary? fun(str: string, cursorcol: integer, linelen: integer, big_word: boolean): integer
---@field matching_pair? fun(str: string, cursorcol: integer, linelen: integer): fun(): integer

local FUNCTION_NAMES = {
    "line_start_non_whitespace",
    "line_end",
    "next_word_boundary",
    "end_of_word",
    "prev_word_boundary",
    "matching_pair",
}

local DEFAULT_HM_ADAPTER = {
    line_start_non_whitespace = default_hm.line_start_non_whitespace,
    line_end = default_hm.line_end,
    next_word_boundary = default_hm.next_word_boundary,
    end_of_word = default_hm.end_of_word,
    prev_word_boundary = default_hm.prev_word_boundary,
    matching_pair = default_hm.matching_pair,
}

M.integration_adapter = {
    ---@type Precognition.HorizontalMotionsAdapter | nil
    horizontal_motions_adapter = nil,
}

--- Clear all the integration adapters
function M.clear()
    M.integration_adapter = {
        horizontal_motions_adapter = nil,
    }
end

--- Register a horizontal motions adapter.
---@param adapter Precognition.HorizontalMotionsAdapter
function M.register_horizontal_motions(adapter)
    assert(vim.tbl_isempty(adapter) == false, "cannot register an empty adapter")

    -- get the current adapter or use the default one
    local current_adapter = M.integration_adapter.horizontal_motions_adapter or DEFAULT_HM_ADAPTER

    -- override the functions if they are not defined
    vim.iter(FUNCTION_NAMES)
        :filter(function(name)
            return adapter[name]
        end)
        :each(function(name)
            assert(type(adapter[name]) == "function", name .. " must be a function")
            current_adapter[name] = adapter[name]
        end)

    M.integration_adapter.horizontal_motions_adapter = current_adapter
end

--- Get the horizontal motions adapter.
---@return Precognition.HorizontalMotionsAdapter | nil
function M.get_hm_integration()
    return M.integration_adapter.horizontal_motions_adapter
end

return M
