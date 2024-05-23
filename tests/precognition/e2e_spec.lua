local precognition = require("precognition")
---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

local function get_gutter_extmarks(buffer)
    local gutter_extmarks = {}
    for _, extmark in
        pairs(vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, {
            details = true,
        }))
    do
        if extmark[4] and extmark[4].sign_name and extmark[4].sign_name:match(precognition.gutter_group) then
            table.insert(gutter_extmarks, extmark)
        end
    end
    return gutter_extmarks
end

local function hex2dec(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))

    local dec = (r * 256 ^ 2) + (g * 256) + b

    return dec
end

describe("e2e tests", function()
    before_each(function()
        precognition.setup({})
    end)

    it("auto commands are set", function()
        local autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(4, vim.tbl_count(autocmds))
        precognition.peek()
        autocmds = vim.api.nvim_get_autocmds({ group = "precognition" })
        eq(7, vim.tbl_count(autocmds))
    end)

    -- it("namespace is created", function()
    --     local ns = vim.api.nvim_get_namespaces()
    --
    --     eq(1, ns["precognition"])
    --     eq(2, ns["precognition_gutter"])
    -- end)
    --
    it("virtual line is displayed and updated", function()
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        local gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Comment" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq({ link = "Comment" }, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))

        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        precognition.on_cursor_moved()

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b         e w            $", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 2, 1 })
        precognition.on_cursor_moved()

        gutter_extmarks = get_gutter_extmarks(buffer)

        extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b  e w", extmarks[3].virt_lines[1][1][1])

        vim.api.nvim_win_set_cursor(0, { 4, 1 })
        precognition.on_cursor_moved()
        gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq(2, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq(4, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end
    end)

    it("virtual line text color can be customised", function()
        precognition.setup({ highlightColor = { link = "Function" } })
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        local gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq({ link = "Function" }, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))
    end)

    it("virtual line can be customised without a link", function()
        local background = "#00ff00"
        local foreground = "#ff0000"
        local customColor = { foreground = foreground, background = background }
        local customMark = { fg = hex2dec(foreground), bg = hex2dec(background) }
        precognition.setup({ highlightColor = customColor })
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.api.nvim_buf_set_lines(
            buffer,
            0,
            -1,
            false,
            { "Hello World this is a test", "line 2", "", "line 4", "", "line 6" }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 1 })

        precognition.on_cursor_moved()

        local extmarks = vim.api.nvim_buf_get_extmark_by_id(buffer, precognition.ns, precognition.extmark, {
            details = true,
        })

        local gutter_extmarks = get_gutter_extmarks(buffer)

        for _, extmark in pairs(gutter_extmarks) do
            if extmark[4].sign_text == "G " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(5, extmark[2])
            elseif extmark[4].sign_text == "gg" then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "{ " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(0, extmark[2])
            elseif extmark[4].sign_text == "} " then
                eq("PrecognitionHighlight", extmark[4].sign_hl_group)
                eq(customMark, vim.api.nvim_get_hl(0, { name = extmark[4].sign_hl_group }))
                eq(2, extmark[2])
            else
                assert(false, "unexpected sign text")
            end
        end

        eq(vim.api.nvim_win_get_cursor(0)[1] - 1, extmarks[1])
        eq("b   e w                  $", extmarks[3].virt_lines[1][1][1])
        eq("PrecognitionHighlight", extmarks[3].virt_lines[1][1][2])
        eq(customMark, vim.api.nvim_get_hl(0, { name = extmarks[3].virt_lines[1][1][2] }))
    end)
end)
