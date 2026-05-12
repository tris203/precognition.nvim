# 💭👀precognition.nvim

> /ˌpriːkɒɡˈnɪʃn/
> _noun_
>
> 1. foreknowledge of an event, especially as a form of extrasensory perception.

**precognition.nvim** assists with discovering motions (Both vertical and horizontal) to navigate your current buffer

![image](https://github.com/user-attachments/assets/82b60c32-638f-4b80-b2eb-754f68df18b8)

Visual/Change/Delete a/i Hints
![image](https://github.com/user-attachments/assets/8b8963df-b54c-434e-8b7f-57ca10328e0b)

Comma and Semi-Colon Repeat Hints
![image](https://github.com/user-attachments/assets/ec67d350-ed64-49b2-a93f-72676c5d91a1)

## 📦 Installation

Installation with any package manager, Lazy example below:

```lua

return {
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    opts = {
    -- startVisible = true,
    -- debounceMs = 0,
    -- showBlankVirtLine = true,
    -- highlightFullVirtLine = false,
    -- highlightColor = { link = "Comment" },
    -- targetedMotionHighlightColor = { link = "PrecognitionTargetedMotionDefault" },
    -- textObjectHighlightColors = {
    --     { link = "DiffText" },
    --     { link = "DiffChange" },
    --     { link = "Visual" },
    -- },
    -- targetedMotionHints = {
    --     enabled = true,
    --     prio = 1,
    -- },
    -- hints = {
    --      Caret = { text = "^", prio = 2 },
    --      Dollar = { text = "$", prio = 1 },
    --      MatchingPair = { text = "%", prio = 5 },
    --      Zero = { text = "0", prio = 1 },
    --      w = { text = "w", prio = 10 },
    --      b = { text = "b", prio = 9 },
    --      e = { text = "e", prio = 8 },
    --      W = { text = "W", prio = 7 },
    --      B = { text = "B", prio = 6 },
    --      E = { text = "E", prio = 5 },
    -- },
    -- gutterHints = {
    --     G = { text = "G", prio = 10 },
    --     gg = { text = "gg", prio = 9 },
    --     PrevParagraph = { text = "{", prio = 8 },
    --     NextParagraph = { text = "}", prio = 8 },
    -- },
    -- disabled_fts = {
    --     "startify",
    -- },
    },
}
```

## ⚙️ Config

- `hints` can be hidden by setting their priority to 0. If you want to hide the
  entire virtual line, set all elements to `prio = 0` in combination with the
  below.
- `debounceMs = 0`
  Debounces hint updates after cursor movement by the given number of
  milliseconds. The default `0` disables debouncing so hints update immediately.
- `showBlankVirtLine = false`
  Setting this option will mean that if a Virtual Line would be blank it won't be
  rendered
- `highlightFullVirtLine = true`
  Pads Inline Hint virtual lines to the current window width. This is useful when
  `highlightColor` includes a background color and you want that background to
  extend across the whole visible row.
- `gutterHints` can be hidden by setting their priority to 0.
- `highlightColor` can be set in two ways:

    1. As a table containing a link property pointing to an existing highlight group (see `:highlight` for valid options).
    2. As a table specifying custom highlight values, such as foreground and background colors. ([more info](<https://neovim.io/doc/user/api.html#nvim_set_hl()>))

- `textObjectHighlightColors` controls the nested text object range highlight groups.
  Each entry uses the same format as `highlightColor` and maps to
  `PrecognitionTextObjectRange1`, `PrecognitionTextObjectRange2`, etc.

- `targetedMotionHighlightColor` controls the highlight used for targeted motion
  key hints such as `f` and `F`. It uses the same format as `highlightColor`.
  The default links to `PrecognitionTargetedMotionDefault`, which blends
  `Comment` with `SpecialComment` so targeted motion hints stay subtle while
  remaining distinguishable from regular hints.

- `targetedMotionHints` controls dynamic same-line targeted motion hints. By
  default Precognition shows first-occurrence `f` / `F` hints for single-width
  printable non-whitespace characters. These hints render as `f` or `F` until
  that motion is pending, then render the target character. Leading counts are
  supported, so `2f` previews the second reachable occurrence of each target
  character. After `f`, `F`, `t`, or `T` has been used, repeat targets are shown
  as `;` and `,`. Set `enabled = false` to hide these hints. `prio` is a number that
  defaults to `1` and is used when an individual targeted hint does not provide
  its own priority; higher-priority hints win when multiple hints share a
  destination.

- `disabled_fts` can be used to disable `precognition` on specific filetypes.

### Hint priorities

Any hints that could appear in the same place as others should have unique priorities to avoid conflicts.

## ❔Usage

`precognition` can be controlled with the `Precognition` user command, as well as programmatically via the Lua API.

### Toggling

The hints can be toggled on and off with

```vim
:Precognition toggle
```

or

```lua
require("precognition").toggle()
```

The return value indicating the visible state can be used to produce a notification.

```lua
if require("precognition").toggle() then
    vim.notify("precognition on")
else
    vim.notify("precognition off")
end
```

The subcommands and functions `show` and `hide` are also available.

### Peeking

The hints can be peeked, this means that the hint will be show until the next
cursor movement.

```vim
:Precognition peek
```

or

```lua
require("precognition").peek()
```

## 💻 Supported Versions

This plugin supports stable and nightly. >0.9 at the time of writing.

## ✍️ Contributing

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion to improve the plugin, please open an issue first, fork the repo, and create a pull request.

If you have found a bug please open an issue, and submit a pull request with a failing test if possible.

If you’re interested in adding custom motions to Precognition, take a look at [interface.lua](https://github.com/tris203/precognition.nvim/blob/main/lua/precognition/motions/interface.lua) for the available integration points.

More details on how to contribute can be found in CONTRIBUTING.md. Please read this prior to creating a pull request.

Don't forget to give the project a star! Thanks again!
