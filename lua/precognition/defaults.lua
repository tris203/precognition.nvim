local M = {}

M.hints = {
    Caret = { text = "^", prio = 2 },
    Dollar = { text = "$", prio = 1 },
    MatchingPair = { text = "%", prio = 5 },
    Zero = { text = "0", prio = 1 },
    w = { text = "w", prio = 10 },
    b = { text = "b", prio = 9 },
    e = { text = "e", prio = 8 },
    W = { text = "W", prio = 7 },
    B = { text = "B", prio = 6 },
    E = { text = "E", prio = 5 },
}

M.config = {
    debounceMs = 0,
    startVisible = true,
    showBlankVirtLine = true,
    highlightFullVirtLine = false,
    highlightColor = { link = "SpecialComment" },
    targetedMotionHighlightColor = { link = "Comment" },
    textObjectHighlightColors = {
        { link = "DiffText" },
        { link = "DiffChange" },
        { link = "Visual" },
    },
    targetedMotionHints = {
        enabled = true,
        prio = 1,
    },
    hints = M.hints,
    gutterHints = {
        G = { text = "G", prio = 10 },
        gg = { text = "gg", prio = 9 },
        PrevParagraph = { text = "{", prio = 8 },
        NextParagraph = { text = "}", prio = 8 },
    },
    disabled_fts = {
        "startify",
    },
}

return M
