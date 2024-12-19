local M = {}

local ranges = {
    { 32, 126 }, -- Basic Latin (ASCII)
    --TODO: Add other character ranges but this opens a load of multibyte edge cases
    -- { 160, 591 }, -- Latin-1 Supplement and Latin Extended-A
    -- { 880, 2047 }, -- Greek, Cyrillic, Armenian, Hebrew
    -- { 8192, 8303 }, -- General Punctuation
    -- { 9728, 9983 }, -- Miscellaneous Symbols
    -- { 12352, 12447 }, -- Hiragana
    -- { 19904, 19967 }, -- Mahjong Tiles
    -- { 0x1F300, 0x1F6FF }, -- Emoji
}

---@class dts.Random
---@field cursor_col number
---@field line string

---Generate a random line with Unicode characters.
---@param seed number
---@return dts.Random
function M.generate_random_line(seed)
    math.randomseed(seed) -- Set the seed for reproducibility

    -- Randomize the line length (e.g., between 20 and 100 characters)
    local line_length = math.random(20, 100)

    -- Function to generate a random printable Unicode character
    local function random_unicode_char()
        -- Randomly pick a range
        local range = ranges[math.random(1, #ranges)]
        -- Generate a random codepoint within the selected range
        local codepoint = math.random(range[1], range[2])
        return vim.fn.nr2char(codepoint) -- Convert codepoint to UTF-8 character
    end

    -- Generate the random line with Unicode characters
    local line = ""
    for _ = 1, line_length do
        line = line .. random_unicode_char()
    end

    -- Choose a random cursor position within the line
    local cursor_col = math.random(1, vim.fn.strcharlen(line)) -- Ensure valid cursor position
    ---@type dts.Random
    return {
        cursor_col = cursor_col,
        line = line,
    }
end

return M
