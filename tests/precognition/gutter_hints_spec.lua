local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("Gutter hints table", function()
    it("should return a table with the correct keys", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 4, 0 })

        local hints = precognition.build_gutter_hints(testBuf)

        eq({
            ["gg"] = 1,
            PrevParagraph = 3,
            NextParagraph = 5,
            ["G"] = 8,
        }, hints)
    end)

    it("should return a table with the correct keys when the buffer is empty", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {})
        vim.api.nvim_set_current_buf(testBuf)

        local hints = precognition.build_gutter_hints(testBuf)

        eq({
            ["gg"] = 1,
            NextParagraph = 1,
            PrevParagraph = 1,
            ["G"] = 1,
        }, hints)
    end)

    it("should return a table with the correct keys when the buffer is a single line", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local hints = precognition.build_gutter_hints(testBuf)
        eq({
            ["gg"] = 1,
            NextParagraph = 1,
            PrevParagraph = 1,
            ["G"] = 1,
        }, hints)
    end)

    it("moving the cursor will update the hints table", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 4, 0 })

        local hints = precognition.build_gutter_hints(testBuf)

        eq({
            ["gg"] = 1,
            PrevParagraph = 3,
            NextParagraph = 5,
            ["G"] = 8,
        }, hints)

        vim.api.nvim_win_set_cursor(0, { 6, 0 })
        hints = precognition.build_gutter_hints(testBuf)
        eq({
            ["gg"] = 1,
            PrevParagraph = 5,
            NextParagraph = 7,
            ["G"] = 8,
        }, hints)
    end)

    it("adding a line will update the hints table", function()
        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, { "ABC" })
        vim.api.nvim_set_current_buf(testBuf)
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        local hints = precognition.build_gutter_hints(testBuf)
        eq({
            ["gg"] = 1,
            NextParagraph = 1,
            PrevParagraph = 1,
            ["G"] = 1,
        }, hints)

        vim.api.nvim_buf_set_lines(testBuf, 1, 1, false, { "DEF" })

        hints = precognition.build_gutter_hints(testBuf)
        eq({
            ["gg"] = 1,
            PrevParagraph = 1,
            NextParagraph = 2,
            ["G"] = 2,
        }, hints)

        vim.api.nvim_buf_set_lines(testBuf, 2, 2, false, { "GHI" })

        hints = precognition.build_gutter_hints(testBuf)

        eq({
            ["gg"] = 1,
            PrevParagraph = 1,
            NextParagraph = 3,
            ["G"] = 3,
        }, hints)

        vim.api.nvim_buf_set_lines(testBuf, 3, 3, false, { "" })
        vim.api.nvim_buf_set_lines(testBuf, 4, 4, false, { "JKL" })

        hints = precognition.build_gutter_hints(testBuf)

        eq({
            ["gg"] = 1,
            PrevParagraph = 1,
            NextParagraph = 4,
            ["G"] = 5,
        }, hints)
    end)
end)

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

describe("Priority", function()
    it("0 priority item is not added", function()
        precognition.setup({
            ---@diagnostic disable-next-line: missing-fields
            gutterHints = {
                G = { text = "G", prio = 0 },
                gg = { text = "gg", prio = 9 },
                PrevParagraph = { text = "{", prio = 8 },
                NextParagraph = { text = "}", prio = 8 },
            },
        })

        local testBuf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(testBuf, "foo")

        vim.api.nvim_buf_set_lines(testBuf, 0, -1, false, {
            "ABC",
            "DEF",
            "",
            "GHI",
            "",
            "JKL",
            "",
            "MNO",
        })

        local hints = precognition.build_gutter_hints(testBuf)
        precognition.apply_gutter_hints(hints, testBuf)

        local def = vim.fn.sign_getdefined("precognition_gutter_PrevParagraph")
        print("def")
        print(dump(def))

        local gutter_group = "precognition_gutter"
        local buf_name = vim.fn.bufname(testBuf)
        print("buf name " .. buf_name)
        local placed = vim.fn.sign_getplaced("foo", { group = "*" })

        print("placed")
        print(dump(placed))
        print(placed[1].signs[1])
        for _, g in ipairs(placed[1].signs) do
            print(g.name)
        end
        -- print("hints g is `" .. precognition.gutter_signs_cache["G"] .. "`")
        -- eq({
        --     ["gg"] = 1,
        --     PrevParagraph = 3,
        --     NextParagraph = 5,
        --     ["G"] = 8,
        -- }, hints)
    end)
end)
