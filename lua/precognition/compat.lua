local M = {}

function M.inlay_hints_enabled(t)
    if vim.lsp and vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled then
        return vim.lsp.inlay_hint.is_enabled(t)
    end
    return false
end

return M
