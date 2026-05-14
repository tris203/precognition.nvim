local M = {}

---@type integer
local sim_buf

---@return integer
local function ensure_sim_buf()
    if sim_buf and vim.api.nvim_buf_is_valid(sim_buf) then
        return sim_buf
    end

    sim_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[sim_buf].bufhidden = "hide"
    vim.bo[sim_buf].buftype = "nofile"
    vim.bo[sim_buf].swapfile = false
    vim.bo[sim_buf].matchpairs = vim.o.matchpairs

    return sim_buf
end

--- @param string string
---@param col integer
---@param default_config Precognition.HintConfig
---@return Precognition.VirtLine
local function check_pos(string, col, default_config)
    ---@type Precognition.VirtLine
    local result = {
        Zero = 0,
        Caret = 0,
        MatchingPair = 0,
        Dollar = 0,
        w = 0,
        b = 0,
        e = 0,
        W = 0,
        B = 0,
        E = 0,
    }
    local locations = vim.tbl_keys(default_config)
    local buf = ensure_sim_buf()

    vim.api.nvim_buf_call(buf, function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", string, "" })
        for _, motion_name in ipairs(locations) do
            local motion_key = default_config[motion_name].text
            vim.fn.setcursorcharpos(2, col)
            local start_col = vim.fn.getcursorcharpos(0)[3]
            vim.cmd({ cmd = "normal", bang = true, args = { motion_key } })
            local cur_pos = vim.fn.getcursorcharpos(0)
            if cur_pos[2] == 2 then
                if motion_name == "MatchingPair" then
                    if cur_pos[3] ~= start_col then
                        result[motion_name] = cur_pos[3]
                    end
                else
                    result[motion_name] = cur_pos[3]
                end
            end
        end
    end)

    return result
end

M.check = function(line, col)
    return check_pos(line, col, require("precognition.defaults").hints)
end

---@param line string
---@param col integer
---@param inputs string[]
---@return table<string, integer>
M.motion_destinations = function(line, col, inputs)
    local buf = ensure_sim_buf()
    local destinations = {}
    local previous_charsearch = vim.fn.getcharsearch()

    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", line, "" })

        for _, input in ipairs(inputs) do
            vim.fn.setcursorcharpos(2, col)
            local start_col = vim.fn.getcursorcharpos(0)[3]
            vim.cmd({ cmd = "normal", bang = true, args = { input } })
            local cur_pos = vim.fn.getcursorcharpos(0)
            if cur_pos[2] == 2 and cur_pos[3] ~= start_col then
                destinations[input] = cur_pos[3]
            end
        end
    end)
    vim.fn.setcharsearch(previous_charsearch)
    if not ok then
        error(err)
    end

    return destinations
end

---@param line string
---@param col integer
---@param keys_by_name table<string, string>
---@return table<string, { start_col: integer, end_col: integer }>
M.select_text_objects = function(line, col, keys_by_name)
    local buf = ensure_sim_buf()
    local selections = {}

    vim.api.nvim_buf_call(buf, function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", line, "" })

        for name, keys in pairs(keys_by_name) do
            vim.fn.setcursorcharpos(2, col)
            vim.cmd({ cmd = "normal", bang = true, args = { "v" .. keys } })

            local visual_start = vim.fn.getpos("v")
            local visual_end = vim.fn.getcursorcharpos(0)
            if visual_start[2] == 2 and visual_end[2] == 2 then
                selections[name] = {
                    start_col = math.min(visual_start[3], visual_end[3]),
                    end_col = math.max(visual_start[3], visual_end[3]),
                }
            end

            vim.cmd({ cmd = "normal", bang = true, args = { "\27" } })
        end
    end)

    return selections
end

return M
