local M = {}

---@return ffi.namespace*
function M.load()
    if not _G.precog_C then
        local ffi = require("ffi")
        local ok, err = pcall(
            ffi.cdef,
            [[
                  int utf_class(const int c);
            ]]
        )
        ---@diagnostic disable-next-line: need-check-nil
        if not ok then
            error(err)
        end
        _G.precog_C = ffi.C
    end
    return _G.precog_C
end

return setmetatable(M, {
    __index = function(_, key)
        return M.load()[key]
    end,
    __newindex = function(_, k, v)
        M.load()[k] = v
    end,
})
