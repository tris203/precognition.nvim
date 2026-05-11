---@class Precognition.Renderer
---@field private _ns integer
---@field private _range_ns integer
---@field private _extmark integer | nil
---@field private _gutter_group string
---@field private _gutter_name_prefix string
---@field private _gutter_signs_cache table<string, { line: integer, id: integer }>
local Renderer = {}
Renderer.__index = Renderer

---@class Precognition.RendererModule
local M = {}

---@return Precognition.Renderer
function M.new()
    local renderer = setmetatable({
        _ns = vim.api.nvim_create_namespace("precognition"),
        _range_ns = vim.api.nvim_create_namespace("precognition_text_object_ranges"),
        _extmark = nil,
        _gutter_group = "precognition_gutter",
        _gutter_name_prefix = "precognition_gutter_",
        _gutter_signs_cache = {},
    }, Renderer)
    ---@cast renderer Precognition.Renderer
    return renderer
end

function Renderer:reset()
    self._ns = vim.api.nvim_create_namespace("precognition")
    self._range_ns = vim.api.nvim_create_namespace("precognition_text_object_ranges")
    self._extmark = nil
    self._gutter_signs_cache = {}
end

---@param bufnr? integer
function Renderer:clear(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if self._extmark then
        vim.api.nvim_buf_del_extmark(bufnr, self._ns, self._extmark)
        self._extmark = nil
    end
    vim.api.nvim_buf_clear_namespace(bufnr, self._ns, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, self._range_ns, 0, -1)
    vim.fn.sign_unplace(self._gutter_group)
    self._gutter_signs_cache = {}
end

---@param cursorline integer
---@param virt_line table
function Renderer:render_inline_hint_virt_line(cursorline, virt_line)
    self._extmark = vim.api.nvim_buf_set_extmark(0, self._ns, cursorline - 1, 0, {
        id = self._extmark,
        virt_lines = { virt_line },
    })
end

---@param bufnr integer
---@param cursorline integer
function Renderer:clear_inline_hint_if_moved(bufnr, cursorline)
    if not self._extmark then
        return
    end

    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, self._ns, self._extmark, {
        details = true,
    })
    if extmark and extmark[1] ~= cursorline - 1 then
        vim.api.nvim_buf_del_extmark(bufnr, self._ns, self._extmark)
        self._extmark = nil
    end
end

---@param hint string
---@param loc integer
---@param bufnr integer
---@param text string
function Renderer:render_gutter_hint(hint, loc, bufnr, text)
    local sign_name = self._gutter_name_prefix .. hint
    vim.fn.sign_define(sign_name, {
        text = text,
        texthl = "PrecognitionHighlight",
    })
    local ok, res = pcall(vim.fn.sign_place, 0, self._gutter_group, sign_name, bufnr, {
        lnum = loc,
        priority = 100,
    })
    if ok then
        self._gutter_signs_cache[hint] = { line = loc, id = res }
        return
    end
    if loc ~= 0 then
        vim.notify_once("Failed to place sign: " .. hint .. " at line " .. loc .. vim.inspect(res), vim.log.levels.WARN)
    end
end

---@param hint string
function Renderer:clear_gutter_hint(hint)
    if not self._gutter_signs_cache[hint] then
        return
    end
    vim.fn.sign_unplace(self._gutter_group, { id = self._gutter_signs_cache[hint].id })
    self._gutter_signs_cache[hint] = nil
end

---@param bufnr integer
function Renderer.flush(_self, bufnr)
    -- nvim__redraw is experimental, but we intentionally use it here to flush this buffer's hints.
    vim.api.nvim__redraw({ buf = bufnr, flush = true })
end

---@return integer | nil
function Renderer:extmark()
    return self._extmark
end

---@return integer
function Renderer:ns()
    return self._ns
end

---@return integer
function Renderer:range_ns()
    return self._range_ns
end

---@return string
function Renderer:gutter_group()
    return self._gutter_group
end

return M
