local mt = require("mini.test")

local M = {}

local function check_pos(string, col, default_config)
    local result = {}
    local locations = vim.tbl_keys(default_config)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " ", string, " " })
    vim.api.nvim_set_current_buf(buf)
    for _, motion_name in ipairs(locations) do
        local motion_key = default_config[motion_name].text
        vim.fn.setcursorcharpos(2, col)
        vim.api.nvim_feedkeys(motion_key, "x", true)
        local cur_pos = vim.fn.getcursorcharpos(0)
        if cur_pos[2] == 2 then
            if motion_name == "MatchingPair" and cur_pos[3] ~= col then
                result[motion_name] = cur_pos[3]
            else
                result[motion_name] = cur_pos[3]
            end
        end
    end

    return result
end

M.check = function(line, col)
    local remote = mt.new_child_neovim()
    remote.start()

    local remote_data = remote.lua_func(check_pos, line, col, require("precognition").default_hint_config)
    remote.stop()
    return remote_data
end

return M
