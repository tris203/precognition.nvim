local M = {}

function M.inlay_hints_enabled(t)
    if vim.lsp and vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled then
        return vim.lsp.inlay_hint.is_enabled(t)
    end
    return false
end

function M.flatten(t)
    if vim.fn.has("nvim-0.11") then
        return vim.iter(t):flatten():totable()
    else
        return vim.tbl_flatten(t)
    end
end

return M
