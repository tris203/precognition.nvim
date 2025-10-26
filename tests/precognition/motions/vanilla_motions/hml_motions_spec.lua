-- Test for HML vertical motions
local vm = require("precognition.motions.vanilla_motions.vertical_motions")

describe("HML vertical motions", function()
    it("should calculate home line correctly", function()
        local home_line = vm.home_line()
        -- H should return the first visible line in the window
        assert.is_true(home_line > 0)
        assert.equals(vim.fn.line("w0"), home_line)
    end)

    it("should calculate middle line correctly", function()
        local middle_line = vm.middle_line()
        -- M should return the middle visible line in the window
        assert.is_true(middle_line > 0)
        local expected = vim.fn.line("w$") - math.floor((vim.fn.line("w$") - vim.fn.line("w0")) / 2)
        assert.equals(expected, middle_line)
    end)

    it("should calculate last line correctly", function()
        local last_line = vm.last_line()
        -- L should return the last visible line in the window
        assert.is_true(last_line > 0)
        assert.equals(vim.fn.line("w$"), last_line)
    end)

    it("should have consistent ordering H <= M <= L", function()
        local home_line = vm.home_line()
        local middle_line = vm.middle_line()
        local last_line = vm.last_line()
        
        assert.is_true(home_line <= middle_line)
        assert.is_true(middle_line <= last_line)
    end)
end)
