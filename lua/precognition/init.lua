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
local config = {}

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

	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function()
			-- todo: hide the hints
		end,
	})
	vim.api.nvim_create_autocmd("CursorHold", {
		callback = function()
			-- todo: show the hints if they're hidden
		end,
	})
end

return M
