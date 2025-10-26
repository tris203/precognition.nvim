--- HML utility functions for calculating virtual lines with fold support
--- Based on the logic from jumpsigns

local M = {}

--- Calculates the virtual line number (1-based count within viewport, skipping folded
--- lines) for a given absolute buffer line number (lnum).
---@param lnum integer
---@param start_blnum integer
---@param end_blnum integer
---@return integer
local function get_virtual_lnum_for_blnum(lnum, start_blnum, end_blnum)
    local total_lines = vim.fn.line('$')
    start_blnum = start_blnum or 1
    end_blnum = end_blnum or total_lines

    if lnum < start_blnum or lnum > end_blnum then return 0 end

    local fold_start_check = vim.fn.foldclosed(lnum)
    if fold_start_check ~= -1 and fold_start_check ~= lnum then
        lnum = fold_start_check
    end

    local current_blnum = start_blnum
    local virtual_lnum = 1

    while current_blnum <= end_blnum do
        local fold_start = vim.fn.foldclosed(current_blnum)

        if current_blnum == lnum then
            return virtual_lnum
        end

        if fold_start == -1 then
            current_blnum = current_blnum + 1
            virtual_lnum = virtual_lnum + 1
        else
            local fold_end = vim.fn.foldclosedend(fold_start)
            virtual_lnum = virtual_lnum + 1
            current_blnum = fold_end + 1
            if fold_end >= end_blnum then break end
        end
    end
    return virtual_lnum
end

--- Takes a virtual line number (vnum) within the viewport
--- and returns the corresponding absolute buffer line number.
---@param vnum integer
---@param start_blnum integer
---@param end_blnum integer
---@return integer?
local function get_blnum_for_virtual_lnum(vnum, start_blnum, end_blnum)
    local total_lines = vim.fn.line('$')
    start_blnum = start_blnum or 1
    end_blnum = end_blnum or total_lines
    if vnum < 1 or total_lines == 0 then return nil end

    local current_blnum = start_blnum
    local virtual_lnum = 1

    while current_blnum <= end_blnum and virtual_lnum <= vnum do
        local fold_start = vim.fn.foldclosed(current_blnum)

        if virtual_lnum == vnum then
            return fold_start ~= -1 and fold_start or current_blnum
        end

        if fold_start == -1 then
            current_blnum = current_blnum + 1
            virtual_lnum = virtual_lnum + 1
        else
            local fold_end = vim.fn.foldclosedend(fold_start)
            virtual_lnum = virtual_lnum + 1
            current_blnum = fold_end + 1
            if fold_end >= end_blnum then break end
        end
    end

    return nil
end

--- Calculates the fold-content-safe absolute buffer line numbers for H, M, L marks.
--- Returns line numbers for H, M, L considering scrolloff and folds.
---@param bufnr? integer
---@return integer? H_linenr, integer? M_linenr, integer? L_linenr
function M.calculate_hml_lines(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    
    -- Normalize viewport boundaries to fold starts
    local viewport_top_blnum = vim.fn.foldclosed(vim.fn.line('w0'))
    if viewport_top_blnum == -1 then
        viewport_top_blnum = vim.fn.line('w0')
    end

    local viewport_bottom_blnum = vim.fn.foldclosed(vim.fn.line('w$'))
    if viewport_bottom_blnum == -1 then
        viewport_bottom_blnum = vim.fn.line('w$')
    else
        -- If bottom is a folded start, expand to its fold end
        local fold_end = vim.fn.foldclosedend(viewport_bottom_blnum)
        if fold_end ~= -1 then
            viewport_bottom_blnum = fold_end
        end
    end

    local last_line = vim.api.nvim_buf_line_count(bufnr)
    local scrolloff = vim.wo.scrolloff

    if viewport_bottom_blnum - viewport_top_blnum < 2 then
        return nil, nil, nil
    end

    -- Compute virtual lines relative to viewport
    local virtual_top = get_virtual_lnum_for_blnum(viewport_top_blnum, viewport_top_blnum, viewport_bottom_blnum)
    local virtual_bottom = get_virtual_lnum_for_blnum(viewport_bottom_blnum, viewport_top_blnum, viewport_bottom_blnum)
    if virtual_top == 0 or virtual_bottom == 0 then
        return nil, nil, nil
    end

    local viewport_height = virtual_bottom - virtual_top + 1
    local H_vnum, M_vnum, L_vnum

    -- H (high)
    if viewport_top_blnum == 1 then
        H_vnum = virtual_top
    else
        local calculated_H = virtual_top + scrolloff
        H_vnum = math.max(calculated_H, virtual_top)
        H_vnum = math.min(H_vnum, virtual_bottom)
    end

    -- L (low)
    if viewport_bottom_blnum >= last_line then
        L_vnum = virtual_bottom
    else
        local calculated_L = virtual_bottom - scrolloff
        L_vnum = math.max(calculated_L, virtual_top)
        L_vnum = math.min(L_vnum, virtual_bottom)
    end

    -- M (middle)
    M_vnum = math.floor((virtual_top + virtual_bottom) / 2)
    M_vnum = math.max(M_vnum, H_vnum)
    M_vnum = math.min(M_vnum, L_vnum)

    -- Translate back to buffer lines within viewport
    local H_linenr = get_blnum_for_virtual_lnum(H_vnum, viewport_top_blnum, viewport_bottom_blnum)
    local M_linenr = get_blnum_for_virtual_lnum(M_vnum, viewport_top_blnum, viewport_bottom_blnum)
    local L_linenr = get_blnum_for_virtual_lnum(L_vnum, viewport_top_blnum, viewport_bottom_blnum)

    return H_linenr, M_linenr, L_linenr
end

return M

