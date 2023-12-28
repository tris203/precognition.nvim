local M = {}

---@class Precognition.Config
---@field hints table<string, string>

---@class Precognition.PartialConfig
---@field hints? table<string, string>

---@type Precognition.Config
local default = {
    hints = {
        ["^"] = "^",
        ["$"] = "$",
        ["w"] = "w",
        ["W"] = "W",
        ["b"] = "b",
        ["e"] = "e",
        ["ge"] = "ge", -- should we support multi-char / multi-byte hints?
    },
}

---@type Precognition.Config
local config = default

--- Show the hints until the next keypress or CursorMoved event
function M.peek()
    error("not implemented")
end

--- Enable automatic showing of hints
function M.show()
    error("not implemented")
end

--- Disable automatic showing of hints
function M.hide()
    error("not implemented")
end

--- Toggle automatic showing of hints
function M.toggle()
    error("not implemented")
end

---@param opts Precognition.PartialConfig
function M.setup(opts)
    config = vim.tbl_deep_extend("force", default, opts or {})

    local ns = vim.api.nvim_create_namespace("precognition")
    local au = vim.api.nvim_create_augroup("precognition", { clear = true })

    -- This is a test with basic functionality, definitely should be moved out of the setup function and into
    -- functions that the public methods can call.

    ---@type integer?
    local extmark -- the active extmark in the current buffer

    -- clear the extmark entirely when leaving a buffer (hints should only show in current buffer)
    vim.api.nvim_create_autocmd("BufLeave", {
        group = au,
        callback = function(ev)
            vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
            extmark = nil
        end,
    })

    -- clear the extmark when the cursor moves, or when insert mode is entered
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
        group = au,
        callback = function()
            if extmark then
                vim.api.nvim_buf_del_extmark(0, ns, extmark)
                extmark = nil
            end
        end,
    })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = au,
        -- TODO: add debounce / delay before showing hints to reduce flickering
        -- during fast movements
        callback = function()
            if extmark then
                return
            end

            local cursorline, cursorcol = unpack(vim.api.nvim_win_get_cursor(0))
            local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
            local cur_line = vim.api.nvim_get_current_line():gsub("\t", string.rep(" ", tab_width))
            local line_len = vim.fn.strcharlen(cur_line)
            local after_cursor = vim.fn.strcharpart(cur_line, cursorcol - 1)

            -- FIXME: Lua patterns don't play nice with utf-8, we need a better way to
            -- get char offsets for more complex motions.
            local line_start = cur_line:find("%S") or 0
            local line_end = line_len
            local w_reg = vim.regex("\\v-@![-[:lower:][:upper:][:digit:]_]+")
            local w_punct_reg = vim.regex("\\v-@![[:punct:]]+")

            -- skip past the current word
            local cur_word, cur_word_end = w_reg:match_str(after_cursor)
            local cur_word_punct, cur_word_punct_end = w_punct_reg:match_str(vim.fn.strcharpart(after_cursor, 1))
            if cur_word_punct and cur_word and cur_word_punct < cur_word then
                cur_word = cur_word_punct
                cur_word_end = cur_word_punct_end
            elseif cur_word_punct and not cur_word then
                cur_word = cur_word_punct
                cur_word_end = cur_word_punct_end
            end
            -- vim.notify(cur_word .. ":" .. cur_word_end, vim.log.levels.INFO, {})

            -- if the match is after the cursor, don't add the end offset
            if cur_word > 1 then
                cur_word_end = 0
            end

            local motion_w = w_reg:match_str(vim.fn.strcharpart(after_cursor, cur_word_end + 1))
            local motion_w_punct = w_punct_reg:match_str(vim.fn.strcharpart(after_cursor, cur_word_end + 1))
            if motion_w and motion_w_punct and motion_w_punct < motion_w then
                motion_w = motion_w_punct
            elseif motion_w_punct and not motion_w then
                motion_w = motion_w_punct
            end

            local virt_line = {}

            -- create the list of hints to show in { hint, column } format
            -- TODO: extract this into a function, add hints for other motions
            local marks = {}
            table.insert(marks, { "^", math.max(0, line_start - 1) })
            table.insert(marks, { "$", line_end - 1 })
            if motion_w then
                table.insert(marks, { "w", cursorcol + cur_word_end + motion_w })
            end

            table.sort(marks, function(a, b)
                return a[2] < b[2]
            end)

            -- build the virtual line out of virt text chunks
            local last_col = 0
            for _, mark in ipairs(marks) do
                local hint = config.hints[mark[1]] or mark[1]
                local col = mark[2]
                if col > last_col then
                    -- add padding between hints
                    table.insert(virt_line, { string.rep(" ", (col - last_col)) })
                    last_col = col + 1
                end
                table.insert(virt_line, { hint, "Comment" })
            end

            -- create (or overwrite) the extmark
            extmark = vim.api.nvim_buf_set_extmark(0, ns, cursorline - 1, 0, {
                id = extmark, -- reuse the same extmark if it exists
                virt_lines = { virt_line },
            })
        end,
    })
end

return M
