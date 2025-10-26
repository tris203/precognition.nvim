---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("motions", function()
    local motions = require("precognition.motions")
    before_each(function()
        motions.reset_default()
    end)

    it("should be able to load the motions integration adapters", function()
        local test_adapter = {
            line_start_non_whitespace = function() end,
            line_end = function() end,
            next_word_boundary = function() end,
            end_of_word = function() end,
            prev_word_boundary = function() end,
            matching_pair = function() end,
            matching_comment = function() end,
            matching_bracket = function() end,
            file_start = function() end,
            file_end = function() end,
            next_paragraph_line = function() end,
            prev_paragraph_line = function() end,
            home_line = function() end,
            middle_line = function() end,
            last_line = function() end,
        }
        motions.register_motions(test_adapter)

        eq(test_adapter, motions.get_motions())
    end)

    it("should error when registering an empty adapter", function()
        local test_adapter = {}

        local _, err = pcall(function()
            motions.register_motions(test_adapter)
        end)

        assert(err)
        assert(string.find(err, "cannot register an empty adapter"))
    end)

    it("should default to default motions", function()
        local test_adapter = {
            line_start_non_whitespace = function() end,
        }

        motions.register_motions(test_adapter)

        local adapter = assert(motions.get_motions())

        -- assert the default functions are still there
        assert(adapter.line_end)
        assert(adapter.next_word_boundary)
        assert(adapter.end_of_word)
        assert(adapter.prev_word_boundary)
        assert(adapter.matching_pair)
    end)

    it("should be able to register different motions by override", function()
        local test_adapter_a = {
            line_start_non_whitespace = function() end,
            next_word_boundary = function() end,
            end_of_word = function() end,
        }
        local test_adapter_b = {
            line_start_non_whitespace = function() end,
            next_word_boundary = function() end,
        }
        local test_adapter_c = {
            line_start_non_whitespace = function() end,
        }

        motions.register_motions(test_adapter_a)
        motions.register_motions(test_adapter_b)
        motions.register_motions(test_adapter_c)

        local adapter = assert(motions.get_motions())

        eq(test_adapter_c.line_start_non_whitespace, adapter.line_start_non_whitespace)
        eq(test_adapter_b.next_word_boundary, adapter.next_word_boundary)
        eq(test_adapter_a.end_of_word, adapter.end_of_word)
    end)
end)
