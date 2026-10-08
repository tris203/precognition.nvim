local eq = MiniTest.expect.equality
local ss = MiniTest.expect.reference_screenshot
local child = MiniTest.new_child_neovim()

local function start_child(enabled)
    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.lua_func(function(enable)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local x = "hello world"', 'local x = "hello world"' })
        if enable then
            require("precognition").setup()
        end
    end, enabled)
end

local function record(keys)
    child.type_keys("qa")
    for _, key in ipairs(keys) do
        child.type_keys(key)
    end
    child.type_keys("q")
    return child.lua_get('vim.fn.getreg("a")')
end

describe("macro recording", function()
    after_each(function()
        if child.is_running() then
            child.stop()
        end
    end)

    it("records and replays quote replacement without plugin-added keys", function()
        -- End with a motion so Neovim retains the last user-generated <Ignore>
        -- in both runs, independently of its trailing-key trimming behavior.
        local keys = { "0", "f", '"', "r", "'", "f", '"', "r", "'", "0" }
        start_child(false)
        local expected = record(keys)
        start_child(true)
        eq(expected, record(keys))
        eq("local x = 'hello world'", child.lua_get("vim.api.nvim_get_current_line()"))
        child.type_keys("j", "@a")
        eq("local x = 'hello world'", child.lua_get("vim.api.nvim_get_current_line()"))
    end)

    it("skips targeted simulations for pending, counted and repeat motions while recording", function()
        start_child(true)
        child.lua_func(function()
            local sim = require("precognition.motions.sim_motions.sim")
            local original = sim.motion_destinations
            _G.recorded_simulations = 0
            sim.motion_destinations = function(...)
                if vim.fn.reg_recording() ~= "" then
                    _G.recorded_simulations = _G.recorded_simulations + 1
                end
                return original(...)
            end
        end)
        record({ "2", "f", "l", ";", ",", "F", "l", "t", "o", "T", "l", "0" })
        eq(0, child.lua_get("_G.recorded_simulations"))
    end)

    it("refreshes targeted hints at recording boundaries without cursor movement", function()
        start_child(true)
        child.lua_func(function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab cab!a" })
            vim.api.nvim_win_set_cursor(0, { 1, 3 })
            vim.api.nvim_exec_autocmds("CursorMoved", { group = "precognition" })
        end)
        ss(child.get_screenshot())
        child.type_keys("qa")
        ss(child.get_screenshot())
        child.type_keys("q")
        ss(child.get_screenshot())
    end)

    it("keeps hints hidden when hide runs before the deferred recording refresh", function()
        start_child(true)
        child.type_keys("qa")
        child.lua_func(function()
            vim.api.nvim_create_autocmd("RecordingLeave", {
                once = true,
                callback = function()
                    require("precognition").hide()
                end,
            })
        end)
        child.type_keys("q")
        eq(false, child.lua_get('require("precognition").is_visible()'))
        eq(
            {},
            child.lua_get('vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces()["precognition"], 0, -1, {})')
        )
    end)
end)
