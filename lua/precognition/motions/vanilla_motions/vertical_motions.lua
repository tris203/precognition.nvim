---@type Precognition.MotionsAdapter
local M = {}

---@return Precognition.PlaceLoc
function M.file_start()
    return 1
end

---@param bufnr? integer
---@return Precognition.PlaceLoc
function M.file_end(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return vim.api.nvim_buf_line_count(bufnr)
end

---@param bufnr? integer
---@return Precognition.PlaceLoc
function M.next_paragraph_line(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local loc = 0
    vim.api.nvim_buf_call(bufnr, function()
        local found
        local visibleline = vim.fn.line("w$")
        local buffcontent = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local cursorline, _ = unpack(vim.api.nvim_win_get_cursor(0))
        while not found and cursorline < visibleline do
            local cursorlinecontent = buffcontent[cursorline]
            while cursorline < visibleline and cursorlinecontent:match("^[\n\r]*$") do
                cursorline = cursorline + 1
                cursorlinecontent = buffcontent[cursorline]
            end
            -- find next blank line below
            while cursorline < visibleline and not found do
                cursorline = cursorline + 1
                cursorlinecontent = buffcontent[cursorline]
                if cursorlinecontent:match("^[\n\r]*$") then
                    found = true
                end
            end
        end
        loc = cursorline
    end)
    return loc
end

---@param bufnr? integer
---@return Precognition.PlaceLoc
function M.prev_paragraph_line(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local loc = 0
    vim.api.nvim_buf_call(bufnr, function()
        local found
        local visibleline = vim.fn.line("w0")
        local buffcontent = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local cursorline, _ = unpack(vim.api.nvim_win_get_cursor(0))
        while not found and cursorline > visibleline do
            local cursorlinecontent = buffcontent[cursorline]
            while cursorline > visibleline and cursorlinecontent:match("^[\n\r]*$") do
                cursorline = cursorline - 1
                cursorlinecontent = buffcontent[cursorline]
            end
            -- find next blank line above
            while cursorline > visibleline and not found do
                cursorline = cursorline - 1
                cursorlinecontent = buffcontent[cursorline]
                if cursorlinecontent:match("^[\n\r]*$") then
                    found = true
                end
            end
        end
        loc = cursorline
    end)
    --check if line above is empty
    --if so, return the line above that
    return loc
end

return M
