---@type fun(left: any, right: any)
local eq = MiniTest.expect.equality
---@type table
local sim = require("precognition.motions.sim_motions.sim")

---@param line string
---@return integer?
local function find_sim_buffer(line)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_is_loaded(buf)
            and not vim.bo[buf].buflisted
            and vim.bo[buf].buftype == "nofile"
            and vim.bo[buf].bufhidden == "hide"
            and not vim.bo[buf].swapfile
        then
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            if vim.tbl_contains(lines, line) then
                return buf
            end
        end
    end
end

describe("simulation buffer", function()
    ---@type integer[]
    local buffers_to_delete

    before_each(function()
        buffers_to_delete = {}
    end)

    after_each(function()
        for _, buf in ipairs(buffers_to_delete) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end)

    it("replaces an externally unloaded buffer before simulating", function()
        local current_buf = vim.api.nvim_get_current_buf()

        eq({ w = 7 }, sim.motion_destinations("alpha beta", 1, { "w" }))
        local unloaded_buf = assert(find_sim_buffer("alpha beta"))
        table.insert(buffers_to_delete, unloaded_buf)

        vim.cmd({ cmd = "bunload", bang = true, args = { tostring(unloaded_buf) } })
        eq(true, vim.api.nvim_buf_is_valid(unloaded_buf))
        eq(false, vim.api.nvim_buf_is_loaded(unloaded_buf))

        eq({ w = 5 }, sim.motion_destinations("one two", 1, { "w" }))
        local replacement_buf = assert(find_sim_buffer("one two"))
        table.insert(buffers_to_delete, replacement_buf)

        eq(false, vim.api.nvim_buf_is_loaded(unloaded_buf))
        assert(replacement_buf ~= unloaded_buf)
        eq(false, vim.bo[replacement_buf].buflisted)
        eq("nofile", vim.bo[replacement_buf].buftype)
        eq("hide", vim.bo[replacement_buf].bufhidden)
        eq(false, vim.bo[replacement_buf].swapfile)
        eq(false, vim.bo[replacement_buf].modified)
        eq(current_buf, vim.api.nvim_get_current_buf())
    end)
end)
