local HintPriority = require("precognition.hint_priority")

local M = {}

---@param cur_line string
---@param charcol number
---@param offset number
---@return number
---@return string
---@return number
function M.calculate_visual_cursorcol(cur_line, charcol, offset)
    local leading_whitespace = string.match(cur_line, "^([ \t]*)")
    local cursorcol = charcol - #leading_whitespace + offset
    local tab_width = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
    local sanitised_line = cur_line:gsub("\t", string.rep(" ", tab_width))
    return cursorcol, sanitised_line, tab_width
end

---@param config Precognition.Config
---@param marks Precognition.VirtLine
---@param line_len integer
---@param extra_padding Precognition.ExtraPadding[]
---@param min_width? integer
---@return table
function M.build(config, marks, line_len, extra_padding, min_width)
    local utils = require("precognition.utils")
    if not marks or line_len == 0 then
        return {}
    end

    local line_table = utils.create_pad_array(line_len, " ")
    local priority = HintPriority.new()
    for mark, loc in pairs(marks) do
        local updated_hint = priority:add(loc, config.hints[mark].prio, config.hints[mark].text or mark)
        if updated_hint and loc > 0 and loc <= line_len then
            line_table[loc] = updated_hint
        end
    end

    for _, padding in ipairs(extra_padding) do
        line_table[padding.start] = line_table[padding.start] .. string.rep(" ", padding.length)
    end

    local line = table.concat(line_table)
    if min_width and vim.fn.strdisplaywidth(line) < min_width then
        line = line .. string.rep(" ", min_width - vim.fn.strdisplaywidth(line))
    end
    if line:match("^%s+$") then
        if min_width and config.showBlankVirtLine then
            return { { line, "PrecognitionHighlight" } }
        end
        return {}
    end

    return { { line, "PrecognitionHighlight" } }
end

return M
