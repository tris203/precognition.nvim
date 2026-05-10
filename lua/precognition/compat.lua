local M = {}

function M.inlay_hints_enabled(t)
    if vim.lsp and vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled then
        ---@type fun(t?: table): boolean
        local is_enabled = vim.lsp.inlay_hint.is_enabled
        return is_enabled(t)
    end
    return false
end

function M.get_inlay_hints(t)
    ---@type fun(t?: table): vim.lsp.inlay_hint.get.ret[]
    local get = vim.lsp.inlay_hint.get
    return get(t)
end

return M
