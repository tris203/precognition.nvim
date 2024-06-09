# 💭👀precognition.nvim

> /ˌpriːkɒɡˈnɪʃn/
> _noun_
>
> 1. foreknowledge of an event, especially as a form of extrasensory perception.

**precognition.nvim** assists with discovering motions (Both vertical and horizontal) to navigate your current buffer

![image](https://github.com/tris203/precognition.nvim/assets/18444302/6250954f-01c1-4343-8d89-0bdb84504c8d)

## 📦 Installation

Installation with any package manager, Lazy example below:

```lua

return {
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    config = {
    -- startVisible = true,
    -- showBlankVirtLine = true,
    -- highlightColor = { link = "Comment" },
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
    },
}
```

## ⚙️ Config

- `hints` can be hidden by setting their priority to 0. If you want to hide the
  entire virtual line, set all elements to `prio = 0` in combination with the
  below.
- `showBlankVirtLine = false`
  Setting this option will mean that if a Virtual Line would be blank it won't be
  rendered
- `gutterHints` can be hidden by setting their priority to 0.
- `highlightColor` can be set in two ways:

    1. As a table containing a link property pointing to an existing highlight group (see `:highlight` for valid options).
    2. As a table specifying custom highlight values, such as foreground and background colors. ([more info](<https://neovim.io/doc/user/api.html#nvim_set_hl()>))

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

More details on how to contribute can be found in CONTRIBUTING.md. Please read this prior to creating a pull request.

Don't forget to give the project a star! Thanks again!
