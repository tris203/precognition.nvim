local utils = require("precognition.utils")

local M = {}

---@return integer
function M.file_start()
    return 1
end

---@param lines table
---@return integer
function M.file_end(lines)
    return #lines
end

---@return integer | nil
function M.next_paragraph_line()
    --TODO: refactor this to use a testable function
    return vim.fn.search("^\\s*$", "n")
end

---@return integer | nil
function M.prev_paragraph_line()
    --TODO: refactor this to use a testable function
    return vim.fn.search("^\\s*$", "bn")
end

return M
