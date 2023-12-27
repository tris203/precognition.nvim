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

			local cursorline, _cursorcol = unpack(vim.api.nvim_win_get_cursor(0))
			local cur_line = vim.api.nvim_get_current_line():gsub("\t", "    ")

			-- vim.fn.col("^") doesn't work :(
			local line_end = #cur_line or 0

			-- FIXME: does not play nice with utf-8, we need a better way to
			-- get char offsets.
			--
			-- Notice that on a line with a string containing utf-8 symbols, the marks to not
			-- appear in the correct place. We need to treat this as a char array, it seems that vim regex
			-- treats it like a byte array.
			-- local line_start = select(2, re_line_start:match_str(cur_line)) or 0
			local line_start = cur_line:find("%S") or 0

			local virt_line = {}

			-- create the list of hints to show in { hint, column } format
			-- TODO: extract this into a function, add hints for other motions
			local marks = {}
			table.insert(marks, { "^", math.max(0, line_start - 1) })
			table.insert(marks, { "$", line_end - 1 })

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
