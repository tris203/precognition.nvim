local M = {}

---@return integer
function M.file_start()
    return 1
end

---@param bufnr? integer
---@return integer
function M.file_end(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return vim.api.nvim_buf_line_count(bufnr)
end

---@param bufnr? integer
---@return integer | nil
function M.next_paragraph_line(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local loc
    vim.api.nvim_buf_call(bufnr, function()
        loc = vim.fn.search("^\\_s*$", "nW", vim.fn.line("w$"))
    end)
    if loc == 0 then
        return nil
    end
    return loc
end

---@param bufnr? integer
---@return integer | nil
function M.prev_paragraph_line(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local loc
    vim.api.nvim_buf_call(bufnr, function()
        loc = vim.fn.search("^\\_s*$", "bnW", vim.fn.line("w0"))
    end)
    if loc == 0 then
        return nil
    end
    return loc
end

return M
