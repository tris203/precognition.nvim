local M = {}

M.get_active_lsp_clients = vim.lsp.get_clients() or vim.lsp.get_active_clients()

return M
