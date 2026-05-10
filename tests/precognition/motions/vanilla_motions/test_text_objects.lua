local hm = require("precognition.motions.vanilla_motions.horizontal_motions")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local function has_anchor(anchors, label, col)
    for _, anchor in ipairs(anchors) do
        if anchor.label == label and anchor.col == col then
            return true
        end
    end

    return false
end

T["text object hints"] = MiniTest.new_set({
    parametrize = { { "di" }, { "ci" }, { "vi" } },
})

T["text object hints"]["finds pair text objects from either delimiter"] = function(prefix)
    local str = "abc (efg)"

    local anchors = hm.text_object_hints(prefix, str, 5, #str)

    eq(true, has_anchor(anchors, "(", 5))
    eq(true, has_anchor(anchors, ")", 9))

    anchors = hm.text_object_hints(prefix, str, 9, #str)

    eq(true, has_anchor(anchors, "(", 5))
    eq(true, has_anchor(anchors, ")", 9))
end

T["text object hints"]["finds quote text objects from either quote"] = function(prefix)
    local str = 'this = "that"'

    local anchors = hm.text_object_hints(prefix, str, 8, #str)

    eq(true, has_anchor(anchors, '"', 8))
    eq(true, has_anchor(anchors, '"', 13))

    anchors = hm.text_object_hints(prefix, str, 13, #str)

    eq(true, has_anchor(anchors, '"', 8))
    eq(true, has_anchor(anchors, '"', 13))
end

return T
