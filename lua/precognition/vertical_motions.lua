local M = {}

---@return integer
function M.file_start()
    return 1
end

---@param bufnr integer
---@return integer
function M.file_end(bufnr)
    return vim.api.nvim_buf_line_count(bufnr)
end

---@param buf integer
---@return integer | nil
function M.next_paragraph_line(buf)
    local loc
    vim.api.nvim_buf_call(buf, function()
        loc = vim.fn.search("^\\_s*$", "nW", vim.fn.line("w$"))
    end)
    if loc == 0 then
        return nil
    end
    return loc
end

---@param buf integer
---@return integer | nil
function M.prev_paragraph_line(buf)
    local loc
    vim.api.nvim_buf_call(buf, function()
        loc = vim.fn.search("^\\_s*$", "bnW", vim.fn.line("w0"))
    end)
    if loc == 0 then
        return nil
    end
    return loc
end

return M
